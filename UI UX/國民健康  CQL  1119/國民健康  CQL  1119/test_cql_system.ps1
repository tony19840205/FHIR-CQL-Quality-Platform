# CQL 測試系統 - PowerShell 版本
# 此腳本展示如何連接 SMART FHIR 伺服器並擷取資料

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "                    國民健康 CQL 測量指標系統                    " -ForegroundColor Yellow
Write-Host "================================================================================`n" -ForegroundColor Cyan

# 讀取配置
Write-Host "步驟 1/5: 載入配置檔案..." -ForegroundColor Green
$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json

Write-Host "✓ 配置檔案載入成功" -ForegroundColor Green
Write-Host "  - FHIR 伺服器數量: $($config.fhir_servers.Count)"
Write-Host "  - 資料時間範圍: $($config.filters.time_period_years) 年"
Write-Host "  - CQL 測量庫數量: $($config.cql_libraries.Count)"

foreach ($server in $config.fhir_servers) {
    Write-Host "  - 伺服器: $($server.name) ($($server.base_url))"
}

# 連接並測試 FHIR 伺服器
Write-Host "`n步驟 2/5: 連接 FHIR 伺服器並測試..." -ForegroundColor Green

$allData = @{
    Patient = @()
    Immunization = @()
    Condition = @()
    Observation = @()
}

