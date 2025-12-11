$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "========================================"
Write-Host "Fix and Upload Failed Bundles (v3)"
Write-Host "========================================"

$bundles = @(
    "CGMH_test_data_same_hospital_overlap_42_bundle.json"
)

function Fix-DateTime {
    param($dateTimeString)
    
    if (-not $dateTimeString) { return $dateTimeString }
    
    # Check if already has timezone (Z or +/-offset)
    if ($dateTimeString -match 'Z$' -or $dateTimeString -match '[+-]\d{2}:\d{2}$') {
        return $dateTimeString
    }
    
    # Add Z if no timezone
    return $dateTimeString + "Z"
}

function Fix-EncounterResource {
    param($resource)
    
    if ($resource.period) {
        $resource.period.start = Fix-DateTime $resource.period.start
        $resource.period.end = Fix-DateTime $resource.period.end
    }
    
    # Remove serviceProvider reference
    if ($resource.serviceProvider) {
        $resource.PSObject.Properties.Remove('serviceProvider')
    }
    
    return $resource
}

function Fix-ConditionResource {
    param($resource)
    
    if ($resource.onsetDateTime) {
        $resource.onsetDateTime = Fix-DateTime $resource.onsetDateTime
    }
    if ($resource.recordedDate) {
        $resource.recordedDate = Fix-DateTime $resource.recordedDate
    }
    
    return $resource
}

function Fix-MedicationRequestResource {
    param($resource)
    
    if ($resource.authoredOn) {
        $resource.authoredOn = Fix-DateTime $resource.authoredOn
    }
    
    if ($resource.dispenseRequest -and $resource.dispenseRequest.validityPeriod) {
        $vp = $resource.dispenseRequest.validityPeriod
        $vp.start = Fix-DateTime $vp.start
        $vp.end = Fix-DateTime $vp.end
    }
    
    return $resource
}

foreach ($bundlePath in $bundles) {
    Write-Host "`nProcessing: $bundlePath"
    
    $jsonContent = Get-Content $bundlePath -Raw
    $bundle = $jsonContent | ConvertFrom-Json
    
    $successCount = 0
    $failCount = 0
    $skipCount = 0
    $totalEntries = $bundle.entry.Count
    
    for ($i = 0; $i -lt $totalEntries; $i++) {
        $entry = $bundle.entry[$i]
        $resource = $entry.resource
        $resourceType = $resource.resourceType
        $resourceId = $resource.id
        
        # Skip Patient resources (already uploaded)
        if ($resourceType -eq "Patient") {
            $skipCount++
            continue
        }
        
        # Apply fixes based on resource type
        switch ($resourceType) {
            "Encounter" {
                $resource = Fix-EncounterResource $resource
            }
            "Condition" {
                $resource = Fix-ConditionResource $resource
            }
            "MedicationRequest" {
                $resource = Fix-MedicationRequestResource $resource
            }
        }
        
        # Upload resource
        $url = "$FHIR_SERVER/$resourceType/$resourceId"
        $body = $resource | ConvertTo-Json -Depth 10 -Compress
        
        try {
            $response = Invoke-RestMethod -Method PUT -Uri $url `
                -ContentType "application/fhir+json" `
                -Body $body `
                -ErrorAction Stop
            
            $successCount++
            Write-Host "  OK [$($i+1)/$totalEntries] $resourceType/$resourceId"
            
        } catch {
            $failCount++
            Write-Host "  FAIL [$($i+1)/$totalEntries] $resourceType/$resourceId"
        }
        
        # Rate limiting
        if ($successCount % 10 -eq 0 -and $successCount -gt 0) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Host "Stats: Success=$successCount, Failed=$failCount, Skipped=$skipCount"
}

Write-Host "`n========================================"
Write-Host "Upload Complete"
Write-Host "========================================"
