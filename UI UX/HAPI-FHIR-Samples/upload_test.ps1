# 上傳第1個Bundle - 測試用
$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"
$bundleFile = "CGMH_test_data_taiwan_100_bundle.json"

Write-Host "上傳: $bundleFile" -ForegroundColor Cyan

$bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
$resourceCount = $bundle.entry.Count
Write-Host "資源數: $resourceCount" -ForegroundColor Yellow

$success = 0
$fail = 0

for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
    $resource = $bundle.entry[$i].resource
    $resourceType = $resource.resourceType
    $resourceId = $resource.id
    
    if ($resourceId) {
        if (($i + 1) % 10 -eq 0) {
            Write-Host "進度: $($i+1)/$resourceCount" -ForegroundColor Gray
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

Write-Host ""
Write-Host "完成: ✅ $success 成功, ❌ $fail 失敗" -ForegroundColor Green
