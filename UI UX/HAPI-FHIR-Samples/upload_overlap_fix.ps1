$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "========================================"
Write-Host "Upload Same Hospital Overlap Bundle"
Write-Host "========================================"

$bundlePath = "CGMH_test_data_same_hospital_overlap_42_bundle.json"

# Read JSON with UTF8 encoding
$jsonContent = Get-Content $bundlePath -Raw -Encoding UTF8
$bundle = $jsonContent | ConvertFrom-Json

$successCount = 0
$failCount = 0
$skipCount = 0
$totalEntries = $bundle.entry.Count

Write-Host "Total entries: $totalEntries"

for ($i = 0; $i -lt $totalEntries; $i++) {
    $entry = $bundle.entry[$i]
    $resource = $entry.resource
    $resourceType = $resource.resourceType
    $resourceId = $resource.id
    
    # Skip Patient resources
    if ($resourceType -eq "Patient") {
        $skipCount++
        continue
    }
    
    # Remove serviceProvider from Encounter
    if ($resourceType -eq "Encounter" -and $resource.serviceProvider) {
        $resource.PSObject.Properties.Remove('serviceProvider')
    }
    
    # Upload resource
    $url = "$FHIR_SERVER/$resourceType/$resourceId"
    $body = $resource | ConvertTo-Json -Depth 10 -Compress
    
    try {
        $response = Invoke-RestMethod -Method PUT -Uri $url `
            -ContentType "application/fhir+json;charset=UTF-8" `
            -Body $body `
            -ErrorAction Stop
        
        $successCount++
        Write-Host "  OK [$($i+1)/$totalEntries] $resourceType/$resourceId"
        
    } catch {
        $failCount++
        Write-Host "  FAIL [$($i+1)/$totalEntries] $resourceType/$resourceId"
        # Write-Host "    Error: $($_.Exception.Message)"
    }
    
    # Rate limiting
    if (($successCount + $failCount) % 10 -eq 0 -and ($successCount + $failCount) -gt 0) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`n========================================"
Write-Host "Stats:"
Write-Host "  Success: $successCount"
Write-Host "  Failed: $failCount"
Write-Host "  Skipped: $skipCount (Patients)"
Write-Host "========================================"
