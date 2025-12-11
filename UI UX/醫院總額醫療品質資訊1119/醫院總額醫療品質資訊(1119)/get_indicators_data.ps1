# Hospital Quality Indicators Data Query
# Indicator 01: Outpatient Injection Usage Rate (3127)
# Indicator 02: Outpatient Antibiotic Usage Rate (1140.01)
# Data Period: 2024-01-01 to 2025-11-20

$fhirServer = "https://hapi.fhir.org/baseR4"
$outputFile = "Indicators_Data_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Hospital Quality Indicators Data Query" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Define quarters
$quarters = @(
    @{ Q = "2024Q1"; Start = "2024-01-01"; End = "2024-03-31" }
    @{ Q = "2024Q2"; Start = "2024-04-01"; End = "2024-06-30" }
    @{ Q = "2024Q3"; Start = "2024-07-01"; End = "2024-09-30" }
    @{ Q = "2024Q4"; Start = "2024-10-01"; End = "2024-12-31" }
    @{ Q = "2025Q1"; Start = "2025-01-01"; End = "2025-03-31" }
    @{ Q = "2025Q2"; Start = "2025-04-01"; End = "2025-06-30" }
    @{ Q = "2025Q3"; Start = "2025-07-01"; End = "2025-09-30" }
    @{ Q = "2025Q4"; Start = "2025-10-01"; End = "2025-11-20" }
)

$report = @"
========================================
HOSPITAL QUALITY INDICATORS DATA REPORT
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Data Period: 2024-01-01 to 2025-11-20
FHIR Server: $fhirServer

========================================
INDICATOR 01: OUTPATIENT INJECTION USAGE RATE (3127)
========================================

Definition:
  Numerator: Number of injection drug cases (drug code 10 digits, 8th digit = '2')
  Denominator: Total drug dispensing cases
  Baseline: 0.94% (2022Q1: 54,653 / 5,831,409)

Quarterly Data:
----------------------------------------

"@

$totalInjections = 0
$totalMedications = 0

Write-Host "[INDICATOR 01] Outpatient Injection Usage Rate" -ForegroundColor Yellow

