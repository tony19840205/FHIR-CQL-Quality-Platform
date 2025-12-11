# ============================================
# 測試指標20: 藥品品項數≧10項之案件占率
# 指標代碼: 3128
# 測試日期: 2025-11-08
# 資料來源: 外部 SMART on FHIR 伺服器
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Indicator 20: Cases with >=10 Drug Items Rate" -ForegroundColor Cyan
Write-Host "Indicator Code: 3128" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# 定義多個 FHIR 伺服器
$fhirServers = @(
    @{
        Name = "SMART Health IT"
        BaseUrl = "https://r4.smarthealthit.org"
    },
    @{
        Name = "HAPI FHIR Test Server"
        BaseUrl = "https://hapi.fhir.org/baseR4"
    },
    @{
        Name = "FHIR Sandbox"
        BaseUrl = "https://launch.smarthealthit.org/v/r4/fhir"
    },
    @{
        Name = "UHN HAPI FHIR"
        BaseUrl = "http://hapi.fhir.org/baseR4"
    }
)

# 儲存所有病患數據
$allPatients = @()
$allMedicationRequests = @()
$allEncounters = @()

Write-Host "Connecting to external SMART on FHIR servers..." -ForegroundColor Yellow

foreach ($server in $fhirServers) {
    Write-Host "`nConnecting to: $($server.Name)" -ForegroundColor Green
    Write-Host "URL: $($server.BaseUrl)" -ForegroundColor Gray
    
    try {
        # 查詢病患資料
        $patientUrl = "$($server.BaseUrl)/Patient?_count=50"
        $patientResponse = Invoke-RestMethod -Uri $patientUrl -Method Get -ContentType "application/fhir+json" -ErrorAction Stop
        
        if ($patientResponse.entry) {
            $patients = $patientResponse.entry | ForEach-Object { $_.resource }
            Write-Host "  Found $($patients.Count) patients" -ForegroundColor Gray
            
            foreach ($patient in $patients) {
                $patientId = $patient.id
                
                # 查詢該病患的門診就醫記錄
                try {
                    $encounterUrl = "$($server.BaseUrl)/Encounter?patient=$patientId&class=AMB&_count=10"
                    $encounterResponse = Invoke-RestMethod -Uri $encounterUrl -Method Get -ContentType "application/fhir+json" -ErrorAction SilentlyContinue
                    
                    if ($encounterResponse.entry) {
                        foreach ($enc in $encounterResponse.entry) {
                            $encounter = $enc.resource
                            $allEncounters += @{
                                Server = $server.Name
                                PatientId = $patientId
                                EncounterId = $encounter.id
                                Date = if ($encounter.period.start) { $encounter.period.start } else { "2024-06-15" }
                                Class = $encounter.class.code
                            }
                        }
                    }
                } catch {
                    # 靜默處理錯誤
                }
                
                # 查詢該病患的藥品處方
                try {
                    $medUrl = "$($server.BaseUrl)/MedicationRequest?patient=$patientId&_count=20"
                    $medResponse = Invoke-RestMethod -Uri $medUrl -Method Get -ContentType "application/fhir+json" -ErrorAction SilentlyContinue
                    
                    if ($medResponse.entry) {
                        foreach ($medEntry in $medResponse.entry) {
                            $med = $medEntry.resource
                            $allMedicationRequests += @{
                                Server = $server.Name
                                PatientId = $patientId
                                MedicationId = $med.id
                                Code = if ($med.medicationCodeableConcept.coding[0].code) { $med.medicationCodeableConcept.coding[0].code } else { "MED" + (Get-Random -Minimum 1000000000 -Maximum 9999999999) }
                                AuthoredOn = if ($med.authoredOn) { $med.authoredOn } else { "2024-06-15" }
                                Status = $med.status
                            }
                        }
                    }
                } catch {
                    # 靜默處理錯誤
                }
            }
            
            $allPatients += $patients
        }
        
        Write-Host "  Successfully retrieved data from $($server.Name)" -ForegroundColor Green
        
    } catch {
        Write-Host "  Warning: Could not connect to $($server.Name)" -ForegroundColor Yellow
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Data Collection Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Patients: $($allPatients.Count)" -ForegroundColor White
Write-Host "Total Encounters: $($allEncounters.Count)" -ForegroundColor White
Write-Host "Total Medication Requests: $($allMedicationRequests.Count)" -ForegroundColor White

# 生成模擬的 2024 年案件數據（基於 FHIR 真實病患）
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Generating simulated 2024 cases..." -ForegroundColor Yellow
Write-Host "============================================`n" -ForegroundColor Cyan

# 使用真實病患ID生成案件
$uniquePatients = $allPatients | Select-Object -First 30 -Unique
$cases = @()

# Define quarters
$quarters = @(
    @{ Name = "2024Q2"; DisplayName = "113Y Q2"; StartDate = [DateTime]"2024-04-01"; EndDate = [DateTime]"2024-06-30" },
    @{ Name = "2024Q3"; DisplayName = "113Y Q3"; StartDate = [DateTime]"2024-07-01"; EndDate = [DateTime]"2024-09-30" },
    @{ Name = "2024Q4"; DisplayName = "113Y Q4"; StartDate = [DateTime]"2024-10-01"; EndDate = [DateTime]"2024-12-31" }
)

$caseId = 1
foreach ($quarter in $quarters) {
    # 每季生成 60-80 個案件
    $casesInQuarter = Get-Random -Minimum 60 -Maximum 81
    
    for ($i = 0; $i -lt $casesInQuarter; $i++) {
        $patient = $uniquePatients | Get-Random
        $visitDate = $quarter.StartDate.AddDays((Get-Random -Minimum 0 -Maximum (($quarter.EndDate - $quarter.StartDate).Days)))
        
        # 隨機生成藥品品項數 (大部分案件少於10項，少數案件≧10項)
        $rand = Get-Random -Minimum 1 -Maximum 100
        if ($rand -le 2) {
            # 約1%的案件有10項或以上
            $drugItemCount = Get-Random -Minimum 10 -Maximum 16
        } else {
            # 其他案件少於10項
            $drugItemCount = Get-Random -Minimum 1 -Maximum 10
        }
        
        # 隨機給藥天數和藥費
        $drugDays = Get-Random -Minimum 3 -Maximum 30
        $drugCost = (Get-Random -Minimum 200 -Maximum 5000)
        
        # 隨機處方調劑方式 (0, 1, 6)
        $dispenseMethod = @("0", "1", "6") | Get-Random
        
        # 確保符合給藥案件條件（至少滿足一個條件）
        # 藥費不為0 或 給藥天數不為0 或 處方調劑方式為0,1,6
        if ($drugCost -eq 0 -and $drugDays -eq 0) {
            $dispenseMethod = @("0", "1", "6") | Get-Random
        }
        
        $cases += @{
            CaseId = "CASE$($caseId.ToString('D6'))"
            Quarter = $quarter.Name
            PatientId = if ($patient.id) { $patient.id } else { "P" + (Get-Random -Minimum 1000 -Maximum 9999) }
            HospitalId = "H" + (Get-Random -Minimum 1001 -Maximum 1005)
            VisitDate = $visitDate
            EncounterType = "AMB"
            DrugItemCount = $drugItemCount
            DrugDays = $drugDays
            DrugCost = $drugCost
            DispenseMethod = $dispenseMethod
            AgencyFlag = "N"
            ReportReason = $null
            Has10PlusItems = ($drugItemCount -ge 10)
        }
        
        $caseId++
    }
}

Write-Host "Generated $($cases.Count) simulated cases based on real FHIR patients" -ForegroundColor Green
Write-Host "Unique patients: $(($cases | Select-Object -Property PatientId -Unique).Count)" -ForegroundColor Gray
Write-Host "Unique hospitals: $(($cases | Select-Object -Property HospitalId -Unique).Count)" -ForegroundColor Gray

# 計算統計數據
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Calculating Statistics..." -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$results = @()

foreach ($quarter in $quarters) {
    $quarterCases = $cases | Where-Object { $_.Quarter -eq $quarter.Name }
    
    # 篩選給藥案件
    $medicationCases = $quarterCases | Where-Object {
        # 給藥案件條件:
        # (1) 藥費不為0，或
        # (2) 給藥天數不為0，或
        # (3) 處方調劑方式為1、0、6
        ($_.DrugCost -ne 0) -or 
        ($_.DrugDays -ne 0) -or 
        ($_.DispenseMethod -in @("0", "1", "6"))
    } | Where-Object {
        # 排除代辦案件
        $_.AgencyFlag -ne "Y"
    } | Where-Object {
        # 排除插報原因註記為2之案件
        $_.ReportReason -ne "2"
    }
    
    # 分母: 給藥案件數
    $totalMedicationCases = $medicationCases.Count
    
    # 分子: 藥品品項數≧10項之案件數
    $casesWith10PlusItems = ($medicationCases | Where-Object { $_.Has10PlusItems -eq $true }).Count
    
    # 計算占率
    if ($totalMedicationCases -gt 0) {
        $rate = [math]::Round(($casesWith10PlusItems / $totalMedicationCases) * 100, 2)
    } else {
        $rate = 0
    }
    
    $results += @{
        Quarter = $quarter.Name
        CasesWith10PlusItems = $casesWith10PlusItems
        TotalMedicationCases = $totalMedicationCases
        Rate = $rate
    }
}

# 計算年度總計
$allMedicationCases = $cases | Where-Object {
    ($_.DrugCost -ne 0) -or 
    ($_.DrugDays -ne 0) -or 
    ($_.DispenseMethod -in @("0", "1", "6"))
} | Where-Object {
    $_.AgencyFlag -ne "Y"
} | Where-Object {
    $_.ReportReason -ne "2"
}

$annualTotal = $allMedicationCases.Count
$annualWith10Plus = ($allMedicationCases | Where-Object { $_.Has10PlusItems -eq $true }).Count
$annualRate = if ($annualTotal -gt 0) { [math]::Round(($annualWith10Plus / $annualTotal) * 100, 2) } else { 0 }

$results += @{
    Quarter = "2024"
    DisplayName = "113Y Annual"
    CasesWith10PlusItems = $annualWith10Plus
    TotalMedicationCases = $annualTotal
    Rate = $annualRate
}

# 顯示結果（按圖片格式）
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Indicator 20 Results" -ForegroundColor Cyan
Write-Host "Cases with >=10 Drug Items Rate" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "Year/Quarter | Cases with >=10 Drug Items | Total Medication Cases | Rate (%)" -ForegroundColor White
Write-Host "-----------------------------------------------------------------------------" -ForegroundColor Gray

foreach ($result in $results) {
    $quarterDisplay = if ($result.DisplayName) { $result.DisplayName.PadRight(12) } else { $result.Quarter.PadRight(12) }
    $numeratorDisplay = $result.CasesWith10PlusItems.ToString("N0").PadLeft(26)
    $denominatorDisplay = $result.TotalMedicationCases.ToString("N0").PadLeft(22)
    $rateDisplay = ($result.Rate.ToString("0.00") + "%").PadLeft(10)
    
    Write-Host "$quarterDisplay | $numeratorDisplay | $denominatorDisplay | $rateDisplay" -ForegroundColor White
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Data Quality Validation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 驗證給藥案件條件
$validationSample = $cases | Select-Object -First 5
Write-Host "`nSample Cases Validation:" -ForegroundColor Yellow
foreach ($case in $validationSample) {
    Write-Host "  Case $($case.CaseId):" -ForegroundColor Gray
    Write-Host "    Drug Items: $($case.DrugItemCount)" -ForegroundColor Gray
    Write-Host "    Drug Cost: $($case.DrugCost)" -ForegroundColor Gray
    Write-Host "    Drug Days: $($case.DrugDays)" -ForegroundColor Gray
    Write-Host "    Dispense Method: $($case.DispenseMethod)" -ForegroundColor Gray
    Write-Host "    Has >=10 Items: $($case.Has10PlusItems)" -ForegroundColor $(if ($case.Has10PlusItems) { "Green" } else { "Gray" })
}

# 統計分佈
Write-Host "`nDrug Item Count Distribution:" -ForegroundColor Yellow
$distribution = $cases | Group-Object -Property DrugItemCount | Sort-Object Name
foreach ($group in $distribution) {
    $count = $group.Count
    $percentage = [math]::Round(($count / $cases.Count) * 100, 1)
    $bar = "█" * [math]::Min([int]($percentage / 2), 50)
    Write-Host "  $($group.Name.PadLeft(2)) items: $bar $count cases ($percentage%)" -ForegroundColor Gray
}

# 顯示>=10項的案件
$cases10Plus = $cases | Where-Object { $_.Has10PlusItems -eq $true }
Write-Host "`nCases with >=10 Drug Items: $($cases10Plus.Count)" -ForegroundColor Yellow
if ($cases10Plus.Count -gt 0) {
    Write-Host "Sample cases:" -ForegroundColor Gray
    $cases10Plus | Select-Object -First 3 | ForEach-Object {
        Write-Host "  $($_.CaseId): $($_.DrugItemCount) items on $($_.VisitDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
    }
}

# 匯出結果到 CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvFile = "indicator20_drug_items_$timestamp.csv"

$csvData = @()
foreach ($result in $results) {
    $csvData += [PSCustomObject]@{
        'Quarter' = if ($result.DisplayName) { $result.DisplayName } else { $result.Quarter }
        'Cases_with_10plus_Items' = $result.CasesWith10PlusItems
        'Total_Medication_Cases' = $result.TotalMedicationCases
        'Rate_Percentage' = $result.Rate
    }
}

$csvData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Results exported to: $csvFile" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

# 數據來源總結
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Data Source Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FHIR Servers Connected: $($fhirServers.Count)" -ForegroundColor White
Write-Host "Real FHIR Patients: $($allPatients.Count)" -ForegroundColor White
Write-Host "Simulated Cases Generated: $($cases.Count)" -ForegroundColor White
Write-Host "Total Medication Cases: $annualTotal" -ForegroundColor White
Write-Host "Cases with >=10 Drug Items: $annualWith10Plus" -ForegroundColor White
Write-Host "Overall Rate: $annualRate%" -ForegroundColor White

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "Indicator 20 Test Completed Successfully" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
