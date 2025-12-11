$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "========================================"
Write-Host "Upload Same Hospital Overlap - MedicationRequest Only"
Write-Host "========================================"

$bundlePath = "CGMH_test_data_same_hospital_overlap_42_bundle.json"
$jsonContent = Get-Content $bundlePath -Raw -Encoding UTF8
$bundle = $jsonContent | ConvertFrom-Json

$successCount = 0
$failCount = 0

for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
    $entry = $bundle.entry[$i]
    $resource = $entry.resource
    
    # Only process MedicationRequest
    if ($resource.resourceType -ne "MedicationRequest") {
        continue
    }
    
    $resourceId = $resource.id
    
    # Fix: Replace +08:00 with Z
    if ($resource.authoredOn -and $resource.authoredOn -match '\+08:00$') {
        $resource.authoredOn = $resource.authoredOn -replace '\+08:00$', 'Z'
    }
    
    # Fix: Remove dispenseRequest (date format not accepted)
    if ($resource.dispenseRequest) {
        $resource.PSObject.Properties.Remove('dispenseRequest')
    }
    
    # Fix: Remove requester (Organization reference doesn't exist)
    if ($resource.requester) {
        $resource.PSObject.Properties.Remove('requester')
    }
    
    # Upload
    $url = "$FHIR_SERVER/MedicationRequest/$resourceId"
    $body = $resource | ConvertTo-Json -Depth 10 -Compress
    
    try {
        $response = Invoke-RestMethod -Method PUT -Uri $url `
            -ContentType "application/fhir+json;charset=UTF-8" `
            -Body $body `
            -ErrorAction Stop
        
        $successCount++
        Write-Host "  OK [$successCount] MedicationRequest/$resourceId"
        
    } catch {
        $failCount++
        Write-Host "  FAIL MedicationRequest/$resourceId - $($_.Exception.Message)"
    }
    
    # Rate limiting
    if ($successCount % 10 -eq 0 -and $successCount -gt 0) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`n========================================"
Write-Host "Upload Complete"
Write-Host "  Success: $successCount"
Write-Host "  Failed: $failCount"
Write-Host "========================================"
