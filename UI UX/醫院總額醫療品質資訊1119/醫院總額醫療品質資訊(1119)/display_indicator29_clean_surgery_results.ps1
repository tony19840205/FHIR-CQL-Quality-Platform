# Indicator 29: Clean Surgery Postoperative Antibiotic Use Over 3 Days Rate
# Display Results Script

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Indicator 29: Clean Surgery Postoperative Antibiotic Use Over 3 Days Rate" -ForegroundColor Cyan
Write-Host "Indicator Code: 1155" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Data Structure
$data = @{
    Year112 = @{
        AntibioticOver3Days = 1489
        CleanSurgeryCount = 17234
        Rate = 8.64
    }
    Year113Q1 = @{
        AntibioticOver3Days = 328
        CleanSurgeryCount = 4287
        Rate = 7.65
    }
    Year113Q2 = @{
        AntibioticOver3Days = 365
        CleanSurgeryCount = 4731
        Rate = 7.71
    }
    Year113Q3 = @{
        AntibioticOver3Days = 391
        CleanSurgeryCount = 4912
        Rate = 7.96
    }
    Year113Q4 = @{
        AntibioticOver3Days = 372
        CleanSurgeryCount = 4869
        Rate = 7.64
    }
    Year113 = @{
        AntibioticOver3Days = 1456
        CleanSurgeryCount = 18799
        Rate = 7.75
    }
}

# Display Results
Write-Host "Results Table" -ForegroundColor Green
Write-Host ("=" * 100) -ForegroundColor Gray
Write-Host ""

$headerFormat = "{0,-18} {1,-50} {2,20}"
Write-Host ($headerFormat -f "Period", "Item", "Value") -ForegroundColor Yellow
Write-Host ("-" * 100) -ForegroundColor Gray

# 112 Year
$rowFormat = "{0,-18} {1,-50} {2,20}"
Write-Host ($rowFormat -f "112 Year", "Antibiotic Over 3 Days Cases", $data.Year112.AntibioticOver3Days)
Write-Host ($rowFormat -f "", "Clean Surgery Cases", $data.Year112.CleanSurgeryCount)
$rateText112 = "{0:N2}%" -f $data.Year112.Rate
Write-Host ($rowFormat -f "", "Antibiotic Over 3 Days Rate", $rateText112) -ForegroundColor Cyan
Write-Host ("-" * 100) -ForegroundColor Gray

# 113 Year Q1
Write-Host ($rowFormat -f "113 Year Q1", "Antibiotic Over 3 Days Cases", $data.Year113Q1.AntibioticOver3Days)
Write-Host ($rowFormat -f "", "Clean Surgery Cases", $data.Year113Q1.CleanSurgeryCount)
$rateTextQ1 = "{0:N2}%" -f $data.Year113Q1.Rate
Write-Host ($rowFormat -f "", "Antibiotic Over 3 Days Rate", $rateTextQ1) -ForegroundColor Cyan
Write-Host ("-" * 100) -ForegroundColor Gray

# 113 Year Q2
Write-Host ($rowFormat -f "113 Year Q2", "Antibiotic Over 3 Days Cases", $data.Year113Q2.AntibioticOver3Days)
Write-Host ($rowFormat -f "", "Clean Surgery Cases", $data.Year113Q2.CleanSurgeryCount)
$rateTextQ2 = "{0:N2}%" -f $data.Year113Q2.Rate
Write-Host ($rowFormat -f "", "Antibiotic Over 3 Days Rate", $rateTextQ2) -ForegroundColor Cyan
Write-Host ("-" * 100) -ForegroundColor Gray

# 113 Year Q3
Write-Host ($rowFormat -f "113 Year Q3", "Antibiotic Over 3 Days Cases", $data.Year113Q3.AntibioticOver3Days)
Write-Host ($rowFormat -f "", "Clean Surgery Cases", $data.Year113Q3.CleanSurgeryCount)
$rateTextQ3 = "{0:N2}%" -f $data.Year113Q3.Rate
Write-Host ($rowFormat -f "", "Antibiotic Over 3 Days Rate", $rateTextQ3) -ForegroundColor Cyan
Write-Host ("-" * 100) -ForegroundColor Gray

# 113 Year Q4
Write-Host ($rowFormat -f "113 Year Q4", "Antibiotic Over 3 Days Cases", $data.Year113Q4.AntibioticOver3Days)
Write-Host ($rowFormat -f "", "Clean Surgery Cases", $data.Year113Q4.CleanSurgeryCount)
$rateTextQ4 = "{0:N2}%" -f $data.Year113Q4.Rate
Write-Host ($rowFormat -f "", "Antibiotic Over 3 Days Rate", $rateTextQ4) -ForegroundColor Cyan
Write-Host ("-" * 100) -ForegroundColor Gray

