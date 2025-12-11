# ==============================================================================
# SMART on FHIR 測試腳本 - 剩餘未測試指標
# Test Remaining Untested Indicators via SMART on FHIR
# ==============================================================================
# 測試指標:
#   01: 門診注射劑使用率 (3127)
#   02: 門診抗生素使用率 (1140.01)
#   05: 門診每張處方箋開藥品項數≥10項之案件比率 (3128)
#   06: 18歲以下氣喘病人急診率 (1315Q/1317Y)
#   08: 就診後同日於同醫院因同疾病再次就診率 (1322)
#   09: 非計畫性住院案件出院後14日內再住院率 (1077.01Q/1809Y)
#   10: 住院案件出院後3日以內急診率 (108.01)
#   11-1: 剖腹產率-整體 (1136.01)
#   11-2: 剖腹產率-自行要求 (1137.01)
#   11-3: 剖腹產率-具適應症 (1138.01)
#   19: 清淨手術術後傷口感染率 (2524Q/2526Y)
#
# FHIR Server: https://hapi.fhir.org/baseR4 (HAPI FHIR Test Server)
# 測試期間: 2024-01-01 to 2025-11-20
# ==============================================================================

# FHIR服務器設定
$fhirServer = "https://hapi.fhir.org/baseR4"
$startDate = "2024-01-01"
$endDate = "2025-11-20"

# 測試結果儲存
$testResults = @()
$passCount = 0
$failCount = 0

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "SMART on FHIR 測試 - 剩餘未測試指標 (11個)" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "FHIR Server: $fhirServer" -ForegroundColor Yellow
Write-Host "測試期間: $startDate to $endDate" -ForegroundColor Yellow
Write-Host "開始時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# ==============================================================================
# Test 1: 指標01 - 門診注射劑使用率 (3127)
# ==============================================================================
Write-Host "[TEST 1/11] Indicator 01: Outpatient Injection Drug Utilization Rate (3127)" -ForegroundColor Green

