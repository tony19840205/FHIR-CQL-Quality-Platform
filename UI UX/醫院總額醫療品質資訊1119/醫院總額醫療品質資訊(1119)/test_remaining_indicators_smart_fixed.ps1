# ==============================================================================
# SMART on FHIR 皜祈岫?單 - ?拚??芣葫閰行?璅?
# Test Remaining Untested Indicators via SMART on FHIR
# ==============================================================================
# 皜祈岫??:
#   01: ?閮箸釣撠?雿輻??(3127)
#   02: ?閮箸???雿輻??(1140.01)
#   05: ?閮箸?撘菔??寧?????詹10??獢辣瘥? (3128)
#   06: 18甇脖誑銝除??鈭箸亥那??(1315Q/1317Y)
#   08: 撠梯那敺??交??Ｗ????甈∪停閮箇? (1322)
#   09: ???急找??Ｘ?隞嗅?Ｗ?14?亙???Ｙ? (1077.01Q/1809Y)
#   10: 雿獢辣?粹敺??乩誑?扳亥那??(108.01)
#   11-1: ??Ｙ?-?湧? (1136.01)
#   11-2: ??Ｙ?-?芾?閬? (1137.01)
#   11-3: ??Ｙ?-?琿?? (1138.01)
#   19: 皜楊??銵??瑕????(2524Q/2526Y)
#
# FHIR Server: https://hapi.fhir.org/baseR4 (HAPI FHIR Test Server)
# 皜祈岫??: 2024-01-01 to 2025-11-20
# ==============================================================================

# FHIR???刻身摰?
$fhirServer = "https://hapi.fhir.org/baseR4"
$startDate = "2024-01-01"
$endDate = "2025-11-20"

# 皜祈岫蝯??脣?
$testResults = @()
$passCount = 0
$failCount = 0

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "SMART on FHIR 皜祈岫 - ?拚??芣葫閰行?璅?(11??" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "FHIR Server: $fhirServer" -ForegroundColor Yellow
Write-Host "皜祈岫??: $startDate to $endDate" -ForegroundColor Yellow
Write-Host "????: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# ==============================================================================
# Test 1: ??01 - ?閮箸釣撠?雿輻??(3127)
# ==============================================================================
Write-Host "[TEST 1/11] Indicator 01: Outpatient Injection Drug Utilization Rate (3127)" -ForegroundColor Green

