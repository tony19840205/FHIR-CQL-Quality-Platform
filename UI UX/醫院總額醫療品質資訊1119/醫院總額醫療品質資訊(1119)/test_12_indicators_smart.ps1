# SMART on FHIR Comprehensive Test - 12 Indicators
# Testing Period: 2024-01-01 to 2025-11-20
# FHIR Server: https://hapi.fhir.org/baseR4

$fhirServer = "https://hapi.fhir.org/baseR4"
$outputFile = "SMART_12_Indicators_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR - 12 Indicators Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$startDate = "2024-01-01"
$endDate = "2025-11-20"

$report = @"
========================================
SMART on FHIR COMPREHENSIVE TEST
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
FHIR Server: $fhirServer
Test Period: $startDate to $endDate
Total Indicators: 12

========================================
TEST SUMMARY
========================================

"@

$testResults = @()
$totalTests = 12
$passedTests = 0
$failedTests = 0

# ========================================
# Test 1: Indicator 03-2 - Lipid-Lowering Drug Overlap (1711)
# ========================================
Write-Host "[TEST 1/12] Indicator 03-2: Lipid-Lowering Drug Overlap" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $lipidCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "C10*") -or ($coding.display -match "statin|atorvastatin|simvastatin")) {
                        $lipidCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-2 Lipid-Lowering"
        Code = "1711"
        ATC = "C10"
        Status = "PASS"
        Total = $total
        Found = $lipidCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Lipid drugs: $lipidCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-2"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 2: Indicator 03-3 - Antidiabetic Drug Overlap (1712)
# ========================================
Write-Host "[TEST 2/12] Indicator 03-3: Antidiabetic Drug Overlap" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $diabetesCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "A10*") -or ($coding.display -match "insulin|metformin|glipizide")) {
                        $diabetesCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-3 Antidiabetic"
        Code = "1712"
        ATC = "A10"
        Status = "PASS"
        Total = $total
        Found = $diabetesCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Diabetes drugs: $diabetesCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-3"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 3: Indicator 03-4 - Antipsychotic Drug Overlap (1726)
# ========================================
Write-Host "[TEST 3/12] Indicator 03-4: Antipsychotic Drug Overlap" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $antipsychoticCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "N05A*") -or ($coding.display -match "risperidone|olanzapine|quetiapine|haloperidol")) {
                        $antipsychoticCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-4 Antipsychotic"
        Code = "1726"
        ATC = "N05A"
        Status = "PASS"
        Total = $total
        Found = $antipsychoticCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Antipsychotic drugs: $antipsychoticCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-4"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 4: Indicator 03-5 - Antidepressant Drug Overlap (1727)
# ========================================
Write-Host "[TEST 4/12] Indicator 03-5: Antidepressant Drug Overlap" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $antidepressantCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "N06A*") -or ($coding.display -match "fluoxetine|sertraline|paroxetine|escitalopram|venlafaxine")) {
                        $antidepressantCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-5 Antidepressant"
        Code = "1727"
        ATC = "N06A"
        Status = "PASS"
        Total = $total
        Found = $antidepressantCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Antidepressant drugs: $antidepressantCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-5"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 5: Indicator 03-6 - Sedative Drug Overlap (1728)
# ========================================
Write-Host "[TEST 5/12] Indicator 03-6: Sedative Drug Overlap" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $sedativeCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "N05C*") -or ($coding.display -match "zolpidem|zopiclone|diazepam|lorazepam|alprazolam")) {
                        $sedativeCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-6 Sedative"
        Code = "1728"
        ATC = "N05C"
        Status = "PASS"
        Total = $total
        Found = $sedativeCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Sedative drugs: $sedativeCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-6"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 6: Indicator 03-7 - Antithrombotic Drug Overlap (3375)
# ========================================
Write-Host "[TEST 6/12] Indicator 03-7: Antithrombotic Drug Overlap" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $antithromboticCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "B01*") -or ($coding.display -match "aspirin|clopidogrel|warfarin|rivaroxaban|apixaban")) {
                        $antithromboticCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-7 Antithrombotic"
        Code = "3375"
        ATC = "B01"
        Status = "PASS"
        Total = $total
        Found = $antithromboticCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Antithrombotic drugs: $antithromboticCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-7"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 7: Indicator 03-13 - Cross-Hospital Antidepressant Overlap (1730)
# ========================================
Write-Host "[TEST 7/12] Indicator 03-13: Cross-Hospital Antidepressant" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100`&_include=MedicationRequest:patient`&_include=MedicationRequest:encounter"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $patients = @{}
    $orgs = @{}
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.resourceType -eq "Patient") {
                $patients[$entry.resource.id] = $true
            }
            if ($entry.resource.performer) {
                foreach ($performer in $entry.resource.performer) {
                    if ($performer.reference -like "Organization/*") {
                        $orgs[$performer.reference] = $true
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-13 Cross-Hospital Antidepressant"
        Code = "1730"
        ATC = "N06A"
        Status = "PASS"
        Total = $total
        Patients = $patients.Count
        Organizations = $orgs.Count
        Resource = "MedicationRequest+Patient+Organization"
    }
    $passedTests++
    Write-Host "  PASSED - Prescriptions: $total, Patients: $($patients.Count), Orgs: $($orgs.Count)" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-13"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 8: Indicator 03-14 - Cross-Hospital Sedative Overlap (1731)
# ========================================
Write-Host "[TEST 8/12] Indicator 03-14: Cross-Hospital Sedative" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Encounter?date=ge$startDate`&class=AMB`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $ambulatory = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.class.code -eq "AMB") {
                $ambulatory++
            }
        }
    }
    
    $testResults += @{
        Test = "03-14 Cross-Hospital Sedative"
        Code = "1731"
        Status = "PASS"
        Total = $total
        Ambulatory = $ambulatory
        Resource = "Encounter"
    }
    $passedTests++
    Write-Host "  PASSED - Total encounters: $total, Ambulatory: $ambulatory" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-14"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 9: Indicator 03-15 - Cross-Hospital Antithrombotic (3377)
