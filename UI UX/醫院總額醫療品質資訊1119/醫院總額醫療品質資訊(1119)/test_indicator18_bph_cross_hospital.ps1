# ============================================
# 指標18: 跨醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服)
# 資料來源: SMART on FHIR 測試伺服器
# 指標代碼: 3378
# 執行日期: 2025-11-08
# ============================================

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "指標18: 跨醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服)" -ForegroundColor Cyan
Write-Host "資料來源: SMART on FHIR 測試伺服器" -ForegroundColor Cyan
Write-Host "指標代碼: 3378" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# SMART FHIR 測試伺服器列表
$fhirServers = @(
    @{
        Name = "SMART Health IT"
        BaseUrl = "https://r4.smarthealthit.org"
        Description = "SMART Health IT R4 測試伺服器"
    },
    @{
        Name = "HAPI FHIR Test"
        BaseUrl = "https://hapi.fhir.org/baseR4"
        Description = "HAPI FHIR R4 公開測試伺服器"
    }
)

# BPH ATC Codes (G04CA, G04CB)
$bphAtcCodes = @(
    "G04CA",
    "G04CB"
)

# Define Quarters
$quarters = @(
    @{ Name = "113Q3"; StartDate = "2024-07-01"; EndDate = "2024-09-30" },
    @{ Name = "113Q4"; StartDate = "2024-10-01"; EndDate = "2024-12-31" },
    @{ Name = "113Annual"; StartDate = "2024-01-01"; EndDate = "2024-12-31" }
)

# 儲存所有處方資料
$allPrescriptions = @()
$serverIndex = 1

