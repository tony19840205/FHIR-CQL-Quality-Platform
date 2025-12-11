# =============================================================================
# 從SMART FHIR伺服器撈取真實病患數據 - 指標27: 剖腹產率-自行要求
# Fetch Real Patient Data from SMART FHIR - Indicator 27: Patient Requested Cesarean
# =============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fetching Real Patient Data from SMART FHIR" -ForegroundColor Cyan
Write-Host "Indicator 27: Patient Requested Cesarean Section Rate" -ForegroundColor Cyan
Write-Host "Code: 1137.01" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# FHIR Server Configuration
$fhirBaseUrl = "https://launch.smarthealthit.org/v/r4/fhir"

Write-Host "Connecting to SMART Health IT FHIR Server..." -ForegroundColor Yellow
Write-Host "URL: $fhirBaseUrl`n" -ForegroundColor Gray

# Initialize counters
$patientRequestedCesareanCount = 0
$totalCesareanCount = 0
$naturalDeliveryCount = 0
$totalDeliveryCount = 0

# Data collection arrays
$allPatients = @()
$allEncounters = @()
$patientRequestedCases = @()
$cesareanCases = @()
$naturalCases = @()

# Period definition (using current year and quarters)
$currentYear = (Get-Date).Year
$quarters = @{
    "Q1" = @{
        Start = [DateTime]::new($currentYear, 1, 1)
        End = [DateTime]::new($currentYear, 3, 31)
    }
    "Q2" = @{
        Start = [DateTime]::new($currentYear, 4, 1)
        End = [DateTime]::new($currentYear, 6, 30)
    }
    "Q3" = @{
        Start = [DateTime]::new($currentYear, 7, 1)
        End = [DateTime]::new($currentYear, 9, 30)
    }
    "Q4" = @{
        Start = [DateTime]::new($currentYear, 10, 1)
        End = [DateTime]::new($currentYear, 12, 31)
    }
}

$yearlyData = @{
    Q1 = @{ PatientRequested = 0; Total = 0 }
    Q2 = @{ PatientRequested = 0; Total = 0 }
    Q3 = @{ PatientRequested = 0; Total = 0 }
    Q4 = @{ PatientRequested = 0; Total = 0 }
    Year = @{ PatientRequested = 0; Total = 0 }
}

