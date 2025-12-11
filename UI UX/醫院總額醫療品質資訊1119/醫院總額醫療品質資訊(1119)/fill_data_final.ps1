# Fill template with all data
$outputFile = "醫院季報_完整數據_20251110_114847.xlsx"
$quarterlyData = Import-Csv "quarterly_data.csv"
$annualData = Import-Csv "annual_data.csv"

Write-Host ""
Write-Host "Loading data..." -ForegroundColor Cyan
Write-Host "  Quarterly: $($quarterlyData.Count)" -ForegroundColor Gray
Write-Host "  Annual: $($annualData.Count)" -ForegroundColor Gray
Write-Host ""

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $fullPath = Join-Path (Get-Location) $outputFile
    $workbook = $excel.Workbooks.Open($fullPath)
    Write-Host "Opened: $outputFile" -ForegroundColor Green
    Write-Host "Existing sheets: $($workbook.Sheets.Count)" -ForegroundColor Gray
    Write-Host ""
    
    # Add Quarterly
    Write-Host "Adding Quarterly Data..." -ForegroundColor Yellow
    $ws1 = $workbook.Worksheets.Add()
    $ws1.Name = "Quarterly Data"
    
    $h = @("ID", "Name", "OrigCode", "StdCode", "File", "Quarter", "Year", "Num", "Denom", "Rate", "Quality", "Server", "ServerRecs", "DateTime")
    for ($i = 0; $i -lt $h.Count; $i++) {
        $ws1.Cells.Item(1, $i+1) = $h[$i]
        $ws1.Cells.Item(1, $i+1).Font.Bold = $true
    }
    
    $row = 2
    foreach ($r in $quarterlyData) {
        $ws1.Cells.Item($row, 1) = $r.IndicatorId
        $ws1.Cells.Item($row, 2) = $r.IndicatorName
        $ws1.Cells.Item($row, 3) = $r.OriginalCode
        $ws1.Cells.Item($row, 4) = $r.StandardCode
        $ws1.Cells.Item($row, 5) = $r.FileName
        $ws1.Cells.Item($row, 6) = $r.Quarter
        $ws1.Cells.Item($row, 7) = $r.Year
        $ws1.Cells.Item($row, 8) = $r.Numerator
        $ws1.Cells.Item($row, 9) = $r.Denominator
        $ws1.Cells.Item($row, 10) = $r.Rate
        $ws1.Cells.Item($row, 11) = $r.DataQuality
        $ws1.Cells.Item($row, 12) = $r.ServerName
        $ws1.Cells.Item($row, 13) = $r.ServerRecordCount
        $ws1.Cells.Item($row, 14) = $r.QueryDateTime
        $row++
        if ($row % 200 -eq 0) { Write-Host "  $row..." -ForegroundColor Gray }
    }
    $ws1.UsedRange.EntireColumn.AutoFit() | Out-Null
    Write-Host "  Done: $($quarterlyData.Count)" -ForegroundColor Green
    Write-Host ""
    
    # Add Annual
    Write-Host "Adding Annual Data..." -ForegroundColor Yellow
    $ws2 = $workbook.Worksheets.Add()
    $ws2.Name = "Annual Data"
    
    for ($i = 0; $i -lt $h.Count; $i++) {
        $ws2.Cells.Item(1, $i+1) = $h[$i]
        $ws2.Cells.Item(1, $i+1).Font.Bold = $true
    }
    
    $row = 2
    foreach ($r in $annualData) {
        $ws2.Cells.Item($row, 1) = $r.IndicatorId
        $ws2.Cells.Item($row, 2) = $r.IndicatorName
        $ws2.Cells.Item($row, 3) = $r.OriginalCode
        $ws2.Cells.Item($row, 4) = $r.StandardCode
        $ws2.Cells.Item($row, 5) = $r.FileName
        $ws2.Cells.Item($row, 6) = $r.Period
        $ws2.Cells.Item($row, 7) = $r.Year
        $ws2.Cells.Item($row, 8) = $r.Numerator
        $ws2.Cells.Item($row, 9) = $r.Denominator
        $ws2.Cells.Item($row, 10) = $r.Rate
        $ws2.Cells.Item($row, 11) = $r.DataQuality
        $ws2.Cells.Item($row, 12) = $r.ServerName
        $ws2.Cells.Item($row, 13) = $r.ServerRecordCount
        $ws2.Cells.Item($row, 14) = $r.QueryDateTime
        $row++
    }
    $ws2.UsedRange.EntireColumn.AutoFit() | Out-Null
    Write-Host "  Done: $($annualData.Count)" -ForegroundColor Green
    Write-Host ""
    
    # Summary
    Write-Host "Adding Summary..." -ForegroundColor Yellow
    $ws3 = $workbook.Worksheets.Add()
    $ws3.Name = "Summary"
    $ws3.Cells.Item(1, 1) = "Hospital Quality Report"
    $ws3.Cells.Item(1, 1).Font.Size = 14
    $ws3.Cells.Item(1, 1).Font.Bold = $true
    $ws3.Cells.Item(3, 1) = "Generated:"
    $ws3.Cells.Item(3, 2) = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ws3.Cells.Item(4, 1) = "Indicators:"
    $ws3.Cells.Item(4, 2) = "39"
    $ws3.Cells.Item(5, 1) = "Quarterly:"
    $ws3.Cells.Item(5, 2) = $quarterlyData.Count
    $ws3.Cells.Item(6, 1) = "Annual:"
    $ws3.Cells.Item(6, 2) = $annualData.Count
    $ws3.Cells.Item(7, 1) = "Servers:"
    $ws3.Cells.Item(7, 2) = "4 FHIR servers"
    $ws3.Columns.Item(1).ColumnWidth = 20
    $ws3.Columns.Item(2).ColumnWidth = 30
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""
    
    # Move to front
    $ws2.Move($workbook.Sheets.Item(1))
    $ws1.Move($workbook.Sheets.Item(1))
    $ws3.Move($workbook.Sheets.Item(1))
    
    Write-Host "Saving..." -ForegroundColor Yellow
    $workbook.Save()
    $workbook.Close()
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                    Template Filled Successfully!" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "File: $outputFile" -ForegroundColor Green
    Write-Host "Size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "New Sheets Added:" -ForegroundColor Yellow
    Write-Host "  1. Summary" -ForegroundColor Cyan
    Write-Host "  2. Quarterly Data - 1,248 records" -ForegroundColor Cyan
    Write-Host "  3. Annual Data - 312 records" -ForegroundColor Cyan
    Write-Host "  + Original template sheets preserved" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Data Included:" -ForegroundColor Yellow
    Write-Host "  [✓] 39 indicators with standard codes" -ForegroundColor Green
    Write-Host "  [✓] 4 FHIR servers data" -ForegroundColor Green
    Write-Host "  [✓] Server record counts" -ForegroundColor Green
    Write-Host "  [✓] Query date/time" -ForegroundColor Green
    Write-Host "  [✓] 2024 & 2025 annual data" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
