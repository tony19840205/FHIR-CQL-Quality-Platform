# SMART on FHIR Test - Remaining 11 Indicators
$fhirServer = "https://hapi.fhir.org/baseR4"
$startDate = "2024-01-01"
$endDate = "2025-11-20"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR - Remaining Indicators Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passCount = 0
$failCount = 0

# Test 1: Indicator 01
Write-Host "[1/11] Indicator 01: Outpatient Injection Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Encounter?class=AMB`&date=ge$startDate`&_count=100"
    $encounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $ambulatoryCount = if ($encounters.total) { $encounters.total } else { 0 }
    
    $url = "$fhirServer/MedicationRequest?intent=order`&date=ge$startDate`&_count=100"
    $medReq = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $injectionCount = 0
    
    if ($medReq.entry) {
        foreach ($entry in $medReq.entry) {
            if ($entry.resource.dosageInstruction) {
                foreach ($dosage in $entry.resource.dosageInstruction) {
                    if ($dosage.route.text -match "inject|IM|IV|SC") {
                        $injectionCount++
                        break
                    }
                }
            }
        }
    }
    
    Write-Host "  PASSED - Ambulatory: $ambulatoryCount, Injections: $injectionCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 2: Indicator 02
Write-Host "[2/11] Indicator 02: Outpatient Antibiotic Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Encounter?class=AMB`&date=ge$startDate`&_count=100"
    $encounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $ambulatoryCount = if ($encounters.total) { $encounters.total } else { 0 }
    
    $url = "$fhirServer/MedicationRequest?intent=order`&date=ge$startDate`&_count=100"
    $medReq = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $antibioticCount = 0
    
    if ($medReq.entry) {
        foreach ($entry in $medReq.entry) {
            if ($entry.resource.medicationCodeableConcept.coding) {
                foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                    if ($coding.code -match "^J01") {
                        $antibioticCount++
                        break
                    }
                }
            }
        }
    }
    
    Write-Host "  PASSED - Ambulatory: $ambulatoryCount, Antibiotics: $antibioticCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 3: Indicator 05
Write-Host "[3/11] Indicator 05: Prescription 10+ Drug Items Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/MedicationRequest?intent=order`&date=ge$startDate`&_count=100"
    $medReq = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    $encounterDrugs = @{}
    if ($medReq.entry) {
        foreach ($entry in $medReq.entry) {
            $encRef = $entry.resource.encounter.reference
            if ($encRef) {
                if (-not $encounterDrugs.ContainsKey($encRef)) {
                    $encounterDrugs[$encRef] = 0
                }
                $encounterDrugs[$encRef]++
            }
        }
    }
    
    $totalRx = $encounterDrugs.Count
    $over10 = ($encounterDrugs.Values | Where-Object { $_ -ge 10 }).Count
    
    Write-Host "  PASSED - Total Rx: $totalRx, Over 10 items: $over10" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 4: Indicator 06
Write-Host "[4/11] Indicator 06: Pediatric Asthma ED Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Condition?code=J45`&_count=100"
    $conditions = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $asthmaCount = if ($conditions.total) { $conditions.total } else { 0 }
    
    $url = "$fhirServer/Encounter?class=EMER`&date=ge$startDate`&_count=100"
    $edVisits = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $edCount = if ($edVisits.total) { $edVisits.total } else { 0 }
    
    Write-Host "  PASSED - Asthma: $asthmaCount, ED: $edCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 5: Indicator 08
Write-Host "[5/11] Indicator 08: Same Day Same Disease Revisit Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Encounter?class=AMB`&date=ge$startDate`&_count=100"
    $encounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $encounterCount = if ($encounters.total) { $encounters.total } else { 0 }
    
    Write-Host "  PASSED - Encounters: $encounterCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 6: Indicator 09
Write-Host "[6/11] Indicator 09: 14-Day Unplanned Readmission Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Encounter?class=IMP`&status=finished`&date=ge$startDate`&_count=100"
    $discharges = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $dischargeCount = if ($discharges.total) { $discharges.total } else { 0 }
    
    Write-Host "  PASSED - Discharges: $dischargeCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 7: Indicator 10
Write-Host "[7/11] Indicator 10: 3-Day ED After Discharge Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Encounter?class=IMP`&status=finished`&date=ge$startDate`&_count=100"
    $discharges = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $dischargeCount = if ($discharges.total) { $discharges.total } else { 0 }
    
    $url = "$fhirServer/Encounter?class=EMER`&date=ge$startDate`&_count=100"
    $edVisits = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $edCount = if ($edVisits.total) { $edVisits.total } else { 0 }
    
    Write-Host "  PASSED - Discharges: $dischargeCount, ED: $edCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 8: Indicator 11-1
Write-Host "[8/11] Indicator 11-1: Overall Cesarean Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Procedure?code=11466000`&date=ge$startDate`&_count=100"
    $cesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $cesareanCount = if ($cesarean.total) { $cesarean.total } else { 0 }
    
    $url = "$fhirServer/Procedure?code=302383004`&date=ge$startDate`&_count=100"
    $vaginal = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $vaginalCount = if ($vaginal.total) { $vaginal.total } else { 0 }
    
    Write-Host "  PASSED - Cesarean: $cesareanCount, Vaginal: $vaginalCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 9: Indicator 11-2
Write-Host "[9/11] Indicator 11-2: Patient-Requested Cesarean Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Procedure?code=386637004`&date=ge$startDate`&_count=100"
    $requested = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $requestedCount = if ($requested.total) { $requested.total } else { 0 }
    
    Write-Host "  PASSED - Requested Cesarean: $requestedCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 10: Indicator 11-3
Write-Host "[10/11] Indicator 11-3: Cesarean with Indication Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Procedure?code=177141003`&date=ge$startDate`&_count=100"
    $elective = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $electiveCount = if ($elective.total) { $elective.total } else { 0 }
    
    $url = "$fhirServer/Procedure?code=177152005`&date=ge$startDate`&_count=100"
    $emergency = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $emergencyCount = if ($emergency.total) { $emergency.total } else { 0 }
    
    Write-Host "  PASSED - Elective: $electiveCount, Emergency: $emergencyCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

# Test 11: Indicator 19
Write-Host "[11/11] Indicator 19: Clean Surgery Wound Infection Rate" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Procedure?date=ge$startDate`&_count=100"
    $procedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $procedureCount = if ($procedures.total) { $procedures.total } else { 0 }
    
    $url = "$fhirServer/Condition?code=T81.4`&_count=100"
    $infections = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $infectionCount = if ($infections.total) { $infections.total } else { 0 }
    
    Write-Host "  PASSED - Procedures: $procedureCount, Infections: $infectionCount" -ForegroundColor Green
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Total: 11, Passed: $passCount, Failed: $failCount" -ForegroundColor Yellow
$successRate = [math]::Round(($passCount / 11) * 100, 2)
Write-Host "Success Rate: $successRate%" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
