# ========================================
# 醫院品質指標數據查詢腳本
# 指標 01: 門診注射劑使用率 (3127)
# 指標 02: 門診抗生素使用率 (1140.01)
# 數據期間: 2024-01-01 至 2025-11-20
# ========================================

$fhirServer = "https://hapi.fhir.org/baseR4"
$outputFile = "Indicators_01_02_Data_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "醫院品質指標數據查詢" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 定義季度時間範圍
$quarters = @(
    @{ Quarter = "2024Q1"; StartDate = "2024-01-01"; EndDate = "2024-03-31" }
    @{ Quarter = "2024Q2"; StartDate = "2024-04-01"; EndDate = "2024-06-30" }
    @{ Quarter = "2024Q3"; StartDate = "2024-07-01"; EndDate = "2024-09-30" }
    @{ Quarter = "2024Q4"; StartDate = "2024-10-01"; EndDate = "2024-12-31" }
    @{ Quarter = "2025Q1"; StartDate = "2025-01-01"; EndDate = "2025-03-31" }
    @{ Quarter = "2025Q2"; StartDate = "2025-04-01"; EndDate = "2025-06-30" }
    @{ Quarter = "2025Q3"; StartDate = "2025-07-01"; EndDate = "2025-09-30" }
    @{ Quarter = "2025Q4"; StartDate = "2025-10-01"; EndDate = "2025-11-20" }
)

$allResults = @{
    GeneratedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    DataPeriod = "2024-01-01 to 2025-11-20"
    FHIRServer = $fhirServer
    Indicators = @()
}

# ========================================
# 指標 01: 門診注射劑使用率
# ========================================
Write-Host "`n[指標 01] 門診注射劑使用率 (3127)" -ForegroundColor Yellow
Write-Host "定義: 門診使用注射劑的案件比率" -ForegroundColor Gray

$indicator01Data = @{
    IndicatorCode = "3127"
    IndicatorName = "門診注射劑使用率"
    EnglishName = "Outpatient Injection Usage Rate"
    Description = "分子: 給藥案件之針劑藥品案件數 / 分母: 給藥案件數"
    Baseline = @{
        Period = "2022Q1"
        Numerator = 54653
        Denominator = 5831409
        Rate = 0.94
    }
    QuarterlyData = @()
}

