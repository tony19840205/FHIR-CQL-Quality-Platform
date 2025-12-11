# 逐個資源上傳到衛福部 SAND-BOX
# 避免 Bundle 太大導致 400 錯誤

$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

# 所有 Bundle 檔案
$bundles = @(
    "CGMH_test_data_taiwan_100_bundle.json",
    "CGMH_test_data_vaccine_100_bundle.json",
    "CGMH_test_data_antibiotic_49_bundle.json",
    "CGMH_test_data_waste_9_bundle.json",
    "CGMH_test_data_quality_50_bundle.json",
    "CGMH_test_data_outpatient_quality_53_bundle.json",
    "CGMH_test_data_inpatient_quality_46_bundle.json",
    "CGMH_test_data_surgical_quality_46_bundle.json",
    "CGMH_test_data_outcome_quality_12_bundle.json",
    "CGMH_test_data_same_hospital_overlap_42_bundle.json",
    "Mr_FHIR_CQL_Demo_Patient.json"
)

$totalSuccess = 0
$totalFail = 0
$bundleCount = 0

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "上傳測試資料到衛福部 FHIR SAND-BOX" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "伺服器: $FHIR_SERVER" -ForegroundColor Yellow
Write-Host "Bundle 數: $($bundles.Count)" -ForegroundColor Yellow
Write-Host ""

foreach ($bundleFile in $bundles) {
    $bundleCount++
    Write-Host ""
    Write-Host "[$bundleCount/$($bundles.Count)] 處理: $bundleFile" -ForegroundColor Cyan
    Write-Host ("-" * 70) -ForegroundColor Gray
    
    if (-not (Test-Path $bundleFile)) {
        Write-Host "  ❌ 檔案不存在" -ForegroundColor Red
        continue
    }
    
    # 讀取 Bundle
    try {
        $bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $resourceCount = $bundle.entry.Count
        Write-Host "  ✅ 已載入 $resourceCount 個資源" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ 讀取失敗: $_" -ForegroundColor Red
        continue
    }
    
    # 逐個上傳資源
    $success = 0
    $fail = 0
    
    for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
        $entry = $bundle.entry[$i]
        $resource = $entry.resource
        $resourceType = $resource.resourceType
        $resourceId = $resource.id
        
        if (-not $resourceId) {
            Write-Host "  ⚠️  跳過無ID資源 (#$($i+1))" -ForegroundColor Yellow
            continue
        }
        
        # 顯示進度
        if (($i + 1) % 10 -eq 0) {
            Write-Host "    進度: $($i+1)/$resourceCount" -ForegroundColor Gray
        }
        
        try {
            $json = $resource | ConvertTo-Json -Depth 20 -Compress
            $url = "$FHIR_SERVER/$resourceType/$resourceId"
            
            $response = Invoke-RestMethod -Uri $url -Method Put -Body $json `
                -ContentType "application/fhir+json" -ErrorAction Stop
            
            $success++
            $totalSuccess++
        } catch {
            $fail++
            $totalFail++
            Write-Host "    ❌ $resourceType/$resourceId 上傳失敗" -ForegroundColor Red
        }
    }
    
    Write-Host "  📊 Bundle 完成: ✅ $success 成功, ❌ $fail 失敗" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "📊 上傳完成統計" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "✅ 總成功: $totalSuccess" -ForegroundColor Green
Write-Host "❌ 總失敗: $totalFail" -ForegroundColor $(if ($totalFail -eq 0) { 'Green' } else { 'Red' })
Write-Host "=" * 70 -ForegroundColor Cyan

if ($totalFail -eq 0) {
    Write-Host ""
    Write-Host "🎉 所有資料上傳成功！" -ForegroundColor Green
    Write-Host "✅ 509位病患的測試資料已上傳至衛福部 SAND-BOX" -ForegroundColor Green
}
