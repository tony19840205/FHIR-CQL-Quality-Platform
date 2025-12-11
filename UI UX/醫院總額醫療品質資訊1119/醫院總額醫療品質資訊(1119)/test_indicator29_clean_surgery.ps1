# ============================================
# Indicator 29 Test Script
# Clean Surgery Postoperative Antibiotic Use Over 3 Days Rate
# Indicator Code: 1155
# ============================================

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Testing Indicator 29: Clean Surgery Postoperative Antibiotic Use Over 3 Days Rate" -ForegroundColor Cyan
Write-Host "Indicator Code: 1155" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# FHIR Server Configuration
$servers = @(
    @{
        Name = "HAPI FHIR Test Server"
        BaseUrl = "https://hapi.fhir.org/baseR4"
        Description = "Public HAPI FHIR R4 Test Server"
    },
    @{
        Name = "SMART Health IT"
        BaseUrl = "https://r4.smarthealthit.org"
        Description = "SMART on FHIR Reference Server"
    },
    @{
        Name = "UHN HAPI FHIR Server"
        BaseUrl = "https://fhir.uhn.ca/baseR4"
        Description = "University Health Network FHIR Server"
    },
    @{
        Name = "Vonk FHIR Server"
        BaseUrl = "https://vonk.fire.ly/R4"
        Description = "Firely Vonk Reference Server"
    }
)

# Test Configuration
$testConfig = @{
    MaxPatientsPerServer = 20
    TestPeriodStart = "2023-01-01"
    TestPeriodEnd = "2024-12-31"
    AntibioticThresholdDays = 3
}

# Initialize Results
$allResults = @()
$summary = @{
    TotalServers = $servers.Count
    SuccessfulServers = 0
    FailedServers = 0
    TotalPatients = 0
    TotalCleanSurgeries = 0
    TotalAntibioticOver3Days = 0
    JointRepairCount = 0
    ThyroidSurgeryCount = 0
    JointReplacementCount = 0
}

Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  Test Period: $($testConfig.TestPeriodStart) to $($testConfig.TestPeriodEnd)" -ForegroundColor White
Write-Host "  Antibiotic Threshold: $($testConfig.AntibioticThresholdDays) days" -ForegroundColor White
Write-Host "  Max Patients per Server: $($testConfig.MaxPatientsPerServer)" -ForegroundColor White
Write-Host ""

