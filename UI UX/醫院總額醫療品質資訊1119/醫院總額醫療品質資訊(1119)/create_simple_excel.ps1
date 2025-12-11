# Create Excel Report from CSV data
# 39 CQL Indicators

Write-Host ""
Write-Host "Creating Excel Report..." -ForegroundColor Cyan
Write-Host ""

$csvFile = "all_indicators_data_20251110_100424.csv"
$data = Import-Csv $csvFile
Write-Host "Loaded $($data.Count) records" -ForegroundColor Green

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$workbook = $excel.Workbooks.Add()

# Sheet 1
$ws1 = $workbook.Sheets.Item(1)
$ws1.Name = "Data"

$row = 1
$ws1.Cells.Item($row, 1) = "ID"
$ws1.Cells.Item($row, 2) = "Name"
$ws1.Cells.Item($row, 3) = "Code"
$ws1.Cells.Item($row, 4) = "File"
$ws1.Cells.Item($row, 5) = "Quarter"
$ws1.Cells.Item($row, 6) = "Numerator"
$ws1.Cells.Item($row, 7) = "Denominator"
$ws1.Cells.Item($row, 8) = "Rate"
$ws1.Cells.Item($row, 9) = "Quality"

foreach ($r in $data) {
    $row++
    $ws1.Cells.Item($row, 1) = $r.IndicatorId
    $ws1.Cells.Item($row, 2) = $r.IndicatorName
    $ws1.Cells.Item($row, 3) = $r.IndicatorCode
    $ws1.Cells.Item($row, 4) = $r.FileName
    $ws1.Cells.Item($row, 5) = $r.Quarter
    $ws1.Cells.Item($row, 6) = $r.Numerator
    $ws1.Cells.Item($row, 7) = $r.Denominator
    $ws1.Cells.Item($row, 8) = $r.Rate
    $ws1.Cells.Item($row, 9) = $r.DataQuality
}

$ws1.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "Sheet 1 completed: $($data.Count) records" -ForegroundColor Green

$outputPath = Join-Path (Get-Location) "Hospital_Report_39_Indicators.xlsx"
$workbook.SaveAs($outputPath)
$workbook.Close()
$excel.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws1) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "Excel Report Created!" -ForegroundColor Green
Write-Host "File: $outputPath" -ForegroundColor Cyan
Write-Host "Records: 312 (39 indicators x 8 quarters)" -ForegroundColor Cyan
Write-Host ""
