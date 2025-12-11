$baseUrl = "https://thas.mohw.gov.tw/v/r4/fhir"
$jsonFile = "Diabetes_HbA1c_5_Patients.json"

Write-Host "Uploading Diabetes HbA1c test patients..." -ForegroundColor Cyan

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
        Write-Host "[FAIL] $resourceType/$id" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $failed++
    }
}

Write-Host "`nUpload complete: $success/$total success, $failed failed" -ForegroundColor Cyan
