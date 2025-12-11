# ==================================================================================
# Test Script for Indicator 13: Average ESWL Procedures per Patient
# 指標13: 接受體外震波碎石術(ESWL)病人平均利用ESWL之次數
# ==================================================================================

param(
    [string]$ServerUrl = "https://launch.smarthealthit.org/v/r4/fhir",
    [int]$MaxProcedures = 500
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 13: Average ESWL Procedures per Patient" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "FHIR Server: $ServerUrl" -ForegroundColor Yellow
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# ==================================================================================
# Functions
# ==================================================================================

function Get-FHIRResource {
    param(
        [string]$ResourceType,
        [string]$Query = "",
        [int]$Count = 100
    )
    
    $url = "$ServerUrl/$ResourceType"
    if ($Query) {
        $url += "?$Query&_count=$Count"
    } else {
        $url += "?_count=$Count"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        return $response
    } catch {
        Write-Host "Warning: Cannot retrieve $ResourceType - $_" -ForegroundColor Yellow
        return $null
    }
}

function Test-ESWLProcedure {
    param($procedure)
    
    # ESWL codes to check
    $eswlCodes = @{
        'SNOMEDCT' = @('80146002', '397741005', '175096000')  # ESWL procedures
        'CPT' = @('50590', '52353')  # Lithotripsy codes
        'ICD10PCS' = @('0TF00ZZ', '0TF10ZZ', '0TF20ZZ', '0TF30ZZ')  # Extracorporeal lithotripsy
    }
    
    foreach ($coding in $procedure.code.coding) {
        $system = $coding.system
        $code = $coding.code
        
        if ($system -like '*snomed*' -and $code -in $eswlCodes['SNOMEDCT']) {
            return $true
        }
        if ($system -like '*cpt*' -and $code -in $eswlCodes['CPT']) {
            return $true
        }
        if ($system -like '*icd-10-pcs*' -and $code -in $eswlCodes['ICD10PCS']) {
            return $true
        }
        
        # Check display text for ESWL keywords
        if ($coding.display -match '(?i)(eswl|extracorporeal|shock.*wave|lithotripsy|碎石)') {
            return $true
        }
    }
    
    return $false
}

function Get-QuarterFromDate {
    param([DateTime]$date)
    
    $year = $date.Year - 1911  # ROC year
    $quarter = [Math]::Ceiling($date.Month / 3)
    
    return "${year}Y-Q${quarter}"
}

# ==================================================================================
# Main Logic: Fetch and Analyze Data
# ==================================================================================

Write-Host "Fetching ESWL procedure data..." -ForegroundColor Cyan

# Fetch all Procedure resources
$procedures = Get-FHIRResource -ResourceType "Procedure" -Query "status=completed" -Count $MaxProcedures

if (-not $procedures -or -not $procedures.entry) {
    Write-Host "No procedures found, trying without status filter..." -ForegroundColor Yellow
    $procedures = Get-FHIRResource -ResourceType "Procedure" -Count $MaxProcedures
}

if (-not $procedures -or -not $procedures.entry) {
    Write-Host "ERROR: Cannot retrieve any procedure records" -ForegroundColor Red
    Write-Host "Using simulated data for demonstration..." -ForegroundColor Yellow
    
    # Use simulated data
    $useSimulated = $true
} else {
    Write-Host "Found $($procedures.entry.Count) procedure records" -ForegroundColor Green
    $useSimulated = $false
}

# ==================================================================================
# Process Real Data
# ==================================================================================

if (-not $useSimulated) {
    Write-Host "Analyzing procedures for ESWL..." -ForegroundColor Cyan
    
    $results = @{}
    $patientESWLCount = @{}
    
    foreach ($entry in $procedures.entry) {
        $procedure = $entry.resource
        
        # Check if this is an ESWL procedure
        if (-not (Test-ESWLProcedure -procedure $procedure)) {
            continue
        }
        
        # Get procedure date
        if (-not $procedure.performedDateTime -and -not $procedure.performedPeriod) {
            continue
        }
        
        $procedureDate = $null
        if ($procedure.performedDateTime) {
            $procedureDate = [DateTime]::Parse($procedure.performedDateTime)
        } elseif ($procedure.performedPeriod -and $procedure.performedPeriod.start) {
            $procedureDate = [DateTime]::Parse($procedure.performedPeriod.start)
        }
        
        if (-not $procedureDate) {
            continue
        }
        
        # Get quarter
        $quarter = Get-QuarterFromDate -date $procedureDate
        
        if (-not $results.ContainsKey($quarter)) {
            $results[$quarter] = @{
                ESWLCount = 0
                PatientIds = @{}
            }
        }
        
        # Count ESWL procedure
        $results[$quarter].ESWLCount++
        
        # Track unique patients
        $patientRef = $procedure.subject.reference
        if ($patientRef) {
            $patientId = $patientRef -replace 'Patient/', ''
            $results[$quarter].PatientIds[$patientId] = $true
        }
    }
    
    Write-Host "Found $($results.Keys.Count) quarters with ESWL data" -ForegroundColor Green
}

# ==================================================================================
# Generate Simulated Data if needed
# ==================================================================================

if ($useSimulated -or $results.Keys.Count -eq 0) {
    Write-Host ""
    Write-Host "Generating simulated ESWL data for demonstration..." -ForegroundColor Yellow
    
    $results = @{
        "113Y-Q1" = @{
            ESWLCount = [int](Get-Random -Minimum 2500 -Maximum 2700)
            PatientIds = @{}
        }
        "113Y-Q2" = @{
            ESWLCount = [int](Get-Random -Minimum 3400 -Maximum 3600)
            PatientIds = @{}
        }
        "113Y-Q3" = @{
            ESWLCount = [int](Get-Random -Minimum 4000 -Maximum 4200)
            PatientIds = @{}
        }
        "113Y-Q4" = @{
            ESWLCount = [int](Get-Random -Minimum 3400 -Maximum 3600)
            PatientIds = @{}
        }
    }
    
    # Generate unique patient counts (average ~1.1 procedures per patient)
    foreach ($quarter in $results.Keys) {
        $eswlCount = $results[$quarter].ESWLCount
        $patientCount = [int]($eswlCount / (Get-Random -Minimum 1.05 -Maximum 1.15))
        
        for ($i = 1; $i -le $patientCount; $i++) {
            $results[$quarter].PatientIds["patient-$quarter-$i"] = $true
        }
    }
}

# ==================================================================================
# Display Results
# ==================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Calculation Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Sort quarters
$sortedQuarters = $results.Keys | Sort-Object

# Calculate totals
$grandTotalESWL = 0
$grandTotalPatients = 0

foreach ($quarter in $sortedQuarters) {
    $data = $results[$quarter]
    $eswlCount = $data.ESWLCount
    $patientCount = $data.PatientIds.Count
    
    $grandTotalESWL += $eswlCount
    $grandTotalPatients += $patientCount
    
    # Calculate average
    $average = 0.0
    if ($patientCount -gt 0) {
        $average = [math]::Round($eswlCount / $patientCount, 2)
    }
    
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| $quarter                              " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| ESWL Procedure Count               | " -NoNewline
    Write-Host ("{0,8}" -f $eswlCount) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| ESWL Patient Count                 | " -NoNewline
    Write-Host ("{0,8}" -f $patientCount) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| Average ESWL per Patient           | " -NoNewline
    Write-Host ("{0,8:F2}" -f $average) -ForegroundColor Cyan -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host ""
}

# Annual summary
if ($sortedQuarters.Count -gt 0) {
    $overallAverage = 0.0
    if ($grandTotalPatients -gt 0) {
        $overallAverage = [math]::Round($grandTotalESWL / $grandTotalPatients, 2)
    }
    
    # Calculate year
    $firstQuarter = $sortedQuarters[0]
    $year = $firstQuarter -replace '-.*', ''
    
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| $year                                 " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| ESWL Procedure Count               | " -NoNewline
    Write-Host ("{0,8}" -f $grandTotalESWL) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| ESWL Patient Count                 | " -NoNewline
    Write-Host ("{0,8}" -f $grandTotalPatients) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| Average ESWL per Patient           | " -NoNewline
    Write-Host ("{0,8:F2}" -f $overallAverage) -ForegroundColor Cyan -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total ESWL Procedures: $grandTotalESWL" -ForegroundColor White
Write-Host "Total Unique Patients: $grandTotalPatients" -ForegroundColor White
if ($grandTotalPatients -gt 0) {
    $finalAvg = [math]::Round($grandTotalESWL / $grandTotalPatients, 2)
    Write-Host "Overall Average per Patient: $finalAvg" -ForegroundColor Cyan
}
Write-Host ""
$completionTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Calculation completed at: $completionTime" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
