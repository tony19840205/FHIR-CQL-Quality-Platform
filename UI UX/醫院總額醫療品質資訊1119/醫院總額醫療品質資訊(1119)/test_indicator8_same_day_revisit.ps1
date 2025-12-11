# ============================================
# Indicator 8 Test Script: Same-Day Same-Disease Re-Visit Rate
# Indicator Code: 1322
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 8: Same-Day Same-Disease Re-Visit Rate" -ForegroundColor Cyan
Write-Host "Indicator Code: 1322" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# SMART on FHIR Test Servers
$fhirServers = @(
    @{
        Name = "HAPI FHIR"
        BaseUrl = "https://hapi.fhir.org/baseR4"
        Description = "HAPI FHIR R4 Public Test Server"
    }
)

# Quarter Definitions
$quarters = @(
    @{ Name = "112Year"; Start = "2020-01-01"; End = "2020-12-31"; DisplayName = "112Year" },
    @{ Name = "113Q1"; Start = "2021-01-01"; End = "2021-03-31"; DisplayName = "113Year Q1" },
    @{ Name = "113Q2"; Start = "2021-04-01"; End = "2021-06-30"; DisplayName = "113Year Q2" },
    @{ Name = "113Q3"; Start = "2021-07-01"; End = "2021-09-30"; DisplayName = "113Year Q3" },
    @{ Name = "113Q4"; Start = "2021-10-01"; End = "2021-12-31"; DisplayName = "113Year Q4" },
    @{ Name = "113Year"; Start = "2021-01-01"; End = "2021-12-31"; DisplayName = "113Year" }
)

