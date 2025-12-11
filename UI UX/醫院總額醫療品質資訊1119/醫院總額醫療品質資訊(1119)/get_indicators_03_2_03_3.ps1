# Hospital Quality Indicators Data Query
# Indicator 03-2: Same Hospital Lipid-Lowering Drug Overlap Rate (1711)
# Indicator 03-3: Same Hospital Antidiabetic Drug Overlap Rate (1712)
# Data Period: 2024-01-01 to 2025-11-20

$fhirServer = "https://hapi.fhir.org/baseR4"
$outputFile = "Indicators_03_2_03_3_Data_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Drug Overlap Rate Indicators Query" -ForegroundColor Cyan
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
DRUG OVERLAP RATE INDICATORS REPORT
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Data Period: 2024-01-01 to 2025-11-20
FHIR Server: $fhirServer

========================================
INDICATOR 03-2: LIPID-LOWERING DRUG OVERLAP (1711)
========================================

Definition:
  ATC Code: C10 (Lipid modifying agents)
  Category: Same hospital, same patient, different prescriptions
  Calculation: Overlapping medication days / Total medication days

ATC C10 Subcategories:
  - C10AA: HMG CoA reductase inhibitors (Statins)
  - C10AB: Fibrates
  - C10AC: Bile acid sequestrants
  - C10AD: Nicotinic acid derivatives
  - C10AX: Other lipid modifying agents
  - C10BA: Statins + other combinations
  - C10BX: Various combinations

Quarterly Data:
----------------------------------------

"@

$totalLipidMeds = 0
$lipidPatients = @{}

Write-Host "[INDICATOR 03-2] Lipid-Lowering Drug Overlap Rate" -ForegroundColor Yellow

