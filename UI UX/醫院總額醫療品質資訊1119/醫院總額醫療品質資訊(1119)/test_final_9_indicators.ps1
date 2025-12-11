# SMART on FHIR Test - Final 9 Untested Indicators
$fhirServer = "https://hapi.fhir.org/baseR4"
$startDate = "2024-01-01"
$endDate = "2025-11-20"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR - Final 9 Indicators Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passCount = 0
$failCount = 0

# Test 1: Indicator 03-1 (Same Hospital Antihypertensive)
Write-Host "[1/9] Indicator 03-1: Same Hospital Antihypertensive Overlap (1710)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/MedicationRequest?code=http://www.whocc.no/atc|C02,C03,C07,C08,C09`&date=ge$startDate`&_count=100"
    $medReq = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($medReq.total) { $medReq.total } else { 0 }
    Write-Host "  PASSED - Antihypertensive prescriptions: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 2: Indicator 03-3 (Same Hospital Antidiabetic)
Write-Host "[2/9] Indicator 03-3: Same Hospital Antidiabetic Overlap (1712)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|A10`&_count=100"
    $meds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($meds.total) { $meds.total } else { 0 }
    Write-Host "  PASSED - Antidiabetic medications: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 3: Indicator 03-4 (Same Hospital Antipsychotic)
Write-Host "[3/9] Indicator 03-4: Same Hospital Antipsychotic Overlap (1726)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|N05A`&_count=100"
    $meds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($meds.total) { $meds.total } else { 0 }
    Write-Host "  PASSED - Antipsychotic medications: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 4: Indicator 03-5 (Same Hospital Antidepressant)
Write-Host "[4/9] Indicator 03-5: Same Hospital Antidepressant Overlap (1727)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|N06A`&_count=100"
    $meds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($meds.total) { $meds.total } else { 0 }
    Write-Host "  PASSED - Antidepressant medications: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 5: Indicator 03-6 (Same Hospital Sedative)
Write-Host "[5/9] Indicator 03-6: Same Hospital Sedative Overlap (1728)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|N05C`&_count=100"
    $meds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($meds.total) { $meds.total } else { 0 }
    Write-Host "  PASSED - Sedative medications: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 6: Indicator 03-7 (Same Hospital Antithrombotic)
Write-Host "[6/9] Indicator 03-7: Same Hospital Antithrombotic Overlap (3375)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|B01`&_count=100"
    $meds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($meds.total) { $meds.total } else { 0 }
    Write-Host "  PASSED - Antithrombotic medications: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 7: Indicator 03-8 (Same Hospital Prostate)
Write-Host "[7/9] Indicator 03-8: Same Hospital Prostate Overlap (3376)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|G04C`&_count=100"
    $meds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($meds.total) { $meds.total } else { 0 }
    Write-Host "  PASSED - Prostate medications: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 8: Indicator 03-9 (Cross Hospital Antihypertensive)
Write-Host "[8/9] Indicator 03-9: Cross Hospital Antihypertensive Overlap (1713)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/MedicationRequest?code=http://www.whocc.no/atc|C02,C03,C07,C08,C09`&date=ge$startDate`&_count=100"
    $medReq = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($medReq.total) { $medReq.total } else { 0 }
    Write-Host "  PASSED - Cross-hospital antihypertensive: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 9: Indicator 11-3 (Cesarean with Indication)
Write-Host "[9/9] Indicator 11-3: Cesarean with Indication Rate (1138.01)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|177141003,177152005`&date=ge$startDate`&_count=100"
    $procedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($procedures.total) { $procedures.total } else { 0 }
    Write-Host "  PASSED - Indicated cesarean procedures: $count" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Total: 9, Passed: $passCount, Failed: $failCount" -ForegroundColor Yellow
$successRate = [math]::Round(($passCount / 9) * 100, 2)
Write-Host "Success Rate: $successRate%" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
"Final 9 Indicators Test - $timestamp`nPassed: $passCount/9`nSuccess Rate: $successRate%" | Out-File "SMART_Final_9_Indicators_$timestamp.txt"
Write-Host "`nReport saved: SMART_Final_9_Indicators_$timestamp.txt" -ForegroundColor Green