try {
    # ?亥岷?閮箏停?怎???
    $url = "$fhirServer/Encounter?class=AMB&date=ge$startDate&date=le$endDate&_count=100"
    $ambulatoryEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $ambulatoryCount = if ($ambulatoryEncounters.total) { $ambulatoryEncounters.total } else { 0 }
    
    # ?亥岷瘜典?????(Medication route = injection)
    $url = "$fhirServer/MedicationRequest?intent=order&date=ge$startDate&_count=100"
    $injectionMeds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $injectionCount = 0
    if ($injectionMeds.entry) {
        foreach ($entry in $injectionMeds.entry) {
            $med = $entry.resource
            # 瑼Ｘ蝯西???臬?箸釣撠?
            if ($med.dosageInstruction) {
                foreach ($dosage in $med.dosageInstruction) {
                    if ($dosage.route.coding) {
                        foreach ($route in $dosage.route.coding) {
                            if ($route.code -match "(inject|IM|IV|SC|intravenous|intramuscular|subcutaneous)") {
                                $injectionCount++
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    $rate = if ($ambulatoryCount -gt 0) { [math]::Round(($injectionCount / $ambulatoryCount) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Ambulatory: $ambulatoryCount, Injection Meds: $injectionCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 1"
        Indicator = "01 (3127)"
        Name = "?閮箸釣撠?雿輻??
        Status = "PASSED"
        Details = "?閮? $ambulatoryCount, 瘜典??? $injectionCount, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 1"
        Indicator = "01 (3127)"
        Name = "?閮箸釣撠?雿輻??
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 2: ??02 - ?閮箸???雿輻??(1140.01)
# ==============================================================================
Write-Host "[TEST 2/11] Indicator 02: Outpatient Antibiotic Utilization Rate (1140.01)" -ForegroundColor Green

try {
    # ?亥岷?閮箏停?怎???
    $url = "$fhirServer/Encounter?class=AMB&date=ge$startDate&date=le$endDate&_count=100"
    $ambulatoryEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $ambulatoryCount = if ($ambulatoryEncounters.total) { $ambulatoryEncounters.total } else { 0 }
    
    # ?亥岷??蝝???(ATC J01)
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|J01&_count=100"
    $antibiotics = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $antibioticMedIds = @()
    
    if ($antibiotics.entry) {
        foreach ($entry in $antibiotics.entry) {
            $antibioticMedIds += $entry.resource.id
        }
    }
    
    # ?亥岷??蝝??寡?瘙?
    $url = "$fhirServer/MedicationRequest?intent=order&date=ge$startDate&_count=100"
    $medRequests = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $antibioticCount = 0
    if ($medRequests.entry) {
        foreach ($entry in $medRequests.entry) {
            $medReq = $entry.resource
            # 瑼Ｘ?臬?箸??? (ATC J01 ??medication reference)
            $isAntibiotic = $false
            
            if ($medReq.medicationCodeableConcept -and $medReq.medicationCodeableConcept.coding) {
                foreach ($coding in $medReq.medicationCodeableConcept.coding) {
                    if ($coding.system -eq "http://www.whocc.no/atc" -and $coding.code -match "^J01") {
                        $isAntibiotic = $true
                        break
                    }
                }
            }
            
            if ($medReq.medicationReference -and $medReq.medicationReference.reference) {
                $medId = $medReq.medicationReference.reference -replace "Medication/", ""
                if ($antibioticMedIds -contains $medId) {
                    $isAntibiotic = $true
                }
            }
            
            if ($isAntibiotic) {
                $antibioticCount++
            }
        }
    }
    
    $rate = if ($ambulatoryCount -gt 0) { [math]::Round(($antibioticCount / $ambulatoryCount) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Ambulatory: $ambulatoryCount, Antibiotics: $antibioticCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 2"
        Indicator = "02 (1140.01)"
        Name = "?閮箸???雿輻??
        Status = "PASSED"
        Details = "?閮? $ambulatoryCount, ??蝝? $antibioticCount, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 2"
        Indicator = "02 (1140.01)"
        Name = "?閮箸???雿輻??
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 3: ??05 - ?閮箸?撘菔??寧?????詹10??獢辣瘥? (3128)
# ==============================================================================
Write-Host "[TEST 3/11] Indicator 05: Prescription with 10+ Drug Items Rate (3128)" -ForegroundColor Green

try {
    # ?亥岷?閮箄???
    $url = "$fhirServer/MedicationRequest?intent=order&date=ge$startDate&_count=100"
    $prescriptions = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    # ??encounter ??閮??亙?????
    $encounterDrugCount = @{}
    
    if ($prescriptions.entry) {
        foreach ($entry in $prescriptions.entry) {
            $medReq = $entry.resource
            if ($medReq.encounter -and $medReq.encounter.reference) {
                $encounterId = $medReq.encounter.reference
                if (-not $encounterDrugCount.ContainsKey($encounterId)) {
                    $encounterDrugCount[$encounterId] = 0
                }
                $encounterDrugCount[$encounterId]++
            }
        }
    }
    
    $totalPrescriptions = $encounterDrugCount.Count
    $over10Items = ($encounterDrugCount.Values | Where-Object { $_ -ge 10 }).Count
    $rate = if ($totalPrescriptions -gt 0) { [math]::Round(($over10Items / $totalPrescriptions) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Prescriptions: $totalPrescriptions, ??0 Items: $over10Items, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 3"
        Indicator = "05 (3128)"
        Name = "?蝞10?亙???瘥?"
        Status = "PASSED"
        Details = "?蝞蜇?? $totalPrescriptions, ??0??: $over10Items, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 3"
        Indicator = "05 (3128)"
        Name = "?蝞10?亙???瘥?"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 4: ??06 - 18甇脖誑銝除??鈭箸亥那??(1315Q/1317Y)
# ==============================================================================
Write-Host "[TEST 4/11] Indicator 06: Pediatric Asthma ED Rate (1315Q/1317Y)" -ForegroundColor Green

try {
    # ?亥岷瘞??閮箸 (ICD-10 J45)
    $url = "$fhirServer/Condition?code=http://hl7.org/fhir/sid/icd-10-cm|J45&_count=100"
    $asthmaConditions = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $pediatricAsthmaPatients = @()
    
    if ($asthmaConditions.entry) {
        foreach ($entry in $asthmaConditions.entry) {
            $condition = $entry.resource
            if ($condition.subject -and $condition.subject.reference) {
                $patientId = $condition.subject.reference -replace "Patient/", ""
                
                # ?亥岷?撟湧翩
                try {
                    $patientUrl = "$fhirServer/Patient/$patientId"
                    $patient = Invoke-RestMethod -Uri $patientUrl -Method Get -ContentType "application/fhir+json"
                    
                    if ($patient.birthDate) {
                        $birthDate = [DateTime]::Parse($patient.birthDate)
                        $age = ((Get-Date) - $birthDate).Days / 365.25
                        
                        if ($age -le 18 -and $pediatricAsthmaPatients -notcontains $patientId) {
                            $pediatricAsthmaPatients += $patientId
                        }
                    }
                } catch {
                    # ?⊥??亥岷?鞈?嚗歲??
                }
            }
        }
    }
    
    # ?亥岷?亥那撠梢蝝??
    $edCount = 0
    foreach ($patientId in $pediatricAsthmaPatients) {
        try {
            $url = "$fhirServer/Encounter?patient=$patientId&class=EMER&date=ge$startDate&_count=10"
            $edEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
            
            if ($edEncounters.entry) {
                $edCount += $edEncounters.entry.Count
            }
        } catch {
            # ?亥岷憭望?嚗歲??
        }
    }
    
    $totalPatients = $pediatricAsthmaPatients.Count
    $rate = if ($totalPatients -gt 0) { [math]::Round(($edCount / $totalPatients) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Pediatric Asthma Patients: $totalPatients, ED Visits: $edCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 4"
        Indicator = "06 (1315Q/1317Y)"
        Name = "18甇脖誑銝除??鈭箸亥那??
        Status = "PASSED"
        Details = "瘞???咱: $totalPatients, ?亥那甈⊥: $edCount, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 4"
        Indicator = "06 (1315Q/1317Y)"
        Name = "18甇脖誑銝除??鈭箸亥那??
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 5: ??08 - 撠梯那敺??交??Ｗ????甈∪停閮箇? (1322)
# ==============================================================================
Write-Host "[TEST 5/11] Indicator 08: Same Day Same Disease Revisit Rate (1322)" -ForegroundColor Green

try {
    # ?亥岷?閮箏停?怎???
    $url = "$fhirServer/Encounter?class=AMB&date=ge$startDate&date=le$endDate&_count=100"
    $encounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    # ?????那?瑕?蝯?
    $sameDayRevisits = 0
    $totalEncounters = 0
    $patientDailyVisits = @{}
    
    if ($encounters.entry) {
        foreach ($entry in $encounters.entry) {
            $encounter = $entry.resource
            $totalEncounters++
            
            if ($encounter.subject -and $encounter.period -and $encounter.period.start) {
                $patientId = $encounter.subject.reference
                $visitDate = ([DateTime]::Parse($encounter.period.start)).ToString("yyyy-MM-dd")
                
                # ?亥岷閮箸
                $diagnosisCodes = @()
                if ($encounter.diagnosis) {
                    foreach ($diag in $encounter.diagnosis) {
                        if ($diag.condition -and $diag.condition.reference) {
                            $diagnosisCodes += $diag.condition.reference
                        }
                    }
                }
                
                $key = "$patientId-$visitDate"
                if (-not $patientDailyVisits.ContainsKey($key)) {
                    $patientDailyVisits[$key] = @{
                        Count = 0
                        Diagnoses = @()
                    }
                }
                
                $patientDailyVisits[$key].Count++
                $patientDailyVisits[$key].Diagnoses += $diagnosisCodes
            }
        }
        
        # 閮???活撠梯那嚗?那?瘀?
        foreach ($visit in $patientDailyVisits.Values) {
            if ($visit.Count -gt 1) {
                # 瑼Ｘ?臬??銴那??
                $uniqueDiagnoses = $visit.Diagnoses | Select-Object -Unique
                if ($visit.Diagnoses.Count -gt $uniqueDiagnoses.Count) {
                    $sameDayRevisits++
                }
            }
        }
    }
    
    $rate = if ($totalEncounters -gt 0) { [math]::Round(($sameDayRevisits / $totalEncounters) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Encounters: $totalEncounters, Same Day Revisits: $sameDayRevisits, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 5"
        Indicator = "08 (1322)"
        Name = "????停閮箇?"
        Status = "PASSED"
        Details = "蝮賢停閮? $totalEncounters, ??那: $sameDayRevisits, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 5"
        Indicator = "08 (1322)"
        Name = "????停閮箇?"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 6: ??09 - ???急找??Ｘ?隞嗅?Ｗ?14?亙???Ｙ? (1077.01Q/1809Y)
# ==============================================================================
Write-Host "[TEST 6/11] Indicator 09: 14-Day Unplanned Readmission Rate (1077.01Q/1809Y)" -ForegroundColor Green

try {
    # ?亥岷雿獢辣
    $url = "$fhirServer/Encounter?class=IMP&status=finished&date=ge$startDate&_count=100"
    $inpatientEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $totalDischarges = 0
    $readmissions14Day = 0
    
    if ($inpatientEncounters.entry) {
        foreach ($entry in $inpatientEncounters.entry) {
            $encounter = $entry.resource
            
            if ($encounter.period -and $encounter.period.end -and $encounter.subject) {
                $totalDischarges++
                $dischargeDate = [DateTime]::Parse($encounter.period.end)
                $patientId = $encounter.subject.reference -replace "Patient/", ""
                
                # ?亥岷14憭拙??雿
                $followUpStart = $dischargeDate.AddDays(1).ToString("yyyy-MM-dd")
                $followUpEnd = $dischargeDate.AddDays(14).ToString("yyyy-MM-dd")
                
                try {
                    $url = "$fhirServer/Encounter?patient=$patientId&class=IMP&date=ge$followUpStart&date=le$followUpEnd&_count=10"
                    $followUpEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
                    
                    if ($followUpEncounters.entry -and $followUpEncounters.entry.Count -gt 0) {
                        $readmissions14Day++
                    }
                } catch {
                    # ?亥岷憭望?嚗歲??
                }
            }
        }
    }
    
    $rate = if ($totalDischarges -gt 0) { [math]::Round(($readmissions14Day / $totalDischarges) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Discharges: $totalDischarges, 14-Day Readmissions: $readmissions14Day, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 6"
        Indicator = "09 (1077.01Q/1809Y)"
        Name = "14?亙???Ｙ?"
        Status = "PASSED"
        Details = "?粹獢辣: $totalDischarges, 14?亙???? $readmissions14Day, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 6"
        Indicator = "09 (1077.01Q/1809Y)"
        Name = "14?亙???Ｙ?"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 7: ??10 - 雿獢辣?粹敺??乩誑?扳亥那??(108.01)
# ==============================================================================
Write-Host "[TEST 7/11] Indicator 10: 3-Day ED After Discharge Rate (108.01)" -ForegroundColor Green

try {
    # ?亥岷雿獢辣
    $url = "$fhirServer/Encounter?class=IMP&status=finished&date=ge$startDate&_count=100"
    $inpatientEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $totalDischarges = 0
    $ed3Day = 0
    
    if ($inpatientEncounters.entry) {
        foreach ($entry in $inpatientEncounters.entry) {
            $encounter = $entry.resource
            
            if ($encounter.period -and $encounter.period.end -and $encounter.subject) {
                $totalDischarges++
                $dischargeDate = [DateTime]::Parse($encounter.period.end)
                $patientId = $encounter.subject.reference -replace "Patient/", ""
                
                # ?亥岷3憭拙?亥那
                $followUpStart = $dischargeDate.AddDays(1).ToString("yyyy-MM-dd")
                $followUpEnd = $dischargeDate.AddDays(3).ToString("yyyy-MM-dd")
                
                try {
                    $url = "$fhirServer/Encounter?patient=$patientId&class=EMER&date=ge$followUpStart&date=le$followUpEnd&_count=10"
                    $edEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
                    
                    if ($edEncounters.entry -and $edEncounters.entry.Count -gt 0) {
                        $ed3Day++
                    }
                } catch {
                    # ?亥岷憭望?嚗歲??
                }
            }
        }
    }
    
    $rate = if ($totalDischarges -gt 0) { [math]::Round(($ed3Day / $totalDischarges) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Discharges: $totalDischarges, 3-Day ED: $ed3Day, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 7"
        Indicator = "10 (108.01)"
        Name = "3?亙?亥那??
        Status = "PASSED"
        Details = "?粹獢辣: $totalDischarges, 3?亙?亥那: $ed3Day, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 7"
        Indicator = "10 (108.01)"
        Name = "3?亙?亥那??
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 8: ??11-1 - ??Ｙ?-?湧? (1136.01)
# ==============================================================================
Write-Host "[TEST 8/11] Indicator 11-1: Overall Cesarean Section Rate (1136.01)" -ForegroundColor Green

try {
    # ?亥岷??Ｘ?銵?(SNOMED 11466000)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|11466000&date=ge$startDate&_count=100"
    $cesareanProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $cesareanCount = if ($cesareanProcedures.total) { $cesareanProcedures.total } else { 0 }
    
    # ?亥岷?芰??(SNOMED 302383004)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|302383004&date=ge$startDate&_count=100"
    $vaginalProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $vaginalCount = if ($vaginalProcedures.total) { $vaginalProcedures.total } else { 0 }
    
    # 銋閰Ｗ?憡抵那??(ICD-10 O82 ??? O80 ?芰??
    $url = "$fhirServer/Condition?code=http://hl7.org/fhir/sid/icd-10-cm|O82&_count=100"
    $cesareanConditions = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    if ($cesareanConditions.total) {
        $cesareanCount += $cesareanConditions.total
    }
    
    $url = "$fhirServer/Condition?code=http://hl7.org/fhir/sid/icd-10-cm|O80&_count=100"
    $vaginalConditions = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    if ($vaginalConditions.total) {
        $vaginalCount += $vaginalConditions.total
    }
    
    $totalDeliveries = $cesareanCount + $vaginalCount
    $rate = if ($totalDeliveries -gt 0) { [math]::Round(($cesareanCount / $totalDeliveries) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Deliveries: $totalDeliveries, Cesarean: $cesareanCount, Vaginal: $vaginalCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 8"
        Indicator = "11-1 (1136.01)"
        Name = "??Ｙ?-?湧?"
        Status = "PASSED"
        Details = "蝮賜??? $totalDeliveries, ??? $cesareanCount, ?芰?? $vaginalCount, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 8"
        Indicator = "11-1 (1136.01)"
        Name = "??Ｙ?-?湧?"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 9: ??11-2 - ??Ｙ?-?芾?閬? (1137.01)
# ==============================================================================
Write-Host "[TEST 9/11] Indicator 11-2: Patient-Requested Cesarean Rate (1137.01)" -ForegroundColor Green

try {
    # ?亥岷?芾?閬????(SNOMED 386637004)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|386637004&date=ge$startDate&_count=100"
    $requestedCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $requestedCount = if ($requestedCesarean.total) { $requestedCesarean.total } else { 0 }
    
    # ?亥岷????寧
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|11466000&date=ge$startDate&_count=100"
    $allCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $cesareanCount = if ($allCesarean.total) { $allCesarean.total } else { 0 }
    
    # ?亥岷?芰??
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|302383004&date=ge$startDate&_count=100"
    $vaginalProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $vaginalCount = if ($vaginalProcedures.total) { $vaginalProcedures.total } else { 0 }
    
    $totalDeliveries = $cesareanCount + $vaginalCount
    $rate = if ($totalDeliveries -gt 0) { [math]::Round(($requestedCount / $totalDeliveries) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Deliveries: $totalDeliveries, Patient-Requested Cesarean: $requestedCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 9"
        Indicator = "11-2 (1137.01)"
        Name = "??Ｙ?-?芾?閬?"
        Status = "PASSED"
        Details = "蝮賜??? $totalDeliveries, ?芾?閬???? $requestedCount, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 9"
        Indicator = "11-2 (1137.01)"
        Name = "??Ｙ?-?芾?閬?"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 10: ??11-3 - ??Ｙ?-?琿?? (1138.01)
# ==============================================================================
Write-Host "[TEST 10/11] Indicator 11-3: Cesarean with Indication Rate (1138.01)" -ForegroundColor Green

try {
    # ?亥岷?豢??批??寧 (SNOMED 177141003 - ?航?琿??)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|177141003&date=ge$startDate&_count=100"
    $electiveCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $electiveCount = if ($electiveCesarean.total) { $electiveCesarean.total } else { 0 }
    
    # ?亥岷蝺亙??寧 (SNOMED 177152005 - ?琿??)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|177152005&date=ge$startDate&_count=100"
    $emergencyCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $emergencyCount = if ($emergencyCesarean.total) { $emergencyCesarean.total } else { 0 }
    
    $indicatedCesarean = $electiveCount + $emergencyCount
    
    # ?亥岷?芰??
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|302383004&date=ge$startDate&_count=100"
    $vaginalProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $vaginalCount = if ($vaginalProcedures.total) { $vaginalProcedures.total } else { 0 }
    
    $totalDeliveries = $indicatedCesarean + $vaginalCount
    $rate = if ($totalDeliveries -gt 0) { [math]::Round(($indicatedCesarean / $totalDeliveries) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Deliveries: $totalDeliveries, Indicated Cesarean: $indicatedCesarean, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 10"
        Indicator = "11-3 (1138.01)"
        Name = "??Ｙ?-?琿??"
        Status = "PASSED"
        Details = "蝮賜??? $totalDeliveries, ?琿????? $indicatedCesarean, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 10"
        Indicator = "11-3 (1138.01)"
        Name = "??Ｙ?-?琿??"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 11: ??19 - 皜楊??銵??瑕????(2524Q/2526Y)
# ==============================================================================
Write-Host "[TEST 11/11] Indicator 19: Clean Surgery Wound Infection Rate (2524Q/2526Y)" -ForegroundColor Green

try {
    # ?亥岷皜楊?? (clean surgery procedures)
    $url = "$fhirServer/Procedure?date=ge$startDate&_count=100"
    $procedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $cleanSurgeryCount = 0
    $cleanSurgeryPatients = @()
    
    if ($procedures.entry) {
        foreach ($entry in $procedures.entry) {
            $proc = $entry.resource
            # 蝪∪??文?嚗?閮剜???銵?舀?瘛冽?銵脰?皜祈岫
            if ($proc.status -eq "completed" -and $proc.subject -and $proc.subject.reference) {
                $cleanSurgeryCount++
                $patientId = $proc.subject.reference -replace "Patient/", ""
                if ($cleanSurgeryPatients -notcontains $patientId) {
                    $cleanSurgeryPatients += $patientId
                }
            }
        }
    }
    
    # ?亥岷銵??瑕?? (ICD-10 T81.4)
    $url = "$fhirServer/Condition?code=http://hl7.org/fhir/sid/icd-10-cm|T81.4&_count=100"
    $woundInfections = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $infectionCount = 0
    if ($woundInfections.entry) {
        foreach ($entry in $woundInfections.entry) {
            $condition = $entry.resource
            if ($condition.subject -and $condition.subject.reference) {
                $patientId = $condition.subject.reference -replace "Patient/", ""
                if ($cleanSurgeryPatients -contains $patientId) {
                    $infectionCount++
                }
            }
        }
    }
    
    $rate = if ($cleanSurgeryCount -gt 0) { [math]::Round(($infectionCount / $cleanSurgeryCount) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Clean Surgeries: $cleanSurgeryCount, Wound Infections: $infectionCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 11"
        Indicator = "19 (2524Q/2526Y)"
        Name = "皜楊???瑕????
        Status = "PASSED"
        Details = "皜楊??: $cleanSurgeryCount, ?瑕??: $infectionCount, 瘥?: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 11"
        Indicator = "19 (2524Q/2526Y)"
        Name = "皜楊???瑕????
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# 皜祈岫蝯?蝮賜?
# ==============================================================================
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "皜祈岫蝯?蝮賜?" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$successRate = if (($passCount + $failCount) -gt 0) { [math]::Round(($passCount / ($passCount + $failCount)) * 100, 2) } else { 0 }

foreach ($result in $testResults) {
    $statusColor = if ($result.Status -eq "PASSED") { "Green" } else { "Red" }
    $statusSymbol = if ($result.Status -eq "PASSED") { "?? } else { "?? }
    
    Write-Host "$statusSymbol [$($result.Test)] ?? $($result.Indicator) - $($result.Name)" -ForegroundColor $statusColor
    Write-Host "   $($result.Details)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Total Tests: $($passCount + $failCount)" -ForegroundColor Yellow
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# ?脣??勗?
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = "SMART_Remaining_Indicators_Test_$timestamp.txt"

$reportContent = @"
================================================================================
SMART on FHIR 皜祈岫?勗? - ?拚??芣葫閰行?璅?(11??
================================================================================
FHIR Server: $fhirServer
皜祈岫??: $startDate to $endDate
皜祈岫??: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

皜祈岫??:
  01: ?閮箸釣撠?雿輻??(3127)
  02: ?閮箸???雿輻??(1140.01)
  05: ?閮箸?撘菔??寧?????詹10??獢辣瘥? (3128)
  06: 18甇脖誑銝除??鈭箸亥那??(1315Q/1317Y)
  08: 撠梯那敺??交??Ｗ????甈∪停閮箇? (1322)
  09: ???急找??Ｘ?隞嗅?Ｗ?14?亙???Ｙ? (1077.01Q/1809Y)
  10: 雿獢辣?粹敺??乩誑?扳亥那??(108.01)
  11-1: ??Ｙ?-?湧? (1136.01)
  11-2: ??Ｙ?-?芾?閬? (1137.01)
  11-3: ??Ｙ?-?琿?? (1138.01)
  19: 皜楊??銵??瑕????(2524Q/2526Y)

================================================================================
皜祈岫蝯?閰喟敦鞈?
================================================================================

"@

foreach ($result in $testResults) {
    $reportContent += @"
[$($result.Test)] ?? $($result.Indicator) - $($result.Name)
??? $($result.Status)
閰喟敦鞈?: $($result.Details)

"@
}

$reportContent += @"
================================================================================
皜祈岫蝮賜?
================================================================================
Total Tests: $($passCount + $failCount)
Passed: $passCount
Failed: $failCount
Success Rate: $successRate%

================================================================================
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Report saved to: $reportPath" -ForegroundColor Green

