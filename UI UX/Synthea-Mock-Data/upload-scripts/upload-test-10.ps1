# 簡易 FHIR 上傳腳本 - 上傳 10 筆測試資料

$fhirServer = "https://emr-smart.appx.com.tw/v/r4/fhir"
$dataDir = "C:\Users\tony1\OneDrive\桌面\UI UX-20251122(0013)\UI UX\Synthea-Mock-Data\generated-fhir-data\fhir"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FHIR 測試資料上傳" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "目標伺服器: $fhirServer" -ForegroundColor Gray
Write-Host ""

# 取得所有病人檔案（排除 hospital 和 practitioner）
$files = Get-ChildItem -Path $dataDir -Filter "*.json" | 
    Where-Object { $_.Name -notmatch "hospital|practitioner" } |
    Select-Object -First 10

Write-Host "準備上傳 $($files.Count) 筆病人資料" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($file in $files) {
    Write-Host "[$($successCount + $failCount + 1)/$($files.Count)] 上傳: $($file.Name)" -ForegroundColor Gray
    
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        $response = Invoke-RestMethod `
            -Uri $fhirServer `
            -Method Post `
            -Body $content `
            -ContentType "application/fhir+json; charset=utf-8" `
            -ErrorAction Stop
        
        Write-Host "  ✓ 成功" -ForegroundColor Green
        $successCount++
        
    } catch {
        Write-Host "  ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
    
    # 避免伺服器負載過高
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  上傳完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "成功: $successCount 筆" -ForegroundColor Green
Write-Host "失敗: $failCount 筆" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""
Write-Host "請開啟 FHIR Dashboard 檢查資料:" -ForegroundColor Yellow
Write-Host "URL: https://emr-smart.appx.com.tw/FHIR-Dashboard-App/" -ForegroundColor Cyan
Write-Host ""
