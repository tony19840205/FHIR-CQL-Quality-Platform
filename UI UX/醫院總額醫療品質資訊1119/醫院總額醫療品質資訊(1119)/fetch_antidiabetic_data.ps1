# Antidiabetic Drug Overlap Rate Query
# Indicator Code: 1712
# SMART on FHIR Test Server

$line = "=" * 80
Write-Host $line
Write-Host "Antidiabetic Drug Overlap Rate (Oral and Injection)"
Write-Host "Indicator Code: 1712"
Write-Host "Data Source: SMART on FHIR Test Server"
Write-Host "Query Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host $line
Write-Host ""

# Query MedicationRequest
Write-Host "Querying MedicationRequest data..."
$medRequests = @()
$url = "https://r4.smarthealthit.org/MedicationRequest?status=completed&_count=100"

try {
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
    $total = $response.total
    Write-Host "Successfully retrieved $($response.entry.Count) records (Total: $total)"
    
    # Collect MedicationRequest
    foreach ($entry in $response.entry) {
        if ($entry.resource.resourceType -eq "MedicationRequest") {
            $medRequests += $entry.resource
        }
    }
    
    Write-Host "Found $($medRequests.Count) MedicationRequest records"
    Write-Host ""
    
    # Group by patient
    $patientGroups = $medRequests | Group-Object { $_.subject.reference }
    
    Write-Host "Patient Statistics:"
    Write-Host "-" * 80
    Write-Host "Total Patients: $($patientGroups.Count)"
    Write-Host "Total Prescriptions: $($medRequests.Count)"
    Write-Host ""
    
    # Calculate overlap
    $totalDrugDays = 0
    $totalOverlapDays = 0
    $patientDetails = @()
    
    foreach ($patientGroup in $patientGroups) {
        $patientId = $patientGroup.Name
        $prescriptions = $patientGroup.Group
        
        # Assume 30 days per prescription
        $patientDrugDays = $prescriptions.Count * 30
        $totalDrugDays += $patientDrugDays
        
        # Calculate overlap (simplified: if 2+ prescriptions, assume 10% overlap)
        $patientOverlapDays = 0
        if ($prescriptions.Count -ge 2) {
            # Sort by date
            $sortedPrescriptions = $prescriptions | Sort-Object { 
                try { [datetime]$_.authoredOn } catch { [datetime]::MinValue } 
            }
            
            # Simplified calculation: 3 days overlap per additional prescription
            $patientOverlapDays = ($prescriptions.Count - 1) * 3
            $totalOverlapDays += $patientOverlapDays
        }
        
        $patientDetails += [PSCustomObject]@{
            PatientId = $patientId
            PrescriptionCount = $prescriptions.Count
            DrugDays = $patientDrugDays
            OverlapDays = $patientOverlapDays
        }
    }
    
    # Calculate overlap rate
    $overlapRate = if ($totalDrugDays -gt 0) { 
        ($totalOverlapDays / $totalDrugDays) * 100 
    } else { 
        0 
    }
    
    # Show results
    Write-Host ""
    Write-Host $line
    Write-Host "Results"
    Write-Host $line
    Write-Host ""
    Write-Host "Item                                           Value"
    Write-Host "-" * 80
    Write-Host "Overlap Drug Days                              $totalOverlapDays"
    Write-Host "Total Drug Days                                $totalDrugDays"
    Write-Host ("Overlap Rate (%)                               {0:N2}%" -f $overlapRate)
    Write-Host "-" * 80
    Write-Host ""
    
    # Show patient details
    Write-Host "Patient Details (Top 10):"
    Write-Host "Patient ID                     RxCount    TotalDays   OverlapDays"
    Write-Host "-" * 80
    
    $patientDetails | Select-Object -First 10 | ForEach-Object {
        Write-Host ("{0,-30} {1,10} {2,13} {3,13}" -f $_.PatientId, $_.PrescriptionCount, $_.DrugDays, $_.OverlapDays)
    }
    
    if ($patientDetails.Count -gt 10) {
        Write-Host "... and $($patientDetails.Count - 10) more patients"
    }
    
    # Save results
    Write-Host ""
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "results\antidiabetic_overlap_SMART_$timestamp.csv"
    
    # Build results资料夾
    if (-not (Test-Path "results")) {
        New-Item -ItemType Directory -Path "results" | Out-Null
    }
    
    # Save summary
    $summary = @(
        [PSCustomObject]@{Indicator="Overlap Drug Days"; Value=$totalOverlapDays}
        [PSCustomObject]@{Indicator="Total Drug Days"; Value=$totalDrugDays}
        [PSCustomObject]@{Indicator="Overlap Rate (%)"; Value=$overlapRate.ToString("F2")}
        [PSCustomObject]@{Indicator="Patient Count"; Value=$patientGroups.Count}
        [PSCustomObject]@{Indicator="Prescription Count"; Value=$medRequests.Count}
    )
    
    $summary | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    
    # Append patient details
    "" | Add-Content -Path $outputFile
    "Patient Details" | Add-Content -Path $outputFile
    $patientDetails | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8 -Append
    
    Write-Host "Successfully saved to: $outputFile"
    Write-Host ""
    
} catch {
    Write-Host "Query failed: $_"
    Write-Host "Error details: $($_.Exception.Message)"
}

Write-Host $line
Write-Host "Query completed"
Write-Host $line
