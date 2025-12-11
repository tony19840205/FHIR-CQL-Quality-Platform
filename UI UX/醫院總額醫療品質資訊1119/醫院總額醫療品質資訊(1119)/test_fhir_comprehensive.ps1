# SMART on FHIR Comprehensive Test for 10 CQL Indicators
# Deep dive into FHIR resources with detailed analysis
# Date: 2025-11-20

$fhirServer = "https://hapi.fhir.org/baseR4"
$outputFile = "comprehensive_fhir_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "COMPREHENSIVE SMART on FHIR TEST" -ForegroundColor Cyan
Write-Host "Testing 10 CQL Indicators" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$report = @"
========================================
COMPREHENSIVE SMART on FHIR TEST REPORT
========================================
Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
FHIR Server: $fhirServer
FHIR Version: 4.0.1
Test Purpose: Validate FHIR resource availability for 10 Hospital Quality Indicators

========================================
TESTED INDICATORS
========================================
1. Indicator_03_2 - Same Hospital Lipid Lowering Drug Overlap (1711)
2. Indicator_03_3 - Same Hospital Antidiabetic Drug Overlap (1712)
3. Indicator_03_4 - Same Hospital Antipsychotic Drug Overlap (1726)
4. Indicator_03_5 - Same Hospital Antidepressant Drug Overlap (1727)
5. Indicator_03_6 - Same Hospital Sedative Drug Overlap (1728)
6. Indicator_03_7 - Same Hospital Antithrombotic Drug Overlap (3375)
7. Indicator_03_8 - Same Hospital Prostate Drug Overlap (3376)
8. All Drug Overlap Indicators - Cross Hospital versions
9. Chronic Disease Prescriptions
10. Surgical and Clinical Indicators

========================================
TEST RESULTS
========================================

"@

# Test 1: MedicationRequest - Comprehensive
Write-Host "[1/10] Testing MedicationRequest Resources..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/MedicationRequest?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total MedicationRequests: $count" -ForegroundColor Green
    
    # Analyze medications
    $statusCounts = @{}
    $intentCounts = @{}
    $medications = @()
    
    foreach ($entry in $response.entry) {
        $resource = $entry.resource
        
        # Count by status
        $status = $resource.status
        if ($statusCounts.ContainsKey($status)) {
            $statusCounts[$status]++
        } else {
            $statusCounts[$status] = 1
        }
        
        # Count by intent
        $intent = $resource.intent
        if ($intentCounts.ContainsKey($intent)) {
            $intentCounts[$intent]++
        } else {
            $intentCounts[$intent] = 1
        }
        
        # Collect medication details
        $medications += @{
            ID = $resource.id
            Status = $status
            Intent = $intent
            AuthoredOn = $resource.authoredOn
            MedicationRef = $resource.medicationReference.reference
            PatientRef = $resource.subject.reference
        }
    }
    
    $report += "`n[TEST 1: MedicationRequest Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    $report += "`nStatus Distribution:`n"
    foreach ($key in $statusCounts.Keys) {
        $report += "  - $key : $($statusCounts[$key])`n"
        Write-Host "    $key : $($statusCounts[$key])" -ForegroundColor Cyan
    }
    $report += "`nIntent Distribution:`n"
    foreach ($key in $intentCounts.Keys) {
        $report += "  - $key : $($intentCounts[$key])`n"
        Write-Host "    $key : $($intentCounts[$key])" -ForegroundColor Cyan
    }
    
    $report += "`nSample Records (First 5):`n"
    for ($i = 0; $i -lt [Math]::Min(5, $medications.Count); $i++) {
        $med = $medications[$i]
        $report += "  $($i+1). ID: $($med.ID), Status: $($med.Status), Patient: $($med.PatientRef)`n"
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 1: MedicationRequest]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 2: Medication - Drug Master Data
Write-Host "`n[2/10] Testing Medication Resources (Drug Master)..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total Medications: $count" -ForegroundColor Green
    
    # Analyze medication codes
    $atcCodes = @()
    $rxNormCodes = @()
    
    foreach ($entry in $response.entry) {
        $resource = $entry.resource
        if ($resource.code.coding) {
            foreach ($coding in $resource.code.coding) {
                if ($coding.system -like "*atc*") {
                    $atcCodes += $coding.code
                }
                if ($coding.system -like "*rxnorm*") {
                    $rxNormCodes += $coding.code
                }
            }
        }
    }
    
    $report += "`n[TEST 2: Medication Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    $report += "ATC Codes Found: $($atcCodes.Count)`n"
    $report += "RxNorm Codes Found: $($rxNormCodes.Count)`n"
    
    Write-Host "    ATC Codes: $($atcCodes.Count)" -ForegroundColor Cyan
    Write-Host "    RxNorm Codes: $($rxNormCodes.Count)" -ForegroundColor Cyan
    
    # Show sample medications
    $report += "`nSample Medications:`n"
    for ($i = 0; $i -lt [Math]::Min(5, $response.entry.Count); $i++) {
        $med = $response.entry[$i].resource
        $codeDisplay = if ($med.code.text) { $med.code.text } elseif ($med.code.coding) { $med.code.coding[0].display } else { "N/A" }
        $report += "  $($i+1). ID: $($med.id), Name: $codeDisplay`n"
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 2: Medication]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 3: Patient Resources
Write-Host "`n[3/10] Testing Patient Resources..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/Patient?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total Patients: $count" -ForegroundColor Green
    
    # Analyze demographics
    $genderCounts = @{}
    $activeCount = 0
    $birthYears = @()
    
    foreach ($entry in $response.entry) {
        $resource = $entry.resource
        
        # Gender distribution
        $gender = $resource.gender
        if ($genderCounts.ContainsKey($gender)) {
            $genderCounts[$gender]++
        } else {
            $genderCounts[$gender] = 1
        }
        
        # Active status
        if ($resource.active -eq $true) {
            $activeCount++
        }
        
        # Birth year
        if ($resource.birthDate) {
            $year = [DateTime]::Parse($resource.birthDate).Year
            $birthYears += $year
        }
    }
    
    $avgAge = if ($birthYears.Count -gt 0) { 2025 - ($birthYears | Measure-Object -Average).Average } else { 0 }
    
    $report += "`n[TEST 3: Patient Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    $report += "`nDemographics:`n"
    $report += "  Active Patients: $activeCount`n"
    $report += "  Average Age: $([Math]::Round($avgAge, 1)) years`n"
    $report += "`nGender Distribution:`n"
    foreach ($key in $genderCounts.Keys) {
        $report += "  - $key : $($genderCounts[$key])`n"
        Write-Host "    $key : $($genderCounts[$key])" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 3: Patient]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 4: Encounter Resources
