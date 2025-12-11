# SMART on FHIR 測試腳本
# 測試 10 個 CQL 文件的 FHIR 資源查詢
# 測試日期: 2025-11-20

# 使用公開的 FHIR 測試服務器
$fhirServer = "https://hapi.fhir.org/baseR4"

# 測試結果輸出文件
$outputFile = "smart_fhir_test_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR 測試開始" -ForegroundColor Cyan
Write-Host "測試服務器: $fhirServer" -ForegroundColor Cyan
Write-Host "測試時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 初始化結果
$results = @()

# 測試 1: Indicator_03_2 - 降血脂藥物 (Lipid Lowering)
Write-Host "`n[1/10] 測試 Indicator_03_2 - 同醫院門診同藥理用藥日數重疊率-降血脂" -ForegroundColor Yellow
$test1 = @{
    Indicator = "03_2_Same_Hospital_Lipid_Lowering_Overlap_1711"
    Description = "降血脂藥物 (ATC: C10)"
    Queries = @()
}

# 查詢 1.1: MedicationRequest - 降血脂藥物處方
Write-Host "  查詢 1.1: MedicationRequest (降血脂藥物處方)..." -ForegroundColor Gray
$url1 = "$fhirServer/MedicationRequest?code=C10`&status=completed`&_count=50`&_sort=-_lastUpdated"
try {
    $response1 = Invoke-RestMethod -Uri $url1 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count1 = if ($response1.total) { $response1.total } else { $response1.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count1 筆 MedicationRequest" -ForegroundColor Green
    $test1.Queries += @{
        Type = "MedicationRequest"
        URL = $url1
        Status = "Success"
        Count = $count1
        Sample = if ($response1.entry) { $response1.entry[0].resource | ConvertTo-Json -Depth 3 -Compress } else { "No Data" }
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test1.Queries += @{
        Type = "MedicationRequest"
        URL = $url1
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

# 查詢 1.2: Medication - 降血脂藥品資訊
Write-Host "  查詢 1.2: Medication (降血脂藥品資訊)..." -ForegroundColor Gray
$url2 = "$fhirServer/Medication?code=C10&_count=50"
try {
    $response2 = Invoke-RestMethod -Uri $url2 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count2 = if ($response2.total) { $response2.total } else { $response2.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count2 筆 Medication" -ForegroundColor Green
    $test1.Queries += @{
        Type = "Medication"
        URL = $url2
        Status = "Success"
        Count = $count2
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test1.Queries += @{
        Type = "Medication"
        URL = $url2
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

# 查詢 1.3: Encounter - 門診就診記錄
Write-Host "  查詢 1.3: Encounter (門診就診記錄)..." -ForegroundColor Gray
$url3 = "$fhirServer/Encounter?class=AMB`&status=finished`&_count=50`&_sort=-_lastUpdated"
try {
    $response3 = Invoke-RestMethod -Uri $url3 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count3 = if ($response3.total) { $response3.total } else { $response3.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count3 筆 Encounter" -ForegroundColor Green
    $test1.Queries += @{
        Type = "Encounter"
        URL = $url3
        Status = "Success"
        Count = $count3
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test1.Queries += @{
        Type = "Encounter"
        URL = $url3
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test1

# 測試 2: Indicator_03_3 - 降血糖藥物 (Antidiabetic)
Write-Host "`n[2/10] 測試 Indicator_03_3 - 同醫院門診同藥理用藥日數重疊率-降血糖" -ForegroundColor Yellow
$test2 = @{
    Indicator = "03_3_Same_Hospital_Antidiabetic_Overlap_1712"
    Description = "降血糖藥物 (ATC: A10)"
    Queries = @()
}

Write-Host "  查詢 2.1: MedicationRequest (降血糖藥物處方)..." -ForegroundColor Gray
$url4 = "$fhirServer/MedicationRequest?code=A10`&status=completed`&_count=50`&_sort=-_lastUpdated"
try {
    $response4 = Invoke-RestMethod -Uri $url4 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count4 = if ($response4.total) { $response4.total } else { $response4.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count4 筆 MedicationRequest" -ForegroundColor Green
    $test2.Queries += @{
        Type = "MedicationRequest"
        URL = $url4
        Status = "Success"
        Count = $count4
        Sample = if ($response4.entry) { $response4.entry[0].resource | ConvertTo-Json -Depth 3 -Compress } else { "No Data" }
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test2.Queries += @{
        Type = "MedicationRequest"
        URL = $url4
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

Write-Host "  查詢 2.2: Patient (病人資訊)..." -ForegroundColor Gray
$url5 = "$fhirServer/Patient?_count=50`&_sort=-_lastUpdated"
try {
    $response5 = Invoke-RestMethod -Uri $url5 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count5 = if ($response5.total) { $response5.total } else { $response5.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count5 筆 Patient" -ForegroundColor Green
    $test2.Queries += @{
        Type = "Patient"
        URL = $url5
        Status = "Success"
        Count = $count5
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test2.Queries += @{
        Type = "Patient"
        URL = $url5
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test2

# 測試 3: Indicator_03_4 - 抗思覺失調症藥物 (Antipsychotic)
Write-Host "`n[3/10] 測試 Indicator_03_4 - 同醫院門診同藥理用藥日數重疊率-抗思覺失調症" -ForegroundColor Yellow
$test3 = @{
    Indicator = "03_4_Same_Hospital_Antipsychotic_Overlap_1726"
    Description = "抗思覺失調症藥物 (ATC: N05A)"
    Queries = @()
}

Write-Host "  查詢 3.1: MedicationRequest (抗思覺失調症藥物處方)..." -ForegroundColor Gray
$url6 = "$fhirServer/MedicationRequest?code=N05A`&status=completed`&_count=50`&_sort=-_lastUpdated"
try {
    $response6 = Invoke-RestMethod -Uri $url6 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count6 = if ($response6.total) { $response6.total } else { $response6.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count6 筆 MedicationRequest" -ForegroundColor Green
    $test3.Queries += @{
        Type = "MedicationRequest"
        URL = $url6
        Status = "Success"
        Count = $count6
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test3.Queries += @{
        Type = "MedicationRequest"
        URL = $url6
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

Write-Host "  查詢 3.2: Organization (醫療機構)..." -ForegroundColor Gray
$url7 = "$fhirServer/Organization?type=prov`&_count=50"
try {
    $response7 = Invoke-RestMethod -Uri $url7 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count7 = if ($response7.total) { $response7.total } else { $response7.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count7 筆 Organization" -ForegroundColor Green
    $test3.Queries += @{
        Type = "Organization"
        URL = $url7
        Status = "Success"
        Count = $count7
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test3.Queries += @{
        Type = "Organization"
        URL = $url7
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test3

# 測試 4: Indicator_03_5 - 抗憂鬱症藥物 (Antidepressant)
Write-Host "`n[4/10] 測試 Indicator_03_5 - 同醫院門診同藥理用藥日數重疊率-抗憂鬱症" -ForegroundColor Yellow
$test4 = @{
    Indicator = "03_5_Same_Hospital_Antidepressant_Overlap_1727"
    Description = "抗憂鬱症藥物 (ATC: N06A)"
    Queries = @()
}

Write-Host "  查詢 4.1: MedicationRequest (抗憂鬱症藥物處方)..." -ForegroundColor Gray
$url8 = "$fhirServer/MedicationRequest?code=N06A`&status=completed`&_count=50`&_sort=-_lastUpdated"
try {
    $response8 = Invoke-RestMethod -Uri $url8 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count8 = if ($response8.total) { $response8.total } else { $response8.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count8 筆 MedicationRequest" -ForegroundColor Green
    $test4.Queries += @{
        Type = "MedicationRequest"
        URL = $url8
        Status = "Success"
        Count = $count8
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test4.Queries += @{
        Type = "MedicationRequest"
        URL = $url8
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test4

# 測試 5: Indicator_03_6 - 安眠鎮靜藥物 (Sedative)
Write-Host "`n[5/10] 測試 Indicator_03_6 - 同醫院門診同藥理用藥日數重疊率-安眠鎮靜" -ForegroundColor Yellow
$test5 = @{
    Indicator = "03_6_Same_Hospital_Sedative_Overlap_1728"
    Description = "安眠鎮靜藥物 (口服)"
    Queries = @()
}

Write-Host "  查詢 5.1: MedicationRequest (安眠鎮靜藥物處方)..." -ForegroundColor Gray
$url9 = "$fhirServer/MedicationRequest?code=N05C`&status=completed`&_count=50`&_sort=-_lastUpdated"
try {
    $response9 = Invoke-RestMethod -Uri $url9 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count9 = if ($response9.total) { $response9.total } else { $response9.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count9 筆 MedicationRequest" -ForegroundColor Green
    $test5.Queries += @{
        Type = "MedicationRequest"
        URL = $url9
        Status = "Success"
        Count = $count9
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test5.Queries += @{
        Type = "MedicationRequest"
        URL = $url9
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

# 查詢最近的處方，不限藥物類型
Write-Host "  查詢 5.2: MedicationRequest (最近處方 - 不限類型)..." -ForegroundColor Gray
$url10 = "$fhirServer/MedicationRequest?status=completed`&_count=100`&_sort=-_lastUpdated"
try {
    $response10 = Invoke-RestMethod -Uri $url10 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count10 = if ($response10.total) { $response10.total } else { $response10.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count10 筆 MedicationRequest (最近處方)" -ForegroundColor Green
    $test5.Queries += @{
        Type = "MedicationRequest (All)"
        URL = $url10
        Status = "Success"
        Count = $count10
        Sample = if ($response10.entry) { 
            $sample = $response10.entry[0..2] | ForEach-Object { 
                @{
                    ID = $_.resource.id
                    Status = $_.resource.status
                    Intent = $_.resource.intent
                    MedicationReference = $_.resource.medicationReference.reference
                    Subject = $_.resource.subject.reference
                    AuthoredOn = $_.resource.authoredOn
                }
            }
            $sample | ConvertTo-Json -Depth 2
        } else { "No Data" }
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test5.Queries += @{
        Type = "MedicationRequest (All)"
        URL = $url10
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test5

# 測試 6: Indicator_03_7 - 抗血栓藥物 (Antithrombotic)
Write-Host "`n[6/10] 測試 Indicator_03_7 - 同醫院門診同藥理用藥日數重疊率-抗血栓" -ForegroundColor Yellow
$test6 = @{
    Indicator = "03_7_Same_Hospital_Antithrombotic_Overlap_3375"
    Description = "抗血栓藥物 (ATC: B01)"
    Queries = @()
}

Write-Host "  查詢 6.1: MedicationRequest (抗血栓藥物處方)..." -ForegroundColor Gray
$url11 = "$fhirServer/MedicationRequest?code=B01`&status=completed`&_count=50`&_sort=-_lastUpdated"
try {
    $response11 = Invoke-RestMethod -Uri $url11 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count11 = if ($response11.total) { $response11.total } else { $response11.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count11 筆 MedicationRequest" -ForegroundColor Green
    $test6.Queries += @{
        Type = "MedicationRequest"
        URL = $url11
        Status = "Success"
        Count = $count11
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test6.Queries += @{
        Type = "MedicationRequest"
        URL = $url11
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test6

# 測試 7-10: 綜合查詢測試
Write-Host "`n[7/10] 測試綜合查詢 - Medication 資源" -ForegroundColor Yellow
$test7 = @{
    Indicator = "Comprehensive_Medication_Test"
    Description = "Medication 資源綜合測試"
    Queries = @()
}

Write-Host "  查詢 7.1: 所有 Medication 資源..." -ForegroundColor Gray
$url12 = "$fhirServer/Medication?_count=100`&_sort=-_lastUpdated"
try {
    $response12 = Invoke-RestMethod -Uri $url12 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count12 = if ($response12.total) { $response12.total } else { $response12.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count12 筆 Medication" -ForegroundColor Green
    
    # 分析 Medication 資源
    if ($response12.entry) {
        $medications = $response12.entry | ForEach-Object {
            $med = $_.resource
            @{
                ID = $med.id
                Code = if ($med.code.coding) { $med.code.coding[0].code } else { "N/A" }
                System = if ($med.code.coding) { $med.code.coding[0].system } else { "N/A" }
                Display = if ($med.code.coding) { $med.code.coding[0].display } else { $med.code.text }
            }
        }
        
        $test7.Queries += @{
            Type = "Medication"
            URL = $url12
            Status = "Success"
            Count = $count12
            Sample = $medications[0..4] | ConvertTo-Json -Depth 2
        }
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test7.Queries += @{
        Type = "Medication"
        URL = $url12
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test7

Write-Host "`n[8/10] 測試綜合查詢 - Patient 資源" -ForegroundColor Yellow
$test8 = @{
    Indicator = "Comprehensive_Patient_Test"
    Description = "Patient 資源綜合測試"
    Queries = @()
}

Write-Host "  查詢 8.1: 所有 Patient 資源..." -ForegroundColor Gray
$url13 = "$fhirServer/Patient?_count=100`&_sort=-_lastUpdated"
try {
    $response13 = Invoke-RestMethod -Uri $url13 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count13 = if ($response13.total) { $response13.total } else { $response13.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count13 筆 Patient" -ForegroundColor Green
    
    if ($response13.entry) {
        $patients = $response13.entry | ForEach-Object {
            $pat = $_.resource
            @{
                ID = $pat.id
                Gender = $pat.gender
                BirthDate = $pat.birthDate
                Active = $pat.active
            }
        }
        
        $test8.Queries += @{
            Type = "Patient"
            URL = $url13
            Status = "Success"
            Count = $count13
            Sample = $patients[0..4] | ConvertTo-Json -Depth 2
        }
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test8.Queries += @{
        Type = "Patient"
        URL = $url13
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test8

Write-Host "`n[9/10] 測試綜合查詢 - Encounter 資源" -ForegroundColor Yellow
$test9 = @{
    Indicator = "Comprehensive_Encounter_Test"
    Description = "Encounter 資源綜合測試"
    Queries = @()
}

Write-Host "  查詢 9.1: 所有 Encounter 資源..." -ForegroundColor Gray
$url14 = "$fhirServer/Encounter?_count=100`&_sort=-_lastUpdated"
try {
    $response14 = Invoke-RestMethod -Uri $url14 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count14 = if ($response14.total) { $response14.total } else { $response14.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count14 筆 Encounter" -ForegroundColor Green
    
    if ($response14.entry) {
        $encounters = $response14.entry | ForEach-Object {
            $enc = $_.resource
            @{
                ID = $enc.id
                Status = $enc.status
                Class = if ($enc.class.code) { $enc.class.code } else { $enc.class.display }
                Period = $enc.period
                Subject = $enc.subject.reference
            }
        }
        
        $test9.Queries += @{
            Type = "Encounter"
            URL = $url14
            Status = "Success"
            Count = $count14
            Sample = $encounters[0..4] | ConvertTo-Json -Depth 2
        }
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test9.Queries += @{
        Type = "Encounter"
        URL = $url14
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test9

Write-Host "`n[10/10] 測試綜合查詢 - Organization 資源" -ForegroundColor Yellow
$test10 = @{
    Indicator = "Comprehensive_Organization_Test"
    Description = "Organization 資源綜合測試"
    Queries = @()
}

Write-Host "  查詢 10.1: 所有 Organization 資源..." -ForegroundColor Gray
$url15 = "$fhirServer/Organization?_count=100`&_sort=-_lastUpdated"
try {
    $response15 = Invoke-RestMethod -Uri $url15 -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count15 = if ($response15.total) { $response15.total } else { $response15.entry.Count }
    Write-Host "    ✓ 成功: 找到 $count15 筆 Organization" -ForegroundColor Green
    
    if ($response15.entry) {
        $orgs = $response15.entry | ForEach-Object {
            $org = $_.resource
            @{
                ID = $org.id
                Name = $org.name
                Active = $org.active
                Type = if ($org.type) { $org.type[0].coding[0].display } else { "N/A" }
            }
        }
        
        $test10.Queries += @{
            Type = "Organization"
            URL = $url15
            Status = "Success"
            Count = $count15
            Sample = $orgs[0..4] | ConvertTo-Json -Depth 2
        }
    }
} catch {
    Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    $test10.Queries += @{
        Type = "Organization"
        URL = $url15
        Status = "Failed"
        Error = $_.Exception.Message
    }
}

$results += $test10

# 生成詳細測試報告
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "測試完成 - 生成詳細報告" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$report = @"
========================================
SMART on FHIR 測試報告
========================================
測試時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
測試服務器: $fhirServer
測試文件數: 10 個 CQL 指標

========================================
測試結果摘要
========================================

"@

$totalQueries = 0
$successQueries = 0
$failedQueries = 0
$totalRecords = 0

foreach ($result in $results) {
    $report += "`n[$($result.Indicator)]`n"
    $report += "描述: $($result.Description)`n"
    $report += "----------------------------------------`n"
    
    foreach ($query in $result.Queries) {
        $totalQueries++
        if ($query.Status -eq "Success") {
            $successQueries++
            $totalRecords += $query.Count
            $report += "✓ $($query.Type): 成功 (找到 $($query.Count) 筆)`n"
            $report += "  URL: $($query.URL)`n"
            if ($query.Sample -and $query.Sample -ne "無資料") {
                $report += "  範例資料:`n$($query.Sample | Out-String)`n"
            }
        } else {
            $failedQueries++
            $report += "✗ $($query.Type): 失敗`n"
            $report += "  URL: $($query.URL)`n"
            $report += "  錯誤: $($query.Error)`n"
        }
    }
    $report += "`n"
}

$report += @"
========================================
統計摘要
========================================
總查詢數: $totalQueries
成功查詢: $successQueries
失敗查詢: $failedQueries
成功率: $([math]::Round($successQueries/$totalQueries*100, 2))%
總記錄數: $totalRecords

========================================
測試結論
========================================

"@

if ($successQueries -eq $totalQueries) {
    $report += "✓ 所有測試通過！FHIR 服務器連接正常，資源查詢成功。`n"
} elseif ($successQueries -gt 0) {
    $report += "⚠ 部分測試通過。成功: $successQueries/$totalQueries`n"
} else {
    $report += "✗ 所有測試失敗。請檢查 FHIR 服務器連接。`n"
}

$report += @"

========================================
FHIR 資源對照表
========================================
MedicationRequest → 藥品處方記錄
Medication → 藥品資訊主檔
Patient → 病人基本資料
Encounter → 就醫記錄
Organization → 醫療機構資料

========================================
ATC 藥物分類對照
========================================
C10  - 降血脂藥物 (Lipid Lowering)
A10  - 降血糖藥物 (Antidiabetic)
N05A - 抗思覺失調症藥物 (Antipsychotic)
N06A - 抗憂鬱症藥物 (Antidepressant)
N05C - 安眠鎮靜藥物 (Sedative/Hypnotic)
B01  - 抗血栓藥物 (Antithrombotic)

========================================
測試完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================
"@

# 輸出到文件
$report | Out-File -FilePath $outputFile -Encoding UTF8

# 顯示報告
Write-Host $report

Write-Host "`n測試報告已保存到: $outputFile" -ForegroundColor Green
Write-Host "`n按任意鍵結束..." -ForegroundColor Cyan
