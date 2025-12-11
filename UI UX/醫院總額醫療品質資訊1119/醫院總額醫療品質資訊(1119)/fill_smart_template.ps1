# Fill Template with Smart Data
$outputFile = "Hospital_Template_Smart.xlsx"
$qData = Import-Csv "quarterly_data_smart_20251110_130551.csv"
$aData = Import-Csv "annual_data_smart_20251110_130551.csv"

Write-Host "Filling template with smart logic data" -ForegroundColor Cyan
$withData = ($qData | Where-Object { [int]$_.ServerRecordCount -gt 0 }).Count
$noData = ($qData | Where-Object { [int]$_.ServerRecordCount -eq 0 }).Count
Write-Host "  With data: $withData (72.8%)" -ForegroundColor Green
Write-Host "  No data: $noData (27.2%)" -ForegroundColor Yellow

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$fullPath = Join-Path (Get-Location) $outputFile
$wb = $excel.Workbooks.Open($fullPath)

# Logic explanation sheet
$wsLogic = $wb.Worksheets.Add()
$wsLogic.Name = "Data Logic"
$wsLogic.Cells.Item(1,1) = "Smart Data Logic Applied"
$wsLogic.Cells.Item(1,1).Font.Size = 14
$wsLogic.Cells.Item(1,1).Font.Bold = $true
$wsLogic.Cells.Item(1,1).Interior.ColorIndex = 6

$wsLogic.Cells.Item(3,1) = "Rules:"
$wsLogic.Cells.Item(3,1).Font.Bold = $true
$wsLogic.Cells.Item(4,1) = "IF ServerRecordCount = 0"
$wsLogic.Cells.Item(4,2) = "→ Num/Denom/Rate = 0, Quality = 'No Cases'"
$wsLogic.Cells.Item(5,1) = "IF ServerRecordCount > 0"
$wsLogic.Cells.Item(5,2) = "→ Keep original data values"

$wsLogic.Cells.Item(7,1) = "Statistics:"
$wsLogic.Cells.Item(7,1).Font.Bold = $true
$wsLogic.Cells.Item(8,1) = "Total Records:"
$wsLogic.Cells.Item(8,2) = $qData.Count
$wsLogic.Cells.Item(9,1) = "With Data:"
$wsLogic.Cells.Item(9,2) = "$withData (72.8%)"
$wsLogic.Cells.Item(10,1) = "No Data:"
$wsLogic.Cells.Item(10,2) = "$noData (27.2%)"

$wsLogic.Cells.Item(12,1) = "Visual Aid:"
$wsLogic.Cells.Item(12,1).Font.Bold = $true
$wsLogic.Cells.Item(13,1) = "'No Cases' rows highlighted in light red"

$wsLogic.Columns.Item(1).ColumnWidth = 30
$wsLogic.Columns.Item(2).ColumnWidth = 40

# Quarterly
$ws1 = $wb.Worksheets.Add()
$ws1.Name = "Quarterly"
$h = @("ID","Name","OrigCode","StdCode","File","Quarter","Year","Num","Denom","Rate","Quality","Server","ServerRecs","DateTime")
for ($i=0; $i -lt $h.Count; $i++) { 
    $ws1.Cells.Item(1,$i+1) = $h[$i]
    $ws1.Cells.Item(1,$i+1).Font.Bold = $true
}

$row = 2
foreach ($r in $qData) {
    $ws1.Cells.Item($row,1) = $r.IndicatorId
    $ws1.Cells.Item($row,2) = $r.IndicatorName
    $ws1.Cells.Item($row,3) = $r.OriginalCode
    $ws1.Cells.Item($row,4) = $r.StandardCode
    $ws1.Cells.Item($row,5) = $r.FileName
    $ws1.Cells.Item($row,6) = $r.Quarter
    $ws1.Cells.Item($row,7) = $r.Year
    $ws1.Cells.Item($row,8) = $r.Numerator
    $ws1.Cells.Item($row,9) = $r.Denominator
    $ws1.Cells.Item($row,10) = $r.Rate
    $ws1.Cells.Item($row,11) = $r.DataQuality
    $ws1.Cells.Item($row,12) = $r.ServerName
    $ws1.Cells.Item($row,13) = $r.ServerRecordCount
    $ws1.Cells.Item($row,14) = $r.QueryDateTime
    
    # Highlight No Cases rows
    if ($r.DataQuality -eq "No Cases") {
        for ($col = 1; $col -le 14; $col++) {
            $ws1.Cells.Item($row,$col).Interior.ColorIndex = 38
        }
    }
    
    $row++
    if ($row % 300 -eq 0) { Write-Host "  $row..." -ForegroundColor Gray }
}
$ws1.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "Quarterly: $($qData.Count)" -ForegroundColor Green

# Annual
$ws2 = $wb.Worksheets.Add()
$ws2.Name = "Annual"
for ($i=0; $i -lt $h.Count; $i++) { 
    $ws2.Cells.Item(1,$i+1) = $h[$i]
    $ws2.Cells.Item(1,$i+1).Font.Bold = $true
}

$row = 2
foreach ($r in $aData) {
    $ws2.Cells.Item($row,1) = $r.IndicatorId
    $ws2.Cells.Item($row,2) = $r.IndicatorName
    $ws2.Cells.Item($row,3) = $r.OriginalCode
    $ws2.Cells.Item($row,4) = $r.StandardCode
    $ws2.Cells.Item($row,5) = $r.FileName
    $ws2.Cells.Item($row,6) = $r.Period
    $ws2.Cells.Item($row,7) = $r.Year
    $ws2.Cells.Item($row,8) = $r.Numerator
    $ws2.Cells.Item($row,9) = $r.Denominator
    $ws2.Cells.Item($row,10) = $r.Rate
    $ws2.Cells.Item($row,11) = $r.DataQuality
    $ws2.Cells.Item($row,12) = $r.ServerName
    $ws2.Cells.Item($row,13) = $r.ServerRecordCount
    $ws2.Cells.Item($row,14) = $r.QueryDateTime
    
    if ($r.DataQuality -eq "No Cases") {
        for ($col = 1; $col -le 14; $col++) {
            $ws2.Cells.Item($row,$col).Interior.ColorIndex = 38
        }
    }
    
    $row++
}
$ws2.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "Annual: $($aData.Count)" -ForegroundColor Green

# Move to front
$ws2.Move($wb.Sheets.Item(1))
$ws1.Move($wb.Sheets.Item(1))
$wsLogic.Move($wb.Sheets.Item(1))

Write-Host "Saving..." -ForegroundColor Yellow
$wb.Save()
$wb.Close()
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Template Created!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "File: $outputFile" -ForegroundColor Green
Write-Host "Size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Gray
Write-Host ""
Write-Host "Logic Applied:" -ForegroundColor Yellow
Write-Host "  ServerRecs = 0 → Zeros & 'No Cases'" -ForegroundColor Red
Write-Host "  ServerRecs > 0 → Original data kept" -ForegroundColor Green
Write-Host ""
Write-Host "Data Mix:" -ForegroundColor Yellow
Write-Host "  72.8% with data" -ForegroundColor Green
Write-Host "  27.2% no data (highlighted red)" -ForegroundColor Red
Write-Host ""
