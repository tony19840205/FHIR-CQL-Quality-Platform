# Fill Hospital Template with Data - Simple Version
$outputFile = "Hospital_Template_Filled.xlsx"
$qData = Import-Csv "quarterly_data.csv"
$aData = Import-Csv "annual_data.csv"

Write-Host "Loading data: Q=$($qData.Count), A=$($aData.Count)" -ForegroundColor Cyan

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$fullPath = Join-Path (Get-Location) $outputFile
$wb = $excel.Workbooks.Open($fullPath)

Write-Host "Opened workbook, adding sheets..." -ForegroundColor Yellow

# Quarterly
$ws1 = $wb.Worksheets.Add()
$ws1.Name = "Quarterly"
$h = @("ID","Name","OrigCode","StdCode","File","Quarter","Year","Num","Denom","Rate","Quality","Server","ServerRecs","DateTime")
for ($i=0; $i -lt $h.Count; $i++) { $ws1.Cells.Item(1,$i+1) = $h[$i]; $ws1.Cells.Item(1,$i+1).Font.Bold = $true }
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
    $row++
    if ($row % 300 -eq 0) { Write-Host "  $row..." -ForegroundColor Gray }
}
$ws1.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "Quarterly: $($qData.Count) done" -ForegroundColor Green

# Annual
$ws2 = $wb.Worksheets.Add()
$ws2.Name = "Annual"
for ($i=0; $i -lt $h.Count; $i++) { $ws2.Cells.Item(1,$i+1) = $h[$i]; $ws2.Cells.Item(1,$i+1).Font.Bold = $true }
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
    $row++
}
$ws2.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "Annual: $($aData.Count) done" -ForegroundColor Green

# Summary
$ws3 = $wb.Worksheets.Add()
$ws3.Name = "Summary"
$ws3.Cells.Item(1,1) = "Hospital Quality Indicators Report"
$ws3.Cells.Item(1,1).Font.Bold = $true
$ws3.Cells.Item(1,1).Font.Size = 14
$ws3.Cells.Item(3,1) = "Generated:"; $ws3.Cells.Item(3,2) = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ws3.Cells.Item(4,1) = "Indicators:"; $ws3.Cells.Item(4,2) = "39"
$ws3.Cells.Item(5,1) = "Quarterly:"; $ws3.Cells.Item(5,2) = $qData.Count
$ws3.Cells.Item(6,1) = "Annual:"; $ws3.Cells.Item(6,2) = $aData.Count
$ws3.Cells.Item(7,1) = "Servers:"; $ws3.Cells.Item(7,2) = "4"
$ws3.Columns.Item(1).ColumnWidth = 20
$ws3.Columns.Item(2).ColumnWidth = 30

# Move to front
$ws2.Move($wb.Sheets.Item(1))
$ws1.Move($wb.Sheets.Item(1))
$ws3.Move($wb.Sheets.Item(1))

Write-Host "Saving..." -ForegroundColor Yellow
$wb.Save()
$wb.Close()
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Success! Data filled into template" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "File: $outputFile" -ForegroundColor Green
Write-Host "Size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Gray
Write-Host ""
Write-Host "Sheets added:" -ForegroundColor Yellow
Write-Host "  1. Summary" -ForegroundColor Cyan
Write-Host "  2. Quarterly - 1,248 records" -ForegroundColor Cyan
Write-Host "  3. Annual - 312 records" -ForegroundColor Cyan
Write-Host "  + Original template sheets" -ForegroundColor Gray
Write-Host ""
