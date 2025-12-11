# ============================================
# SMART on FHIR 資料撷取與分析腳本
# 模擬從2個FHIR伺服器撷取門診注射劑資料
# 時間範圍: 2024Q1 ~ 2025Q4 (至2025-11-06)
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR 門診注射劑使用率資料撷取" -ForegroundColor Cyan
Write-Host "查詢期間: 2024-01-01 ~ 2025-11-06" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# 建立結果目錄
$resultDir = ".\results"
if (-not (Test-Path $resultDir)) {
    New-Item -ItemType Directory -Path $resultDir | Out-Null
}

# ============================================
# 模擬FHIR Server 1: 健保署FHIR伺服器
# ============================================
Write-Host "[1/5] 連接 FHIR Server 1 (健保署)..." -ForegroundColor Yellow
Write-Host "Endpoint: https://fhir.nhi.gov.tw/fhir/" -ForegroundColor Gray

# 模擬資料 - MedicationRequest (藥品處方)
$fhirServer1Data = @(
    @{Quarter="2024Q1"; HospitalName="台大醫院"; InjectionCases=4521; Patients=3890; DrugTypes=45}
    @{Quarter="2024Q1"; HospitalName="榮總"; InjectionCases=3876; Patients=3245; DrugTypes=38}
    @{Quarter="2024Q2"; HospitalName="台大醫院"; InjectionCases=4698; Patients=4012; DrugTypes=47}
    @{Quarter="2024Q2"; HospitalName="榮總"; InjectionCases=4021; Patients=3456; DrugTypes=40}
    @{Quarter="2024Q3"; HospitalName="台大醫院"; InjectionCases=4834; Patients=4123; DrugTypes=48}
    @{Quarter="2024Q3"; HospitalName="榮總"; InjectionCases=4187; Patients=3589; DrugTypes=42}
    @{Quarter="2024Q4"; HospitalName="台大醫院"; InjectionCases=5012; Patients=4289; DrugTypes=50}
    @{Quarter="2024Q4"; HospitalName="榮總"; InjectionCases=4356; Patients=3712; DrugTypes=43}
    @{Quarter="2025Q1"; HospitalName="台大醫院"; InjectionCases=5234; Patients=4456; DrugTypes=52}
    @{Quarter="2025Q1"; HospitalName="榮總"; InjectionCases=4521; Patients=3845; DrugTypes=45}
    @{Quarter="2025Q2"; HospitalName="台大醫院"; InjectionCases=5412; Patients=4598; DrugTypes=53}
    @{Quarter="2025Q2"; HospitalName="榮總"; InjectionCases=4689; Patients=3978; DrugTypes=46}
    @{Quarter="2025Q3"; HospitalName="台大醫院"; InjectionCases=5598; Patients=4734; DrugTypes=55}
    @{Quarter="2025Q3"; HospitalName="榮總"; InjectionCases=4856; Patients=4112; DrugTypes=48}
    @{Quarter="2025Q4"; HospitalName="台大醫院"; InjectionCases=2134; Patients=1823; DrugTypes=42}
    @{Quarter="2025Q4"; HospitalName="榮總"; InjectionCases=1856; Patients=1567; DrugTypes=38}
)

Write-Host "✓ 成功撷取 $($fhirServer1Data.Count) 筆 MedicationRequest 資料`n" -ForegroundColor Green

# ============================================
# 模擬FHIR Server 2: 醫院總額FHIR伺服器
# ============================================
Write-Host "[2/5] 連接 FHIR Server 2 (醫院總額)..." -ForegroundColor Yellow
Write-Host "Endpoint: https://fhir.hospitals.tw/fhir/" -ForegroundColor Gray

# 模擬資料 - Encounter (就診紀錄)
$fhirServer2Data = @(
    @{Quarter="2024Q1"; HospitalName="台大醫院"; TotalCases=487234; AmbulatoryCases=456789}
    @{Quarter="2024Q1"; HospitalName="榮總"; TotalCases=423156; AmbulatoryCases=398765}
    @{Quarter="2024Q2"; HospitalName="台大醫院"; TotalCases=501234; AmbulatoryCases=469876}
    @{Quarter="2024Q2"; HospitalName="榮總"; TotalCases=435678; AmbulatoryCases=410234}
    @{Quarter="2024Q3"; HospitalName="台大醫院"; TotalCases=512345; AmbulatoryCases=478923}
    @{Quarter="2024Q3"; HospitalName="榮總"; TotalCases=445789; AmbulatoryCases=419876}
    @{Quarter="2024Q4"; HospitalName="台大醫院"; TotalCases=523456; AmbulatoryCases=489012}
    @{Quarter="2024Q4"; HospitalName="榮總"; TotalCases=456890; AmbulatoryCases=430123}
    @{Quarter="2025Q1"; HospitalName="台大醫院"; TotalCases=534567; AmbulatoryCases=499234}
    @{Quarter="2025Q1"; HospitalName="榮總"; TotalCases=467901; AmbulatoryCases=440456}
    @{Quarter="2025Q2"; HospitalName="台大醫院"; TotalCases=545678; AmbulatoryCases=509345}
    @{Quarter="2025Q2"; HospitalName="榮總"; TotalCases=478012; AmbulatoryCases=450789}
    @{Quarter="2025Q3"; HospitalName="台大醫院"; TotalCases=556789; AmbulatoryCases=519456}
    @{Quarter="2025Q3"; HospitalName="榮總"; TotalCases=489123; AmbulatoryCases=461012}
    @{Quarter="2025Q4"; HospitalName="台大醫院"; TotalCases=213456; AmbulatoryCases=199234}
    @{Quarter="2025Q4"; HospitalName="榮總"; TotalCases=187234; AmbulatoryCases=176543}
)

