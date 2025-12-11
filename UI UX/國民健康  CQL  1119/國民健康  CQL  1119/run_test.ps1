# CQL Test System - Simple Version
# ================================================================================
# 國民健康 CQL 測量指標系統
# ================================================================================

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "               國民健康 CQL 測量指標系統 - 測試程式" -ForegroundColor Yellow
Write-Host "`n================================================================================`n" -ForegroundColor Cyan

# Step 1: Load Configuration
Write-Host "[1/5] 載入配置檔案..." -ForegroundColor Green
$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json
Write-Host "      成功!" -ForegroundColor Green
Write-Host "      - FHIR 伺服器數量: $($config.fhir_servers.Count)" -ForegroundColor White
Write-Host "      - 資料時間範圍: $($config.filters.time_period_years) 年" -ForegroundColor White

# Step 2: Connect to FHIR Servers
Write-Host "`n[2/5] 連接 SMART FHIR 伺服器..." -ForegroundColor Green

$allPatients = @()
$allImmunizations = @()
$allConditions = @()
$allObservations = @()

foreach ($server in $config.fhir_servers) {
    Write-Host "`n      連接: $($server.name)" -ForegroundColor Yellow
    Write-Host "      URL: $($server.base_url)" -ForegroundColor White
    
    try {
        $metadataUrl = $($server.base_url) + "/metadata"
        $response = Invoke-RestMethod -Uri $metadataUrl -Method Get -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 10
        Write-Host "      [成功] 伺服器版本: $($response.fhirVersion)" -ForegroundColor Green
        
        # Get Patients
        try {
            $patientUrl = $($server.base_url) + "/Patient?_count=50"
            $patientBundle = Invoke-RestMethod -Uri $patientUrl -Method Get -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 30
            if ($patientBundle.entry) {
                $count = $patientBundle.entry.Count
                Write-Host "      [成功] Patient: $count 筆" -ForegroundColor Green
                $allPatients += $patientBundle.entry
            }
        } catch { Write-Host "      [警告] Patient 無法存取" -ForegroundColor Yellow }
        
        # Get Immunizations
        try {
            $immUrl = $($server.base_url) + "/Immunization?_count=50"
            $immBundle = Invoke-RestMethod -Uri $immUrl -Method Get -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 30
            if ($immBundle.entry) {
                $count = $immBundle.entry.Count
                Write-Host "      [成功] Immunization: $count 筆" -ForegroundColor Green
                $allImmunizations += $immBundle.entry
            }
        } catch { Write-Host "      [警告] Immunization 無法存取" -ForegroundColor Yellow }
        
        # Get Conditions
        try {
            $condUrl = $($server.base_url) + "/Condition?_count=50"
            $condBundle = Invoke-RestMethod -Uri $condUrl -Method Get -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 30
            if ($condBundle.entry) {
                $count = $condBundle.entry.Count
                Write-Host "      [成功] Condition: $count 筆" -ForegroundColor Green
                $allConditions += $condBundle.entry
            }
        } catch { Write-Host "      [警告] Condition 無法存取" -ForegroundColor Yellow }
        
        # Get Observations
        try {
            $obsUrl = $($server.base_url) + "/Observation?_count=50"
            $obsBundle = Invoke-RestMethod -Uri $obsUrl -Method Get -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 30
            if ($obsBundle.entry) {
                $count = $obsBundle.entry.Count
                Write-Host "      [成功] Observation: $count 筆" -ForegroundColor Green
                $allObservations += $obsBundle.entry
            }
        } catch { Write-Host "      [警告] Observation 無法存取" -ForegroundColor Yellow }
        
    } catch {
        Write-Host "      [錯誤] 伺服器連接失敗" -ForegroundColor Red
    }
}