# 113 Year Total
Write-Host ($rowFormat -f "113 Year Total", "Antibiotic Over 3 Days Cases", $data.Year113.AntibioticOver3Days) -ForegroundColor Green
Write-Host ($rowFormat -f "", "Clean Surgery Cases", $data.Year113.CleanSurgeryCount) -ForegroundColor Green
$rateTextTotal = "{0:N2}%" -f $data.Year113.Rate
Write-Host ($rowFormat -f "", "Antibiotic Over 3 Days Rate", $rateTextTotal) -ForegroundColor Green -BackgroundColor DarkBlue
Write-Host ("=" * 100) -ForegroundColor Gray

Write-Host ""
Write-Host ""

# Statistical Summary
Write-Host "Statistical Summary" -ForegroundColor Green
Write-Host ("=" * 100) -ForegroundColor Gray
Write-Host ""

$year112Rate = $data.Year112.Rate
$year113Rate = $data.Year113.Rate
$yearChange = [math]::Round($year113Rate - $year112Rate, 2)

Write-Host "Year-over-Year Comparison:" -ForegroundColor Yellow
Write-Host ("  112 Year: {0:N0} cases, {1:N0} surgeries, {2:N2}% rate" -f $data.Year112.AntibioticOver3Days, $data.Year112.CleanSurgeryCount, $data.Year112.Rate) -ForegroundColor White
Write-Host ("  113 Year: {0:N0} cases, {1:N0} surgeries, {2:N2}% rate" -f $data.Year113.AntibioticOver3Days, $data.Year113.CleanSurgeryCount, $data.Year113.Rate) -ForegroundColor White
Write-Host ""

Write-Host "Clean Surgery Volume Change:" -ForegroundColor Yellow
$volumeChange = $data.Year113.CleanSurgeryCount - $data.Year112.CleanSurgeryCount
$volumeChangePercent = [math]::Round(($volumeChange / $data.Year112.CleanSurgeryCount) * 100, 2)
$volumeText = "{0:N0}" -f $data.Year113.CleanSurgeryCount
$percentText = if ($volumeChangePercent -ge 0) { "+$volumeChangePercent%" } else { "$volumeChangePercent%" }
Write-Host ("  Total cases increased by {0:N0} ({1})" -f $volumeChange, $percentText) -ForegroundColor White
Write-Host ""

Write-Host "Rate Trend Analysis:" -ForegroundColor Yellow
if ($yearChange -lt 0) {
    Write-Host ("  Rate DECREASED by {0:N2} percentage points (GOOD)" -f [math]::Abs($yearChange)) -ForegroundColor Green
} elseif ($yearChange -gt 0) {
    Write-Host ("  Rate INCREASED by {0:+N2} percentage points (CONCERN)" -f $yearChange) -ForegroundColor Red
} else {
    Write-Host "  Rate remained stable (NEUTRAL)" -ForegroundColor Yellow
}
Write-Host ""

$quarterRates = @($data.Year113Q1.Rate, $data.Year113Q2.Rate, $data.Year113Q3.Rate, $data.Year113Q4.Rate)
$maxQuarterRate = ($quarterRates | Measure-Object -Maximum).Maximum
$minQuarterRate = ($quarterRates | Measure-Object -Minimum).Minimum
$quarterVariation = [math]::Round($maxQuarterRate - $minQuarterRate, 2)

Write-Host "Quarterly Variation:" -ForegroundColor Yellow
Write-Host ("  Range: {0:N2}% - {1:N2}%" -f $minQuarterRate, $maxQuarterRate) -ForegroundColor White
Write-Host ("  Variation: {0:N2} percentage points" -f $quarterVariation) -ForegroundColor White
if ($quarterVariation -lt 1.0) {
    Write-Host "  Assessment: Very stable (EXCELLENT)" -ForegroundColor Green
} elseif ($quarterVariation -lt 2.0) {
    Write-Host "  Assessment: Stable (GOOD)" -ForegroundColor Green
} else {
    Write-Host "  Assessment: Moderate variation (ACCEPTABLE)" -ForegroundColor Yellow
}
Write-Host ""

# Clinical Assessment
Write-Host ("=" * 100) -ForegroundColor Gray
Write-Host "Clinical Assessment" -ForegroundColor Green
Write-Host ("=" * 100) -ForegroundColor Gray
Write-Host ""

$currentRate = $data.Year113.Rate
$ratingColor = "Yellow"
$ratingText = "FAIR"

if ($currentRate -lt 5.0) {
    $ratingColor = "Green"
    $ratingText = "EXCELLENT"
} elseif ($currentRate -lt 8.0) {
    $ratingColor = "Green"
    $ratingText = "GOOD"
} elseif ($currentRate -lt 10.0) {
    $ratingColor = "Yellow"
    $ratingText = "FAIR"
} else {
    $ratingColor = "Red"
    $ratingText = "NEEDS IMPROVEMENT"
}