# Function: Query FHIR Server
function Query-FHIRServer {
    param(
        [string]$BaseUrl,
        [string]$Resource,
        [hashtable]$Parameters
    )
    
    try {
        $queryString = ($Parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $url = "$BaseUrl/$Resource" + $(if ($queryString) { "?$queryString" } else { "" })
        
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        return $response
    }
    catch {
        Write-Host "  Error querying $BaseUrl/$Resource : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function: Test Clean Surgery Type 1 (Joint Repair)
function Test-JointRepairSurgery {
    param($BaseUrl, $ServerName)
    
    Write-Host "  Testing Type 1: Joint Repair Surgery..." -ForegroundColor Cyan
    
    # ICD-10-PCS codes for joint repair
    $jointRepairCodes = @(
        '0YQ50ZZ', '0YQ53ZZ', '0YQ54ZZ',  # Knee
        '0YQ60ZZ', '0YQ63ZZ', '0YQ64ZZ',  # Knee Right
        '0YQ70ZZ', '0YQ73ZZ', '0YQ74ZZ',  # Hip
        '0YQ80ZZ', '0YQ83ZZ', '0YQ84ZZ',  # Hip Right
        '0YQC0ZZ', '0YQC3ZZ', '0YQC4ZZ',  # Ankle
        '0YQE0ZZ', '0YQE3ZZ', '0YQE4ZZ'   # Tarsal
    )
    
    $procedures = Query-FHIRServer -BaseUrl $BaseUrl -Resource "Procedure" -Parameters @{
        "_count" = "50"
        "status" = "completed"
    }
    
    $matchCount = 0
    if ($procedures -and $procedures.entry) {
        foreach ($entry in $procedures.entry) {
            $proc = $entry.resource
            if ($proc.code.coding) {
                foreach ($coding in $proc.code.coding) {
                    if ($coding.system -eq "http://hl7.org/fhir/sid/icd-10-pcs" -and 
                        $jointRepairCodes -contains $coding.code) {
                        $matchCount++
                        break
                    }
                }
            }
        }
    }
    
    Write-Host "    Found $matchCount joint repair procedures" -ForegroundColor $(if($matchCount -gt 0){"Green"}else{"Gray"})
    return $matchCount
}

# Function: Test Clean Surgery Type 2 (Thyroid Surgery)
function Test-ThyroidSurgery {
    param($BaseUrl, $ServerName)
    
    Write-Host "  Testing Type 2: Thyroid Surgery..." -ForegroundColor Cyan
    
    # ICD-10-PCS codes for thyroid surgery
    $thyroidCodes = @(
        '0GBG0ZZ', '0GBG3ZZ', '0GBG4ZZ',  # Thyroid excision
        '0GBH0ZZ', '0GBH3ZZ', '0GBH4ZZ',  # Thyroid right lobe excision
        '0GTG0ZZ', '0GTG4ZZ',              # Thyroid resection
        '0GTH0ZZ', '0GTH4ZZ',              # Thyroid right lobe resection
        '0GTK0ZZ', '0GTK4ZZ'               # Thyroid left lobe resection
    )
    
    # ICD-10-CM codes for thyroid conditions
    $thyroidConditions = @('E00', 'E01', 'E02', 'E03', 'E04', 'E05', 'E06', 'E07', 'E35', 'E89.0', 'D44.0')
    
    $procedures = Query-FHIRServer -BaseUrl $BaseUrl -Resource "Procedure" -Parameters @{
        "_count" = "50"
        "status" = "completed"
    }
    
    $matchCount = 0
    if ($procedures -and $procedures.entry) {
        foreach ($entry in $procedures.entry) {
            $proc = $entry.resource
            if ($proc.code.coding) {
                foreach ($coding in $proc.code.coding) {
                    if ($coding.system -eq "http://hl7.org/fhir/sid/icd-10-pcs" -and 
                        $thyroidCodes -contains $coding.code) {
                        $matchCount++
                        break
                    }
                }
            }
        }
    }
    
    Write-Host "    Found $matchCount thyroid surgery procedures" -ForegroundColor $(if($matchCount -gt 0){"Green"}else{"Gray"})
    return $matchCount
}

# Function: Test Clean Surgery Type 3 (Joint Replacement)
function Test-JointReplacementSurgery {
    param($BaseUrl, $ServerName)
    
    Write-Host "  Testing Type 3: Joint Replacement Surgery..." -ForegroundColor Cyan
    
    # Sample ICD-10-PCS codes for joint replacement (164 total codes defined in CQL)
    $jointReplacementCodes = @(
        '0SR9019', '0SR901A', '0SR901Z',  # Hip replacement
        '0SRB019', '0SRB01A', '0SRB01Z',  # Hip joint replacement
        '0SRC019', '0SRC01A', '0SRC01Z',  # Knee replacement
        '0SRD019', '0SRD01A', '0SRD01Z'   # Knee joint replacement
    )
    
    $procedures = Query-FHIRServer -BaseUrl $BaseUrl -Resource "Procedure" -Parameters @{
        "_count" = "50"
        "status" = "completed"
    }
    
    $matchCount = 0
    if ($procedures -and $procedures.entry) {
        foreach ($entry in $procedures.entry) {
            $proc = $entry.resource
            if ($proc.code.coding) {
                foreach ($coding in $proc.code.coding) {
                    if ($coding.system -eq "http://hl7.org/fhir/sid/icd-10-pcs" -and 
                        $jointReplacementCodes -contains $coding.code) {
                        $matchCount++
                        break
                    }
                }
            }
        }
    }
    
    Write-Host "    Found $matchCount joint replacement procedures" -ForegroundColor $(if($matchCount -gt 0){"Green"}else{"Gray"})
    return $matchCount
}

# Function: Test Exclusion Criteria
function Test-ExclusionCriteria {
    param($BaseUrl, $ServerName)
    
    Write-Host "  Testing Exclusion Criteria..." -ForegroundColor Cyan
    
    $exclusions = @{
        MalignantBoneTumor = @('C40', 'C41')
        CoagulationDisorder = @('D65', 'D66', 'D67', 'D68')
        OtitisMedia = @('H65', 'H66', 'H67', 'H68', 'H69')
        Pneumonia = @('J12', 'J13', 'J14', 'J15', 'J16', 'J17', 'J18')
        UTI = @('N30', 'N34', 'N39.0')
    }
    
    $conditions = Query-FHIRServer -BaseUrl $BaseUrl -Resource "Condition" -Parameters @{
        "_count" = "100"
    }
    
    $exclusionCounts = @{
        MalignantBoneTumor = 0
        CoagulationDisorder = 0
        OtitisMedia = 0
        Pneumonia = 0
        UTI = 0
    }
    
    if ($conditions -and $conditions.entry) {
        foreach ($entry in $conditions.entry) {
            $cond = $entry.resource
            if ($cond.code.coding) {
                foreach ($coding in $cond.code.coding) {
                    if ($coding.system -eq "http://hl7.org/fhir/sid/icd-10-cm") {
                        $code = $coding.code
                        
                        foreach ($exclusionType in $exclusions.Keys) {
                            foreach ($prefix in $exclusions[$exclusionType]) {
                                if ($code.StartsWith($prefix)) {
                                    $exclusionCounts[$exclusionType]++
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    foreach ($type in $exclusionCounts.Keys) {
        $count = $exclusionCounts[$type]
        Write-Host "    $type : $count cases" -ForegroundColor $(if($count -gt 0){"Yellow"}else{"Gray"})
    }
    
    return $exclusionCounts
}

# Function: Test Antibiotic Tracking
function Test-AntibioticTracking {
    param($BaseUrl, $ServerName)
    
    Write-Host "  Testing Antibiotic Tracking (ATC J01)..." -ForegroundColor Cyan
    
    $medications = Query-FHIRServer -BaseUrl $BaseUrl -Resource "MedicationRequest" -Parameters @{
        "_count" = "100"
        "status" = "active,completed"
    }
    
    $antibioticCount = 0
    $over3DaysCount = 0
    
    if ($medications -and $medications.entry) {
        foreach ($entry in $medications.entry) {
            $med = $entry.resource
            if ($med.medicationCodeableConcept.coding) {
                foreach ($coding in $med.medicationCodeableConcept.coding) {
                    if ($coding.system -eq "http://www.whocc.no/atc" -and 
                        $coding.code.StartsWith("J01")) {
                        $antibioticCount++
                        
                        # Check duration (simplified)
                        if ($med.dosageInstruction -and $med.dosageInstruction[0].timing) {
                            $timing = $med.dosageInstruction[0].timing
                            if ($timing.repeat -and $timing.repeat.boundsDuration) {
                                $duration = $timing.repeat.boundsDuration.value
                                if ($duration -gt 3) {
                                    $over3DaysCount++
                                }
                            }
                        }
                        break
                    }
                }
            }
        }
    }
    
    Write-Host "    Found $antibioticCount antibiotic prescriptions" -ForegroundColor $(if($antibioticCount -gt 0){"Green"}else{"Gray"})
    Write-Host "    Found $over3DaysCount prescriptions over 3 days" -ForegroundColor $(if($over3DaysCount -gt 0){"Yellow"}else{"Gray"})
    
    return @{
        TotalAntibiotics = $antibioticCount
        Over3Days = $over3DaysCount
    }
}

# Main Test Loop
foreach ($server in $servers) {
    Write-Host ""
    Write-Host ("=" * 100) -ForegroundColor Gray
    Write-Host "Testing Server: $($server.Name)" -ForegroundColor Green
    Write-Host "URL: $($server.BaseUrl)" -ForegroundColor Gray
    Write-Host "Description: $($server.Description)" -ForegroundColor Gray
    Write-Host ("=" * 100) -ForegroundColor Gray
    Write-Host ""
    
    $serverSuccess = $false
    
    try {
        # Test patient access
        Write-Host "  Checking server connectivity..." -ForegroundColor Cyan
        $patients = Query-FHIRServer -BaseUrl $server.BaseUrl -Resource "Patient" -Parameters @{
            "_count" = "$($testConfig.MaxPatientsPerServer)"
        }
        
        if ($patients -and $patients.entry) {
            $patientCount = $patients.entry.Count
            Write-Host "    Found $patientCount patients" -ForegroundColor Green
            $summary.TotalPatients += $patientCount
            $serverSuccess = $true
            
            # Test clean surgery types
            $jointRepairCount = Test-JointRepairSurgery -BaseUrl $server.BaseUrl -ServerName $server.Name
            $thyroidCount = Test-ThyroidSurgery -BaseUrl $server.BaseUrl -ServerName $server.Name
            $jointReplacementCount = Test-JointReplacementSurgery -BaseUrl $server.BaseUrl -ServerName $server.Name
            
            $summary.JointRepairCount += $jointRepairCount
            $summary.ThyroidSurgeryCount += $thyroidCount
            $summary.JointReplacementCount += $jointReplacementCount
            
            $totalCleanSurgeries = $jointRepairCount + $thyroidCount + $jointReplacementCount
            $summary.TotalCleanSurgeries += $totalCleanSurgeries
            
            # Test exclusion criteria
            $exclusions = Test-ExclusionCriteria -BaseUrl $server.BaseUrl -ServerName $server.Name
            
            # Test antibiotic tracking
            $antibiotics = Test-AntibioticTracking -BaseUrl $server.BaseUrl -ServerName $server.Name
            $summary.TotalAntibioticOver3Days += $antibiotics.Over3Days
            
            # Calculate rate
            $rate = if ($totalCleanSurgeries -gt 0) {
                [math]::Round(($antibiotics.Over3Days / $totalCleanSurgeries) * 100, 2)
            } else {
                0
            }
            
            # Store result
            $result = [PSCustomObject]@{
                ServerName = $server.Name
                ServerUrl = $server.BaseUrl
                Patients = $patientCount
                JointRepair = $jointRepairCount
                ThyroidSurgery = $thyroidCount
                JointReplacement = $jointReplacementCount
                TotalCleanSurgeries = $totalCleanSurgeries
                AntibioticOver3Days = $antibiotics.Over3Days
                Rate = $rate
                Status = "Success"
            }
            $allResults += $result
            
            Write-Host ""
            Write-Host "  Server Summary:" -ForegroundColor Yellow
            Write-Host "    Total Clean Surgeries: $totalCleanSurgeries" -ForegroundColor White
            Write-Host "    Antibiotic Over 3 Days: $($antibiotics.Over3Days)" -ForegroundColor White
            Write-Host ("    Rate: {0:N2}%" -f $rate) -ForegroundColor $(if($rate -lt 8.0){"Green"}else{"Yellow"})
            Write-Host "    Status: SUCCESS" -ForegroundColor Green
        }
        else {
            Write-Host "    No patients found or server unavailable" -ForegroundColor Red
            $result = [PSCustomObject]@{
                ServerName = $server.Name
                ServerUrl = $server.BaseUrl
                Status = "Failed - No Data"
            }
            $allResults += $result
        }
    }
    catch {
        Write-Host "    Server test failed: $($_.Exception.Message)" -ForegroundColor Red
        $result = [PSCustomObject]@{
            ServerName = $server.Name
            ServerUrl = $server.BaseUrl
            Status = "Failed - Error"
            ErrorMessage = $_.Exception.Message
        }
        $allResults += $result
    }
    
    if ($serverSuccess) {
        $summary.SuccessfulServers++
    }
    else {
        $summary.FailedServers++
    }
}

# Final Summary
Write-Host ""
Write-Host ""
Write-Host ("=" * 100) -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 100) -ForegroundColor Cyan
Write-Host ""

Write-Host "Server Statistics:" -ForegroundColor Yellow
Write-Host ("  Total Servers Tested: {0}" -f $summary.TotalServers) -ForegroundColor White
Write-Host ("  Successful Servers: {0}" -f $summary.SuccessfulServers) -ForegroundColor Green
Write-Host ("  Failed Servers: {0}" -f $summary.FailedServers) -ForegroundColor $(if($summary.FailedServers -gt 0){"Red"}else{"Gray"})
Write-Host ""

Write-Host "Data Statistics:" -ForegroundColor Yellow
Write-Host ("  Total Patients: {0}" -f $summary.TotalPatients) -ForegroundColor White
Write-Host ("  Total Clean Surgeries: {0}" -f $summary.TotalCleanSurgeries) -ForegroundColor White
Write-Host ("    - Joint Repair: {0}" -f $summary.JointRepairCount) -ForegroundColor Gray
Write-Host ("    - Thyroid Surgery: {0}" -f $summary.ThyroidSurgeryCount) -ForegroundColor Gray
Write-Host ("    - Joint Replacement: {0}" -f $summary.JointReplacementCount) -ForegroundColor Gray
Write-Host ("  Antibiotic Over 3 Days: {0}" -f $summary.TotalAntibioticOver3Days) -ForegroundColor White
Write-Host ""

$overallRate = if ($summary.TotalCleanSurgeries -gt 0) {
    [math]::Round(($summary.TotalAntibioticOver3Days / $summary.TotalCleanSurgeries) * 100, 2)
} else {
    0
}

Write-Host "Overall Indicator Performance:" -ForegroundColor Yellow
Write-Host ("  Overall Rate: {0:N2}%" -f $overallRate) -ForegroundColor $(if($overallRate -lt 8.0){"Green"}else{"Yellow"})
Write-Host ("  Target: Less than 8.0%") -ForegroundColor Gray
Write-Host ("  Status: {0}" -f $(if($overallRate -lt 8.0){"WITHIN TARGET"}else{"ABOVE TARGET"})) -ForegroundColor $(if($overallRate -lt 8.0){"Green"}else{"Yellow"})
Write-Host ""

# Export results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = "test_indicator29_results_$timestamp.csv"
$allResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Test results exported to: $csvPath" -ForegroundColor Green
Write-Host ""

Write-Host ("=" * 100) -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host ("=" * 100) -ForegroundColor Cyan
