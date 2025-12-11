# ============================================
# FHIR 資料上傳腳本
# 上傳 Synthea 生成的資料到 FHIR 伺服器
# ============================================

param(
    [Parameter(Mandatory=$false)]
    [string]$FhirServer = "https://emr-smart.appx.com.tw/v/r4/fhir",
    
    [Parameter(Mandatory=$false)]
    [switch]$TestMode = $false,
    
    [Parameter(Mandatory=$false)]
    [int]$BatchSize = 10
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FHIR 資料上傳工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$dataDir = "..\generated-fhir-data\fhir-processed"

# 檢查資料目錄
if (-not (Test-Path $dataDir)) {
    Write-Host "✗ 錯誤: 找不到資料目錄" -ForegroundColor Red
    Write-Host "  路徑: $dataDir" -ForegroundColor Red
    Write-Host "  請先執行後處理腳本生成資料" -ForegroundColor Yellow
    exit 1
}

# 取得所有 JSON 檔案
$files = Get-ChildItem -Path $dataDir -Filter "*.json" | Sort-Object Name

if ($files.Count -eq 0) {
    Write-Host "✗ 錯誤: 資料目錄中沒有 JSON 檔案" -ForegroundColor Red
    exit 1
}

Write-Host "找到 $($files.Count) 個 FHIR Bundle 檔案" -ForegroundColor Gray
Write-Host "目標伺服器: $FhirServer" -ForegroundColor Gray
Write-Host ""

# 測試模式：只上傳 10 個檔案
if ($TestMode) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  測試模式" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "只會上傳前 $BatchSize 個檔案進行測試" -ForegroundColor Yellow
    Write-Host ""
    $files = $files | Select-Object -First $BatchSize
}

# 確認上傳
Write-Host "準備上傳 $($files.Count) 個檔案" -ForegroundColor Cyan
$confirm = Read-Host "確定要繼續嗎？(Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "取消上傳" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "開始上傳..." -ForegroundColor Yellow
Write-Host ""

# 統計資訊
$stats = @{
    Success = 0
    Failed = 0
    TotalResources = 0
    Errors = @()
}

# 上傳每個檔案
$index = 0
foreach ($file in $files) {
    $index++
    $percentage = [math]::Round(($index / $files.Count) * 100, 1)
    
    Write-Host "[$index/$($files.Count)] ($percentage%) 上傳: $($file.Name)" -ForegroundColor Gray
    
    try {
        # 讀取 Bundle
        $bundleContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $bundle = $bundleContent | ConvertFrom-Json
        
        # 統計資源數
        if ($bundle.entry) {
            $stats.TotalResources += $bundle.entry.Count
        }
        
        # 上傳到 FHIR 伺服器
        $response = Invoke-RestMethod `
            -Uri $FhirServer `
            -Method Post `
            -Body $bundleContent `
            -ContentType "application/fhir+json; charset=utf-8" `
            -ErrorAction Stop
        
        $stats.Success++
        Write-Host "  ✓ 成功" -ForegroundColor Green
        
    } catch {
        $stats.Failed++
        $errorMsg = $_.Exception.Message
        $stats.Errors += "$($file.Name): $errorMsg"
        Write-Host "  ✗ 失敗: $errorMsg" -ForegroundColor Red
    }
    
    # 每 10 個檔案休息一下，避免伺服器負載過高
    if ($index % 10 -eq 0) {
        Write-Host ""
        Write-Host "  已上傳 $index 個檔案，休息 2 秒..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
        Write-Host ""
    }
}

# 輸出結果
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  上傳完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "總檔案數: $($files.Count)" -ForegroundColor Gray
Write-Host "成功: $($stats.Success)" -ForegroundColor Green
Write-Host "失敗: $($stats.Failed)" -ForegroundColor $(if ($stats.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "總資源數: $($stats.TotalResources)" -ForegroundColor Gray
Write-Host ""

# 顯示錯誤（如果有）
if ($stats.Errors.Count -gt 0) {
    Write-Host "錯誤列表:" -ForegroundColor Red
    Write-Host "----------------------------------------" -ForegroundColor Red
    $stats.Errors | ForEach-Object {
        Write-Host "  ✗ $_" -ForegroundColor Red
    }
    Write-Host ""
}

# 測試模式提示
if ($TestMode) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  測試模式完成" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "測試上傳完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步:" -ForegroundColor Yellow
    Write-Host "  1. 在瀏覽器開啟 FHIR Dashboard 檢查資料" -ForegroundColor Cyan
    Write-Host "     URL: https://emr-smart.appx.com.tw/FHIR-Dashboard-App/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. 確認醫療品質指標正常顯示" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. 如果一切正常，執行完整上傳:" -ForegroundColor Cyan
    Write-Host "     .\upload-to-fhir.ps1" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "所有資料已上傳！" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步:" -ForegroundColor Yellow
    Write-Host "  在瀏覽器開啟 FHIR Dashboard 查看結果" -ForegroundColor Cyan
    Write-Host "  URL: https://emr-smart.appx.com.tw/FHIR-Dashboard-App/" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