Write-Host "Overall Rating: " -NoNewline
Write-Host $ratingText -ForegroundColor $ratingColor
Write-Host ""

Write-Host "Key Findings:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Antibiotic Stewardship Performance:" -ForegroundColor Cyan
$targetText = "Target: less than 8.0%"
Write-Host ("   - 113 Year rate: {0:N2}% ({1})" -f $currentRate, $targetText) -ForegroundColor White
if ($currentRate -lt 8.0) {
    Write-Host "   - Status: WITHIN TARGET" -ForegroundColor Green
} else {
    Write-Host "   - Status: ABOVE TARGET" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "2. Clean Surgery Volume:" -ForegroundColor Cyan
Write-Host ("   - 112 Year: {0:N0} cases" -f $data.Year112.CleanSurgeryCount) -ForegroundColor White
Write-Host ("   - 113 Year: $volumeText cases ($percentText)") -ForegroundColor White
Write-Host ""

Write-Host "3. Temporal Trend:" -ForegroundColor Cyan
if ($yearChange -lt -0.5) {
    Write-Host "   - Improving trend (antibiotic use decreasing)" -ForegroundColor Green
} elseif ($yearChange -gt 0.5) {
    Write-Host "   - Concerning trend (antibiotic use increasing)" -ForegroundColor Red
} else {
    Write-Host "   - Stable performance maintained" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "4. Quarterly Consistency:" -ForegroundColor Cyan
Write-Host ("   - Q1: {0:N2}%, Q2: {1:N2}%, Q3: {2:N2}%, Q4: {3:N2}%" -f $data.Year113Q1.Rate, $data.Year113Q2.Rate, $data.Year113Q3.Rate, $data.Year113Q4.Rate) -ForegroundColor White
if ($quarterVariation -lt 1.0) {
    Write-Host "   - Excellent consistency across quarters" -ForegroundColor Green
} else {
    Write-Host "   - Acceptable variation between quarters" -ForegroundColor Yellow
}
Write-Host ""

# Export CSV
Write-Host ("=" * 100) -ForegroundColor Gray
Write-Host "Exporting Results" -ForegroundColor Green
Write-Host ("=" * 100) -ForegroundColor Gray
Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = "indicator29_clean_surgery_results_$timestamp.csv"

$csvData = @()
$csvData += [PSCustomObject]@{
    Period = "112_Year"
    PeriodCN = "112_Year"
    AntibioticOver3Days = $data.Year112.AntibioticOver3Days
    CleanSurgeryCount = $data.Year112.CleanSurgeryCount
    Rate = $data.Year112.Rate
}
$csvData += [PSCustomObject]@{
    Period = "113_Year_Q1"
    PeriodCN = "113_Year_Q1"
    AntibioticOver3Days = $data.Year113Q1.AntibioticOver3Days
    CleanSurgeryCount = $data.Year113Q1.CleanSurgeryCount
    Rate = $data.Year113Q1.Rate
}
$csvData += [PSCustomObject]@{
    Period = "113_Year_Q2"
    PeriodCN = "113_Year_Q2"
    AntibioticOver3Days = $data.Year113Q2.AntibioticOver3Days
    CleanSurgeryCount = $data.Year113Q2.CleanSurgeryCount
    Rate = $data.Year113Q2.Rate
}
$csvData += [PSCustomObject]@{
    Period = "113_Year_Q3"
    PeriodCN = "113_Year_Q3"
    AntibioticOver3Days = $data.Year113Q3.AntibioticOver3Days
    CleanSurgeryCount = $data.Year113Q3.CleanSurgeryCount
    Rate = $data.Year113Q3.Rate
}
$csvData += [PSCustomObject]@{
    Period = "113_Year_Q4"
    PeriodCN = "113_Year_Q4"
    AntibioticOver3Days = $data.Year113Q4.AntibioticOver3Days
    CleanSurgeryCount = $data.Year113Q4.CleanSurgeryCount
    Rate = $data.Year113Q4.Rate
}
$csvData += [PSCustomObject]@{
    Period = "113_Year_Total"
    PeriodCN = "113_Year_Total"
    AntibioticOver3Days = $data.Year113.AntibioticOver3Days
    CleanSurgeryCount = $data.Year113.CleanSurgeryCount
    Rate = $data.Year113.Rate
}

$csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Results exported to: $csvPath" -ForegroundColor Green
Write-Host ""

Write-Host ("=" * 100) -ForegroundColor Gray
Write-Host "Analysis Complete" -ForegroundColor Green
Write-Host ("=" * 100) -ForegroundColor Gray
