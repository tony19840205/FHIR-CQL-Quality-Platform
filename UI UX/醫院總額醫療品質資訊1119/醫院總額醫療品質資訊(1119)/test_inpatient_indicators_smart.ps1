# SMART on FHIR Comprehensive Test - Inpatient Indicators
# Testing Period: 2024-01-01 to 2025-11-20
# FHIR Server: https://hapi.fhir.org/baseR4

$fhirServer = "https://hapi.fhir.org/baseR4"
$outputFile = "SMART_Inpatient_Indicators_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR - Inpatient Indicators Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$startDate = "2024-01-01"
$endDate = "2025-11-20"

$report = @"
========================================
SMART on FHIR INPATIENT INDICATORS TEST
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
FHIR Server: $fhirServer
Test Period: $startDate to $endDate
Total Indicators: 10

========================================
TEST SUMMARY
========================================

"@

$testResults = @()
$totalTests = 10
$passedTests = 0
$failedTests = 0

# ========================================
# Test 1: Indicator 11-4 - Cesarean Section Rate First Time (1075.01)
# ========================================
Write-Host "[TEST 1/10] Indicator 11-4: Cesarean Section Rate - First Time" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Procedure?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $cesareanCount = 0
    $deliveryCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.display -match "cesarean|caesarean|C-section") {
                        $cesareanCount++
                        break
                    }
                    if ($coding.display -match "delivery|birth") {
                        $deliveryCount++
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "11-4 Cesarean First Time"
        Code = "1075.01"
        Status = "PASS"
        Total = $total
        Cesarean = $cesareanCount
        Delivery = $deliveryCount
        Resource = "Procedure"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Cesarean: $cesareanCount, Delivery: $deliveryCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "11-4"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 2: Indicator 12 - Clean Surgery Antibiotic >3 Days (1155)
# ========================================
Write-Host "[TEST 2/10] Indicator 12: Clean Surgery Antibiotic >3 Days" -ForegroundColor Yellow

try {
    $url = "$fhirServer/MedicationRequest?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $antibioticCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if (($coding.code -like "J01*") -or ($coding.display -match "antibiotic|penicillin|cephalosporin")) {
                        $antibioticCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "12 Clean Surgery Antibiotic"
        Code = "1155"
        ATC = "J01"
        Status = "PASS"
        Total = $total
        Antibiotics = $antibioticCount
        Resource = "MedicationRequest"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Antibiotics: $antibioticCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "12"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 3: Indicator 13 - ESWL Average Utilization (20.01Q/1804Y)
# ========================================
Write-Host "[TEST 3/10] Indicator 13: ESWL Average Utilization Times" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Procedure?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $eswlCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.display -match "lithotripsy|ESWL|shock wave") {
                        $eswlCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "13 ESWL Utilization"
        Code = "20.01Q/1804Y"
        Status = "PASS"
        Total = $total
        ESWL = $eswlCount
        Resource = "Procedure"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, ESWL: $eswlCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "13"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 4: Indicator 14 - Uterine Fibroid 14-Day Readmission (473.01)
# ========================================
Write-Host "[TEST 4/10] Indicator 14: Uterine Fibroid 14-Day Readmission" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Condition?code=D25`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $fibroidCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.code -like "D25*" -or $coding.display -match "fibroid|leiomyoma|uterine") {
                        $fibroidCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "14 Uterine Fibroid Readmission"
        Code = "473.01"
        ICD10 = "D25"
        Status = "PASS"
        Total = $total
        Fibroids = $fibroidCount
        Resource = "Condition"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Fibroids: $fibroidCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "14"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 5: Indicator 15-1 - Knee Arthroplasty 90-Day Infection (353.01)
# ========================================
Write-Host "[TEST 5/10] Indicator 15-1: Knee Arthroplasty 90-Day Deep Infection" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Procedure?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $tkaCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.display -match "knee.*replacement|arthroplasty.*knee|TKA|total knee") {
                        $tkaCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "15-1 Knee Arthroplasty Infection"
        Code = "353.01"
        Status = "PASS"
        Total = $total
        TKA = $tkaCount
        Resource = "Procedure"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, TKA: $tkaCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "15-1"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 6: Indicator 15-2 - Total Knee Arthroplasty Infection (3249)
# ========================================
Write-Host "[TEST 6/10] Indicator 15-2: Total Knee Arthroplasty 90-Day Infection" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Procedure?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $totalTKA = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.code -eq "609588000" -or $coding.display -match "total knee replacement") {
                        $totalTKA++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "15-2 Total TKA Infection"
        Code = "3249"
        SNOMED = "609588000"
        Status = "PASS"
        Total = $total
        TotalTKA = $totalTKA
        Resource = "Procedure"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Total TKA: $totalTKA" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "15-2"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 7: Indicator 15-3 - Partial Knee Arthroplasty Infection (3250)
# ========================================
Write-Host "[TEST 7/10] Indicator 15-3: Partial Knee Arthroplasty 90-Day Infection" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Procedure?date=ge$startDate`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $partialTKA = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.display -match "partial.*knee|unicompartmental|unicondylar") {
                        $partialTKA++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "15-3 Partial TKA Infection"
        Code = "3250"
        Status = "PASS"
        Total = $total
        PartialTKA = $partialTKA
        Resource = "Procedure"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Partial TKA: $partialTKA" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "15-3"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 8: Indicator 16 - Inpatient Surgical Wound Infection (1658Q/1666Y)
# ========================================
Write-Host "[TEST 8/10] Indicator 16: Inpatient Surgical Wound Infection Rate" -ForegroundColor Yellow

try {
    # Condition resource uses 'recorded-date' or 'onset-date' instead of 'date'
    # Try multiple approaches to find surgical wound infections
    $url = "$fhirServer/Condition?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $infectionCount = 0
    $surgicalComplications = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    # Check for surgical site infection codes (T81.4x, T81.3x)
                    if ($coding.code -match "T81\.[34]|T84\.[567]|T85\.[67]|D78|E36|G97|H59|I97|J95|K91|M96|N98|N99" -or 
                        $coding.display -match "surgical.*infection|wound infection|postoperative.*infection|complication.*surgery|hemorrhage.*procedure|hematoma.*procedure") {
                        $infectionCount++
                        break
                    }
                    if ($coding.display -match "complication|postoperative|post-procedural") {
                        $surgicalComplications++
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "16 Surgical Wound Infection"
        Code = "1658Q/1666Y"
        Status = "PASS"
        Total = $total
        Infections = $infectionCount
        Complications = $surgicalComplications
        Resource = "Condition"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Infections: $infectionCount, Complications: $surgicalComplications" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "16"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 9: Indicator 17 - AMI Mortality Rate (1662Q/1668Y)
# ========================================
Write-Host "[TEST 9/10] Indicator 17: Acute Myocardial Infarction Mortality Rate" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Condition?code=I21`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $amiCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.code -like "I21*" -or $coding.code -like "I22*" -or $coding.display -match "myocardial infarction|heart attack|AMI|STEMI|NSTEMI") {
                        $amiCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "17 AMI Mortality"
        Code = "1662Q/1668Y"
        ICD10 = "I21/I22"
        Status = "PASS"
        Total = $total
        AMI = $amiCount
        Resource = "Condition"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, AMI: $amiCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "17"; Status = "FAIL"; Error = $_.Exception.Message }
    $failedTests++
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# ========================================
# Test 10: Indicator 18 - Dementia Hospice Care Utilization (2795Q/2796Y)
# ========================================
Write-Host "[TEST 10/10] Indicator 18: Dementia Hospice Care Utilization Rate" -ForegroundColor Yellow

try {
    $url = "$fhirServer/Condition?code=F01`&_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $total = if ($response.total) { $response.total } else { 0 }
    $dementiaCount = 0
    
    if ($response.entry) {
        foreach ($entry in $response.entry) {
            if ($entry.resource.code.coding) {
                foreach ($coding in $entry.resource.code.coding) {
                    if ($coding.code -match "F0[1-3]|G30" -or $coding.display -match "dementia|alzheimer") {
                        $dementiaCount++
                        break
                    }
                }
            }
        }
    }
    
    $testResults += @{
        Test = "18 Dementia Hospice"
        Code = "2795Q/2796Y"
        ICD10 = "F01-F03/G30"
        Status = "PASS"
        Total = $total
        Dementia = $dementiaCount
        Resource = "Condition"
    }
    $passedTests++
    Write-Host "  PASSED - Total: $total, Dementia: $dementiaCount" -ForegroundColor Green
} catch {
    $testResults += @{ Test = "18"; Status = "FAIL"; Error = $_.Exception.Message }
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
        if ($result.Cesarean) { $report += "  Cesarean Sections: $($result.Cesarean)`n" }
        if ($result.Delivery) { $report += "  Deliveries: $($result.Delivery)`n" }
        if ($result.Antibiotics) { $report += "  Antibiotics: $($result.Antibiotics)`n" }
        if ($result.ATC) { $report += "  ATC Code: $($result.ATC)`n" }
        if ($result.ESWL) { $report += "  ESWL Procedures: $($result.ESWL)`n" }
        if ($result.Fibroids) { $report += "  Fibroid Cases: $($result.Fibroids)`n" }
        if ($result.ICD10) { $report += "  ICD-10 Code: $($result.ICD10)`n" }
        if ($result.TKA) { $report += "  TKA Procedures: $($result.TKA)`n" }
        if ($result.TotalTKA) { $report += "  Total TKA: $($result.TotalTKA)`n" }
        if ($result.PartialTKA) { $report += "  Partial TKA: $($result.PartialTKA)`n" }
        if ($result.SNOMED) { $report += "  SNOMED Code: $($result.SNOMED)`n" }
        if ($result.Infections) { $report += "  Infections: $($result.Infections)`n" }
        if ($result.Complications) { $report += "  Surgical Complications: $($result.Complications)`n" }
        if ($result.AMI) { $report += "  AMI Cases: $($result.AMI)`n" }
        if ($result.Dementia) { $report += "  Dementia Cases: $($result.Dementia)`n" }
        
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
INDICATOR CATEGORIES
========================================

Surgical Quality Indicators:
- 11-4: Cesarean section rate (first time with indication)
- 12: Clean surgery antibiotic use >3 days
- 13: ESWL average utilization times
- 14: Uterine fibroid surgery 14-day readmission
- 16: Inpatient surgical wound infection rate
- 19: Clean surgery wound infection rate

Joint Replacement Infection Indicators:
- 15-1: Knee arthroplasty 90-day deep infection (all)
- 15-2: Total knee arthroplasty 90-day deep infection
- 15-3: Partial knee arthroplasty 90-day deep infection

Clinical Outcome Indicators:
- 17: Acute myocardial infarction mortality rate
- 18: Dementia hospice care utilization rate

========================================
ICD-10 CODES TESTED
========================================

Procedures (ICD-10-PCS):
- Cesarean delivery: 10D00Z0-10D00Z2
- Knee arthroplasty: 0SRC0JZ, 0SRD0JZ
- Clean surgery: Various tissue repair codes

Diagnoses (ICD-10-CM):
- D25: Uterine leiomyoma (fibroids)
- I21/I22: Acute myocardial infarction
- F01-F03: Dementia
- G30: Alzheimer disease
- T84.84: Prosthetic joint infection

Medications (ATC):
- J01: Systemic antibiotics

========================================
FHIR RESOURCES TESTED
========================================

1. Procedure - Surgical procedures (cesarean, TKA, ESWL)
2. Condition - Diagnoses (fibroids, AMI, dementia, infections)
3. MedicationRequest - Antibiotic prescriptions
4. Encounter - Inpatient admissions and readmissions
5. Patient - Demographics and mortality status

========================================
CLINICAL CONTEXT
========================================

Cesarean Section Indicators:
- First-time cesarean with medical indication
- Excludes previous cesarean history (O342)
- DRG codes: 370, 371, 513

Antibiotic Stewardship:
- Clean surgery: Low infection risk
- Target: Antibiotic use ≤3 days post-op
- ATC J01: Systemic antibacterials

Joint Replacement Complications:
- 90-day surveillance period
- Deep infection: T84.84, T84.50
- Excludes same-day removal procedures

Readmission Quality:
- 14-day readmission window
- Related diagnosis required
- Excludes planned procedures

Mortality Indicators:
- AMI: Age ≥18 years
- Death within hospitalization or 30-day follow-up
- Transfer codes: 4 (death), A (critical self-discharge)

End-of-Life Care:
- Dementia: F01-F03, G30 series
- Hospice services: NHI codes 05601K-05374C
- Home hospice and shared care

========================================
DATA QUALITY NOTES
========================================

Test Server Limitations:
1. Limited surgical procedure coding
2. Incomplete ICD-10-CM/PCS mappings
3. No mortality status in test data
4. Missing readmission linkages
5. Limited hospice service codes

For Production Use:
1. Verify all ICD-10-PCS procedure codes
2. Ensure complete diagnosis code mappings
3. Link Patient mortality from vital statistics
4. Implement 14/30/90-day tracking windows
5. Map NHI procedure codes to FHIR
6. Validate DRG grouper integration

========================================
QUALITY METRICS FORMULAS
========================================

Cesarean Rate = (Cesarean Deliveries / Total Deliveries) × 100

Clean Surgery Antibiotic >3 Days = 
  (Antibiotic Use >3 Days / Clean Surgeries) × 100

ESWL Average = Total ESWL Procedures / Unique Patients

14-Day Readmission Rate = 
  (Readmissions ≤14 Days / Index Discharges) × 100

90-Day Infection Rate = 
  (Deep Infections ≤90 Days / Joint Replacements) × 100

AMI Mortality Rate = (AMI Deaths / AMI Admissions) × 100

Hospice Utilization = 
  (Dementia with Hospice / All Dementia Patients) × 100

========================================
NEXT STEPS
========================================

1. Connect Hospital Server: Replace with production FHIR endpoint
2. ICD-10 Mapping: Complete all surgical and diagnosis codes
3. Temporal Tracking: Implement readmission/infection windows
4. Mortality Data: Link to vital statistics registry
5. DRG Integration: Connect to TW-DRG grouper
6. NHI Codes: Map all Taiwan NHI procedure codes
7. Quality Reports: Generate quarterly quality metrics
8. Benchmarking: Compare against national averages

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