foreach ($q in $quarters) {
    Write-Host "  Querying $($q.Q)..." -ForegroundColor Cyan
    
    try {
        # Query medications with C10 ATC code
        $url = "$fhirServer/MedicationRequest?date=ge$($q.Start)`&date=le$($q.End)`&_count=100"
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        $total = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
        
        # Count lipid-lowering medications (C10)
        $lipidMeds = 0
        $patients = @()
        
        if ($response.entry) {
            foreach ($entry in $response.entry) {
                $hasC10 = $false
                
                # Check medication code
                if ($entry.resource.medicationCodeableConcept.coding) {
                    foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                        if (($coding.system -like "*atc*" -and $coding.code -like "C10*") -or
                            ($coding.display -match "statin|atorvastatin|simvastatin|rosuvastatin|pravastatin|lovastatin|fluvastatin|fibrate|fenofibrate|gemfibrozil|ezetimibe")) {
                            $hasC10 = $true
                            break
                        }
                    }
                }
                
                if ($hasC10) {
                    $lipidMeds++
                    if ($entry.resource.subject.reference) {
                        $patientId = $entry.resource.subject.reference -replace "Patient/", ""
                        if ($patientId -notin $patients) {
                            $patients += $patientId
                        }
                    }
                }
            }
        }
        
        $rate = if ($total -gt 0) { [Math]::Round(($lipidMeds / $total) * 100, 2) } else { 0 }
        
        $totalLipidMeds += $lipidMeds
        foreach ($p in $patients) {
            if (-not $lipidPatients.ContainsKey($p)) {
                $lipidPatients[$p] = 1
            }
        }
        
        $report += "Quarter: $($q.Q) ($($q.Start) to $($q.End))`n"
        $report += "  Lipid-Lowering Medications: $lipidMeds`n"
        $report += "  Total Medications Queried: $total`n"
        $report += "  Unique Patients: $($patients.Count)`n"
        $report += "  Detection Rate: $rate%`n`n"
        
        Write-Host "    Lipid Meds: $lipidMeds, Total: $total, Patients: $($patients.Count), Rate: $rate%" -ForegroundColor Green
        
    } catch {
        $report += "Quarter: $($q.Q) - Query Failed: $($_.Exception.Message)`n`n"
        Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

$avgRateLipid = if ($totalLipidMeds -gt 0) { [Math]::Round($totalLipidMeds / 8, 2) } else { 0 }
$uniquePatientsLipid = $lipidPatients.Count

$report += @"
Summary for Indicator 03-2:
----------------------------------------
Total Lipid-Lowering Medications Found: $totalLipidMeds
Unique Patients: $uniquePatientsLipid
Average per Quarter: $avgRateLipid
Assessment: Data collected for overlap analysis

Note: Overlap calculation requires same patient, same hospital,
      different prescriptions with overlapping date ranges.
      Test server has limited patient linkage data.


"@

Write-Host "`nIndicator 03-2 Summary:" -ForegroundColor Yellow
Write-Host "  Total Lipid Medications: $totalLipidMeds" -ForegroundColor Cyan
Write-Host "  Unique Patients: $uniquePatientsLipid" -ForegroundColor Cyan
Write-Host "  Average per Quarter: $avgRateLipid" -ForegroundColor Cyan

# ========================================
# INDICATOR 03-3
# ========================================

$report += @"
========================================
INDICATOR 03-3: ANTIDIABETIC DRUG OVERLAP (1712)
========================================

Definition:
  ATC Code: A10 (Drugs used in diabetes)
  Category: Same hospital, same patient, different prescriptions
  Calculation: Overlapping medication days / Total medication days

ATC A10 Subcategories:
  - A10A: Insulins and analogues
  - A10B: Blood glucose lowering drugs (oral)
    * A10BA: Biguanides (Metformin)
    * A10BB: Sulfonylureas
    * A10BD: Combinations
    * A10BG: Thiazolidinediones
    * A10BH: DPP-4 inhibitors
    * A10BJ: GLP-1 agonists
    * A10BK: SGLT2 inhibitors
    * A10BX: Other oral agents

Quarterly Data:
----------------------------------------

"@

$totalDiabetesMeds = 0
$diabetesPatients = @{}

Write-Host "`n[INDICATOR 03-3] Antidiabetic Drug Overlap Rate" -ForegroundColor Yellow

foreach ($q in $quarters) {
    Write-Host "  Querying $($q.Q)..." -ForegroundColor Cyan
    
    try {
        # Query medications with A10 ATC code
        $url = "$fhirServer/MedicationRequest?date=ge$($q.Start)`&date=le$($q.End)`&_count=100"
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        $total = if ($response.total) { $response.total } elseif ($response.entry) { $response.entry.Count } else { 0 }
        
        # Count antidiabetic medications (A10)
        $diabetesMeds = 0
        $patients = @()
        
        if ($response.entry) {
            foreach ($entry in $response.entry) {
                $hasA10 = $false
                
                # Check medication code
                if ($entry.resource.medicationCodeableConcept.coding) {
                    foreach ($coding in $entry.resource.medicationCodeableConcept.coding) {
                        if (($coding.system -like "*atc*" -and $coding.code -like "A10*") -or
                            ($coding.display -match "insulin|metformin|glipizide|glyburide|glimepiride|pioglitazone|rosiglitazone|sitagliptin|saxagliptin|linagliptin|liraglutide|exenatide|dulaglutide|canagliflozin|dapagliflozin|empagliflozin")) {
                            $hasA10 = $true
                            break
                        }
                    }
                }
                
                if ($hasA10) {
                    $diabetesMeds++
                    if ($entry.resource.subject.reference) {
                        $patientId = $entry.resource.subject.reference -replace "Patient/", ""
                        if ($patientId -notin $patients) {
                            $patients += $patientId
                        }
                    }
                }
            }
        }
        
        $rate = if ($total -gt 0) { [Math]::Round(($diabetesMeds / $total) * 100, 2) } else { 0 }
        
        $totalDiabetesMeds += $diabetesMeds
        foreach ($p in $patients) {
            if (-not $diabetesPatients.ContainsKey($p)) {
                $diabetesPatients[$p] = 1
            }
        }
        
        $report += "Quarter: $($q.Q) ($($q.Start) to $($q.End))`n"
        $report += "  Antidiabetic Medications: $diabetesMeds`n"
        $report += "  Total Medications Queried: $total`n"
        $report += "  Unique Patients: $($patients.Count)`n"
        $report += "  Detection Rate: $rate%`n`n"
        
        Write-Host "    Diabetes Meds: $diabetesMeds, Total: $total, Patients: $($patients.Count), Rate: $rate%" -ForegroundColor Green
        
    } catch {
        $report += "Quarter: $($q.Q) - Query Failed: $($_.Exception.Message)`n`n"
        Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

$avgRateDiabetes = if ($totalDiabetesMeds -gt 0) { [Math]::Round($totalDiabetesMeds / 8, 2) } else { 0 }
$uniquePatientsDiabetes = $diabetesPatients.Count

$report += @"
Summary for Indicator 03-3:
----------------------------------------
Total Antidiabetic Medications Found: $totalDiabetesMeds
Unique Patients: $uniquePatientsDiabetes
Average per Quarter: $avgRateDiabetes
Assessment: Data collected for overlap analysis

Note: Overlap calculation requires same patient, same hospital,
      different prescriptions with overlapping date ranges.
      Test server has limited patient linkage data.


"@

Write-Host "`nIndicator 03-3 Summary:" -ForegroundColor Yellow
Write-Host "  Total Diabetes Medications: $totalDiabetesMeds" -ForegroundColor Cyan
Write-Host "  Unique Patients: $uniquePatientsDiabetes" -ForegroundColor Cyan
Write-Host "  Average per Quarter: $avgRateDiabetes" -ForegroundColor Cyan

# ========================================
# COMPARISON TABLE
# ========================================

$report += @"
========================================
COMPARISON TABLE
========================================

Indicator 03-2 vs Indicator 03-3:

| Metric                    | Indicator 03-2 | Indicator 03-3 |
|---------------------------|----------------|----------------|
| ATC Code                  | C10            | A10            |
| Drug Category             | Lipid-Lowering | Antidiabetic   |
| Total Medications Found   | $totalLipidMeds           | $totalDiabetesMeds           |
| Unique Patients           | $uniquePatientsLipid           | $uniquePatientsDiabetes           |
| Average per Quarter       | $avgRateLipid          | $avgRateDiabetes          |


========================================
OVERLAP CALCULATION METHODOLOGY
========================================

For both indicators, the overlap rate is calculated as:

Numerator: Sum of overlapping medication days where:
  - Same hospital ID
  - Same patient ID
  - Different prescription IDs
  - Medication start/end dates overlap
  - Allow zero-day early refill

Denominator: Total medication days for all prescriptions

Formula:
  Overlap Rate (%) = (Overlapping Days / Total Days) x 100

Example:
  Prescription A: 2024-01-01 to 2024-01-30 (30 days)
  Prescription B: 2024-01-15 to 2024-02-14 (31 days)
  Overlap: 2024-01-15 to 2024-01-30 (16 days)
  Total Days: 30 + 31 = 61 days
  Overlap Rate: (16 / 61) x 100 = 26.23%


========================================
DATA QUALITY NOTES
========================================

Test Server Limitations:
1. Limited patient linkage across prescriptions
2. No hospital organization assignments
3. Medication dates may not reflect real patterns
4. ATC codes may be incomplete

For Production Use:
1. Connect to hospital FHIR server with real data
2. Ensure proper patient identifiers (MRN)
3. Verify organization IDs for hospital assignment
4. Validate ATC code mappings
5. Check medication dispense dates vs prescribed dates


========================================
FHIR RESOURCE QUERIES USED
========================================

Query 1: MedicationRequest with date filter
GET $fhirServer/MedicationRequest?
  date=ge{start_date}&
  date=le{end_date}&
  _count=100

Query 2: Filter by ATC Code (Post-processing)
- C10*: Lipid-lowering agents (Indicator 03-2)
- A10*: Antidiabetic drugs (Indicator 03-3)

Query 3: Extract Patient References
- MedicationRequest.subject.reference

Query 4: Calculate Overlaps (Requires)
- MedicationRequest.authoredOn (prescription date)
- MedicationRequest.dispenseRequest.validityPeriod
- MedicationRequest.dosageInstruction.timing


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

# Display final summary
Write-Host "FINAL SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 03-2 - Lipid-Lowering Drug Overlap:" -ForegroundColor Yellow
Write-Host "  Total Medications: $totalLipidMeds (ATC C10)" -ForegroundColor White
Write-Host "  Unique Patients: $uniquePatientsLipid" -ForegroundColor White
Write-Host "`nIndicator 03-3 - Antidiabetic Drug Overlap:" -ForegroundColor Yellow
Write-Host "  Total Medications: $totalDiabetesMeds (ATC A10)" -ForegroundColor White
Write-Host "  Unique Patients: $uniquePatientsDiabetes" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan
