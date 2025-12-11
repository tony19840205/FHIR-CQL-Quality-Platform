# 上傳所有11個Bundle到衛福部SAND-BOX
$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

$bundles = @(
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

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "上傳剩餘10個Bundle到衛福部SAND-BOX" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

for ($b = 0; $b -lt $bundles.Count; $b++) {
    $bundleFile = $bundles[$b]
    Write-Host "[$($b+2)/11] $bundleFile" -ForegroundColor Cyan
    
    $bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $resourceCount = $bundle.entry.Count
    Write-Host "  資源數: $resourceCount" -ForegroundColor Yellow
    
    $success = 0
    $fail = 0
    
    for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
        $resource = $bundle.entry[$i].resource
        $resourceType = $resource.resourceType
        $resourceId = $resource.id
        
        if ($resourceId) {
            if (($i + 1) % 20 -eq 0) {
                Write-Host "    進度: $($i+1)/$resourceCount" -ForegroundColor Gray
            }
            
            $json = $resource | ConvertTo-Json -Depth 20 -Compress
            $url = "$FHIR_SERVER/$resourceType/$resourceId"
            
            try {
                $null = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json" -ErrorAction Stop
                $success++
            } catch {
                $fail++
            }
        }
    }
    
    $totalSuccess += $success
    $totalFail += $fail
    Write-Host "  完成: ✅ $success 成功, ❌ $fail 失敗" -ForegroundColor Green
    Write-Host ""
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "📊 上傳完成統計" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Bundle 1 (已完成): ✅ 200 成功" -ForegroundColor Green
Write-Host "Bundle 2-11 (剛完成): ✅ $totalSuccess 成功, ❌ $totalFail 失敗" -ForegroundColor Green
Write-Host "總計: ✅ $(200 + $totalSuccess) 成功, ❌ $totalFail 失敗" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan

if ($totalFail -eq 0) {
    Write-Host ""
    Write-Host "🎉 所有509位病患資料上傳成功！" -ForegroundColor Green
}