Write-Host "✓ 成功撷取 $($fhirServer2Data.Count) 筆 Encounter 資料`n" -ForegroundColor Green

# ============================================
# 整合並計算使用率
# ============================================
Write-Host "[3/5] 整合FHIR資料並計算使用率..." -ForegroundColor Yellow

$results = @()
foreach ($med in $fhirServer1Data) {
    $encounter = $fhirServer2Data | Where-Object { 
        $_.Quarter -eq $med.Quarter -and $_.HospitalName -eq $med.HospitalName 
    }
    
    if ($encounter) {
        $usageRate = [math]::Round(($med.InjectionCases / $encounter.TotalCases) * 100, 2)
        
        $results += [PSCustomObject]@{
            期間 = $med.Quarter
            醫院名稱 = $med.HospitalName
            注射劑案件數 = $med.InjectionCases
            門診總案件數 = $encounter.TotalCases
            使用率 = $usageRate
            病人數 = $med.Patients
            藥品種類數 = $med.DrugTypes
            資料來源 = "SMART_on_FHIR"
        }
    }
}

Write-Host "✓ 完成 $($results.Count) 筆資料整合`n" -ForegroundColor Green

# ============================================
# 顯示結果
# ============================================
Write-Host "[4/5] 顯示查詢結果" -ForegroundColor Yellow
Write-Host "============================================`n" -ForegroundColor Cyan

# 依季度匯總
Write-Host "【季度匯總統計】" -ForegroundColor White -BackgroundColor DarkBlue
$quarterSummary = $results | Group-Object 期間 | ForEach-Object {
    $quarter = $_.Name
    $data = $_.Group
    $totalInjections = ($data | Measure-Object -Property 注射劑案件數 -Sum).Sum
    $totalCases = ($data | Measure-Object -Property 門診總案件數 -Sum).Sum
    $avgRate = [math]::Round(($totalInjections / $totalCases) * 100, 2)
    
    [PSCustomObject]@{
        期間 = $quarter
        醫院數 = $data.Count
        總注射劑案件數 = $totalInjections
        總門診案件數 = $totalCases
        整體使用率 = "$avgRate%"
        基準值_111Q1 = "0.94%"
        較基準差異 = "$([math]::Round($avgRate - 0.94, 2))%"
    }
}

$quarterSummary | Format-Table -AutoSize
Write-Host ""

# 各醫院明細
Write-Host "【各醫院明細統計】" -ForegroundColor White -BackgroundColor DarkBlue
$results | Select-Object 期間, 醫院名稱, 注射劑案件數, 門診總案件數, @{
    Name="使用率"; Expression={"$($_.使用率)%"}
}, 病人數, 藥品種類數 | Format-Table -AutoSize

# ============================================
# 儲存結果到CSV
# ============================================
Write-Host "[5/5] 儲存結果..." -ForegroundColor Yellow

$csvPath1 = Join-Path $resultDir "FHIR_季度匯總_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$csvPath2 = Join-Path $resultDir "FHIR_醫院明細_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

$quarterSummary | Export-Csv -Path $csvPath1 -NoTypeInformation -Encoding UTF8
$results | Export-Csv -Path $csvPath2 -NoTypeInformation -Encoding UTF8

Write-Host "✓ 季度匯總已儲存: $csvPath1" -ForegroundColor Green
Write-Host "✓ 醫院明細已儲存: $csvPath2`n" -ForegroundColor Green

# ============================================
# 與基準值比較
# ============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "【與111Q1基準值(0.94%)比較】" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""

$comparison = $quarterSummary | ForEach-Object {
    $currentRate = [decimal]$_.整體使用率.Replace('%','')
    $diff = $currentRate - 0.94
    $status = if ($diff -le 0) { "✓ 低於基準(優)" } 
              elseif ($diff -le 0.5) { "→ 接近基準" }
              else { "⚠ 高於基準" }
    
    [PSCustomObject]@{
        期間 = $_.期間
        當期使用率 = $_.整體使用率
        基準值 = "0.94%"
        差異 = "$([math]::Round($diff, 2))%"
        評估 = $status
    }
}

$comparison | Format-Table -AutoSize

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "查詢完成！" -ForegroundColor Green
Write-Host "結果檔案位置: $resultDir" -ForegroundColor Gray
Write-Host "============================================`n" -ForegroundColor Cyan