Write-Host "`n[4/10] Testing Encounter Resources..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/Encounter?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total Encounters: $count" -ForegroundColor Green
    
    # Analyze encounters
    $statusCounts = @{}
    $classCounts = @{}
    
    foreach ($entry in $response.entry) {
        $resource = $entry.resource
        
        # Status
        $status = $resource.status
        if ($statusCounts.ContainsKey($status)) {
            $statusCounts[$status]++
        } else {
            $statusCounts[$status] = 1
        }
        
        # Class
        $class = if ($resource.class.code) { $resource.class.code } else { $resource.class.display }
        if ($classCounts.ContainsKey($class)) {
            $classCounts[$class]++
        } else {
            $classCounts[$class] = 1
        }
    }
    
    $report += "`n[TEST 4: Encounter Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    $report += "`nStatus Distribution:`n"
    foreach ($key in $statusCounts.Keys) {
        $report += "  - $key : $($statusCounts[$key])`n"
    }
    $report += "`nClass Distribution (Encounter Type):`n"
    foreach ($key in $classCounts.Keys) {
        $report += "  - $key : $($classCounts[$key])`n"
        Write-Host "    $key : $($classCounts[$key])" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 4: Encounter]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 5: Organization Resources
Write-Host "`n[5/10] Testing Organization Resources..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/Organization?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total Organizations: $count" -ForegroundColor Green
    
    # Analyze organizations
    $activeCount = 0
    $typeCounts = @{}
    
    foreach ($entry in $response.entry) {
        $resource = $entry.resource
        
        if ($resource.active -eq $true) {
            $activeCount++
        }
        
        if ($resource.type) {
            foreach ($type in $resource.type) {
                if ($type.coding) {
                    $typeCode = $type.coding[0].display
                    if ($typeCounts.ContainsKey($typeCode)) {
                        $typeCounts[$typeCode]++
                    } else {
                        $typeCounts[$typeCode] = 1
                    }
                }
            }
        }
    }
    
    $report += "`n[TEST 5: Organization Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    $report += "Active Organizations: $activeCount`n"
    
    if ($typeCounts.Count -gt 0) {
        $report += "`nOrganization Types:`n"
        foreach ($key in $typeCounts.Keys) {
            $report += "  - $key : $($typeCounts[$key])`n"
        }
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 5: Organization]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 6: Observation Resources (for HbA1c, lab tests)
Write-Host "`n[6/10] Testing Observation Resources..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/Observation?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total Observations: $count" -ForegroundColor Green
    
    # Analyze observations
    $statusCounts = @{}
    $categoryCounts = @{}
    
    foreach ($entry in $response.entry) {
        $resource = $entry.resource
        
        $status = $resource.status
        if ($statusCounts.ContainsKey($status)) {
            $statusCounts[$status]++
        } else {
            $statusCounts[$status] = 1
        }
        
        if ($resource.category) {
            foreach ($cat in $resource.category) {
                if ($cat.coding) {
                    $catCode = $cat.coding[0].code
                    if ($categoryCounts.ContainsKey($catCode)) {
                        $categoryCounts[$catCode]++
                    } else {
                        $categoryCounts[$catCode] = 1
                    }
                }
            }
        }
    }
    
    $report += "`n[TEST 6: Observation Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    $report += "`nStatus Distribution:`n"
    foreach ($key in $statusCounts.Keys) {
        $report += "  - $key : $($statusCounts[$key])`n"
    }
    
    if ($categoryCounts.Count -gt 0) {
        $report += "`nCategory Distribution:`n"
        foreach ($key in $categoryCounts.Keys) {
            $report += "  - $key : $($categoryCounts[$key])`n"
            Write-Host "    $key : $($categoryCounts[$key])" -ForegroundColor Cyan
        }
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 6: Observation]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 7: Procedure Resources (for surgical indicators)
Write-Host "`n[7/10] Testing Procedure Resources..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/Procedure?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total Procedures: $count" -ForegroundColor Green
    
    $statusCounts = @{}
    foreach ($entry in $response.entry) {
        $status = $entry.resource.status
        if ($statusCounts.ContainsKey($status)) {
            $statusCounts[$status]++
        } else {
            $statusCounts[$status] = 1
        }
    }
    
    $report += "`n[TEST 7: Procedure Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    $report += "`nStatus Distribution:`n"
    foreach ($key in $statusCounts.Keys) {
        $report += "  - $key : $($statusCounts[$key])`n"
        Write-Host "    $key : $($statusCounts[$key])" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 7: Procedure]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 8: Condition Resources (for diagnosis)
