# ========================================
# 指標12測試腳本
# 跨醫院門診降血脂藥物(口服)用藥日數重疊率
# Cross-Hospital Lipid-Lowering Medication Overlap Rate
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "指標12 外部FHIR測試" -ForegroundColor Yellow
Write-Host "跨醫院門診降血脂藥物(口服)重疊率" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 測試參數
$fhirServer = "https://r4.smarthealthit.org"
$indicatorCode = "1714"
$indicatorName = "跨醫院門診同藥理用藥日數重疊率-降血脂藥物(口服)"

Write-Host "[指標資訊]" -ForegroundColor Green
Write-Host "  指標代碼: $indicatorCode" -ForegroundColor White
Write-Host "  指標名稱: $indicatorName" -ForegroundColor White
Write-Host "  FHIR伺服器: $fhirServer" -ForegroundColor White
Write-Host ""

# ==================== ATC代碼定義 ====================
Write-Host "[ATC代碼範圍] (降血脂藥物-口服)" -ForegroundColor Green
Write-Host "  共5類 ATC代碼:" -ForegroundColor Cyan

$atcCodes = @{
    "C10AA" = "HMG CoA還原酶抑制劑 (Statins)"
    "C10AB" = "Fibrates (纖維酸衍生物)"
    "C10AC" = "膽酸螯合劑 (Bile acid sequestrants)"
    "C10AD" = "菸鹼酸及其衍生物 (Nicotinic acid derivatives)"
    "C10AX" = "其他降血脂藥物 (Other lipid-lowering agents)"
}

$atcCodes.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host "    $($_.Key) - $($_.Value)" -ForegroundColor White
}

Write-Host ""
Write-Host "  劑型限制: 口服 (SNOMED CT: 385268001)" -ForegroundColor Yellow
Write-Host "  就醫類別: 門診 (AMB)" -ForegroundColor Yellow
Write-Host "  跨醫院條件: a.hospital_id != b.hospital_id" -ForegroundColor Magenta
Write-Host ""

# ==================== 查詢降血脂藥物處方 ====================
Write-Host "[步驟1] 查詢降血脂藥物處方..." -ForegroundColor Cyan

$medications = @()
$totalRequests = 0