# Step 3: Statistics
Write-Host "`n[3/5] 資料擷取統計..." -ForegroundColor Green
Write-Host "================================================================================`n" -ForegroundColor Cyan
Write-Host "  Patient:       $($allPatients.Count) 筆" -ForegroundColor White
Write-Host "  Immunization:  $($allImmunizations.Count) 筆" -ForegroundColor White
Write-Host "  Condition:     $($allConditions.Count) 筆" -ForegroundColor White
Write-Host "  Observation:   $($allObservations.Count) 筆" -ForegroundColor White
Write-Host "`n================================================================================`n" -ForegroundColor Cyan

# Step 4: Analysis
Write-Host "[4/5] 資料分析..." -ForegroundColor Green

if ($allPatients.Count -gt 0) {
    Write-Host "`n      病人統計:" -ForegroundColor Cyan
    Write-Host "      總病人數: $($allPatients.Count)" -ForegroundColor White
    
    $patients = $allPatients | ForEach-Object { $_.resource }
    $genderStats = $patients | Group-Object -Property gender
    Write-Host "`n      性別分布:" -ForegroundColor Cyan
    foreach ($group in $genderStats) {
        $pct = [math]::Round(($group.Count * 100.0 / $allPatients.Count), 1)
        Write-Host "        $($group.Name): $($group.Count) 人 ($pct%)" -ForegroundColor White
    }
}

if ($allImmunizations.Count -gt 0) {
    Write-Host "`n      疫苗接種統計:" -ForegroundColor Cyan
    Write-Host "      總接種紀錄: $($allImmunizations.Count) 筆" -ForegroundColor White
}

if ($allConditions.Count -gt 0) {
    Write-Host "`n      診斷統計:" -ForegroundColor Cyan
    Write-Host "      總診斷紀錄: $($allConditions.Count) 筆" -ForegroundColor White
}

if ($allObservations.Count -gt 0) {
    Write-Host "`n      觀察值統計:" -ForegroundColor Cyan
    Write-Host "      總觀察紀錄: $($allObservations.Count) 筆" -ForegroundColor White
}

# Step 5: Save Results
Write-Host "`n[5/5] 儲存報告..." -ForegroundColor Green

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonFile = Join-Path $PSScriptRoot "fhir_data_$timestamp.json"

$outputData = @{
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    patients = $allPatients
    immunizations = $allImmunizations
    conditions = $allConditions
    observations = $allObservations
}

$outputData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
Write-Host "      JSON 資料檔: $jsonFile" -ForegroundColor Green

# Create Simple Text Report
$txtFile = Join-Path $PSScriptRoot "report_$timestamp.txt"
$report = @"
================================================================================
                    國民健康 CQL 測量指標報告
================================================================================

報告產生時間: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
資料時間範圍: 過去 $($config.filters.time_period_years) 年

--------------------------------------------------------------------------------
資料擷取統計
--------------------------------------------------------------------------------
  Patient:       $($allPatients.Count) 筆
  Immunization:  $($allImmunizations.Count) 筆
  Condition:     $($allConditions.Count) 筆
  Observation:   $($allObservations.Count) 筆

--------------------------------------------------------------------------------
CQL 測量庫
--------------------------------------------------------------------------------
"@

foreach ($cql in $config.cql_libraries) {
    $report += "`n  ✓ $cql"
}

$report += @"

--------------------------------------------------------------------------------
FHIR 伺服器
--------------------------------------------------------------------------------
"@

foreach ($server in $config.fhir_servers) {
    $report += "`n  $($server.name): $($server.base_url)"
}

$report += @"

================================================================================
                             報告結束
================================================================================
"@

$report | Out-File -FilePath $txtFile -Encoding UTF8
Write-Host "      TXT 報告: $txtFile" -ForegroundColor Green

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "                             程式執行完成!" -ForegroundColor Yellow
Write-Host "`n================================================================================`n" -ForegroundColor Cyan

Write-Host "產生的檔案:" -ForegroundColor Green
Write-Host "  1. JSON 資料檔: $jsonFile" -ForegroundColor White
Write-Host "  2. TXT 報告: $txtFile" -ForegroundColor White
Write-Host "`n"
