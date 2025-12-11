$baseUrl = "https://thas.mohw.gov.tw/v/r4/fhir"
$jsonFile = "Polypharmacy_6_Patients_EN.json"

Write-Host "Starting upload..." -ForegroundColor Green

$bundle = Get-Content $jsonFile -Raw -Encoding UTF8 | ConvertFrom-Json
$total = $bundle.entry.Count
$success = 0
$failed = 0

foreach ($entry in $bundle.entry) {
    $resource = $entry.resource
    $resourceType = $resource.resourceType
    $id = $resource.id
    $url = "$baseUrl/$resourceType/$id"
    
    try {
        $json = $resource | ConvertTo-Json -Depth 10 -Compress
        $response = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json; charset=utf-8"
        Write-Host "[OK] $resourceType/$id" -ForegroundColor Green
        $success++
    }
    catch {
        Write-Host "[FAIL] $resourceType/$id - $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`nUpload complete: $success/$total success, $failed failed" -ForegroundColor Cyan
