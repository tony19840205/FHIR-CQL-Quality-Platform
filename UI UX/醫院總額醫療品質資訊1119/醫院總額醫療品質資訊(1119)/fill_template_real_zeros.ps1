# Fill Template with Real Zeros (No Fake Data)
$outputFile = "Hospital_Template_Real_Zeros.xlsx"
$qData = Import-Csv "quarterly_data_real_zeros_20251110_125710.csv"
$aData = Import-Csv "annual_data_real_zeros_20251110_125710.csv"

Write-Host "Filling template with REAL ZEROS (no fake numbers)" -ForegroundColor Cyan
Write-Host "  Quarterly: $($qData.Count)" -ForegroundColor Gray
Write-Host "  Annual: $($aData.Count)" -ForegroundColor Gray

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$fullPath = Join-Path (Get-Location) $outputFile
$wb = $excel.Workbooks.Open($fullPath)

Write-Host "Adding sheets..." -ForegroundColor Yellow

# Notice Sheet
$wsNotice = $wb.Worksheets.Add()
$wsNotice.Name = "IMPORTANT - Read First"
$wsNotice.Cells.Item(1, 1) = "IMPORTANT NOTICE - ALL DATA IS ZERO"
$wsNotice.Cells.Item(1, 1).Font.Bold = $true
$wsNotice.Cells.Item(1, 1).Font.Size = 16
$wsNotice.Cells.Item(1, 1).Font.ColorIndex = 3
$wsNotice.Cells.Item(1, 1).Interior.ColorIndex = 6

$wsNotice.Cells.Item(3, 1) = "Why all zeros?"
$wsNotice.Cells.Item(3, 1).Font.Bold = $true
$wsNotice.Cells.Item(4, 1) = "- No real patient cases from FHIR servers"
$wsNotice.Cells.Item(5, 1) = "- This is demonstration data STRUCTURE only"
$wsNotice.Cells.Item(6, 1) = "- NO FAKE NUMBERS to avoid confusion"
$wsNotice.Cells.Item(7, 1) = "- Ready for real data when you connect to production servers"

$wsNotice.Cells.Item(9, 1) = "Data Fields:"
$wsNotice.Cells.Item(9, 1).Font.Bold = $true
$wsNotice.Cells.Item(10, 1) = "- Numerator = 0 (no cases)"
$wsNotice.Cells.Item(11, 1) = "- Denominator = 0 (no cases)"
$wsNotice.Cells.Item(12, 1) = "- Rate = 0 (cannot calculate)"
$wsNotice.Cells.Item(13, 1) = "- Server Records = 0 (no data retrieved)"
$wsNotice.Cells.Item(14, 1) = "- Quality = 'No Cases'"

$wsNotice.Cells.Item(16, 1) = "To get real data:"
$wsNotice.Cells.Item(16, 1).Font.Bold = $true
$wsNotice.Cells.Item(17, 1) = "1. Connect to production FHIR servers (not test servers)"
$wsNotice.Cells.Item(18, 1) = "2. Execute actual CQL queries against real patient database"
$wsNotice.Cells.Item(19, 1) = "3. Process and calculate from real clinical records"

$wsNotice.Columns.Item(1).ColumnWidth = 60
Write-Host "  Notice sheet added" -ForegroundColor Green

# Quarterly
$ws1 = $wb.Worksheets.Add()
$ws1.Name = "Quarterly (All Zeros)"
$h = @("ID","Name","OrigCode","StdCode","File","Quarter","Year","Num","Denom","Rate","Quality","Server","ServerRecs","DateTime")
for ($i=0; $i -lt $h.Count; $i++) { 
    $ws1.Cells.Item(1,$i+1) = $h[$i]
    $ws1.Cells.Item(1,$i+1).Font.Bold = $true
    $ws1.Cells.Item(1,$i+1).Interior.ColorIndex = 15
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
    $row++
    if ($row % 300 -eq 0) { Write-Host "  $row..." -ForegroundColor Gray }
}
$ws1.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "  Quarterly: $($qData.Count) (all zeros)" -ForegroundColor Green

# Annual
$ws2 = $wb.Worksheets.Add()
$ws2.Name = "Annual (All Zeros)"
for ($i=0; $i -lt $h.Count; $i++) { 
    $ws2.Cells.Item(1,$i+1) = $h[$i]
    $ws2.Cells.Item(1,$i+1).Font.Bold = $true
    $ws2.Cells.Item(1,$i+1).Interior.ColorIndex = 42
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
    $row++
}
$ws2.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "  Annual: $($aData.Count) (all zeros)" -ForegroundColor Green

# Move to front
$ws2.Move($wb.Sheets.Item(1))
$ws1.Move($wb.Sheets.Item(1))
$wsNotice.Move($wb.Sheets.Item(1))

Write-Host "Saving..." -ForegroundColor Yellow
$wb.Save()
$wb.Close()
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Template Filled with Real Zeros" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "File: $outputFile" -ForegroundColor Green
Write-Host "Size: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Gray
Write-Host ""
Write-Host "Important:" -ForegroundColor Yellow
Write-Host "  [✓] ALL fake random numbers REMOVED" -ForegroundColor Red
Write-Host "  [✓] All values are 0 (no real cases)" -ForegroundColor Cyan
Write-Host "  [✓] No misleading fake data" -ForegroundColor Cyan
Write-Host "  [✓] Structure ready for real data" -ForegroundColor Cyan
Write-Host ""
Write-Host "Read 'IMPORTANT - Read First' sheet for details" -ForegroundColor Yellow
Write-Host ""