# 從每個 FHIR 伺服器獲取資料
foreach ($server in $fhirServers) {
    Write-Host "正在連接到: $($server.Name)" -ForegroundColor Yellow
    Write-Host "URL: $($server.BaseUrl)" -ForegroundColor Gray
    
    try {
        # 搜尋前列腺肥大藥物處方
        foreach ($atcCode in $bphAtcCodes) {
            $searchUrl = "$($server.BaseUrl)/MedicationRequest?code=$atcCode&_count=100"
            
            Write-Host "  查詢 ATC: $atcCode" -ForegroundColor Gray
            
            try {
                $response = Invoke-RestMethod -Uri $searchUrl -Method Get -Headers @{
                    "Accept" = "application/fhir+json"
                } -TimeoutSec 30
                
                if ($response.entry) {
                    Write-Host "    找到 $($response.entry.Count) 筆處方" -ForegroundColor Green
                    
                    foreach ($entry in $response.entry) {
                        $medRequest = $entry.resource
                        
                        # 檢查是否為口服劑型
                        $isOral = $false
                        if ($medRequest.dosageInstruction) {
                            foreach ($dosage in $medRequest.dosageInstruction) {
                                if ($dosage.route.coding) {
                                    foreach ($route in $dosage.route.coding) {
                                        if ($route.code -eq "26643006" -or $route.display -match "Oral|口服") {
                                            $isOral = $true
                                            break
                                        }
                                    }
                                }
                            }
                        }
                        
                        # 如果沒有明確劑型資訊，預設為口服（因為是 G04CA/G04CB）
                        if (-not $medRequest.dosageInstruction) {
                            $isOral = $true
                        }
                        
                        if ($isOral) {
                            # 提取處方資訊
                            $patientRef = $medRequest.subject.reference -replace "Patient/", ""
                            $authoredOn = $medRequest.authoredOn
                            
                            # 計算給藥日數
                            $drugDays = 28  # 預設28天
                            if ($medRequest.dispenseRequest.expectedSupplyDuration) {
                                $drugDays = $medRequest.dispenseRequest.expectedSupplyDuration.value
                            }
                            
                            # 計算結束日期
                            $startDate = [DateTime]::Parse($authoredOn)
                            $endDate = $startDate.AddDays($drugDays - 1)
                            
                            # 取得藥品代碼
                            $drugCode = ""
                            $drugName = ""
                            if ($medRequest.medicationCodeableConcept.coding) {
                                $drugCode = $medRequest.medicationCodeableConcept.coding[0].code
                                $drugName = $medRequest.medicationCodeableConcept.coding[0].display
                            }
                            
                            $prescription = [PSCustomObject]@{
                                ServerId = $serverIndex
                                ServerName = $server.Name
                                PatientId = $patientRef
                                ClaimId = $medRequest.id
                                DrugCode = $drugCode
                                DrugName = $drugName
                                AtcCode = $atcCode
                                StartDate = $startDate
                                EndDate = $endDate
                                DrugDays = $drugDays
                                AuthoredOn = $authoredOn
                            }
                            
                            $allPrescriptions += $prescription
                        }
                    }
                } else {
                    Write-Host "    未找到資料" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "    查詢失敗: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            Start-Sleep -Milliseconds 500
        }
        
        $serverIndex++
        
    } catch {
        Write-Host "連接失敗: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Data Collection Completed" -ForegroundColor Green
Write-Host "Total Prescriptions: $($allPrescriptions.Count)" -ForegroundColor Green
Write-Host "Total Patients: $(($allPrescriptions | Select-Object -Unique PatientId).Count)" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# If insufficient data, use simulated data
if ($allPrescriptions.Count -lt 10) {
    Write-Host "Insufficient real data, adding simulated data for calculation..." -ForegroundColor Yellow
    Write-Host ""
    
    # 生成模擬的跨院處方資料
    $simulatedPatients = @("P001", "P002", "P003", "P004", "P005", "P006", "P007", "P008", "P009", "P010")
    $baseDate = Get-Date "2024-07-01"
    
    foreach ($patientId in $simulatedPatients) {
        # 每個病人在兩個不同醫院各有處方
        for ($serverId = 1; $serverId -le 2; $serverId++) {
            $serverName = if ($serverId -eq 1) { "SMART Health IT" } else { "HAPI FHIR Test" }
            
            # 隨機生成處方
            $prescriptionCount = Get-Random -Minimum 2 -Maximum 5
            
            for ($i = 0; $i -lt $prescriptionCount; $i++) {
                $daysOffset = Get-Random -Minimum 0 -Maximum 180
                $drugDays = Get-Random -Minimum 28 -Maximum 90
                $startDate = $baseDate.AddDays($daysOffset)
                $endDate = $startDate.AddDays($drugDays - 1)
                
                $atcCode = if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) { "G04CA" } else { "G04CB" }
                $drugName = if ($atcCode -eq "G04CA") { "Tamsulosin 0.4mg" } else { "Finasteride 5mg" }
                
                $prescription = [PSCustomObject]@{
                    ServerId = $serverId
                    ServerName = $serverName
                    PatientId = $patientId
                    ClaimId = "SIM-$patientId-$serverId-$i"
                    DrugCode = "DRUG-$(Get-Random -Minimum 1000 -Maximum 9999)"
                    DrugName = $drugName
                    AtcCode = $atcCode
                    StartDate = $startDate
                    EndDate = $endDate
                    DrugDays = $drugDays
                    AuthoredOn = $startDate.ToString("yyyy-MM-dd")
                }
                
                $allPrescriptions += $prescription
            }
        }
    }
    
    Write-Host "Simulated data added" -ForegroundColor Green
    Write-Host "Updated total prescriptions: $($allPrescriptions.Count)" -ForegroundColor Green
    Write-Host ""
}

# 計算跨醫院重疊
function Calculate-CrossHospitalOverlap {
    param (
        [array]$Prescriptions,
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    
    # 篩選該季度的處方
    $periodPrescriptions = $Prescriptions | Where-Object {
        $_.StartDate -ge $StartDate -and $_.StartDate -le $EndDate
    }
    
    if ($periodPrescriptions.Count -eq 0) {
        return @{
            TotalDrugDays = 0
            OverlapDays = 0
            OverlapRate = 0
            TotalPatients = 0
            TotalPrescriptions = 0
            CrossHospitalOverlapPatients = 0
            CrossHospitalOverlapPairs = 0
        }
    }
    
    # 計算分母: 所有給藥日數總和
    $totalDrugDays = ($periodPrescriptions | Measure-Object -Property DrugDays -Sum).Sum
    
    # 找出跨醫院的處方配對
    $overlapDays = 0
    $overlapPairs = @()
    $patientsWithOverlap = @{}
    
    # 按病人分組
    $patientGroups = $periodPrescriptions | Group-Object -Property PatientId
    
    foreach ($group in $patientGroups) {
        $patientPrescriptions = $group.Group
        
        # 找出該病人在不同醫院的處方
        $serverGroups = $patientPrescriptions | Group-Object -Property ServerId
        
        if ($serverGroups.Count -ge 2) {
            # 該病人有跨醫院處方
            # 計算所有跨醫院配對的重疊
            for ($i = 0; $i -lt $patientPrescriptions.Count; $i++) {
                for ($j = $i + 1; $j -lt $patientPrescriptions.Count; $j++) {
                    $prescA = $patientPrescriptions[$i]
                    $prescB = $patientPrescriptions[$j]
                    
                    # 只計算跨醫院的配對
                    if ($prescA.ServerId -ne $prescB.ServerId) {
                        # 計算重疊天數 (允許7天遞延)
                        $endA = $prescA.EndDate.AddDays(7)
                        $endB = $prescB.EndDate.AddDays(7)
                        
                        $overlapStart = if ($prescA.StartDate -gt $prescB.StartDate) { $prescA.StartDate } else { $prescB.StartDate }
                        $overlapEnd = if ($endA -lt $endB) { $endA } else { $endB }
                        
                        $overlap = ($overlapEnd - $overlapStart).Days + 1
                        
                        if ($overlap -gt 0) {
                            $overlapDays += $overlap
                            $patientsWithOverlap[$group.Name] = $true
                            
                            $overlapPairs += [PSCustomObject]@{
                                PatientId = $group.Name
                                ClaimA = $prescA.ClaimId
                                ClaimB = $prescB.ClaimId
                                ServerA = $prescA.ServerName
                                ServerB = $prescB.ServerName
                                OverlapDays = $overlap
                            }
                        }
                    }
                }
            }
        }
    }
    
    # 計算重疊率
    $overlapRate = if ($totalDrugDays -gt 0) {
        [Math]::Round(($overlapDays / $totalDrugDays) * 100, 2)
    } else {
        0
    }
    
    return @{
        TotalDrugDays = $totalDrugDays
        OverlapDays = $overlapDays
        OverlapRate = $overlapRate
        TotalPatients = $patientGroups.Count
        TotalPrescriptions = $periodPrescriptions.Count
        CrossHospitalOverlapPatients = $patientsWithOverlap.Count
        CrossHospitalOverlapPairs = $overlapPairs.Count
        OverlapPairs = $overlapPairs
    }
}

# Calculate quarterly statistics
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Calculating Quarterly Statistics" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$results = @()

foreach ($quarter in $quarters) {
    Write-Host "Calculating $($quarter.Name)..." -ForegroundColor Yellow
    
    $startDate = [DateTime]::Parse($quarter.StartDate)
    $endDate = [DateTime]::Parse($quarter.EndDate)
    
    $stats = Calculate-CrossHospitalOverlap -Prescriptions $allPrescriptions -StartDate $startDate -EndDate $endDate
    
    $quarterDisplay = $quarter.Name
    if ($quarter.Name -eq "113Q3") { $quarterDisplay = "113 Q3" }
    elseif ($quarter.Name -eq "113Q4") { $quarterDisplay = "113 Q4" }
    elseif ($quarter.Name -eq "113Annual") { $quarterDisplay = "113 Annual" }
    
    $result = [PSCustomObject]@{
        Quarter = $quarterDisplay
        TotalPatients = $stats.TotalPatients
        TotalPrescriptions = $stats.TotalPrescriptions
        TotalDrugDays = $stats.TotalDrugDays
        OverlapDays = $stats.OverlapDays
        OverlapRate = $stats.OverlapRate
        CrossHospitalOverlapPatients = $stats.CrossHospitalOverlapPatients
        CrossHospitalOverlapPairs = $stats.CrossHospitalOverlapPairs
    }
    
    $results += $result
    
    Write-Host "  Total Patients: $($stats.TotalPatients)" -ForegroundColor Gray
    Write-Host "  Total Prescriptions: $($stats.TotalPrescriptions)" -ForegroundColor Gray
    Write-Host "  Total Drug Days: $($stats.TotalDrugDays)" -ForegroundColor Gray
    Write-Host "  Overlap Days: $($stats.OverlapDays)" -ForegroundColor Gray
    Write-Host "  Overlap Rate: $($stats.OverlapRate)%" -ForegroundColor Green
    Write-Host ""
}

# Display Results (Following Image Format)
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Indicator 18: Cross-Hospital BPH Drug Overlap Rate" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Build Table
$tableData = @()

foreach ($result in $results) {
    # Overlap Days Row
    $tableData += [PSCustomObject]@{
        Period = $result.Quarter
        Item = "BPH Drug (Oral) Overlap Days"
        Value = $result.OverlapDays.ToString("N0")
    }
    
    # Total Drug Days Row
    $tableData += [PSCustomObject]@{
        Period = ""
        Item = "BPH Drug (Oral) Total Days"
        Value = $result.TotalDrugDays.ToString("N0")
    }
    
    # Overlap Rate Row
    $tableData += [PSCustomObject]@{
        Period = ""
        Item = "BPH Drug (Oral) Overlap Rate"
        Value = "$($result.OverlapRate)%"
    }
}

# Display Table
$tableData | Format-Table -AutoSize -Property @(
    @{Label="Period"; Expression={$_.Period}; Width=15},
    @{Label="Item"; Expression={$_.Item}; Width=50},
    @{Label="Value"; Expression={$_.Value}; Width=20; Alignment="Right"}
)

# Detailed Statistics
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Detailed Statistics" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($result in $results) {
    Write-Host "[$($result.Quarter)]" -ForegroundColor Yellow
    Write-Host "  Total Patients: $($result.TotalPatients)" -ForegroundColor White
    Write-Host "  Total Prescriptions: $($result.TotalPrescriptions)" -ForegroundColor White
    Write-Host "  Patients with Cross-Hospital Overlap: $($result.CrossHospitalOverlapPatients)" -ForegroundColor White
    Write-Host "  Cross-Hospital Overlap Pairs: $($result.CrossHospitalOverlapPairs)" -ForegroundColor White
    Write-Host "  Total Drug Days: $($result.TotalDrugDays.ToString('N0'))" -ForegroundColor White
    Write-Host "  Total Overlap Days: $($result.OverlapDays.ToString('N0'))" -ForegroundColor White
    Write-Host "  Overlap Rate: $($result.OverlapRate)%" -ForegroundColor Green
    Write-Host ""
}

# Export to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvFile = "indicator18_bph_cross_hospital_results_$timestamp.csv"

$results | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

Write-Host "Results saved to: $csvFile" -ForegroundColor Green
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Test Completed" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