foreach ($q in $quarters) {
    Write-Host "  查詢 $($q.Quarter)..." -ForegroundColor Cyan
    
    try {
        # 查詢該季度的 MedicationRequest
        $url = "$fhirServer/MedicationRequest?date=ge$($q.StartDate)`&date=le$($q.EndDate)`&_count=100"
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        $totalMedications = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
        
        # 分析注射劑 (模擬邏輯：檢查 route 或 form)
        $injectionCount = 0
        if ($response.entry) {
            foreach ($entry in $response.entry) {
                $resource = $entry.resource
                # 檢查給藥途徑是否為注射
                if ($resource.dosageInstruction) {
                    foreach ($dosage in $resource.dosageInstruction) {
                        if ($dosage.route.coding) {
                            foreach ($coding in $dosage.route.coding) {
                                if ($coding.code -match "inject|INJ|IM|IV|SC" -or 
                                    $coding.display -match "injection|Injectable") {
                                    $injectionCount++
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        
        $rate = if ($totalMedications -gt 0) { [Math]::Round(($injectionCount / $totalMedications) * 100, 2) } else { 0 }
        
        $quarterData = @{
            Quarter = $q.Quarter
            Period = "$($q.StartDate) to $($q.EndDate)"
            Numerator = $injectionCount
            Denominator = $totalMedications
            Rate = $rate
            Status = "Success"
        }
        
        Write-Host "    分子(注射劑): $injectionCount" -ForegroundColor Green
        Write-Host "    分母(總處方): $totalMedications" -ForegroundColor Green
        Write-Host "    使用率: $rate%" -ForegroundColor Green
        
    } catch {
        $quarterData = @{
            Quarter = $q.Quarter
            Period = "$($q.StartDate) to $($q.EndDate)"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        Write-Host "    查詢失敗: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $indicator01Data.QuarterlyData += $quarterData
    Start-Sleep -Milliseconds 500
}

# 計算總計與平均
$totalNumerator01 = ($indicator01Data.QuarterlyData | Where-Object { $_.Status -eq "Success" } | Measure-Object -Property Numerator -Sum).Sum
$totalDenominator01 = ($indicator01Data.QuarterlyData | Where-Object { $_.Status -eq "Success" } | Measure-Object -Property Denominator -Sum).Sum
$avgRate01 = if ($totalDenominator01 -gt 0) { [Math]::Round(($totalNumerator01 / $totalDenominator01) * 100, 2) } else { 0 }

$indicator01Data.Summary = @{
    TotalNumerator = $totalNumerator01
    TotalDenominator = $totalDenominator01
    AverageRate = $avgRate01
    BaselineComparison = [Math]::Round($avgRate01 - 0.94, 2)
}

Write-Host "`n  總計:" -ForegroundColor Yellow
Write-Host "    總注射劑案件: $totalNumerator01" -ForegroundColor Cyan
Write-Host "    總處方案件: $totalDenominator01" -ForegroundColor Cyan
Write-Host "    平均使用率: $avgRate01%" -ForegroundColor Cyan
Write-Host "    vs 基準值(0.94%): $(if($avgRate01 -gt 0.94){'↑'}else{'↓'}) $([Math]::Abs($avgRate01 - 0.94))%" -ForegroundColor $(if($avgRate01 -le 0.94){'Green'}else{'Yellow'})

$allResults.Indicators += $indicator01Data

# ========================================
# 指標 02: 門診抗生素使用率
# ========================================
Write-Host "`n`n[指標 02] 門診抗生素使用率 (1140.01)" -ForegroundColor Yellow
Write-Host "定義: 門診處方抗生素的案件比率" -ForegroundColor Gray

$indicator02Data = @{
    IndicatorCode = "1140.01"
    IndicatorName = "門診抗生素使用率"
    EnglishName = "Outpatient Antibiotic Usage Rate"
    Description = "分子: 門診處方抗生素案件數 / 分母: 門診案件總數"
    ATCCodes = @("J01") # 抗生素 ATC 代碼
    QuarterlyData = @()
}

foreach ($q in $quarters) {
    Write-Host "  查詢 $($q.Quarter)..." -ForegroundColor Cyan
    
    try {
        # 查詢該季度的所有門診 Encounter
        $encounterUrl = "$fhirServer/Encounter?date=ge$($q.StartDate)`&date=le$($q.EndDate)`&class=AMB`&_count=100"
        $encounterResponse = Invoke-RestMethod -Uri $encounterUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        $totalEncounters = if ($encounterResponse.total) { $encounterResponse.total } elseif ($encounterResponse.entry) { $encounterResponse.entry.Count } else { 0 }
        
        # 查詢抗生素處方
        $medUrl = "$fhirServer/MedicationRequest?date=ge$($q.StartDate)`&date=le$($q.EndDate)`&_count=100"
        $medResponse = Invoke-RestMethod -Uri $medUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        # 分析抗生素處方 (ATC code J01)
        $antibioticCount = 0
        if ($medResponse.entry) {
            foreach ($entry in $medResponse.entry) {
                $resource = $entry.resource
                if ($resource.medicationCodeableConcept.coding) {
                    foreach ($coding in $resource.medicationCodeableConcept.coding) {
                        if ($coding.system -like "*atc*" -and $coding.code -like "J01*") {
                            $antibioticCount++
                            break
                        }
                        # 也檢查 display 中是否包含抗生素相關詞彙
                        if ($coding.display -match "antibiotic|penicillin|cephalosporin|quinolone|macrolide") {
                            $antibioticCount++
                            break
                        }
                    }
                }
            }
        }
        
        $rate = if ($totalEncounters -gt 0) { [Math]::Round(($antibioticCount / $totalEncounters) * 100, 2) } else { 0 }
        
        $quarterData = @{
            Quarter = $q.Quarter
            Period = "$($q.StartDate) to $($q.EndDate)"
            Numerator = $antibioticCount
            Denominator = $totalEncounters
            Rate = $rate
            Status = "Success"
        }
        
        Write-Host "    分子(抗生素處方): $antibioticCount" -ForegroundColor Green
        Write-Host "    分母(門診案件): $totalEncounters" -ForegroundColor Green
        Write-Host "    使用率: $rate%" -ForegroundColor Green
        
    } catch {
        $quarterData = @{
            Quarter = $q.Quarter
            Period = "$($q.StartDate) to $($q.EndDate)"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        Write-Host "    查詢失敗: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $indicator02Data.QuarterlyData += $quarterData
    Start-Sleep -Milliseconds 500
}

# 計算總計與平均
$totalNumerator02 = ($indicator02Data.QuarterlyData | Where-Object { $_.Status -eq "Success" } | Measure-Object -Property Numerator -Sum).Sum
$totalDenominator02 = ($indicator02Data.QuarterlyData | Where-Object { $_.Status -eq "Success" } | Measure-Object -Property Denominator -Sum).Sum
$avgRate02 = if ($totalDenominator02 -gt 0) { [Math]::Round(($totalNumerator02 / $totalDenominator02) * 100, 2) } else { 0 }

$indicator02Data.Summary = @{
    TotalNumerator = $totalNumerator02
    TotalDenominator = $totalDenominator02
    AverageRate = $avgRate02
}

Write-Host "`n  總計:" -ForegroundColor Yellow
Write-Host "    總抗生素處方: $totalNumerator02" -ForegroundColor Cyan
Write-Host "    總門診案件: $totalDenominator02" -ForegroundColor Cyan
Write-Host "    平均使用率: $avgRate02%" -ForegroundColor Cyan

$allResults.Indicators += $indicator02Data

# ========================================
# 生成詳細報告
# ========================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "生成詳細報告" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 儲存 JSON 格式
$allResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8

# 生成 Markdown 報告
$mdFile = "Indicators_01_02_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
$mdContent = @"
# 醫院品質指標數據報告

**生成時間**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**數據期間**: 2024-01-01 至 2025-11-20  
**FHIR 服務器**: $fhirServer

---

## 指標 01: 門診注射劑使用率 (3127)

### 指標定義
- **分子**: 給藥案件之針劑藥品（醫令代碼10碼且第8碼為'2'）案件數
- **分母**: 給藥案件數
- **基準值**: 0.94% (2022Q1: 54,653 / 5,831,409)

### 季度數據

| 季度 | 期間 | 注射劑案件數 | 總處方案件數 | 使用率 | 狀態 |
|------|------|--------------|--------------|--------|------|
"@

foreach ($qData in $indicator01Data.QuarterlyData) {
    if ($qData.Status -eq "Success") {
        $mdContent += "| $($qData.Quarter) | $($qData.Period) | $($qData.Numerator) | $($qData.Denominator) | $($qData.Rate)% | ✅ |`n"
    } else {
        $mdContent += "| $($qData.Quarter) | $($qData.Period) | - | - | - | ❌ |`n"
    }
}

$mdContent += @"

### 總計統計

- **總注射劑案件數**: $($indicator01Data.Summary.TotalNumerator)
- **總處方案件數**: $($indicator01Data.Summary.TotalDenominator)
- **平均使用率**: $($indicator01Data.Summary.AverageRate)%
- **與基準值比較**: $($indicator01Data.Summary.BaselineComparison)%
- **評估**: $(if($indicator01Data.Summary.AverageRate -le 0.94){'✅ 低於基準值（優良）'}elseif($indicator01Data.Summary.AverageRate -le 1.5){'⚠️ 接近基準值'}else{'❌ 高於基準值（需注意）'})

### 趨勢圖表

``````
2024Q1: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[0].Rate * 10), 50)) $($indicator01Data.QuarterlyData[0].Rate)%
2024Q2: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[1].Rate * 10), 50)) $($indicator01Data.QuarterlyData[1].Rate)%
2024Q3: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[2].Rate * 10), 50)) $($indicator01Data.QuarterlyData[2].Rate)%
2024Q4: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[3].Rate * 10), 50)) $($indicator01Data.QuarterlyData[3].Rate)%
2025Q1: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[4].Rate * 10), 50)) $($indicator01Data.QuarterlyData[4].Rate)%
2025Q2: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[5].Rate * 10), 50)) $($indicator01Data.QuarterlyData[5].Rate)%
2025Q3: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[6].Rate * 10), 50)) $($indicator01Data.QuarterlyData[6].Rate)%
2025Q4: $('█' * [Math]::Min([int]($indicator01Data.QuarterlyData[7].Rate * 10), 50)) $($indicator01Data.QuarterlyData[7].Rate)%
``````

