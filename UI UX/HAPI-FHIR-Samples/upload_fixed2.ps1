$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "========================================"
Write-Host "Fix and Upload Failed Bundles"
Write-Host "========================================"

$bundles = @(
    "CGMH_test_data_outpatient_quality_53_bundle.json",
    "CGMH_test_data_inpatient_quality_46_bundle.json",
    "CGMH_test_data_same_hospital_overlap_42_bundle.json"
)

function Fix-EncounterResource {
    param($resource)
    if ($resource.period) {
        if ($resource.period.start -and $resource.period.start -notmatch 'Z$') {
            $resource.period.start = $resource.period.start + "Z"
        }
        if ($resource.period.end -and $resource.period.end -notmatch 'Z$') {
            $resource.period.end = $resource.period.end + "Z"
        }
    }
    if ($resource.serviceProvider) {
        $resource.PSObject.Properties.Remove('serviceProvider')
    }
    return $resource
}

function Fix-ConditionResource {
    param($resource)
    if ($resource.onsetDateTime -and $resource.onsetDateTime -notmatch 'Z$') {
        $resource.onsetDateTime = $resource.onsetDateTime + "Z"
    }
    if ($resource.recordedDate -and $resource.recordedDate -notmatch 'Z$') {
        $resource.recordedDate = $resource.recordedDate + "Z"
    }
    return $resource
}

function Fix-MedicationRequestResource {
    param($resource)
    if ($resource.authoredOn -and $resource.authoredOn -notmatch 'Z$') {
        $resource.authoredOn = $resource.authoredOn + "Z"
    }
    if ($resource.dispenseRequest -and $resource.dispenseRequest.validityPeriod) {
        if ($resource.dispenseRequest.validityPeriod.start -and $resource.dispenseRequest.validityPeriod.start -notmatch 'Z$') {
            $resource.dispenseRequest.validityPeriod.start = $resource.dispenseRequest.validityPeriod.start + "Z"
        }
        if ($resource.dispenseRequest.validityPeriod.end -and $resource.dispenseRequest.validityPeriod.end -notmatch 'Z$') {
            $resource.dispenseRequest.validityPeriod.end = $resource.dispenseRequest.validityPeriod.end + "Z"
        }
    }
    return $resource
}

$totalSuccess = 0
$totalFailed = 0
$totalSkipped = 0

foreach ($bundleFile in $bundles) {
    Write-Host "`nProcessing: $bundleFile"
    if (-not (Test-Path $bundleFile)) {
        Write-Host "File not found, skip"
        continue
    }
    
    $bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $success = 0
    $failed = 0
    $skipped = 0
    
    for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
        $resource = $bundle.entry[$i].resource
        $resourceType = $resource.resourceType
        $resourceId = $resource.id
        
        if ($resourceType -eq "Patient") {
            $skipped++
            continue
        }
        
        try {
            switch ($resourceType) {
                "Encounter" { $resource = Fix-EncounterResource $resource }
                "Condition" { $resource = Fix-ConditionResource $resource }
                "MedicationRequest" { $resource = Fix-MedicationRequestResource $resource }
            }
            
            $json = $resource | ConvertTo-Json -Depth 20 -Compress
            $url = "$FHIR_SERVER/$resourceType/$resourceId"
            $null = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json" -ErrorAction Stop
            Write-Host "  OK [$($i+1)/$($bundle.entry.Count)] $resourceType/$resourceId"
            $success++
        } catch {
            Write-Host "  FAIL [$($i+1)/$($bundle.entry.Count)] $resourceType/$resourceId"
            $failed++
        }
        
        if (($i + 1) % 10 -eq 0) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Host "Stats: Success=$success, Failed=$failed, Skipped=$skipped"
    $totalSuccess += $success
    $totalFailed += $failed
    $totalSkipped += $skipped
}

Write-Host "`n========================================"
Write-Host "Total Success: $totalSuccess"
Write-Host "Total Failed: $totalFailed"
Write-Host "Total Skipped: $totalSkipped"
Write-Host "========================================"