foreach ($q in $quarters) {
    Write-Host "  Querying $($q.Q)..." -ForegroundColor Cyan
    
    try {
        $url = "$fhirServer/MedicationRequest?date=ge$($q.Start)`&date=le$($q.End)`&_count=100"
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        $total = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
        
        # Count injections
        $injections = 0
        if ($response.entry) {
            foreach ($entry in $response.entry) {
                if ($entry.resource.dosageInstruction) {
                    foreach ($dosage in $entry.resource.dosageInstruction) {
                        if ($dosage.route.coding) {
                            foreach ($coding in $dosage.route.coding) {
                                if ($coding.code -match "inject|INJ|IM|IV|SC") {
                                    $injections++
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        
        $rate = if ($total -gt 0) { [Math]::Round(($injections / $total) * 100, 2) } else { 0 }
        
        $totalInjections += $injections
        $totalMedications += $total
        
        $report += "Quarter: $($q.Q) ($($q.Start) to $($q.End))`n"
        $report += "  Injection Cases: $injections`n"
        $report += "  Total Cases: $total`n"
        $report += "  Usage Rate: $rate%`n`n"
        
        Write-Host "    Injections: $injections, Total: $total, Rate: $rate%" -ForegroundColor Green
        
    } catch {
        $report += "Quarter: $($q.Q) - Query Failed: $($_.Exception.Message)`n`n"
        Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

$avgRate01 = if ($totalMedications -gt 0) { [Math]::Round(($totalInjections / $totalMedications) * 100, 2) } else { 0 }
$baselineComp = [Math]::Round($avgRate01 - 0.94, 2)

$report += @"
Summary for Indicator 01:
----------------------------------------
Total Injection Cases: $totalInjections
Total Medication Cases: $totalMedications
Average Usage Rate: $avgRate01%
vs Baseline (0.94%): $baselineComp%
Assessment: $(if($avgRate01 -le 0.94){'GOOD - Below baseline'}elseif($avgRate01 -le 1.5){'OK - Near baseline'}else{'ATTENTION - Above baseline'})


"@

Write-Host "`nIndicator 01 Summary:" -ForegroundColor Yellow
Write-Host "  Total Injections: $totalInjections" -ForegroundColor Cyan
Write-Host "  Total Medications: $totalMedications" -ForegroundColor Cyan
Write-Host "  Average Rate: $avgRate01%" -ForegroundColor Cyan
Write-Host "  vs Baseline: $baselineComp%" -ForegroundColor $(if($avgRate01 -le 0.94){'Green'}else{'Yellow'})

# ========================================
# INDICATOR 02
# ========================================

$report += @"
========================================
INDICATOR 02: OUTPATIENT ANTIBIOTIC USAGE RATE (1140.01)
========================================

Definition:
  Numerator: Number of antibiotic prescription cases (ATC code J01*)
  Denominator: Total outpatient cases
  ATC Code: J01 (Systemic antibiotics)

Quarterly Data:
----------------------------------------

"@

$totalAntibiotics = 0
$totalEncounters = 0

Write-Host "`n[INDICATOR 02] Outpatient Antibiotic Usage Rate" -ForegroundColor Yellow

foreach ($q in $quarters) {
    Write-Host "  Querying $($q.Q)..." -ForegroundColor Cyan
    
    try {
        # Query encounters
        $encUrl = "$fhirServer/Encounter?date=ge$($q.Start)`&date=le$($q.End)`&class=AMB`&_count=100"
        $encResponse = Invoke-RestMethod -Uri $encUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        $encounters = if ($encResponse.total) { $encResponse.total } elseif ($encResponse.entry) { $encResponse.entry.Count } else { 0 }
        
        # Query medications
        $medUrl = "$fhirServer/MedicationRequest?date=ge$($q.Start)`&date=le$($q.End)`&_count=100"
        $medResponse = Invoke-RestMethod -Uri $medUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        # Count antibiotics
        $antibiotics = 0
        if ($medResponse.entry) {
            foreach ($entry in $medResponse.entry) {
                if ($entry.resource.medicationCodeableConcept.coding) {
                    foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                        if (($coding.system -like "*atc*" -and $coding.code -like "J01*") -or
                            ($coding.display -match "antibiotic|penicillin|cephalosporin|quinolone")) {
                            $antibiotics++
                            break
                        }
                    }
                }
            }
        }
        
        $rate = if ($encounters -gt 0) { [Math]::Round(($antibiotics / $encounters) * 100, 2) } else { 0 }
        
        $totalAntibiotics += $antibiotics
        $totalEncounters += $encounters
        
        $report += "Quarter: $($q.Q) ($($q.Start) to $($q.End))`n"
        $report += "  Antibiotic Cases: $antibiotics`n"
        $report += "  Total Encounters: $encounters`n"
        $report += "  Usage Rate: $rate%`n`n"
        
        Write-Host "    Antibiotics: $antibiotics, Encounters: $encounters, Rate: $rate%" -ForegroundColor Green
        
    } catch {
        $report += "Quarter: $($q.Q) - Query Failed: $($_.Exception.Message)`n`n"
        Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

$avgRate02 = if ($totalEncounters -gt 0) { [Math]::Round(($totalAntibiotics / $totalEncounters) * 100, 2) } else { 0 }

$report += @"
Summary for Indicator 02:
----------------------------------------
Total Antibiotic Cases: $totalAntibiotics
Total Encounters: $totalEncounters
Average Usage Rate: $avgRate02%


"@

Write-Host "`nIndicator 02 Summary:" -ForegroundColor Yellow
Write-Host "  Total Antibiotics: $totalAntibiotics" -ForegroundColor Cyan
Write-Host "  Total Encounters: $totalEncounters" -ForegroundColor Cyan
Write-Host "  Average Rate: $avgRate02%" -ForegroundColor Cyan

# ========================================
# COMPARISON TABLE
# ========================================

$report += @"
========================================
COMPARISON TABLE
========================================

Indicator 01 vs Indicator 02:

| Metric                    | Indicator 01 | Indicator 02 |
|---------------------------|--------------|--------------|
| Total Target Cases        | $totalInjections      | $totalAntibiotics      |
| Total Base Cases          | $totalMedications      | $totalEncounters      |
| Average Usage Rate        | $avgRate01%        | $avgRate02%        |
| Baseline Comparison       | $baselineComp%       | N/A          |


========================================
DATA SOURCE INFORMATION
========================================

FHIR Resources Used:
- MedicationRequest: Prescription records
- Encounter: Visit records
- Medication: Drug master data

Filter Criteria:
- Indicator 01: Route of administration contains injection codes
- Indicator 02: Medication code ATC = J01* (antibiotics)

SNOMED CT Codes:
- 385219001: Injection
- 385221006: Ampoule
- 415818006: Vial

ATC Codes:
- J01: Systemic antibiotics

Data Quality Notes:
- Data from public FHIR test server (HAPI FHIR)
- Actual clinical data may differ
- Recommend connecting to hospital FHIR server for real data


========================================
REPORT END
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

# Save report
$report | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Report saved to: $outputFile" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

# Display summary
Write-Host "FINAL SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 01 - Injection Usage Rate:" -ForegroundColor Yellow
Write-Host "  Average: $avgRate01% (Baseline: 0.94%)" -ForegroundColor White
Write-Host "Indicator 02 - Antibiotic Usage Rate:" -ForegroundColor Yellow
Write-Host "  Average: $avgRate02%" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan
