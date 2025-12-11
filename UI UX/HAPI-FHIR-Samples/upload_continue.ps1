# 繼續上傳剩餘Bundle (5-11)
$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

$bundles = @(
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

Write-Host "繼續上傳Bundle 5-11..." -ForegroundColor Green

for ($b = 0; $b -lt $bundles.Count; $b++) {
    $bundleFile = $bundles[$b]
    Write-Host "[$($b+5)/11] $bundleFile" -ForegroundColor Cyan
    
    $bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $resourceCount = $bundle.entry.Count
    
    $success = 0
    $fail = 0
    
    for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
        $resource = $bundle.entry[$i].resource
        $resourceType = $resource.resourceType
        $resourceId = $resource.id
        
        if ($resourceId) {
            $json = $resource | ConvertTo-Json -Depth 20 -Compress
            $url = "$FHIR_SERVER/$resourceType/$resourceId"
            
            try {
                $null = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json" -ErrorAction Stop
                $success++
            } catch {
                $fail++
            }
        }
        
        # 每10個顯示進度
        if (($i + 1) % 10 -eq 0) {
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
    }
    
    $totalSuccess += $success
    $totalFail += $fail
    Write-Host ""
    Write-Host "  ✅ $success/$resourceCount" -ForegroundColor Green
}

Write-Host ""
Write-Host "Bundle 5-11完成: ✅ $totalSuccess 成功, ❌ $totalFail 失敗" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 所有資料上傳完成！" -ForegroundColor Green