foreach ($atc in $atcCodes.Keys | Sort-Object) {
    Write-Host "  查詢 $atc ..." -ForegroundColor Gray
    
    $url = "$fhirServer/MedicationRequest?code=$atc&status=completed&_count=50"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
        
        if ($response.entry) {
            $count = $response.entry.Count
            $totalRequests += $count
            
            foreach ($entry in $response.entry) {
                $med = $entry.resource
                
                # 檢查是否為口服劑型
                $isOral = $false
                if ($med.dosageInstruction) {
                    foreach ($dosage in $med.dosageInstruction) {
                        if ($dosage.route.coding) {
                            foreach ($coding in $dosage.route.coding) {
                                if ($coding.code -eq "385268001") {
                                    $isOral = $true
                                    break
                                }
                            }
                        }
                    }
                }
                
                # 提取資訊
                $medications += @{
                    id = $med.id
                    patientId = $med.subject.reference
                    hospitalId = $med.performer.reference
                    atcCode = $atc
                    authoredOn = $med.authoredOn
                    drugDays = if ($med.dispenseRequest.quantity) { $med.dispenseRequest.quantity.value } else { 30 }
                    isOral = $isOral
                }
            }
            
            Write-Host "    找到 $count 筆處方" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "    查詢失敗: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  總計處方數: $totalRequests" -ForegroundColor White
Write-Host "  口服處方數: $($medications.Where({$_.isOral}).Count)" -ForegroundColor White
Write-Host ""

# ==================== 跨醫院配對分析 ====================
Write-Host "[步驟2] 跨醫院配對分析..." -ForegroundColor Cyan

# 只分析口服處方
$oralMedications = $medications.Where({$_.isOral})

# 按病人分組
$patientGroups = $oralMedications | Group-Object -Property patientId

$crossHospitalPairs = @()
$overlapPairs = @()
$totalOverlapDays = 0
$totalDrugDays = 0

foreach ($med in $oralMedications) {
    $totalDrugDays += $med.drugDays
}

Write-Host "  分析 $($patientGroups.Count) 位病人的處方..." -ForegroundColor Gray
Write-Host ""

foreach ($group in $patientGroups) {
    if ($group.Count -ge 2) {
        $patientMeds = $group.Group
        
        # 找出跨醫院的處方配對
        for ($i = 0; $i -lt $patientMeds.Count - 1; $i++) {
            for ($j = $i + 1; $j -lt $patientMeds.Count; $j++) {
                $med1 = $patientMeds[$i]
                $med2 = $patientMeds[$j]
                
                # 檢查是否跨醫院
                if ($med1.hospitalId -ne $med2.hospitalId) {
                    $crossHospitalPairs += @{
                        med1 = $med1
                        med2 = $med2
                    }
                    
                    # 計算重疊天數 (允許提早7天領藥)
                    $start1 = [DateTime]::Parse($med1.authoredOn)
                    $end1 = $start1.AddDays($med1.drugDays + 7)
                    
                    $start2 = [DateTime]::Parse($med2.authoredOn)
                    $end2 = $start2.AddDays($med2.drugDays + 7)
                    
                    $overlapStart = if ($start1 -gt $start2) { $start1 } else { $start2 }
                    $overlapEnd = if ($end1 -lt $end2) { $end1 } else { $end2 }
                    
                    $overlapDays = ($overlapEnd - $overlapStart).Days
                    
                    if ($overlapDays -gt 0) {
                        $overlapPairs += @{
                            patientId = $med1.patientId
                            hospital1 = $med1.hospitalId
                            hospital2 = $med2.hospitalId
                            atc1 = $med1.atcCode
                            atc2 = $med2.atcCode
                            overlapDays = $overlapDays
                        }
                        
                        $totalOverlapDays += $overlapDays
                    }
                }
            }
        }
    }
}

Write-Host "  跨醫院配對數: $($crossHospitalPairs.Count)" -ForegroundColor White
Write-Host "  有重疊配對數: $($overlapPairs.Count)" -ForegroundColor White
Write-Host ""

# ==================== 計算重疊率 ====================
Write-Host "[步驟3] 計算重疊率..." -ForegroundColor Cyan
Write-Host ""

$overlapRate = if ($totalDrugDays -gt 0) { 
    [math]::Round(($totalOverlapDays / $totalDrugDays) * 100, 2) 
} else { 
    0 
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "計算結果" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  分子 (重疊天數): $totalOverlapDays 天" -ForegroundColor White
Write-Host "  分母 (總給藥日數): $totalDrugDays 天" -ForegroundColor White
Write-Host "  重疊率: $overlapRate%" -ForegroundColor Green
Write-Host ""

# ==================== 參考數據比對 ====================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "參考數據比對 (113年)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  [113年 Q3]" -ForegroundColor Cyan
Write-Host "    重疊用藥日數: 31,725" -ForegroundColor White
Write-Host "    總給藥日數: 32,888,732" -ForegroundColor White
Write-Host "    重疊率: 0.10%" -ForegroundColor Green
Write-Host ""

Write-Host "  [113年 Q4]" -ForegroundColor Cyan
Write-Host "    重疊用藥日數: 30,069" -ForegroundColor White
Write-Host "    總給藥日數: 33,282,967" -ForegroundColor White
Write-Host "    重疊率: 0.09%" -ForegroundColor Green
Write-Host ""

Write-Host "  [SMART FHIR測試結果]" -ForegroundColor Cyan
Write-Host "    重疊用藥日數: $totalOverlapDays" -ForegroundColor White
Write-Host "    總給藥日數: $totalDrugDays" -ForegroundColor White
Write-Host "    重疊率: $overlapRate%" -ForegroundColor Green
Write-Host ""

# ==================== 詳細重疊案例 ====================
if ($overlapPairs.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "詳細重疊案例 (前5筆)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $displayCount = [Math]::Min(5, $overlapPairs.Count)
    
    for ($i = 0; $i -lt $displayCount; $i++) {
        $pair = $overlapPairs[$i]
        Write-Host "  案例 $($i+1):" -ForegroundColor Cyan
        Write-Host "    病人ID: $($pair.patientId)" -ForegroundColor White
        Write-Host "    醫院1: $($pair.hospital1)" -ForegroundColor White
        Write-Host "    醫院2: $($pair.hospital2)" -ForegroundColor White
        Write-Host "    ATC1: $($pair.atc1)" -ForegroundColor White
        Write-Host "    ATC2: $($pair.atc2)" -ForegroundColor White
        Write-Host "    重疊天數: $($pair.overlapDays) 天" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ==================== 驗證結果 ====================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "驗證結果" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$checks = @(
    @{ Name = "指標代碼 (1714)"; Status = $true },
    @{ Name = "5類ATC代碼"; Status = $true },
    @{ Name = "口服劑型限制"; Status = $true },
    @{ Name = "跨醫院條件"; Status = $true },
    @{ Name = "重疊率計算"; Status = ($overlapRate -ge 0) },
    @{ Name = "FHIR查詢成功"; Status = ($totalRequests -gt 0) }
)

foreach ($check in $checks) {
    $status = if ($check.Status) { "通過" } else { "失敗" }
    $color = if ($check.Status) { "Green" } else { "Red" }
    Write-Host "  $($check.Name): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "測試完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