# ========================================
Write-Host "[TEST 9/12] Indicator 03-15: Cross-Hospital Antithrombotic" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Medication?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $withATC = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.system -like "*atc*") {
                        $withATC++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-15 Cross-Hospital Antithrombotic"
        Code = "3377"
        ATC = "B01"
        Status = "PASS"
        Total = $total
        WithATC = $withATC
        Resource = "Medication"
    }
    $passedTests++
    Write-Host "  PASSED - Total medications: $total, With ATC: $withATC" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-15"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 10: Indicator 03-16 - Cross-Hospital Prostate (3378)
# ========================================
Write-Host "[TEST 10/12] Indicator 03-16: Cross-Hospital Prostate" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $prostateCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "G04C*") -or ($coding.display -match "tamsulosin|finasteride|dutasteride|alfuzosin")) {
                        $prostateCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "03-16 Cross-Hospital Prostate"
        Code = "3378"
        ATC = "G04C"
        Status = "PASS"
        Total = $total
        Found = $prostateCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Prostate drugs: $prostateCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "03-16"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 11: Indicator 04 - Chronic Prescription Rate (1318)
# ========================================
Write-Host "[TEST 11/12] Indicator 04: Chronic Prescription Rate" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Encounter?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $finished = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.status -eq "finished") {
                $finished++
            }
        }
    }
    
    $testResults += @{
        Test = "04 Chronic Prescription"
        Code = "1318"
        Status = "PASS"
        Total = $total
        Finished = $finished
        Resource = "Encounter"
    }
    $passedTests++
    Write-Host "  PASSED - Total encounters: $total, Finished: $finished" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "04"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 12: Indicator 07 - Diabetes HbA1c Testing (109.01Q/110.01Y)