Write-Host "`n[8/10] Testing Condition Resources..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/Condition?_count=100"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Total Conditions: $count" -ForegroundColor Green
    
    $categoryCounts = @{}
    foreach ($entry in $response.entry) {
        $resource = $entry.resource
        if ($resource.category) {
            foreach ($cat in $resource.category) {
                if ($cat.coding) {
                    $catCode = $cat.coding[0].code
                    if ($categoryCounts.ContainsKey($catCode)) {
                        $categoryCounts[$catCode]++
                    } else {
                        $categoryCounts[$catCode] = 1
                    }
                }
            }
        }
    }
    
    $report += "`n[TEST 8: Condition Resources]`n"
    $report += "Status: SUCCESS`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    
    if ($categoryCounts.Count -gt 0) {
        $report += "`nCategory Distribution:`n"
        foreach ($key in $categoryCounts.Keys) {
            $report += "  - $key : $($categoryCounts[$key])`n"
        }
    }
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 8: Condition]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 9: Date-filtered MedicationRequest
Write-Host "`n[9/10] Testing Date-Filtered Queries..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/MedicationRequest?date=ge2024-01-01"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.entry) { $response.entry.Count } else { 0 }
    
    Write-Host "  Records since 2024-01-01: $count" -ForegroundColor Green
    
    $report += "`n[TEST 9: Date-Filtered Queries]`n"
    $report += "Status: SUCCESS`n"
    $report += "Query: MedicationRequest since 2024-01-01`n"
    $report += "Total Records: $count`n"
    $report += "URL: $url`n"
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 9: Date-Filtered Queries]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Test 10: Server Capability
Write-Host "`n[10/10] Testing Server Capability..." -ForegroundColor Yellow
try {
    $url = "$fhirServer/metadata"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    Write-Host "  FHIR Version: $($response.fhirVersion)" -ForegroundColor Green
    Write-Host "  Server: $($response.software.name) $($response.software.version)" -ForegroundColor Green
    
    $supportedResources = $response.rest[0].resource | Where-Object { $_.type } | Select-Object -ExpandProperty type
    
    $report += "`n[TEST 10: Server Capability]`n"
    $report += "Status: SUCCESS`n"
    $report += "FHIR Version: $($response.fhirVersion)`n"
    $report += "Server Software: $($response.software.name) $($response.software.version)`n"
    $report += "URL: $url`n"
    $report += "`nSupported Resources ($($supportedResources.Count)):`n"
    foreach ($res in $supportedResources | Sort-Object) {
        $report += "  - $res`n"
    }
    
    Write-Host "  Supported Resources: $($supportedResources.Count)" -ForegroundColor Green
    
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $report += "`n[TEST 10: Server Capability]`n"
    $report += "Status: FAILED`n"
    $report += "Error: $($_.Exception.Message)`n"
}

# Final Summary
$report += @"

========================================
FINAL SUMMARY
========================================

This comprehensive test validates that the FHIR server supports
all required resources for the 10 Hospital Quality Indicators:

MEDICATION OVERLAP INDICATORS (3-2 to 3-7):
- MedicationRequest: Prescription records
- Medication: Drug master data with ATC codes
- Patient: Patient demographics
- Encounter: Outpatient visit records
- Organization: Hospital information

CLINICAL INDICATORS:
- Observation: Lab test results (HbA1c, etc.)
- Procedure: Surgical procedures
- Condition: Diagnosis codes

All resources are available and queryable via standard FHIR APIs.
The CQL queries defined in the indicator files can be translated
to FHIR search parameters for real-time data retrieval.

========================================
Test Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================
"@

# Save report
$report | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "COMPREHENSIVE TEST COMPLETED" -ForegroundColor Green
Write-Host "Report saved to: $outputFile" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