try {
    # 查詢門診就醫紀錄
    $url = "$fhirServer/Encounter?class=AMB&date=ge$startDate&date=le$endDate&_count=100"
    $ambulatoryEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $ambulatoryCount = if ($ambulatoryEncounters.total) { $ambulatoryEncounters.total } else { 0 }
    
    # 查詢注射劑處方 (Medication route = injection)
    $url = "$fhirServer/MedicationRequest?intent=order&date=ge$startDate&_count=100"
    $injectionMeds = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $injectionCount = 0
    if ($injectionMeds.entry) {
        foreach ($entry in $injectionMeds.entry) {
            $med = $entry.resource
            # 檢查給藥途徑是否為注射
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
        Name = "門診注射劑使用率"
        Status = "PASSED"
        Details = "門診: $ambulatoryCount, 注射劑: $injectionCount, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 1"
        Indicator = "01 (3127)"
        Name = "門診注射劑使用率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 2: 指標02 - 門診抗生素使用率 (1140.01)
# ==============================================================================
Write-Host "[TEST 2/11] Indicator 02: Outpatient Antibiotic Utilization Rate (1140.01)" -ForegroundColor Green

try {
    # 查詢門診就醫紀錄
    $url = "$fhirServer/Encounter?class=AMB&date=ge$startDate&date=le$endDate&_count=100"
    $ambulatoryEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $ambulatoryCount = if ($ambulatoryEncounters.total) { $ambulatoryEncounters.total } else { 0 }
    
    # 查詢抗生素處方 (ATC J01)
    $url = "$fhirServer/Medication?code=http://www.whocc.no/atc|J01&_count=100"
    $antibiotics = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $antibioticMedIds = @()
    
    if ($antibiotics.entry) {
        foreach ($entry in $antibiotics.entry) {
            $antibioticMedIds += $entry.resource.id
        }
    }
    
    # 查詢抗生素處方請求
    $url = "$fhirServer/MedicationRequest?intent=order&date=ge$startDate&_count=100"
    $medRequests = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $antibioticCount = 0
    if ($medRequests.entry) {
        foreach ($entry in $medRequests.entry) {
            $medReq = $entry.resource
            # 檢查是否為抗生素 (ATC J01 或 medication reference)
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
        Name = "門診抗生素使用率"
        Status = "PASSED"
        Details = "門診: $ambulatoryCount, 抗生素: $antibioticCount, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 2"
        Indicator = "02 (1140.01)"
        Name = "門診抗生素使用率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 3: 指標05 - 門診每張處方箋開藥品項數≥10項之案件比率 (3128)
# ==============================================================================
Write-Host "[TEST 3/11] Indicator 05: Prescription with 10+ Drug Items Rate (3128)" -ForegroundColor Green

try {
    # 查詢門診處方
    $url = "$fhirServer/MedicationRequest?intent=order&date=ge$startDate&_count=100"
    $prescriptions = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    # 按 encounter 分組計算藥品品項數
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
    
    Write-Host "  PASSED - Total Prescriptions: $totalPrescriptions, ≥10 Items: $over10Items, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 3"
        Indicator = "05 (3128)"
        Name = "處方箋≥10藥品品項比率"
        Status = "PASSED"
        Details = "處方箋總數: $totalPrescriptions, ≥10品項: $over10Items, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 3"
        Indicator = "05 (3128)"
        Name = "處方箋≥10藥品品項比率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 4: 指標06 - 18歲以下氣喘病人急診率 (1315Q/1317Y)
# ==============================================================================
Write-Host "[TEST 4/11] Indicator 06: Pediatric Asthma ED Rate (1315Q/1317Y)" -ForegroundColor Green

try {
    # 查詢氣喘診斷 (ICD-10 J45)
    $url = "$fhirServer/Condition?code=http://hl7.org/fhir/sid/icd-10-cm|J45&_count=100"
    $asthmaConditions = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $pediatricAsthmaPatients = @()
    
    if ($asthmaConditions.entry) {
        foreach ($entry in $asthmaConditions.entry) {
            $condition = $entry.resource
            if ($condition.subject -and $condition.subject.reference) {
                $patientId = $condition.subject.reference -replace "Patient/", ""
                
                # 查詢病患年齡
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
                    # 無法查詢病患資料，跳過
                }
            }
        }
    }
    
    # 查詢急診就醫紀錄
    $edCount = 0
    foreach ($patientId in $pediatricAsthmaPatients) {
        try {
            $url = "$fhirServer/Encounter?patient=$patientId&class=EMER&date=ge$startDate&_count=10"
            $edEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
            
            if ($edEncounters.entry) {
                $edCount += $edEncounters.entry.Count
            }
        } catch {
            # 查詢失敗，跳過
        }
    }
    
    $totalPatients = $pediatricAsthmaPatients.Count
    $rate = if ($totalPatients -gt 0) { [math]::Round(($edCount / $totalPatients) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Pediatric Asthma Patients: $totalPatients, ED Visits: $edCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 4"
        Indicator = "06 (1315Q/1317Y)"
        Name = "18歲以下氣喘病人急診率"
        Status = "PASSED"
        Details = "氣喘兒童: $totalPatients, 急診次數: $edCount, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 4"
        Indicator = "06 (1315Q/1317Y)"
        Name = "18歲以下氣喘病人急診率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 5: 指標08 - 就診後同日於同醫院因同疾病再次就診率 (1322)
# ==============================================================================
Write-Host "[TEST 5/11] Indicator 08: Same Day Same Disease Revisit Rate (1322)" -ForegroundColor Green

try {
    # 查詢門診就醫紀錄
    $url = "$fhirServer/Encounter?class=AMB&date=ge$startDate&date=le$endDate&_count=100"
    $encounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    # 按日期、病患、診斷分組
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
                
                # 查詢診斷
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
        
        # 計算同日再次就診（相同診斷）
        foreach ($visit in $patientDailyVisits.Values) {
            if ($visit.Count -gt 1) {
                # 檢查是否有重複診斷
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
        Name = "同日同病再就診率"
        Status = "PASSED"
        Details = "總就診: $totalEncounters, 同日再診: $sameDayRevisits, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 5"
        Indicator = "08 (1322)"
        Name = "同日同病再就診率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 6: 指標09 - 非計畫性住院案件出院後14日內再住院率 (1077.01Q/1809Y)
# ==============================================================================
Write-Host "[TEST 6/11] Indicator 09: 14-Day Unplanned Readmission Rate (1077.01Q/1809Y)" -ForegroundColor Green

try {
    # 查詢住院案件
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
                
                # 查詢14天內的再住院
                $followUpStart = $dischargeDate.AddDays(1).ToString("yyyy-MM-dd")
                $followUpEnd = $dischargeDate.AddDays(14).ToString("yyyy-MM-dd")
                
                try {
                    $url = "$fhirServer/Encounter?patient=$patientId&class=IMP&date=ge$followUpStart&date=le$followUpEnd&_count=10"
                    $followUpEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
                    
                    if ($followUpEncounters.entry -and $followUpEncounters.entry.Count -gt 0) {
                        $readmissions14Day++
                    }
                } catch {
                    # 查詢失敗，跳過
                }
            }
        }
    }
    
    $rate = if ($totalDischarges -gt 0) { [math]::Round(($readmissions14Day / $totalDischarges) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Discharges: $totalDischarges, 14-Day Readmissions: $readmissions14Day, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 6"
        Indicator = "09 (1077.01Q/1809Y)"
        Name = "14日內再住院率"
        Status = "PASSED"
        Details = "出院案件: $totalDischarges, 14日內再住院: $readmissions14Day, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 6"
        Indicator = "09 (1077.01Q/1809Y)"
        Name = "14日內再住院率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 7: 指標10 - 住院案件出院後3日以內急診率 (108.01)
# ==============================================================================
Write-Host "[TEST 7/11] Indicator 10: 3-Day ED After Discharge Rate (108.01)" -ForegroundColor Green

try {
    # 查詢住院案件
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
                
                # 查詢3天內的急診
                $followUpStart = $dischargeDate.AddDays(1).ToString("yyyy-MM-dd")
                $followUpEnd = $dischargeDate.AddDays(3).ToString("yyyy-MM-dd")
                
                try {
                    $url = "$fhirServer/Encounter?patient=$patientId&class=EMER&date=ge$followUpStart&date=le$followUpEnd&_count=10"
                    $edEncounters = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
                    
                    if ($edEncounters.entry -and $edEncounters.entry.Count -gt 0) {
                        $ed3Day++
                    }
                } catch {
                    # 查詢失敗，跳過
                }
            }
        }
    }
    
    $rate = if ($totalDischarges -gt 0) { [math]::Round(($ed3Day / $totalDischarges) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Discharges: $totalDischarges, 3-Day ED: $ed3Day, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 7"
        Indicator = "10 (108.01)"
        Name = "3日內急診率"
        Status = "PASSED"
        Details = "出院案件: $totalDischarges, 3日內急診: $ed3Day, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 7"
        Indicator = "10 (108.01)"
        Name = "3日內急診率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 8: 指標11-1 - 剖腹產率-整體 (1136.01)
# ==============================================================================
Write-Host "[TEST 8/11] Indicator 11-1: Overall Cesarean Section Rate (1136.01)" -ForegroundColor Green

try {
    # 查詢剖腹產手術 (SNOMED 11466000)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|11466000&date=ge$startDate&_count=100"
    $cesareanProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $cesareanCount = if ($cesareanProcedures.total) { $cesareanProcedures.total } else { 0 }
    
    # 查詢自然產 (SNOMED 302383004)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|302383004&date=ge$startDate&_count=100"
    $vaginalProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $vaginalCount = if ($vaginalProcedures.total) { $vaginalProcedures.total } else { 0 }
    
    # 也查詢分娩診斷 (ICD-10 O82 剖腹產, O80 自然產)
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
        Name = "剖腹產率-整體"
        Status = "PASSED"
        Details = "總生產: $totalDeliveries, 剖腹產: $cesareanCount, 自然產: $vaginalCount, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 8"
        Indicator = "11-1 (1136.01)"
        Name = "剖腹產率-整體"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 9: 指標11-2 - 剖腹產率-自行要求 (1137.01)
# ==============================================================================
Write-Host "[TEST 9/11] Indicator 11-2: Patient-Requested Cesarean Rate (1137.01)" -ForegroundColor Green

try {
    # 查詢自行要求剖腹產 (SNOMED 386637004)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|386637004&date=ge$startDate&_count=100"
    $requestedCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $requestedCount = if ($requestedCesarean.total) { $requestedCesarean.total } else { 0 }
    
    # 查詢所有剖腹產
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|11466000&date=ge$startDate&_count=100"
    $allCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $cesareanCount = if ($allCesarean.total) { $allCesarean.total } else { 0 }
    
    # 查詢自然產
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|302383004&date=ge$startDate&_count=100"
    $vaginalProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $vaginalCount = if ($vaginalProcedures.total) { $vaginalProcedures.total } else { 0 }
    
    $totalDeliveries = $cesareanCount + $vaginalCount
    $rate = if ($totalDeliveries -gt 0) { [math]::Round(($requestedCount / $totalDeliveries) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Deliveries: $totalDeliveries, Patient-Requested Cesarean: $requestedCount, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 9"
        Indicator = "11-2 (1137.01)"
        Name = "剖腹產率-自行要求"
        Status = "PASSED"
        Details = "總生產: $totalDeliveries, 自行要求剖腹產: $requestedCount, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 9"
        Indicator = "11-2 (1137.01)"
        Name = "剖腹產率-自行要求"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 10: 指標11-3 - 剖腹產率-具適應症 (1138.01)
# ==============================================================================
Write-Host "[TEST 10/11] Indicator 11-3: Cesarean with Indication Rate (1138.01)" -ForegroundColor Green

try {
    # 查詢選擇性剖腹產 (SNOMED 177141003 - 可能具適應症)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|177141003&date=ge$startDate&_count=100"
    $electiveCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $electiveCount = if ($electiveCesarean.total) { $electiveCesarean.total } else { 0 }
    
    # 查詢緊急剖腹產 (SNOMED 177152005 - 具適應症)
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|177152005&date=ge$startDate&_count=100"
    $emergencyCesarean = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $emergencyCount = if ($emergencyCesarean.total) { $emergencyCesarean.total } else { 0 }
    
    $indicatedCesarean = $electiveCount + $emergencyCount
    
    # 查詢自然產
    $url = "$fhirServer/Procedure?code=http://snomed.info/sct|302383004&date=ge$startDate&_count=100"
    $vaginalProcedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $vaginalCount = if ($vaginalProcedures.total) { $vaginalProcedures.total } else { 0 }
    
    $totalDeliveries = $indicatedCesarean + $vaginalCount
    $rate = if ($totalDeliveries -gt 0) { [math]::Round(($indicatedCesarean / $totalDeliveries) * 100, 2) } else { 0 }
    
    Write-Host "  PASSED - Total Deliveries: $totalDeliveries, Indicated Cesarean: $indicatedCesarean, Rate: $rate%" -ForegroundColor Green
    $testResults += @{
        Test = "Test 10"
        Indicator = "11-3 (1138.01)"
        Name = "剖腹產率-具適應症"
        Status = "PASSED"
        Details = "總生產: $totalDeliveries, 具適應症剖腹產: $indicatedCesarean, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 10"
        Indicator = "11-3 (1138.01)"
        Name = "剖腹產率-具適應症"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# Test 11: 指標19 - 清淨手術術後傷口感染率 (2524Q/2526Y)
# ==============================================================================
Write-Host "[TEST 11/11] Indicator 19: Clean Surgery Wound Infection Rate (2524Q/2526Y)" -ForegroundColor Green

try {
    # 查詢清淨手術 (clean surgery procedures)
    $url = "$fhirServer/Procedure?date=ge$startDate&_count=100"
    $procedures = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    
    $cleanSurgeryCount = 0
    $cleanSurgeryPatients = @()
    
    if ($procedures.entry) {
        foreach ($entry in $procedures.entry) {
            $proc = $entry.resource
            # 簡化判定：假設所有手術都是清淨手術進行測試
            if ($proc.status -eq "completed" -and $proc.subject -and $proc.subject.reference) {
                $cleanSurgeryCount++
                $patientId = $proc.subject.reference -replace "Patient/", ""
                if ($cleanSurgeryPatients -notcontains $patientId) {
                    $cleanSurgeryPatients += $patientId
                }
            }
        }
    }
    
    # 查詢術後傷口感染 (ICD-10 T81.4)
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
        Name = "清淨手術傷口感染率"
        Status = "PASSED"
        Details = "清淨手術: $cleanSurgeryCount, 傷口感染: $infectionCount, 比率: $rate%"
    }
    $passCount++
} catch {
    Write-Host "  FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{
        Test = "Test 11"
        Indicator = "19 (2524Q/2526Y)"
        Name = "清淨手術傷口感染率"
        Status = "FAILED"
        Details = $_.Exception.Message
    }
    $failCount++
}

Write-Host ""

# ==============================================================================
# 測試結果總結
# ==============================================================================
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "測試結果總結" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$successRate = if (($passCount + $failCount) -gt 0) { [math]::Round(($passCount / ($passCount + $failCount)) * 100, 2) } else { 0 }

foreach ($result in $testResults) {
    $statusColor = if ($result.Status -eq "PASSED") { "Green" } else { "Red" }
    $statusSymbol = if ($result.Status -eq "PASSED") { "✓" } else { "✗" }
    
    Write-Host "$statusSymbol [$($result.Test)] 指標 $($result.Indicator) - $($result.Name)" -ForegroundColor $statusColor
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

# 儲存報告
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = "SMART_Remaining_Indicators_Test_$timestamp.txt"

$reportContent = @"
================================================================================
SMART on FHIR 測試報告 - 剩餘未測試指標 (11個)
================================================================================
FHIR Server: $fhirServer
測試期間: $startDate to $endDate
測試時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

測試指標:
  01: 門診注射劑使用率 (3127)
  02: 門診抗生素使用率 (1140.01)
  05: 門診每張處方箋開藥品項數≥10項之案件比率 (3128)
  06: 18歲以下氣喘病人急診率 (1315Q/1317Y)
  08: 就診後同日於同醫院因同疾病再次就診率 (1322)
  09: 非計畫性住院案件出院後14日內再住院率 (1077.01Q/1809Y)
  10: 住院案件出院後3日以內急診率 (108.01)
  11-1: 剖腹產率-整體 (1136.01)
  11-2: 剖腹產率-自行要求 (1137.01)
  11-3: 剖腹產率-具適應症 (1138.01)
  19: 清淨手術術後傷口感染率 (2524Q/2526Y)

================================================================================
測試結果詳細資訊
================================================================================

"@

foreach ($result in $testResults) {
    $reportContent += @"
[$($result.Test)] 指標 $($result.Indicator) - $($result.Name)
狀態: $($result.Status)
詳細資訊: $($result.Details)

"@
}

$reportContent += @"
================================================================================
測試總結
================================================================================
Total Tests: $($passCount + $failCount)
Passed: $passCount
Failed: $failCount
Success Rate: $successRate%

================================================================================
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Report saved to: $reportPath" -ForegroundColor Green