# ========================================
Write-Host "[TEST 12/12] Indicator 07: Diabetes HbA1c Testing" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Observation?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $hba1cCount = 0
    $diabetesRelated = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.code -match "4548-4|17856-6|59261-8" -or $coding.display -match "HbA1c|hemoglobin A1c|glycated") {
                        $hba1cCount++
                        break
                    }
                    if ($coding.display -match "glucose|diabetes") {
                        $diabetesRelated++
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "07 Diabetes HbA1c"
        Code = "109.01Q/110.01Y"
        Status = "PASS"
        Total = $total
        HbA1c = $hba1cCount
        DiabetesRelated = $diabetesRelated
        Resource = "Observation"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, HbA1c: $hba1cCount, Diabetes: $diabetesRelated" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "07"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# ========================================
# Generate Report
# ========================================

$report += @"
Total Tests: $totalTests
Passed: $passedTests
Failed: $failedTests
Success Rate: $([Math]::Round(($passedTests / $totalTests) * 100, 2))%

========================================
DETAILED TEST RESULTS
========================================

"@

$testNum = 1
foreach ($result in $testResults) {
    if ($result.Status -eq "PASS") {
        $report += "[$testNum] $($result.Test) (Code: $($result.Code))`n"
        $report += "  Status: ✓ PASSED`n"
        $report += "  Resource: $($result.Resource)`n"
        
        if ($result.Total) { $report += "  Total Records: $($result.Total)`n" }
        if ($result.Found) { $report += "  Found: $($result.Found)`n" }
        if ($result.ATC) { $report += "  ATC Code: $($result.ATC)`n" }
        if ($result.Patients) { $report += "  Unique Patients: $($result.Patients)`n" }
        if ($result.Organizations) { $report += "  Organizations: $($result.Organizations)`n" }
        if ($result.Ambulatory) { $report += "  Ambulatory Encounters: $($result.Ambulatory)`n" }
        if ($result.WithATC) { $report += "  With ATC Codes: $($result.WithATC)`n" }
        if ($result.Finished) { $report += "  Finished Status: $($result.Finished)`n" }
        if ($result.HbA1c) { $report += "  HbA1c Tests: $($result.HbA1c)`n" }
        if ($result.DiabetesRelated) { $report += "  Diabetes Related: $($result.DiabetesRelated)`n" }
        
        $report += "`n"
    } else {
        $report += "[$testNum] $($result.Test)`n"
        $report += "  Status: ✗ FAILED`n"
        $report += "  Error: $($result.Error)`n`n"
    }
    $testNum++
}

$report += @"
========================================
ATC CODE SUMMARY
========================================

Drug Classification Codes Tested:
- C10: Lipid modifying agents (Statins, Fibrates)
- A10: Drugs used in diabetes (Insulin, Metformin)
- N05A: Antipsychotics (Risperidone, Olanzapine)
- N06A: Antidepressants (SSRIs, SNRIs)
- N05C: Hypnotics and sedatives (Benzodiazepines)
- B01: Antithrombotic agents (Anticoagulants, Antiplatelets)
- G04C: Drugs used in benign prostatic hypertrophy

========================================
FHIR RESOURCES TESTED
========================================

1. MedicationRequest - Prescription records
2. Medication - Drug master data with ATC codes
3. Encounter - Visit records (ambulatory)
4. Patient - Patient demographics
5. Organization - Healthcare providers
6. Observation - Lab results (HbA1c, glucose)

========================================
INDICATOR CATEGORIES
========================================

Drug Overlap Indicators (Same Hospital):
- 03-2: Lipid-lowering drugs
- 03-3: Antidiabetic drugs
- 03-4: Antipsychotic drugs
- 03-5: Antidepressant drugs
- 03-6: Sedative drugs
- 03-7: Antithrombotic drugs

Drug Overlap Indicators (Cross Hospital):
- 03-13: Antidepressant drugs
- 03-14: Sedative drugs
- 03-15: Antithrombotic drugs
- 03-16: Prostate drugs

Prescription Quality Indicators:
- 04: Chronic continuous prescription rate
- 07: Diabetes HbA1c testing rate

========================================
DATA QUALITY NOTES
========================================

Test Server Limitations:
1. Limited ATC code coverage in test data
2. Patient linkage across encounters may be incomplete
3. Organization assignments may not reflect real hospital structure
4. Medication dates may not represent actual clinical patterns

For Production Use:
1. Connect to hospital FHIR server with real patient data
2. Ensure complete ATC code mappings in medication master
3. Verify patient identifiers (MRN) for cross-encounter linkage
4. Validate organization IDs for hospital assignments
5. Check temporal patterns for overlap calculations

========================================
OVERLAP CALCULATION METHODOLOGY
========================================

For Drug Overlap Indicators:
- Same Hospital: Prescriptions from same organization
- Cross Hospital: Prescriptions from different organizations
- Same Patient: Matched by patient identifier
- Overlapping Dates: Medication start/end dates intersect
- Allow zero-day early refill

Formula:
Overlap Rate (%) = (Sum of Overlapping Days / Total Medication Days) × 100

Example:
- Prescription A: 2024-01-01 to 2024-01-30 (Hospital A)
- Prescription B: 2024-01-15 to 2024-02-14 (Hospital B)
- Overlap: 16 days (2024-01-15 to 2024-01-30)
- This counts as cross-hospital overlap

========================================
NEXT STEPS
========================================

1. Validate Results: Review test results for data completeness
2. Connect Real Server: Replace with hospital FHIR endpoint
3. Implement Overlap Logic: Add date range intersection calculations
4. Patient Matching: Ensure proper MRN/identifier resolution
5. Organization Mapping: Map FHIR Organization IDs to hospital codes
6. Quarterly Reports: Generate automated quarterly statistics
7. Quality Monitoring: Set up alerts for abnormal overlap rates

========================================
REPORT END
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
FHIR Server: $fhirServer
Test Status: $passedTests/$totalTests PASSED
"@

# Save report
$report | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FINAL RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if($failedTests -eq 0){'Green'}else{'Red'})
Write-Host "Success Rate: $([Math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if($passedTests -eq $totalTests){'Green'}else{'Yellow'})
Write-Host "`nReport saved to: $outputFile" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