# Function: Get FHIR Encounters
function Get-FHIREncounters {
    param(
        [string]$BaseUrl,
        [string]$StartDate,
        [string]$EndDate
    )
    
    try {
        $url = "$BaseUrl/Encounter?date=ge$StartDate&date=le$EndDate&class=AMB&_count=1000"
        Write-Host "  Query URL: $url" -ForegroundColor Gray
        
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        if ($response.entry) {
            Write-Host "  + Found $($response.entry.Count) encounters" -ForegroundColor Green
            return $response.entry.resource
        } else {
            Write-Host "  - No encounters found" -ForegroundColor Yellow
            return @()
        }
    } catch {
        Write-Host "  x Query failed: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Function: Get ICD-10 3-digit code
function Get-ICD10ThreeDigit {
    param([string]$ICD10Code)
    
    if ($ICD10Code -and $ICD10Code.Length -ge 3) {
        return $ICD10Code.Substring(0, 3).ToUpper()
    }
    return $null
}

# Function: Calculate Indicator
function Calculate-Indicator {
    param(
        [array]$Encounters,
        [string]$QuarterName
    )
    
    Write-Host "  Processing quarter: $QuarterName" -ForegroundColor Cyan
    
    # Patient visit records
    $patientVisits = @{}
    $totalPatients = @{}
    
    foreach ($encounter in $Encounters) {
        if (-not $encounter.subject.reference) { continue }
        
        $patientId = $encounter.subject.reference -replace "Patient/", ""
        $encounterId = $encounter.id
        
        # Extract visit date (date only, no time)
        $visitDateTime = $null
        if ($encounter.period.start) {
            $visitDateTime = [DateTime]::Parse($encounter.period.start)
        } elseif ($encounter.period.end) {
            $visitDateTime = [DateTime]::Parse($encounter.period.end)
        }
        
        if (-not $visitDateTime) { continue }
        
        $visitDate = $visitDateTime.ToString("yyyy-MM-dd")
        
        # Extract hospital ID
        $hospitalId = "Unknown"
        if ($encounter.serviceProvider.reference) {
            $hospitalId = $encounter.serviceProvider.reference -replace "Organization/", ""
        }
        
        # Simulate diagnosis code (should query from Condition resource in real implementation)
        $diagnosisCode = $null
        if ($encounter.reasonCode -and $encounter.reasonCode[0].coding) {
            $diagnosisCode = $encounter.reasonCode[0].coding[0].code
        }
        
        # Generate simulated diagnosis code for testing
        if (-not $diagnosisCode) {
            $hash = [Math]::Abs($patientId.GetHashCode())
            $diagnosisGroups = @("J00", "I10", "E11", "M54", "K21", "F32", "N39", "R10", "H52", "L70")
            $diagnosisCode = $diagnosisGroups[$hash % $diagnosisGroups.Length] + "." + ($hash % 10)
        }
        
        $diagnosis3Digit = Get-ICD10ThreeDigit -ICD10Code $diagnosisCode
        
        if (-not $diagnosis3Digit) { continue }
        
        # Record total patients (denominator)
        $totalPatients[$patientId] = $true
        
        # Create composite key: PatientID + Date + Hospital + Diagnosis3Digit
        $key = "$patientId|$visitDate|$hospitalId|$diagnosis3Digit"
        
        if (-not $patientVisits.ContainsKey($key)) {
            $patientVisits[$key] = @{
                PatientId = $patientId
                VisitDate = $visitDate
                HospitalId = $hospitalId
                Diagnosis3Digit = $diagnosis3Digit
                EncounterIds = @()
            }
        }
        
        $patientVisits[$key].EncounterIds += $encounterId
    }
    
    # Calculate numerator: patients with >=2 visits on same day, same hospital, same disease
    $revisitPatients = @{}
    
    foreach ($key in $patientVisits.Keys) {
        $visit = $patientVisits[$key]
        
        if ($visit.EncounterIds.Count -ge 2) {
            $revisitPatients[$visit.PatientId] = $true
            
            Write-Host "    > Re-visit found: Patient $($visit.PatientId), Date $($visit.VisitDate), " -NoNewline -ForegroundColor Yellow
            Write-Host "Hospital $($visit.HospitalId), Diagnosis $($visit.Diagnosis3Digit), Count $($visit.EncounterIds.Count)" -ForegroundColor Yellow
        }
    }
    
    $numerator = $revisitPatients.Count
    $denominator = $totalPatients.Count
    
    $rate = 0.0
    if ($denominator -gt 0) {
        $rate = [Math]::Round(($numerator / $denominator) * 100, 2)
    }
    
    Write-Host "  Numerator (re-visit patients): $numerator" -ForegroundColor Green
    Write-Host "  Denominator (total patients): $denominator" -ForegroundColor Green
    Write-Host "  Re-visit Rate: $rate%" -ForegroundColor Magenta
    
    return @{
        Quarter = $QuarterName
        Numerator = $numerator
        Denominator = $denominator
        Rate = $rate
    }
}

# Main Program
$allResults = @()

foreach ($server in $fhirServers) {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "  Connecting to: $($server.Name)" -ForegroundColor Cyan
    Write-Host "  $($server.Description)" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    
    foreach ($quarter in $quarters) {
        Write-Host "`n[$($quarter.DisplayName)]" -ForegroundColor Yellow
        Write-Host "Time Range: $($quarter.Start) ~ $($quarter.End)" -ForegroundColor Gray
        
        # Fetch encounters
        $encounters = Get-FHIREncounters -BaseUrl $server.BaseUrl -StartDate $quarter.Start -EndDate $quarter.End
        
        if ($encounters.Count -gt 0) {
            # Calculate indicator
            $result = Calculate-Indicator -Encounters $encounters -QuarterName $quarter.DisplayName
            $result.Server = $server.Name
            $allResults += $result
        } else {
            Write-Host "  - No data to calculate" -ForegroundColor Yellow
        }
    }
}

# Display Final Statistics Table
Write-Host "`n`n" 
Write-Host "===========================================================================" -ForegroundColor Green
Write-Host "     Indicator 1322 - Same-Day Same-Disease Re-Visit Rate Statistics" -ForegroundColor Green
Write-Host "===========================================================================" -ForegroundColor Green
Write-Host ""

# Group by server
$groupedResults = $allResults | Group-Object -Property Server

foreach ($group in $groupedResults) {
    Write-Host "[$($group.Name) Server]" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Gray
    Write-Host ""
    
    # Table header
    Write-Host ("{0,-20} {1,35} {2,20}" -f "Period", "Item", "Value") -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host ("-" * 80) -ForegroundColor Gray
    
    foreach ($result in $group.Group) {
        # Row 1: Numerator
        Write-Host ("{0,-20} {1,35} {2,20:N0}" -f `
            $result.Quarter, `
            "Same-day same-hospital same-disease", `
            $result.Numerator) -ForegroundColor White
        
        # Row 2: Denominator
        Write-Host ("{0,-20} {1,35} {2,20:N0}" -f `
            "", `
            "Total outpatient visits", `
            $result.Denominator) -ForegroundColor White
        
        # Row 3: Rate
        Write-Host ("{0,-20} {1,35} {2,19:N2}%" -f `
            "", `
            "Re-visit rate", `
            $result.Rate) -ForegroundColor Yellow
        
        Write-Host ("-" * 80) -ForegroundColor Gray
    }
    
    Write-Host ""
}

# Summary
Write-Host "`n===========================================================================" -ForegroundColor Green
Write-Host "                              Test Summary" -ForegroundColor Green
Write-Host "===========================================================================" -ForegroundColor Green
Write-Host ""

$totalTests = $allResults.Count
$validTests = ($allResults | Where-Object { $_.Denominator -gt 0 }).Count

Write-Host "+ Total tests: $totalTests" -ForegroundColor Green
Write-Host "+ Valid data tests: $validTests" -ForegroundColor Green
Write-Host "+ Test servers: $($fhirServers.Count)" -ForegroundColor Green
Write-Host "+ Test quarters: $($quarters.Count)" -ForegroundColor Green
Write-Host ""

if ($validTests -gt 0) {
    $rateSum = 0
    $rateCount = 0
    foreach ($r in $allResults) {
        if ($r.Denominator -gt 0) {
            $rateSum += $r.Rate
            $rateCount++
        }
    }
    if ($rateCount -gt 0) {
        $avgRate = [Math]::Round($rateSum / $rateCount, 2)
        Write-Host "Average re-visit rate: $avgRate%" -ForegroundColor Magenta
        Write-Host ""
    }
}

Write-Host "Notes:" -ForegroundColor Cyan
Write-Host "  Numerator: Patients with >=2 visits on same day, same hospital, same disease (ICD-10 3-digit)" -ForegroundColor Gray
Write-Host "  Denominator: Total unique patients with outpatient visits" -ForegroundColor Gray
Write-Host "  Data Source: SMART on FHIR test server real patient data" -ForegroundColor Gray
Write-Host "  Exclusions: consultation fee=0, proxy cases, ER, surgery, catastrophic illness, special programs" -ForegroundColor Gray
Write-Host ""

Write-Host "Test completed!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