---

## 指標 02: 門診抗生素使用率 (1140.01)

### 指標定義
- **分子**: 門診處方抗生素（ATC代碼J01）案件數
- **分母**: 門診案件總數
- **ATC代碼**: J01 (全身性抗菌藥物)

### 季度數據

| 季度 | 期間 | 抗生素處方數 | 門診案件數 | 使用率 | 狀態 |
|------|------|--------------|------------|--------|------|
"@

foreach ($qData in $indicator02Data.QuarterlyData) {
    if ($qData.Status -eq "Success") {
        $mdContent += "| $($qData.Quarter) | $($qData.Period) | $($qData.Numerator) | $($qData.Denominator) | $($qData.Rate)% | ✅ |`n"
    } else {
        $mdContent += "| $($qData.Quarter) | $($qData.Period) | - | - | - | ❌ |`n"
    }
}

$mdContent += @"

### 總計統計

- **總抗生素處方數**: $($indicator02Data.Summary.TotalNumerator)
- **總門診案件數**: $($indicator02Data.Summary.TotalDenominator)
- **平均使用率**: $($indicator02Data.Summary.AverageRate)%

### 趨勢圖表

``````
2024Q1: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[0].Rate * 2), 50)) $($indicator02Data.QuarterlyData[0].Rate)%
2024Q2: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[1].Rate * 2), 50)) $($indicator02Data.QuarterlyData[1].Rate)%
2024Q3: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[2].Rate * 2), 50)) $($indicator02Data.QuarterlyData[2].Rate)%
2024Q4: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[3].Rate * 2), 50)) $($indicator02Data.QuarterlyData[3].Rate)%
2025Q1: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[4].Rate * 2), 50)) $($indicator02Data.QuarterlyData[4].Rate)%
2025Q2: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[5].Rate * 2), 50)) $($indicator02Data.QuarterlyData[5].Rate)%
2025Q3: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[6].Rate * 2), 50)) $($indicator02Data.QuarterlyData[6].Rate)%
2025Q4: $('█' * [Math]::Min([int]($indicator02Data.QuarterlyData[7].Rate * 2), 50)) $($indicator02Data.QuarterlyData[7].Rate)%
``````

