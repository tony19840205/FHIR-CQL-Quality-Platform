# ========================================
# CGMH 大批測試資料批次上傳腳本
# 總計: 500-700 位病患
# 位置: UI UX\HAPI-FHIR-Samples\
# ========================================

# 設定 FHIR Server
$fhirServer = "https://r4.smarthealthit.org"  # 可改為台灣衛福部
$headers = @{
    "Content-Type" = "application/fhir+json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "開始上傳 CGMH 大批測試資料" -ForegroundColor Cyan
Write-Host "目標伺服器: $fhirServer" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# CGMH 檔案清單
$files = @(
    @{Name="CGMH_test_data_taiwan_100_bundle.json"; Patients=100; Resources=200},
    @{Name="CGMH_test_data_vaccine_100_bundle.json"; Patients=100; Resources=219},
    @{Name="CGMH_test_data_antibiotic_49_bundle.json"; Patients=49; Resources=241},
    @{Name="CGMH_test_data_waste_9_bundle.json"; Patients=9; Resources=45},
    @{Name="CGMH_test_data_quality_50_bundle.json"; Patients=50; Resources=502},
    @{Name="CGMH_test_data_outpatient_quality_53_bundle.json"; Patients=53; Resources=585},
    @{Name="CGMH_test_data_inpatient_quality_46_bundle.json"; Patients=46; Resources=172},
    @{Name="CGMH_test_data_surgical_quality_46_bundle.json"; Patients=46; Resources=196},
    @{Name="CGMH_test_data_outcome_quality_12_bundle.json"; Patients=12; Resources=45},
    @{Name="CGMH_test_data_same_hospital_overlap_42_bundle.json"; Patients=42; Resources=252}
)

$totalFiles = $files.Count
$successCount = 0
$failCount = 0
$totalResources = 0

foreach ($i in 0..($files.Count-1)) {
    $file = $files[$i]
    $fileName = $file.Name
    $fileNumber = $i + 1
    
    Write-Host "`n【$fileNumber/$totalFiles】上傳: $fileName" -ForegroundColor Cyan
    Write-Host "  預計病患數: $($file.Patients) 人" -ForegroundColor Gray
    Write-Host "  預計資源數: $($file.Resources) 個" -ForegroundColor Gray
    
    if (-not (Test-Path $fileName)) {
        Write-Host "  ❌ 檔案不存在，跳過" -ForegroundColor Red
        $failCount++
        continue
    }
    
    try {
        # 讀取 Bundle
        $bundleJson = Get-Content $fileName -Raw -Encoding UTF8
        
        # 上傳到 FHIR Server
        $response = Invoke-RestMethod -Uri $fhirServer `
            -Method POST `
            -Headers $headers `
            -Body $bundleJson `
            -ErrorAction Stop
        
        Write-Host "  ✅ 上傳成功" -ForegroundColor Green
        $successCount++
        $totalResources += $file.Resources
        
        # 等待 3 秒避免伺服器過載
        if ($fileNumber -lt $totalFiles) {
            Write-Host "  ⏳ 等待 3 秒..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
    }
    catch {
        Write-Host "  ❌ 上傳失敗: $_" -ForegroundColor Red
        $failCount++
    }
}

# 顯示統計
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "上傳完成統計" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 成功: $successCount 個檔案" -ForegroundColor Green
Write-Host "❌ 失敗: $failCount 個檔案" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host "📊 上傳資源數: 約 $totalResources 個" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "🎉 所有 CGMH 資料上傳完成！" -ForegroundColor Green
} else {
    Write-Host "⚠️  部分檔案上傳失敗，請檢查錯誤訊息" -ForegroundColor Yellow
}
