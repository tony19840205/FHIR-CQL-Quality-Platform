# ================================================================
# Synthea FHIR Upload Script - Individual Resource Mode
# ================================================================
# Function: Extract and upload individual resources from Transaction Bundles
# Usage: .\upload-individual-resources.ps1 -PatientCount 10
# ================================================================

param(
    [Parameter(Mandatory=$false)]
    [int]$PatientCount = 10,
    
    [Parameter(Mandatory=$false)]
    [string]$FhirServer = "https://emr-smart.appx.com.tw/v/r4/fhir"
)

# Set paths
$dataPath = "..\generated-fhir-data\fhir"
$logPath = ".\upload-log.txt"

# Initialize log
"=====================================" | Out-File $logPath
"FHIR Resource Upload Log" | Out-File $logPath -Append
"Time: $(Get-Date)" | Out-File $logPath -Append
"Target Server: $FhirServer" | Out-File $logPath -Append
"=====================================" | Out-File $logPath -Append
"" | Out-File $logPath -Append

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Synthea FHIR Data Upload Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target Server: $FhirServer" -ForegroundColor Yellow
Write-Host "Upload Count: $PatientCount patients" -ForegroundColor Yellow
Write-Host ""

# Get patient files (exclude hospital and practitioner)
$patientFiles = Get-ChildItem -Path $dataPath -Filter "*.json" | 
    Where-Object { $_.Name -notmatch "hospital|practitioner" } | 
    Select-Object -First $PatientCount

Write-Host "Found $($patientFiles.Count) patient files" -ForegroundColor Green
Write-Host ""

# Statistics variables
$totalResources = 0
$successResources = 0
$failedResources = 0
$resourceTypeStats = @{}

# Process each patient file
for ($i = 0; $i -lt $patientFiles.Count; $i++) {
    $file = $patientFiles[$i]
    $patientNum = $i + 1
    
    Write-Host "[$patientNum/$($patientFiles.Count)] Processing: $($file.Name)" -ForegroundColor Cyan
    "[$patientNum/$($patientFiles.Count)] Processing: $($file.Name)" | Out-File $logPath -Append
    
    try {
        # Read Bundle
        $bundle = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $entries = $bundle.entry
        
        Write-Host "  Found $($entries.Count) resources" -ForegroundColor Gray
        
        # Sort resource types by dependency order
        $orderedTypes = @(
            "Patient",           # 1. Patient (base)
            "Organization",      # 2. Organization
            "Practitioner",      # 3. Practitioner
            "Location",          # 4. Location
            "Encounter",         # 5. Encounter
            "Condition",         # 6. Condition
            "Observation",       # 7. Observation
            "Procedure",         # 8. Procedure
            "MedicationRequest", # 9. MedicationRequest
            "Immunization",      # 10. Immunization
            "AllergyIntolerance",# 11. AllergyIntolerance
            "CarePlan",          # 12. CarePlan
            "Goal",              # 13. Goal
            "Claim",             # 14. Claim
            "ExplanationOfBenefit" # 15. ExplanationOfBenefit
        )
        
        # Upload resources in order
        foreach ($resourceType in $orderedTypes) {
            $resources = $entries | Where-Object { $_.resource.resourceType -eq $resourceType }
            
            if ($resources.Count -eq 0) { continue }
            
            Write-Host "  Uploading $resourceType ($($resources.Count) resources)..." -ForegroundColor Gray -NoNewline
            
            $typeSuccess = 0
            $typeFailed = 0
            
            foreach ($entry in $resources) {
                $totalResources++
                $resource = $entry.resource
                
                # Remove id field (let server auto-generate)
                if ($resource.PSObject.Properties['id']) {
                    $resource.PSObject.Properties.Remove('id')
                }
                
                # Convert to JSON
                $resourceJson = $resource | ConvertTo-Json -Depth 20 -Compress
                
                try {
                    # Upload resource
                    $response = Invoke-RestMethod `
                        -Uri "$FhirServer/$resourceType" `
                        -Method Post `
                        -Body $resourceJson `
                        -ContentType "application/fhir+json; charset=utf-8" `
                        -ErrorAction Stop
                    
                    $successResources++
                    $typeSuccess++
                    
                    # Track resource type statistics
                    if (-not $resourceTypeStats.ContainsKey($resourceType)) {
                        $resourceTypeStats[$resourceType] = 0
                    }
                    $resourceTypeStats[$resourceType]++
                    
                } catch {
                    $failedResources++
                    $typeFailed++
                    $errorMsg = $_.Exception.Message
                    "    X $resourceType upload failed: $errorMsg" | Out-File $logPath -Append
                }
            }
            
            if ($typeFailed -eq 0) {
                Write-Host " OK ($typeSuccess/$($resources.Count))" -ForegroundColor Green
            } else {
                Write-Host " WARN ($typeSuccess/$($resources.Count) success, $typeFailed failed)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "  Patient file processed successfully" -ForegroundColor Green
        "" | Out-File $logPath -Append
        
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        "  ERROR: $($_.Exception.Message)" | Out-File $logPath -Append
    }
    
    Write-Host ""
}

# Output statistics
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Upload Statistics" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Resources: $totalResources" -ForegroundColor White
Write-Host "Successful: $successResources" -ForegroundColor Green
Write-Host "Failed: $failedResources" -ForegroundColor $(if ($failedResources -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Resource Type Statistics:" -ForegroundColor Yellow
$resourceTypeStats.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
}
Write-Host ""

if ($failedResources -eq 0) {
    Write-Host "All uploads successful!" -ForegroundColor Green
} else {
    Write-Host "Some resources failed to upload. Check upload-log.txt" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Detailed log saved to: $logPath" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