foreach ($server in $config.fhir_servers) {
    Write-Host "`n正在連接: $($server.name)" -ForegroundColor Yellow
    Write-Host "URL: $($server.base_url)"
    
    try {
        # 測試連接 - 獲取 Capability Statement
        $metadataUrl = "$($server.base_url)/metadata"
        $response = Invoke-RestMethod -Uri $metadataUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 10
        
        Write-Host "✓ 伺服器連接成功" -ForegroundColor Green
        Write-Host "  伺服器版本: $($response.fhirVersion)"
        
        # 嘗試獲取病人資料
        try {
            $patientUrl = "$($server.base_url)/Patient?_count=50"
            $patientBundle = Invoke-RestMethod -Uri $patientUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30 -ErrorAction Stop
            
            if ($patientBundle.entry) {
                $patientCount = $patientBundle.entry.Count
                Write-Host "  獲取 Patient: $patientCount 筆" -ForegroundColor Green
                foreach ($entry in $patientBundle.entry) {
                    $allData.Patient += $entry.resource
                }
            }
        } catch {
            Write-Host "  Patient 資源無法存取" -ForegroundColor Yellow
        }
        
        # 嘗試獲取疫苗接種資料
        try {
            $immunizationUrl = "$($server.base_url)/Immunization?_count=50`&status=completed"
            $immunizationBundle = Invoke-RestMethod -Uri $immunizationUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30 -ErrorAction Stop
            
            if ($immunizationBundle.entry) {
                $immunizationCount = $immunizationBundle.entry.Count
                Write-Host "  獲取 Immunization: $immunizationCount 筆" -ForegroundColor Green
                foreach ($entry in $immunizationBundle.entry) {
                    $allData.Immunization += $entry.resource
                }
            }
        } catch {
            Write-Host "  Immunization 資源無法存取" -ForegroundColor Yellow
        }
        
        # 嘗試獲取診斷資料
        try {
            $conditionUrl = "$($server.base_url)/Condition?_count=50"
            $conditionBundle = Invoke-RestMethod -Uri $conditionUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30 -ErrorAction Stop
            
            if ($conditionBundle.entry) {
                $conditionCount = $conditionBundle.entry.Count
                Write-Host "  獲取 Condition: $conditionCount 筆" -ForegroundColor Green
                foreach ($entry in $conditionBundle.entry) {
                    $allData.Condition += $entry.resource
                }
            }
        } catch {
            Write-Host "  Condition 資源無法存取" -ForegroundColor Yellow
        }
        
        # 嘗試獲取觀察值資料
        try {
            $observationUrl = "$($server.base_url)/Observation?_count=50"
            $observationBundle = Invoke-RestMethod -Uri $observationUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30 -ErrorAction Stop
            
            if ($observationBundle.entry) {
                $observationCount = $observationBundle.entry.Count
                Write-Host "  獲取 Observation: $observationCount 筆" -ForegroundColor Green
                foreach ($entry in $observationBundle.entry) {
                    $allData.Observation += $entry.resource
                }
            }
        } catch {
            Write-Host "  Observation 資源無法存取" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "✗ 伺服器連接失敗: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 資料統計
Write-Host "`n步驟 3/5: 資料擷取統計..." -ForegroundColor Green
Write-Host "================================================================================"
Write-Host "  Patient:       $($allData.Patient.Count) 筆"
Write-Host "  Immunization:  $($allData.Immunization.Count) 筆"
Write-Host "  Condition:     $($allData.Condition.Count) 筆"
Write-Host "  Observation:   $($allData.Observation.Count) 筆"
Write-Host "================================================================================`n"

# 簡單的資料分析
Write-Host "步驟 4/5: 資料分析..." -ForegroundColor Green

if ($allData.Patient.Count -gt 0) {
    Write-Host "`n📊 病人統計:" -ForegroundColor Cyan
    Write-Host "  總病人數: $($allData.Patient.Count)"
    
    # 性別統計
    $genderStats = $allData.Patient | Group-Object -Property gender
    Write-Host "`n  性別分布:"
    foreach ($group in $genderStats) {
        $percentage = [math]::Round(($group.Count / $allData.Patient.Count * 100), 1)
        Write-Host "    $($group.Name): $($group.Count) 人 ($percentage %)"
    }
}

if ($allData.Immunization.Count -gt 0) {
    Write-Host "`n💉 疫苗接種統計:" -ForegroundColor Cyan
    Write-Host "  總接種紀錄: $($allData.Immunization.Count) 筆"
    
    # 統計不同疫苗類型
    $vaccineTypes = @{}
    foreach ($imm in $allData.Immunization) {
        $vaccineName = "未知"
        if ($imm.vaccineCode.coding) {
            $vaccineName = $imm.vaccineCode.coding[0].display
            if (-not $vaccineName) {
                $vaccineName = $imm.vaccineCode.coding[0].code
            }
        } elseif ($imm.vaccineCode.text) {
            $vaccineName = $imm.vaccineCode.text
        }
        
        if ($vaccineTypes.ContainsKey($vaccineName)) {
            $vaccineTypes[$vaccineName]++
        } else {
            $vaccineTypes[$vaccineName] = 1
        }
    }
    
    Write-Host "`n  疫苗類型 (前5名):"
    $vaccineTypes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "    $($_.Key): $($_.Value) 劑"
    }
}

if ($allData.Condition.Count -gt 0) {
    Write-Host "`n🩺 診斷統計:" -ForegroundColor Cyan
    Write-Host "  總診斷紀錄: $($allData.Condition.Count) 筆"
}

if ($allData.Observation.Count -gt 0) {
    Write-Host "`n📈 觀察值統計:" -ForegroundColor Cyan
    Write-Host "  總觀察紀錄: $($allData.Observation.Count) 筆"
}

# 儲存結果
Write-Host "`n步驟 5/5: 儲存報告..." -ForegroundColor Green

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = Join-Path $PSScriptRoot "fhir_data_$timestamp.json"

$allData | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n✓ 資料已儲存到: $outputFile" -ForegroundColor Green

# 產生簡易 HTML 報告
$htmlFile = Join-Path $PSScriptRoot "report_$timestamp.html"
$htmlContent = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>國民健康 CQL 測量指標報告</title>
    <style>
        body {
            font-family: "Microsoft JhengHei", Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        .stat-box {
            background-color: #fff;
            padding: 20px;
            margin: 15px 0;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .stat-title {
            font-size: 1.3em;
            color: #34495e;
            margin-bottom: 15px;
            border-left: 5px solid #3498db;
            padding-left: 10px;
        }
        .stat-item {
            padding: 8px 0;
            border-bottom: 1px solid #ecf0f1;
        }
        .stat-label {
            font-weight: bold;
            color: #2c3e50;
        }
        .stat-value {
            color: #16a085;
            float: right;
        }
    </style>
</head>
<body>
    <h1>🏥 國民健康 CQL 測量指標報告</h1>
    
    <div class="stat-box">
        <div class="stat-title">報告資訊</div>
        <div class="stat-item">
            <span class="stat-label">報告產生時間:</span>
            <span class="stat-value">$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">資料時間範圍:</span>
            <span class="stat-value">過去 $($config.filters.time_period_years) 年</span>
        </div>
    </div>
    
    <div class="stat-box">
        <div class="stat-title">📊 資料擷取統計</div>
        <div class="stat-item">
            <span class="stat-label">病人資料 (Patient):</span>
            <span class="stat-value">$($allData.Patient.Count) 筆</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">疫苗接種 (Immunization):</span>
            <span class="stat-value">$($allData.Immunization.Count) 筆</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">診斷紀錄 (Condition):</span>
            <span class="stat-value">$($allData.Condition.Count) 筆</span>
        </div>
        <div class="stat-item">
            <span class="stat-label">觀察值 (Observation):</span>
            <span class="stat-value">$($allData.Observation.Count) 筆</span>
        </div>
    </div>
    
    <div class="stat-box">
        <div class="stat-title">📋 CQL 測量庫</div>
"@

foreach ($cql in $config.cql_libraries) {
    $htmlContent += @"
        <div class="stat-item">
            <span class="stat-label">✓ $cql</span>
        </div>
"@
}

$htmlContent += @"
    </div>
    
    <div class="stat-box">
        <div class="stat-title">🌐 FHIR 伺服器</div>
"@

foreach ($server in $config.fhir_servers) {
    $htmlContent += @"
        <div class="stat-item">
            <span class="stat-label">$($server.name):</span>
            <span class="stat-value">$($server.base_url)</span>
        </div>
"@
}

$htmlContent += @"
    </div>
    
</body>
</html>
"@

$htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8

Write-Host "HTML 報告已儲存到: $htmlFile" -ForegroundColor Green

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "                             程式執行完成                             " -ForegroundColor Yellow
Write-Host "================================================================================`n" -ForegroundColor Cyan

Write-Host "產生的檔案:" -ForegroundColor Green
Write-Host "  1. JSON 資料檔: $outputFile"
Write-Host "  2. HTML 報告: $htmlFile"
Write-Host "`n提示: 您可以在瀏覽器中開啟 HTML 報告查看結果`n"