try {
    # Step 1: Fetch female patients (potential mothers)
    Write-Host "Step 1: Fetching female patients..." -ForegroundColor Yellow
    $patientUrl = "$fhirBaseUrl/Patient?gender=female&_count=100"
    
    try {
        $patientResponse = Invoke-RestMethod -Uri $patientUrl -Method Get -ContentType "application/fhir+json"
        
        if ($patientResponse.entry) {
            $allPatients = $patientResponse.entry.resource
            Write-Host "  Found $($allPatients.Count) female patients" -ForegroundColor Green
        } else {
            Write-Host "  No female patients found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  Error fetching patients: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Step 2: Search for delivery-related encounters
    Write-Host "Step 2: Searching for delivery encounters..." -ForegroundColor Yellow
    
    foreach ($patient in $allPatients) {
        $patientId = $patient.id
        
        # Search for inpatient encounters (deliveries are typically inpatient)
        $encounterUrl = "$fhirBaseUrl/Encounter?patient=$patientId&class=IMP&_count=50"
        
        try {
            $encounterResponse = Invoke-RestMethod -Uri $encounterUrl -Method Get -ContentType "application/fhir+json"
            
            if ($encounterResponse.entry) {
                foreach ($entry in $encounterResponse.entry) {
                    $encounter = $entry.resource
                    
                    # Check if this is a delivery encounter
                    $isDelivery = $false
                    
                    # Check encounter type
                    if ($encounter.type) {
                        foreach ($type in $encounter.type) {
                            if ($type.coding) {
                                foreach ($coding in $type.coding) {
                                    if ($coding.code -match "deliver|obstetric|pregnancy" -or
                                        $coding.display -match "delivery|obstetric|pregnancy") {
                                        $isDelivery = $true
                                        break
                                    }
                                }
                            }
                        }
                    }
                    
                    # Check reason codes
                    if ($encounter.reasonCode -and -not $isDelivery) {
                        foreach ($reason in $encounter.reasonCode) {
                            if ($reason.coding) {
                                foreach ($coding in $reason.coding) {
                                    if ($coding.code -match "^O8[0-4]" -or  # ICD-10 delivery codes
                                        $coding.display -match "delivery|cesarean|birth") {
                                        $isDelivery = $true
                                        break
                                    }
                                }
                            }
                        }
                    }
                    
                    if ($isDelivery) {
                        $allEncounters += $encounter
                    }
                }
            }
        }
        catch {
            # Skip patients with errors
        }
    }
    
    Write-Host "  Found $($allEncounters.Count) potential delivery encounters" -ForegroundColor Green
    Write-Host ""
    
    # Step 3: Analyze each encounter for delivery type
    Write-Host "Step 3: Analyzing delivery types..." -ForegroundColor Yellow
    
    foreach ($encounter in $allEncounters) {
        $encounterId = $encounter.id
        $patientRef = $encounter.subject.reference
        
        # Get encounter period
        $encounterDate = $null
        if ($encounter.period -and $encounter.period.end) {
            $encounterDate = [DateTime]::Parse($encounter.period.end)
        }
        
        # Determine quarter
        $quarter = $null
        if ($encounterDate) {
            $month = $encounterDate.Month
            if ($month -le 3) { $quarter = "Q1" }
            elseif ($month -le 6) { $quarter = "Q2" }
            elseif ($month -le 9) { $quarter = "Q3" }
            else { $quarter = "Q4" }
        }
        
        $isPatientRequestedCesarean = $false
        $isCesarean = $false
        $isNatural = $false
        
        # Check procedures for this encounter
        $procedureUrl = "$fhirBaseUrl/Procedure?encounter=Encounter/$encounterId"
        
        try {
            $procedureResponse = Invoke-RestMethod -Uri $procedureUrl -Method Get -ContentType "application/fhir+json"
            
            if ($procedureResponse.entry) {
                foreach ($procEntry in $procedureResponse.entry) {
                    $procedure = $procEntry.resource
                    
                    if ($procedure.code -and $procedure.code.coding) {
                        foreach ($coding in $procedure.code.coding) {
                            # Check for patient-requested cesarean (Numerator)
                            # SNOMED: 386637004 (Cesarean on request), 450483001 (Cesarean without indication)
                            if ($coding.system -eq "http://snomed.info/sct" -and
                                ($coding.code -eq "386637004" -or $coding.code -eq "450483001")) {
                                $isPatientRequestedCesarean = $true
                                $isCesarean = $true
                            }
                            
                            # Check for NHI procedure code 97014C (patient-requested cesarean)
                            if ($coding.system -match "nhi-procedure" -and $coding.code -eq "97014C") {
                                $isPatientRequestedCesarean = $true
                                $isCesarean = $true
                            }
                            
                            # Check for general cesarean
                            if ($coding.system -eq "http://snomed.info/sct" -and
                                $coding.code -match "^(11466000|177141003|177152005|40219000|18946005)") {
                                $isCesarean = $true
                            }
                            
                            # Check for natural delivery
                            if ($coding.system -eq "http://snomed.info/sct" -and
                                $coding.code -match "^(302383004|289253008|236974004|177157004|236973005)") {
                                $isNatural = $true
                            }
                            
                            # CPT codes
                            if ($coding.system -eq "http://www.ama-assn.org/go/cpt") {
                                if ($coding.code -match "^595(10|14|15|20)") {
                                    $isCesarean = $true
                                }
                                if ($coding.code -match "^594(00|09|10|12)") {
                                    $isNatural = $true
                                }
                            }
                        }
                    }
                }
            }
        }
        catch {
            # Skip if can't get procedures
        }
        
        # Check claims/accounts for DRG codes
        if ($encounter.account) {
            foreach ($accountRef in $encounter.account) {
                $accountId = $accountRef.reference -replace "Account/", ""
                $claimUrl = "$fhirBaseUrl/Claim?patient=$patientRef&_id=$accountId"
                
                try {
                    $claimResponse = Invoke-RestMethod -Uri $claimUrl -Method Get -ContentType "application/fhir+json"
                    
                    if ($claimResponse.entry) {
                        foreach ($claimEntry in $claimResponse.entry) {
                            $claim = $claimEntry.resource
                            
                            if ($claim.extension) {
                                foreach ($ext in $claim.extension) {
                                    # Check for TW-DRG 513 (patient-requested cesarean)
                                    if ($ext.url -match "tw-drg" -and $ext.valueString -match "^513") {
                                        $isPatientRequestedCesarean = $true
                                        $isCesarean = $true
                                    }
                                    
                                    # Check for DRG_CODE 0373B (patient-requested cesarean)
                                    if ($ext.url -match "drg-code" -and $ext.valueString -eq "0373B") {
                                        $isPatientRequestedCesarean = $true
                                        $isCesarean = $true
                                    }
                                    
                                    # Check for cesarean DRG codes (370, 371, 513)
                                    if ($ext.url -match "tw-drg" -and $ext.valueString -match "^(370|371|513)") {
                                        $isCesarean = $true
                                    }
                                    
                                    # Check for natural delivery DRG codes (372-375)
                                    if ($ext.url -match "tw-drg" -and $ext.valueString -match "^37[2-5]") {
                                        $isNatural = $true
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                    # Skip if can't get claims
                }
            }
        }
        
        # Categorize the delivery
        if ($isPatientRequestedCesarean) {
            $patientRequestedCesareanCount++
            $totalDeliveryCount++
            $totalCesareanCount++
            $patientRequestedCases += [PSCustomObject]@{
                EncounterId = $encounterId
                PatientRef = $patientRef
                Date = $encounterDate
                Quarter = $quarter
                Type = "Patient-Requested Cesarean"
            }
            
            if ($quarter) {
                $yearlyData[$quarter].PatientRequested++
                $yearlyData[$quarter].Total++
                $yearlyData["Year"].PatientRequested++
                $yearlyData["Year"].Total++
            }
        }
        elseif ($isCesarean) {
            $totalCesareanCount++
            $totalDeliveryCount++
            $cesareanCases += [PSCustomObject]@{
                EncounterId = $encounterId
                PatientRef = $patientRef
                Date = $encounterDate
                Quarter = $quarter
                Type = "Cesarean (Medical Indication)"
            }
            
            if ($quarter) {
                $yearlyData[$quarter].Total++
                $yearlyData["Year"].Total++
            }
        }
        elseif ($isNatural) {
            $naturalDeliveryCount++
            $totalDeliveryCount++
            $naturalCases += [PSCustomObject]@{
                EncounterId = $encounterId
                PatientRef = $patientRef
                Date = $encounterDate
                Quarter = $quarter
                Type = "Natural Delivery"
            }
            
            if ($quarter) {
                $yearlyData[$quarter].Total++
                $yearlyData["Year"].Total++
            }
        }
    }
    
    Write-Host "  Analysis complete!" -ForegroundColor Green
    Write-Host ""
    
    # Calculate rates
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Data Collection Summary" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Total Patients Analyzed: $($allPatients.Count)" -ForegroundColor White
    Write-Host "Total Delivery Encounters: $totalDeliveryCount" -ForegroundColor White
    Write-Host "  - Natural Deliveries: $naturalDeliveryCount" -ForegroundColor Green
    Write-Host "  - Cesarean Deliveries: $totalCesareanCount" -ForegroundColor Yellow
    Write-Host "    - With Medical Indication: $($totalCesareanCount - $patientRequestedCesareanCount)" -ForegroundColor White
    Write-Host "    - Patient Requested: $patientRequestedCesareanCount" -ForegroundColor Magenta
    Write-Host ""
    
    # Display results in the format shown in the image
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "指標27: 剖腹產率-自行要求 (1137.01)" -ForegroundColor Cyan
    Write-Host "Patient Requested Cesarean Section Rate" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Calculate annual rate
    $annualRate = if ($yearlyData["Year"].Total -gt 0) {
        [math]::Round(($yearlyData["Year"].PatientRequested / $yearlyData["Year"].Total) * 100, 2)
    } else { 0 }
    
    Write-Host "$($currentYear-1)年 (Year $($currentYear-1)):" -ForegroundColor Yellow
    Write-Host "  不具適應症之剖腹產案件: $($yearlyData["Year"].PatientRequested)" -ForegroundColor White
    Write-Host "  生產案件數: $($yearlyData["Year"].Total)" -ForegroundColor White
    Write-Host "  剖腹產率: $annualRate%" -ForegroundColor Cyan
    Write-Host ""
    
    # Display quarterly data
    foreach ($q in @("Q1", "Q2", "Q3", "Q4")) {
        $qNum = $q.Substring(1, 1)
        $qData = $yearlyData[$q]
        
        $qRate = if ($qData.Total -gt 0) {
            [math]::Round(($qData.PatientRequested / $qData.Total) * 100, 2)
        } else { 0 }
        
        Write-Host "$($currentYear)年 第${qNum}季 (Year $currentYear Q${qNum}):" -ForegroundColor Yellow
        Write-Host "  不具適應症之剖腹產案件: $($qData.PatientRequested)" -ForegroundColor White
        Write-Host "  生產案件數: $($qData.Total)" -ForegroundColor White
        Write-Host "  剖腹產率: $qRate%" -ForegroundColor Cyan
        Write-Host ""
    }
    
    # Summary table (matching image format)
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Summary Table" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $periodLabel = "Period"
    $item1Label = "Patient Requested Cesarean Cases"
    $item2Label = "Total Delivery Cases"
    $item3Label = "Rate"
    
    Write-Host "$periodLabel" -ForegroundColor Yellow
    Write-Host ("-" * 60) -ForegroundColor Gray
    
    # Annual data
    Write-Host "Year $($currentYear-1):" -ForegroundColor White
    Write-Host "  $item1Label : $($yearlyData['Year'].PatientRequested)" -ForegroundColor White
    Write-Host "  $item2Label : $($yearlyData['Year'].Total)" -ForegroundColor White
    Write-Host "  $item3Label : $annualRate%" -ForegroundColor Cyan
    Write-Host ""
    
    # Quarterly data
    foreach ($q in @("Q1", "Q2", "Q3", "Q4")) {
        $qNum = $q.Substring(1, 1)
        $qData = $yearlyData[$q]
        
        $qRate = if ($qData.Total -gt 0) {
            [math]::Round(($qData.PatientRequested / $qData.Total) * 100, 2)
        } else { 0 }
        
        Write-Host "Year $currentYear Q${qNum}:" -ForegroundColor White
        Write-Host "  $item1Label : $($qData.PatientRequested)" -ForegroundColor White
        Write-Host "  $item2Label : $($qData.Total)" -ForegroundColor White
        Write-Host "  $item3Label : $qRate%" -ForegroundColor Cyan
        Write-Host ""
    }
    
    # Clinical interpretation
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Clinical Assessment" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    if ($annualRate -le 5) {
        Write-Host "Rating: EXCELLENT" -ForegroundColor Green
        Write-Host "  - Low patient-requested cesarean rate" -ForegroundColor White
        Write-Host "  - Shared decision-making working well" -ForegroundColor White
    }
    elseif ($annualRate -le 10) {
        Write-Host "Rating: GOOD" -ForegroundColor Yellow
        Write-Host "  - Patient-requested cesarean rate in acceptable range" -ForegroundColor White
        Write-Host "  - Continue to strengthen patient education" -ForegroundColor White
    }
    else {
        Write-Host "Rating: NEEDS IMPROVEMENT" -ForegroundColor Red
        Write-Host "  - High patient-requested cesarean rate" -ForegroundColor White
        Write-Host "  - Review patient counseling processes" -ForegroundColor White
    }
    
    Write-Host ""
    
    # Export detailed data
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # Export to CSV
    $allCases = $patientRequestedCases + $cesareanCases + $naturalCases
    if ($allCases.Count -gt 0) {
        $csvPath = "indicator27_real_data_$timestamp.csv"
        $allCases | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Detailed data exported: $csvPath" -ForegroundColor Green
    }
    
    # Export summary
    $summary = @()
    $summary += [PSCustomObject]@{
        Period = "Year$($currentYear-1)"
        PatientRequestedCesarean = $yearlyData["Year"].PatientRequested
        TotalDeliveries = $yearlyData["Year"].Total
        Rate = $annualRate
    }
    
    foreach ($q in @("Q1", "Q2", "Q3", "Q4")) {
        $qNum = $q.Substring(1, 1)
        $qData = $yearlyData[$q]
        $qRate = if ($qData.Total -gt 0) {
            [math]::Round(($qData.PatientRequested / $qData.Total) * 100, 2)
        } else { 0 }
        
        $summary += [PSCustomObject]@{
            Period = "Year${currentYear}_Q${qNum}"
            PatientRequestedCesarean = $qData.PatientRequested
            TotalDeliveries = $qData.Total
            Rate = $qRate
        }
    }
    
    $summaryPath = "indicator27_summary_$timestamp.csv"
    $summary | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8
    Write-Host "Summary exported: $summaryPath" -ForegroundColor Green
    Write-Host ""
    
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Fetch Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
