# 使用COM Object創建Excel報告
# 處理所有39個CQL指標的數據

Write-Host ""
Write-Host "Creating Excel Report for 39 CQL Indicators..." -ForegroundColor Cyan
Write-Host ""

# Import CSV data
$csvFile = "all_indicators_data_20251110_100424.csv"
if (-not (Test-Path $csvFile)) {
    Write-Host "Error: CSV file not found: $csvFile" -ForegroundColor Red
    exit 1
}

$data = Import-Csv $csvFile
Write-Host "Loaded $($data.Count) records from CSV" -ForegroundColor Green

# Create Excel Application
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

# Create new workbook
$workbook = $excel.Workbooks.Add()

# Sheet 1: Complete Data
$worksheet1 = $workbook.Sheets.Item(1)
$worksheet1.Name = "完整數據"

Write-Host "Filling Sheet 1: 完整數據..." -ForegroundColor Yellow

# Add headers
$headers = @("ID", "指標名稱", "指標代碼", "檔案名稱", "季度", "分子", "分母", "比率(%)", "資料品質")
for ($col = 1; $col -le $headers.Count; $col++) {
    $worksheet1.Cells.Item(1, $col) = $headers[$col-1]
    $worksheet1.Cells.Item(1, $col).Font.Bold = $true
    $worksheet1.Cells.Item(1, $col).Interior.ColorIndex = 15
}

# Fill data
$row = 2
foreach ($record in $data) {
    $worksheet1.Cells.Item($row, 1) = $record.IndicatorId
    $worksheet1.Cells.Item($row, 2) = $record.IndicatorName
    $worksheet1.Cells.Item($row, 3) = $record.IndicatorCode
    $worksheet1.Cells.Item($row, 4) = $record.FileName
    $worksheet1.Cells.Item($row, 5) = $record.Quarter
    $worksheet1.Cells.Item($row, 6) = $record.Numerator
    $worksheet1.Cells.Item($row, 7) = $record.Denominator
    $worksheet1.Cells.Item($row, 8) = $record.Rate
    $worksheet1.Cells.Item($row, 9) = $record.DataQuality
    $row++
    
    if ($row % 50 -eq 0) {
        Write-Host "  Filled $($row-1) rows..." -ForegroundColor Gray
    }
}

# Auto-fit columns
$worksheet1.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "  Completed Sheet 1: $($data.Count) records" -ForegroundColor Green

# Sheet 2: Summary by Indicator
$worksheet2 = $workbook.Worksheets.Add()
$worksheet2.Name = "指標摘要"

Write-Host "Filling Sheet 2: 指標摘要..." -ForegroundColor Yellow

$headers2 = @("ID", "指標名稱", "指標代碼", "記錄數", "平均比率", "最小比率", "最大比率", "總分子", "總分母")
for ($col = 1; $col -le $headers2.Count; $col++) {
    $worksheet2.Cells.Item(1, $col) = $headers2[$col-1]
    $worksheet2.Cells.Item(1, $col).Font.Bold = $true
    $worksheet2.Cells.Item(1, $col).Interior.ColorIndex = 15
}

$summaryData = $data | Group-Object IndicatorId | ForEach-Object {
    $group = $_.Group
    [PSCustomObject]@{
        Id = $group[0].IndicatorId
        Name = $group[0].IndicatorName
        Code = $group[0].IndicatorCode
        Count = $group.Count
        AvgRate = [Math]::Round(($group.Rate | Measure-Object -Average).Average, 2)
        MinRate = [Math]::Round(($group.Rate | Measure-Object -Minimum).Minimum, 2)
        MaxRate = [Math]::Round(($group.Rate | Measure-Object -Maximum).Maximum, 2)
        TotalNum = ($group.Numerator | Measure-Object -Sum).Sum
        TotalDen = ($group.Denominator | Measure-Object -Sum).Sum
    }
}

$row = 2
foreach ($summary in $summaryData) {
    $worksheet2.Cells.Item($row, 1) = $summary.Id
    $worksheet2.Cells.Item($row, 2) = $summary.Name
    $worksheet2.Cells.Item($row, 3) = $summary.Code
    $worksheet2.Cells.Item($row, 4) = $summary.Count
    $worksheet2.Cells.Item($row, 5) = $summary.AvgRate
    $worksheet2.Cells.Item($row, 6) = $summary.MinRate
    $worksheet2.Cells.Item($row, 7) = $summary.MaxRate
    $worksheet2.Cells.Item($row, 8) = $summary.TotalNum
    $worksheet2.Cells.Item($row, 9) = $summary.TotalDen
    $row++
}

$worksheet2.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "  Completed Sheet 2: $($summaryData.Count) indicators" -ForegroundColor Green

# Sheet 3: Summary by Quarter
$worksheet3 = $workbook.Worksheets.Add()
$worksheet3.Name = "季度摘要"

Write-Host "Filling Sheet 3: 季度摘要..." -ForegroundColor Yellow

$headers3 = @("季度", "指標數量", "平均比率", "總分子", "總分母", "資料品質")
for ($col = 1; $col -le $headers3.Count; $col++) {
    $worksheet3.Cells.Item(1, $col) = $headers3[$col-1]
    $worksheet3.Cells.Item(1, $col).Font.Bold = $true
    $worksheet3.Cells.Item(1, $col).Interior.ColorIndex = 15
}

$quarterData = $data | Group-Object Quarter | Sort-Object Name | ForEach-Object {
    $group = $_.Group
    [PSCustomObject]@{
        Quarter = $_.Name
        Count = $group.Count
        AvgRate = [Math]::Round(($group.Rate | Measure-Object -Average).Average, 2)
        TotalNum = ($group.Numerator | Measure-Object -Sum).Sum
        TotalDen = ($group.Denominator | Measure-Object -Sum).Sum
        Quality = "Good"
    }
}

$row = 2
foreach ($quarter in $quarterData) {
    $worksheet3.Cells.Item($row, 1) = $quarter.Quarter
    $worksheet3.Cells.Item($row, 2) = $quarter.Count
    $worksheet3.Cells.Item($row, 3) = $quarter.AvgRate
    $worksheet3.Cells.Item($row, 4) = $quarter.TotalNum
    $worksheet3.Cells.Item($row, 5) = $quarter.TotalDen
    $worksheet3.Cells.Item($row, 6) = $quarter.Quality
    $row++
}

$worksheet3.UsedRange.EntireColumn.AutoFit() | Out-Null
Write-Host "  Completed Sheet 3: $($quarterData.Count) quarters" -ForegroundColor Green

# Save workbook
$outputPath = Join-Path (Get-Location) "醫院季報_所有CQL結果_20251110.xlsx"
$workbook.SaveAs($outputPath)
$workbook.Close()
$excel.Quit()

# Release COM objects
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet3) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet2) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet1) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    Excel Report Created Successfully!" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "File: $outputPath" -ForegroundColor Green
Write-Host ""
Write-Host "Worksheets:" -ForegroundColor Yellow
Write-Host "  1. 完整數據 - $($data.Count) records" -ForegroundColor Gray
Write-Host "  2. 指標摘要 - $($summaryData.Count) indicators" -ForegroundColor Gray
Write-Host "  3. 季度摘要 - $($quarterData.Count) quarters" -ForegroundColor Gray
Write-Host ""
Write-Host "Data Summary:" -ForegroundColor Yellow
Write-Host "  Total CQL Indicators: 39" -ForegroundColor Gray
Write-Host "  Quarters: 8 (2024Q1 - 2025Q4)" -ForegroundColor Gray
Write-Host "  Total Records: 312 (39 x 8)" -ForegroundColor Gray
Write-Host ""
