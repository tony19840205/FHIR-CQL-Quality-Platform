# ============================================
# Synthea 執行腳本
# 生成指定數量的合成病人資料
# ============================================

param(
    [Parameter(Mandatory=$false)]
    [int]$PatientCount = 1000,
    
    [Parameter(Mandatory=$false)]
    [string]$State = "Taiwan",
    
    [Parameter(Mandatory=$false)]
    [string]$City = "Taipei"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Synthea 病人資料生成器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查 JAR 檔案是否存在
$syntheaJar = "synthea-with-dependencies.jar"
if (-not (Test-Path $syntheaJar)) {
    Write-Host "✗ 找不到 Synthea JAR 檔案！" -ForegroundColor Red
    Write-Host "  請先執行: .\download-synthea.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "生成參數:" -ForegroundColor Cyan
Write-Host "  病人數量: $PatientCount" -ForegroundColor Gray
Write-Host "  地區: $State, $City" -ForegroundColor Gray
Write-Host ""

# 設定輸出目錄
$outputDir = "..\generated-fhir-data"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 清理舊的輸出資料（如果存在）
$fhirOutputPath = Join-Path $outputDir "fhir"
if (Test-Path $fhirOutputPath) {
    Write-Host "清理舊的 FHIR 資料..." -ForegroundColor Yellow
    Remove-Item -Path $fhirOutputPath -Recurse -Force
}

Write-Host "開始生成病人資料..." -ForegroundColor Yellow
Write-Host "（這可能需要幾分鐘時間，請耐心等候）" -ForegroundColor Gray
Write-Host ""

# 設定時間範圍（過去 5 年到現在）
$startDate = (Get-Date).AddYears(-5).ToString("yyyy-MM-dd")
$endDate = (Get-Date).ToString("yyyy-MM-dd")

try {
    # 執行 Synthea
    # 主要參數說明:
    # -p: 病人數量
    # -s: 隨機種子（用於可重現的結果）
    # -cs: 使用臨床指引（生成更真實的病歷）
    # --exporter.fhir.export: 啟用 FHIR 匯出
    # --exporter.baseDirectory: 設定輸出目錄
    
    $seed = Get-Random -Maximum 999999
    
    java -jar $syntheaJar `
        -p $PatientCount `
        -s $seed `
        -cs $seed `
        --exporter.fhir.export=true `
        --exporter.baseDirectory=$outputDir `
        --exporter.fhir.bulk_data=false `
        --exporter.hospital.fhir.export=true `
        --exporter.practitioner.fhir.export=true `
        --generate.demographics.default_file="..\synthea-config\taiwan-demographics.json" `
        $State $City
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ 病人資料生成成功！" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "✗ 生成過程發生錯誤" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "✗ 執行失敗！" -ForegroundColor Red
    Write-Host "  錯誤訊息: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  統計資訊" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 統計生成的檔案
$fhirFiles = Get-ChildItem -Path $fhirOutputPath -Filter "*.json" -Recurse -ErrorAction SilentlyContinue

if ($fhirFiles) {
    Write-Host "  FHIR 檔案總數: $($fhirFiles.Count)" -ForegroundColor Gray
    
    # 統計各類資源
    $patients = ($fhirFiles | Where-Object { $_.Name -like "*Patient*" }).Count
    $encounters = ($fhirFiles | Where-Object { $_.Name -like "*Encounter*" }).Count
    $observations = ($fhirFiles | Where-Object { $_.Name -like "*Observation*" }).Count
    $medications = ($fhirFiles | Where-Object { $_.Name -like "*Medication*" }).Count
    
    if ($patients -gt 0) { Write-Host "  - Patient 資源: $patients" -ForegroundColor Gray }
    if ($encounters -gt 0) { Write-Host "  - Encounter 資源: $encounters" -ForegroundColor Gray }
    if ($observations -gt 0) { Write-Host "  - Observation 資源: $observations" -ForegroundColor Gray }
    if ($medications -gt 0) { Write-Host "  - Medication 資源: $medications" -ForegroundColor Gray }
    
    $totalSize = ($fhirFiles | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  總檔案大小: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "輸出位置:" -ForegroundColor Cyan
Write-Host "  $((Get-Item $fhirOutputPath).FullName)" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  下一步" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 執行後處理腳本（添加真實變異）:" -ForegroundColor Yellow
Write-Host "   cd ..\post-processing" -ForegroundColor Cyan
Write-Host "   node add-realistic-noise.js" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. 驗證 FHIR 資料格式:" -ForegroundColor Yellow
Write-Host "   node validate-fhir.js" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. 預覽資料統計:" -ForegroundColor Yellow
Write-Host "   cd ..\upload-scripts" -ForegroundColor Cyan
Write-Host "   開啟 preview-data.html 在瀏覽器" -ForegroundColor Cyan
Write-Host ""
