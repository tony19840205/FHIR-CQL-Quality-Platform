# ============================================
# Synthea 下載腳本
# 自動下載最新版本的 Synthea
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Synthea 下載工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查 Java 版本
Write-Host "正在檢查 Java 環境..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-String "version" | ForEach-Object { $_ -replace '.*version "(.+?)".*', '$1' }
    Write-Host "✓ 找到 Java 版本: $javaVersion" -ForegroundColor Green
    
    $majorVersion = [int]($javaVersion -split '\.')[0]
    if ($majorVersion -lt 11) {
        Write-Host "✗ 警告: Synthea 需要 Java 11 或更高版本" -ForegroundColor Red
        Write-Host "  請從 https://adoptium.net/ 下載並安裝" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ 找不到 Java！" -ForegroundColor Red
    Write-Host "  請先安裝 Java 11 或更高版本" -ForegroundColor Yellow
    Write-Host "  下載連結: https://adoptium.net/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 設定下載 URL 和檔案名稱
$syntheaVersion = "3.2.0"
$syntheaJarName = "synthea-with-dependencies.jar"
$syntheaUrl = "https://github.com/synthetichealth/synthea/releases/download/v$syntheaVersion/$syntheaJarName"

Write-Host "準備下載 Synthea v$syntheaVersion" -ForegroundColor Cyan
Write-Host "下載位置: $syntheaUrl" -ForegroundColor Gray
Write-Host ""

# 檢查檔案是否已存在
if (Test-Path $syntheaJarName) {
    Write-Host "✓ 發現已存在的 Synthea 檔案" -ForegroundColor Green
    $overwrite = Read-Host "是否重新下載？(Y/N)"
    if ($overwrite -ne "Y" -and $overwrite -ne "y") {
        Write-Host "略過下載，使用現有檔案" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  下載完成！" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "下一步: 執行 .\run-synthea.ps1 -PatientCount 1000" -ForegroundColor Yellow
        exit 0
    }
}

# 開始下載
Write-Host "開始下載 Synthea（約 150MB，請稍候）..." -ForegroundColor Yellow
Write-Host ""

# 使用 Invoke-WebRequest 下載
try {
    $ProgressPreference = 'SilentlyContinue'  # 隱藏進度條以提升速度
    Invoke-WebRequest -Uri $syntheaUrl -OutFile $syntheaJarName -ErrorAction Stop
    $ProgressPreference = 'Continue'
    
    Write-Host "✓ 下載完成！" -ForegroundColor Green
    
    # 驗證檔案大小
    $fileSize = (Get-Item $syntheaJarName).Length / 1MB
    Write-Host "  檔案大小: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    
    if ($fileSize -lt 50) {
        Write-Host "✗ 警告: 檔案大小異常，可能下載不完整" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ 下載失敗！" -ForegroundColor Red
    Write-Host "  錯誤訊息: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "請嘗試手動下載:" -ForegroundColor Yellow
    Write-Host "  1. 開啟瀏覽器前往: $syntheaUrl" -ForegroundColor Yellow
    Write-Host "  2. 下載檔案後放到此資料夾" -ForegroundColor Yellow
    Write-Host "  3. 重新執行此腳本" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  安裝完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Synthea 已準備就緒" -ForegroundColor Green
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "  .\run-synthea.ps1 -PatientCount 1000" -ForegroundColor Cyan
Write-Host ""
Write-Host "或者先測試 10 個病人:" -ForegroundColor Yellow
Write-Host "  .\run-synthea.ps1 -PatientCount 10" -ForegroundColor Cyan
Write-Host ""
