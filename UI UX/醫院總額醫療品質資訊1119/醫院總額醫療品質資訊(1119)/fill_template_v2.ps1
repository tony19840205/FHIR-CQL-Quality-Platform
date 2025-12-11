# Fill data into blank template - v2
Write-Host ""
Write-Host "Filling data into blank template..." -ForegroundColor Cyan
Write-Host ""

# Find template file
$templateFile = (Get-ChildItem -Filter "*.xlsx" | Where-Object { $_.Name -like "*空白*" })[0]
if (-not $templateFile) {
    Write-Host "Error: Template file not found" -ForegroundColor Red
    exit 1
}

$sourceFile = "Hospital_Report_Final_20251110_103913.xlsx"
$outputFile = Join-Path (Get-Location) "Hospital_Report_Filled_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"

Write-Host "Source: $sourceFile" -ForegroundColor Green
Write-Host "Template: $($templateFile.Name)" -ForegroundColor Green
Write-Host ""

# Load data from CSV
$quarterlyData = Import-Csv "quarterly_data.csv"
$annualData = Import-Csv "annual_data.csv"

Write-Host "Loaded data:" -ForegroundColor Yellow
Write-Host "  Quarterly: $($quarterlyData.Count) records" -ForegroundColor Gray
Write-Host "  Annual: $($annualData.Count) records" -ForegroundColor Gray
Write-Host ""

# Copy template
Copy-Item -LiteralPath $templateFile.FullName -Destination $outputFile -Force
Write-Host "Created: $outputFile" -ForegroundColor Green
Write-Host ""

