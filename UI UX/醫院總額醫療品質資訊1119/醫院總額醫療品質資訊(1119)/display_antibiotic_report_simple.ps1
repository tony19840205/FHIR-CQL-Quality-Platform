# encoding: utf-8
# 門診抗生素使用率報表顯示腳本

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    門診抗生素使用率查詢報表" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if results directory exists
if (-not (Test-Path "results")) {
    Write-Host "ERROR: results directory not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run: python run_antibiotic_query.py" -ForegroundColor Yellow
    Write-Host ""
    exit
}

# Check report files
$reportFile = "results\fhir_antibiotic_usage_report.csv"
$summaryFile = "results\antibiotic_usage_summary_report.csv"

if (-not (Test-Path $reportFile)) {
    Write-Host "ERROR: Report file not found: $reportFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run: python run_antibiotic_query.py" -ForegroundColor Yellow
    Write-Host ""
    exit
}

# Display detailed report
Write-Host "[1] Antibiotic Usage Detailed Report" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

try {
    $data = Import-Csv $reportFile -Encoding UTF8
    
    if ($data.Count -eq 0) {
        Write-Host "  No data found" -ForegroundColor Yellow
    } else {
        Write-Host "  Total records: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($data.Count)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "  First 10 records:" -ForegroundColor Cyan
        $data | Select-Object -First 10 | Format-Table -AutoSize
        
        Write-Host ""
    }
} catch {
    Write-Host "  ERROR: Failed to read report: $_" -ForegroundColor Red
}

# Display summary report
if (Test-Path $summaryFile) {
    Write-Host ""
    Write-Host "[2] Statistical Summary Report" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $content = Get-Content $summaryFile -Encoding UTF8
        
        foreach ($line in $content) {
            if ($line.Trim() -ne "") {
                Write-Host "  $line" -ForegroundColor White
            }
        }
        
        Write-Host ""
    } catch {
        Write-Host "  ERROR: Failed to read summary: $_" -ForegroundColor Red
    }
}

# Data quality check
Write-Host ""
Write-Host "[3] Data Quality Check" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

try {
    $data = Import-Csv $reportFile -Encoding UTF8
    
    # Check ATC codes
    $validAtc = $data | Where-Object { 
        $_.atc_code -match "^J" -and 
        $_.atc_code -notmatch "^J07" -and 
        $_.atc_code -notmatch "^J06BA"
    }
    
    Write-Host "  ATC Code Check:" -ForegroundColor Cyan
    Write-Host "    - Total records: $($data.Count)" -ForegroundColor White
    Write-Host "    - Valid antibiotic codes: $($validAtc.Count)" -ForegroundColor White
    $validRate = [math]::Round(($validAtc.Count / $data.Count) * 100, 2)
    Write-Host "    - Valid rate: " -NoNewline -ForegroundColor White
    
    if ($validRate -ge 95) {
        Write-Host "$validRate%25" -ForegroundColor Green
    } elseif ($validRate -ge 80) {
        Write-Host "$validRate%25" -ForegroundColor Yellow
    } else {
        Write-Host "$validRate%25" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # ATC classification distribution
    Write-Host "  ATC Classification Distribution:" -ForegroundColor Cyan
    $atcGroups = $data | Group-Object { $_.atc_code.Substring(0, 3) } | Sort-Object Count -Descending
    
    foreach ($group in $atcGroups) {
        $atcClass = $group.Name
        $count = $group.Count
        $percent = [math]::Round(($count / $data.Count) * 100, 2)
        
        Write-Host "    - $atcClass : $count records ($percent%25)" -ForegroundColor White
    }
    
    Write-Host ""
    
    # Route distribution
    Write-Host "  Route Distribution:" -ForegroundColor Cyan
    $routeGroups = $data | Group-Object route | Sort-Object Count -Descending
    
    foreach ($group in $routeGroups) {
        $route = $group.Name
        $count = $group.Count
        $percent = [math]::Round(($count / $data.Count) * 100, 2)
        
        Write-Host "    - $route : $count records ($percent%25)" -ForegroundColor White
    }
    
    Write-Host ""
    
} catch {
    Write-Host "  ERROR: Data quality check failed: $_" -ForegroundColor Red
}

# Important notes
Write-Host ""
Write-Host "[4] Important Notes" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "  Antibiotic Definition:" -ForegroundColor Yellow
Write-Host "     * ATC code starts with 'J' (Anti-infectives)" -ForegroundColor White
Write-Host "     * Exclude 'J07' (Vaccines)" -ForegroundColor White
Write-Host "     * Exclude 'J06BA' (Immunoglobulins)" -ForegroundColor White
Write-Host ""
Write-Host "  Exclusion Criteria:" -ForegroundColor Yellow
Write-Host "     * Emergency cases (case_category=02)" -ForegroundColor White
Write-Host "     * Outpatient surgery (case_category=03)" -ForegroundColor White
Write-Host "     * Prior approval drugs (prior_approval_flag=Y)" -ForegroundColor White
Write-Host "     * STAT medications (frequency=STAT)" -ForegroundColor White
Write-Host "     * Agency cases" -ForegroundColor White
Write-Host ""
Write-Host "  Reference Baseline (2022Q1):" -ForegroundColor Yellow
Write-Host "     * Antibiotic claims: 1,156,837" -ForegroundColor White
Write-Host "     * Total claims: 5,831,409" -ForegroundColor White
Write-Host "     * Antibiotic usage rate: 19.84%25" -ForegroundColor White
Write-Host ""

# End
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                              Report Display Complete" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tip: Check the results directory for detailed CSV files" -ForegroundColor Cyan
Write-Host ""