---

## 數據來源說明

### FHIR 資源對照

**指標 01 (注射劑)**:
- **MedicationRequest**: 藥品處方記錄
- **篩選條件**: dosageInstruction.route 包含注射相關代碼
- **SNOMED CT**: 385219001 (Injection)

**指標 02 (抗生素)**:
- **MedicationRequest**: 藥品處方記錄
- **Encounter**: 門診就醫記錄
- **篩選條件**: medication.code ATC = J01*
- **ATC**: J01 (全身性抗菌藥物)

### 數據品質說明

- 本報告使用公開 FHIR 測試服務器數據
- 實際臨床數據可能與測試數據有差異
- 建議連接實際醫院 FHIR 服務器獲取真實數據

---

## 結論與建議

### 指標 01 建議
$(if($indicator01Data.Summary.AverageRate -le 0.94){
"- ✅ 注射劑使用率控制良好，低於基準值
- 建議: 持續維持現有管理機制"
}elseif($indicator01Data.Summary.AverageRate -le 1.5){
"- ⚠️ 注射劑使用率接近基準值
- 建議: 加強監測，檢討注射劑使用必要性"
}else{
"- ❌ 注射劑使用率偏高
- 建議: 
  1. 審查注射劑處方合理性
  2. 推廣口服藥物替代方案
  3. 加強醫師用藥教育"
})

### 指標 02 建議
- 監測抗生素使用趨勢
- 推動抗生素管理計畫 (Antibiotic Stewardship)
- 加強感染控制措施

---

**報告結束**  
**生成時間**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$mdContent | Out-File -FilePath $mdFile -Encoding UTF8

Write-Host "✅ JSON 數據已儲存至: $outputFile" -ForegroundColor Green
Write-Host "✅ Markdown 報告已儲存至: $mdFile" -ForegroundColor Green

# 顯示摘要
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "數據摘要" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[指標 01] 門診注射劑使用率" -ForegroundColor Yellow
Write-Host "  平均使用率: $($indicator01Data.Summary.AverageRate)%" -ForegroundColor White
Write-Host "  基準值比較: $(if($indicator01Data.Summary.BaselineComparison -gt 0){'+'}else{''})$($indicator01Data.Summary.BaselineComparison)%" -ForegroundColor $(if($indicator01Data.Summary.BaselineComparison -le 0){'Green'}else{'Yellow'})

Write-Host "`n[指標 02] 門診抗生素使用率" -ForegroundColor Yellow
Write-Host "  平均使用率: $($indicator02Data.Summary.AverageRate)%" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "完成！" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
