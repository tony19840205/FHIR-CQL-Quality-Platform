# SMART on FHIR Simple Test
# Test 10 CQL Indicators with FHIR Resources
# Date: 2025-11-20

$fhirServer = "https://hapi.fhir.org/baseR4"
$outputFile = "fhir_test_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR Test Started" -ForegroundColor Cyan
Write-Host "Server: $fhirServer" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results = @()

# Test 1: MedicationRequest for Lipid Lowering (C10)
Write-Host "[1/10] Test: Lipid Lowering Drugs (C10)" -ForegroundColor Yellow
try {
    $url = "$fhirServer/MedicationRequest?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count MedicationRequest resources" -ForegroundColor Green
    $results += @{ Test = "MedicationRequest"; Status = "Success"; Count = $count; URL = $url }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "MedicationRequest"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 2: Medication Resources
Write-Host "`n[2/10] Test: Medication Resources" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Medication?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count Medication resources" -ForegroundColor Green
    $results += @{ Test = "Medication"; Status = "Success"; Count = $count; URL = $url }
    
    # Show sample
    if ($response.entry -and $response.entry.Count -gt 0) {
        $sample = $response.entry[0].resource
        Write-Host "  Sample Medication ID: $($sample.id)" -ForegroundColor Cyan
        if ($sample.code.coding) {
            Write-Host "  Sample Code: $($sample.code.coding[0].code) - $($sample.code.coding[0].display)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Medication"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 3: Patient Resources
Write-Host "`n[3/10] Test: Patient Resources" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Patient?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count Patient resources" -ForegroundColor Green
    $results += @{ Test = "Patient"; Status = "Success"; Count = $count; URL = $url }
    
    # Show sample
    if ($response.entry -and $response.entry.Count -gt 0) {
        $sample = $response.entry[0].resource
        Write-Host "  Sample Patient ID: $($sample.id)" -ForegroundColor Cyan
        Write-Host "  Gender: $($sample.gender), Birth: $($sample.birthDate)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Patient"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 4: Encounter Resources
Write-Host "`n[4/10] Test: Encounter Resources" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Encounter?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count Encounter resources" -ForegroundColor Green
    $results += @{ Test = "Encounter"; Status = "Success"; Count = $count; URL = $url }
    
    # Show sample
    if ($response.entry -and $response.entry.Count -gt 0) {
        $sample = $response.entry[0].resource
        Write-Host "  Sample Encounter ID: $($sample.id)" -ForegroundColor Cyan
        Write-Host "  Status: $($sample.status), Class: $($sample.class.code)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Encounter"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 5: Organization Resources
Write-Host "`n[5/10] Test: Organization Resources" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Organization?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count Organization resources" -ForegroundColor Green
    $results += @{ Test = "Organization"; Status = "Success"; Count = $count; URL = $url }
    
    # Show sample
    if ($response.entry -and $response.entry.Count -gt 0) {
        $sample = $response.entry[0].resource
        Write-Host "  Sample Organization ID: $($sample.id)" -ForegroundColor Cyan
        Write-Host "  Name: $($sample.name)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Organization"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 6: Search by Date - MedicationRequest
Write-Host "`n[6/10] Test: MedicationRequest with Date Filter" -ForegroundColor Yellow
try {
    $url = "$fhirServer/MedicationRequest?date=ge2024-01-01"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count MedicationRequest (date>=2024-01-01)" -ForegroundColor Green
    $results += @{ Test = "MedicationRequest (Date Filter)"; Status = "Success"; Count = $count; URL = $url }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "MedicationRequest (Date Filter)"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 7: Observation Resources (HbA1c for Diabetes indicator)
Write-Host "`n[7/10] Test: Observation Resources" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Observation?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count Observation resources" -ForegroundColor Green
    $results += @{ Test = "Observation"; Status = "Success"; Count = $count; URL = $url }
    
    # Show sample
    if ($response.entry -and $response.entry.Count -gt 0) {
        $sample = $response.entry[0].resource
        Write-Host "  Sample Observation ID: $($sample.id)" -ForegroundColor Cyan
        if ($sample.code.coding) {
            Write-Host "  Code: $($sample.code.coding[0].code) - $($sample.code.coding[0].display)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Observation"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 8: Procedure Resources (Surgery indicators)
Write-Host "`n[8/10] Test: Procedure Resources" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Procedure?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count Procedure resources" -ForegroundColor Green
    $results += @{ Test = "Procedure"; Status = "Success"; Count = $count; URL = $url }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Procedure"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 9: Condition Resources (Diagnosis)
Write-Host "`n[9/10] Test: Condition Resources" -ForegroundColor Yellow
try {
    $url = "$fhirServer/Condition?_count=50"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    $count = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
    Write-Host "  SUCCESS: Found $count Condition resources" -ForegroundColor Green
    $results += @{ Test = "Condition"; Status = "Success"; Count = $count; URL = $url }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Condition"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Test 10: Comprehensive Test - Get Server Metadata
Write-Host "`n[10/10] Test: Server Capability Statement" -ForegroundColor Yellow
try {
    $url = "$fhirServer/metadata"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    Write-Host "  SUCCESS: Server metadata retrieved" -ForegroundColor Green
    Write-Host "  FHIR Version: $($response.fhirVersion)" -ForegroundColor Cyan
    Write-Host "  Server Software: $($response.software.name) $($response.software.version)" -ForegroundColor Cyan
    $results += @{ Test = "Server Metadata"; Status = "Success"; FHIRVersion = $response.fhirVersion; URL = $url }
} catch {
    Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $results += @{ Test = "Server Metadata"; Status = "Failed"; Error = $_.Exception.Message; URL = $url }
}

# Generate Report
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
$failedCount = ($results | Where-Object { $_.Status -eq "Failed" }).Count
$totalCount = $results.Count

Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Passed: $successCount" -ForegroundColor Green
Write-Host "Failed: $failedCount" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round($successCount/$totalCount*100, 2))%" -ForegroundColor Yellow

$totalRecords = ($results | Where-Object { $_.Count } | Measure-Object -Property Count -Sum).Sum
Write-Host "Total Records Found: $totalRecords`n" -ForegroundColor Cyan

# Detailed Results
Write-Host "Detailed Results:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
foreach ($result in $results) {
    if ($result.Status -eq "Success") {
        Write-Host "[OK] $($result.Test): $($result.Count) records" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] $($result.Test): $($result.Error)" -ForegroundColor Red
    }
}

# Save Report
$report = @"
========================================
SMART on FHIR Test Report
========================================
Test Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
FHIR Server: $fhirServer
Total Tests: $totalCount
Passed: $successCount
Failed: $failedCount
Success Rate: $([math]::Round($successCount/$totalCount*100, 2))%
Total Records: $totalRecords

========================================
Detailed Results
========================================

"@

foreach ($result in $results) {
    $report += "`n[$($result.Test)]`n"
    $report += "Status: $($result.Status)`n"
    $report += "URL: $($result.URL)`n"
    if ($result.Status -eq "Success") {
        if ($result.Count) {
            $report += "Records Found: $($result.Count)`n"
        }
        if ($result.FHIRVersion) {
            $report += "FHIR Version: $($result.FHIRVersion)`n"
        }
    } else {
        $report += "Error: $($result.Error)`n"
    }
}

$report += @"

========================================
Test Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================
"@

$report | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Report saved to: $outputFile" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