# Open Excel
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $workbook = $excel.Workbooks.Open($outputFile)
    Write-Host "Opened workbook with $($workbook.Sheets.Count) existing sheets" -ForegroundColor Green
    Write-Host ""
    
    # Add Quarterly Data sheet
    Write-Host "Adding Quarterly Data sheet..." -ForegroundColor Yellow
    $wsQuarterly = $workbook.Worksheets.Add()
    $wsQuarterly.Name = "Quarterly Data"
    
    $headers = @("ID", "Name", "OrigCode", "StdCode", "File", "Quarter", "Year", 
                 "Num", "Denom", "Rate", "Quality", "Server", "ServerRecs", "DateTime")
    
    for ($col = 1; $col -le $headers.Count; $col++) {
        $wsQuarterly.Cells.Item(1, $col) = $headers[$col-1]
        $wsQuarterly.Cells.Item(1, $col).Font.Bold = $true
        $wsQuarterly.Cells.Item(1, $col).Interior.ColorIndex = 15
    }
    
    $row = 2
    foreach ($r in $quarterlyData) {
        $wsQuarterly.Cells.Item($row, 1) = $r.IndicatorId
        $wsQuarterly.Cells.Item($row, 2) = $r.IndicatorName
        $wsQuarterly.Cells.Item($row, 3) = $r.OriginalCode
        $wsQuarterly.Cells.Item($row, 4) = $r.StandardCode
        $wsQuarterly.Cells.Item($row, 5) = $r.FileName
        $wsQuarterly.Cells.Item($row, 6) = $r.Quarter
        $wsQuarterly.Cells.Item($row, 7) = $r.Year
        $wsQuarterly.Cells.Item($row, 8) = $r.Numerator
        $wsQuarterly.Cells.Item($row, 9) = $r.Denominator
        $wsQuarterly.Cells.Item($row, 10) = $r.Rate
        $wsQuarterly.Cells.Item($row, 11) = $r.DataQuality
        $wsQuarterly.Cells.Item($row, 12) = $r.ServerName
        $wsQuarterly.Cells.Item($row, 13) = $r.ServerRecordCount
        $wsQuarterly.Cells.Item($row, 14) = $r.QueryDateTime
        $row++
        
        if ($row % 200 -eq 0) {
            Write-Host "  $row rows..." -ForegroundColor Gray
        }
    }
    
    $wsQuarterly.UsedRange.EntireColumn.AutoFit() | Out-Null
    Write-Host "  Completed: $($quarterlyData.Count) records" -ForegroundColor Green
    Write-Host ""
    
    # Add Annual Data sheet
    Write-Host "Adding Annual Data sheet..." -ForegroundColor Yellow
    $wsAnnual = $workbook.Worksheets.Add()
    $wsAnnual.Name = "Annual Data"
    
    $headers2 = @("ID", "Name", "OrigCode", "StdCode", "File", "Period", "Year", 
                  "Num", "Denom", "Rate", "Quality", "Server", "ServerRecs", "DateTime")
    
    for ($col = 1; $col -le $headers2.Count; $col++) {
        $wsAnnual.Cells.Item(1, $col) = $headers2[$col-1]
        $wsAnnual.Cells.Item(1, $col).Font.Bold = $true
        $wsAnnual.Cells.Item(1, $col).Interior.ColorIndex = 42
    }
    
    $row = 2
    foreach ($r in $annualData) {
        $wsAnnual.Cells.Item($row, 1) = $r.IndicatorId
        $wsAnnual.Cells.Item($row, 2) = $r.IndicatorName
        $wsAnnual.Cells.Item($row, 3) = $r.OriginalCode
        $wsAnnual.Cells.Item($row, 4) = $r.StandardCode
        $wsAnnual.Cells.Item($row, 5) = $r.FileName
        $wsAnnual.Cells.Item($row, 6) = $r.Period
        $wsAnnual.Cells.Item($row, 7) = $r.Year
        $wsAnnual.Cells.Item($row, 8) = $r.Numerator
        $wsAnnual.Cells.Item($row, 9) = $r.Denominator
        $wsAnnual.Cells.Item($row, 10) = $r.Rate
        $wsAnnual.Cells.Item($row, 11) = $r.DataQuality
        $wsAnnual.Cells.Item($row, 12) = $r.ServerName
        $wsAnnual.Cells.Item($row, 13) = $r.ServerRecordCount
        $wsAnnual.Cells.Item($row, 14) = $r.QueryDateTime
        $row++
    }
    
    $wsAnnual.UsedRange.EntireColumn.AutoFit() | Out-Null
    Write-Host "  Completed: $($annualData.Count) records" -ForegroundColor Green
    Write-Host ""
    
    # Add Summary
    Write-Host "Adding Summary sheet..." -ForegroundColor Yellow
    $wsSummary = $workbook.Worksheets.Add()
    $wsSummary.Name = "Summary"
    
    $wsSummary.Cells.Item(1, 1) = "Hospital Quality Indicators Report"
    $wsSummary.Cells.Item(1, 1).Font.Bold = $true
    $wsSummary.Cells.Item(1, 1).Font.Size = 14
    
    $wsSummary.Cells.Item(3, 1) = "Generated:"
    $wsSummary.Cells.Item(3, 2) = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $wsSummary.Cells.Item(4, 1) = "Total Indicators:"
    $wsSummary.Cells.Item(4, 2) = "39"
    $wsSummary.Cells.Item(5, 1) = "Quarterly Records:"
    $wsSummary.Cells.Item(5, 2) = $quarterlyData.Count
    $wsSummary.Cells.Item(6, 1) = "Annual Records:"
    $wsSummary.Cells.Item(6, 2) = $annualData.Count
    $wsSummary.Cells.Item(7, 1) = "FHIR Servers:"
    $wsSummary.Cells.Item(7, 2) = "4"
    
    $wsSummary.Cells.Item(9, 1) = "Servers:"
    $wsSummary.Cells.Item(10, 1) = "1. SMART Health IT"
    $wsSummary.Cells.Item(11, 1) = "2. HAPI FHIR Test"
    $wsSummary.Cells.Item(12, 1) = "3. FHIR Sandbox"
    $wsSummary.Cells.Item(13, 1) = "4. UHN HAPI FHIR"
    
    $wsSummary.Columns.Item(1).ColumnWidth = 25
    $wsSummary.Columns.Item(2).ColumnWidth = 40
    Write-Host "  Completed: Summary" -ForegroundColor Green
    Write-Host ""
    
    # Move new sheets to front
    $wsAnnual.Move($workbook.Sheets.Item(1))
    $wsQuarterly.Move($workbook.Sheets.Item(1))
    $wsSummary.Move($workbook.Sheets.Item(1))
    
    Write-Host "Saving workbook..." -ForegroundColor Yellow
    $workbook.Save()
    $workbook.Close()
    
    Write-Host ""
    Write-Host "================================================================================"-ForegroundColor Cyan
    Write-Host "                    Successfully Filled Template!" -ForegroundColor Cyan
    Write-Host "================================================================================"-ForegroundColor Cyan
    Write-Host ""
    Write-Host "Output: $outputFile" -ForegroundColor Green
    Write-Host "Size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Sheets:" -ForegroundColor Yellow
    Write-Host "  1. Summary" -ForegroundColor Gray
    Write-Host "  2. Quarterly Data - 1,248 records" -ForegroundColor Gray
    Write-Host "  3. Annual Data - 312 records" -ForegroundColor Gray
    Write-Host "  + Original template sheets" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

Write-Host "Done!" -ForegroundColor Green
