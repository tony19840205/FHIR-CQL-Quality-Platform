# ========================================
# 重新上傳部分失敗的Bundle資源
# 日期：2025年12月5日
# ========================================

$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "重新上傳部分失敗的Bundle資源" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 需要重新上傳的Bundle清單
$bundles = @(
    "CGMH_test_data_outpatient_quality_53_bundle.json",
    "CGMH_test_data_inpatient_quality_46_bundle.json",
    "CGMH_test_data_same_hospital_overlap_42_bundle.json",
    "Mr_FHIR_CQL_Demo_Patient.json"
)

$totalSuccess = 0
$totalFailed = 0
$totalSkipped = 0

foreach ($bundleFile in $bundles) {
    Write-Host "`n----------------------------------------" -ForegroundColor Yellow
    Write-Host "處理Bundle: $bundleFile" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    
    if (-not (Test-Path $bundleFile)) {
        Write-Host "❌ 檔案不存在，跳過" -ForegroundColor Red
        continue
    }
    
    # 讀取Bundle
    $bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $success = 0
    $failed = 0
    $skipped = 0
    
    # 遍歷所有資源
    for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
        $resource = $bundle.entry[$i].resource
        $resourceType = $resource.resourceType
        $resourceId = $resource.id
        
        # 檢查資源是否已存在（Patient通常已存在，可跳過）
        $url = "$FHIR_SERVER/$resourceType/$resourceId"
        
        try {
            # 先嘗試GET查詢是否已存在
            $existing = $null
            try {
                $existing = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -ErrorAction Stop
            } catch {
                # 資源不存在，繼續上傳
            }
            
            if ($existing -and $resourceType -eq "Patient") {
                Write-Host "  ⏭️  [$($i+1)/$($bundle.entry.Count)] Patient $resourceId 已存在，跳過" -ForegroundColor Gray
                $skipped++
                continue
            }
            
            # 轉換為JSON
            $json = $resource | ConvertTo-Json -Depth 20 -Compress
            
            # PUT上傳
            $null = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json" -ErrorAction Stop
            Write-Host "  ✅ [$($i+1)/$($bundle.entry.Count)] $resourceType/$resourceId 上傳成功" -ForegroundColor Green
            $success++
            
        } catch {
            Write-Host "  ❌ [$($i+1)/$($bundle.entry.Count)] $resourceType/$resourceId 上傳失敗: $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
        
        # 每10個資源暫停一下，避免過快請求
        if (($i + 1) % 10 -eq 0) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Host "`n📊 $bundleFile 統計:" -ForegroundColor Cyan
    Write-Host "   成功: $success" -ForegroundColor Green
    Write-Host "   失敗: $failed" -ForegroundColor Red
    Write-Host "   跳過: $skipped" -ForegroundColor Gray
    
    $totalSuccess += $success
    $totalFailed += $failed
    $totalSkipped += $skipped
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "總體統計" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 成功上傳: $totalSuccess" -ForegroundColor Green
Write-Host "❌ 上傳失敗: $totalFailed" -ForegroundColor Red
Write-Host "⏭️  跳過資源: $totalSkipped" -ForegroundColor Gray
Write-Host "`n完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# 驗證Patient總數
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "驗證Patient總數" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "$FHIR_SERVER/Patient?_summary=count" -Method Get
    Write-Host "📊 Patient總數: $($response.total)" -ForegroundColor Green
} catch {
    Write-Host "❌ 無法查詢Patient總數" -ForegroundColor Red
}
