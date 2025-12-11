# ========================================
# Indicator 14: 14-Day Readmission Rate after Uterine Myomectomy
# 子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率(473.01)
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 14: 14-Day Readmission Rate after Uterine Myomectomy" -ForegroundColor Cyan
Write-Host "Testing with real FHIR data from public servers" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test with multiple FHIR servers
$fhirServers = @(
    @{
        Name = "SMART Health IT"
        BaseUrl = "https://launch.smarthealthit.org/v/r4/fhir"
    },
    @{
        Name = "HAPI FHIR Test Server"
        BaseUrl = "http://hapi.fhir.org/baseR4"
    }
)

foreach ($server in $fhirServers) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Testing: $($server.Name)" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Yellow
    
    $baseUrl = $server.BaseUrl
    
    # Step 1: Search for encounters with D25 diagnosis (uterine leiomyoma)
    Write-Host "Step 1: Searching for encounters with D25 diagnosis (uterine leiomyoma)..." -ForegroundColor Green
    $d25Codes = @("D25", "D25.0", "D25.1", "D25.2", "D25.9")
    $encountersWithD25 = @()
    
    foreach ($code in $d25Codes) {
        try {
            $url = "$baseUrl/Encounter?diagnosis=$code&_count=100"
            Write-Host "  Querying: $url" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
            
            if ($response.entry) {
                Write-Host "  Found $($response.entry.Count) encounters with $code" -ForegroundColor Cyan
                $encountersWithD25 += $response.entry.resource
            }
        } catch {
            Write-Host "  Error querying $code : $_" -ForegroundColor Red
        }
    }
    
    if ($encountersWithD25.Count -eq 0) {
        Write-Host "`n  No encounters with D25 diagnosis found" -ForegroundColor Yellow
        Write-Host "  Searching for conditions with D25 codes instead..." -ForegroundColor Yellow
        
        foreach ($code in $d25Codes) {
            try {
                $url = "$baseUrl/Condition?code=$code&_count=100"
                Write-Host "  Querying: $url" -ForegroundColor Gray
                $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
                
                if ($response.entry) {
                    Write-Host "  Found $($response.entry.Count) conditions with $code" -ForegroundColor Cyan
                    foreach ($entry in $response.entry) {
                        if ($entry.resource.encounter) {
                            $encounterId = $entry.resource.encounter.reference -replace "Encounter/", ""
                            try {
                                $encUrl = "$baseUrl/Encounter/$encounterId"
                                $encResponse = Invoke-RestMethod -Uri $encUrl -Method Get -ContentType "application/fhir+json"
                                $encountersWithD25 += $encResponse
                            } catch {
                                Write-Host "    Error fetching encounter $encounterId : $_" -ForegroundColor Red
                            }
                        }
                    }
                }
            } catch {
                Write-Host "  Error querying conditions with $code : $_" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`n  Total encounters with D25: $($encountersWithD25.Count)" -ForegroundColor Cyan
    
    if ($encountersWithD25.Count -eq 0) {
        Write-Host "`n  Insufficient data for indicator 14 calculation on $($server.Name)" -ForegroundColor Yellow
        continue
    }
    
    # Step 2: Check for cancer diagnosis exclusions
    Write-Host "`nStep 2: Checking for cancer diagnosis exclusions..." -ForegroundColor Green
    $cancerCodes = @("C00", "C96", "C94.4", "C94.6", "D37", "D48", "Z51.12", "J84.81")
    $encountersWithoutCancer = @()
    
    foreach ($encounter in $encountersWithD25) {
        $hasCancer = $false
        $patientId = $encounter.subject.reference -replace "Patient/", ""
        
        foreach ($code in $cancerCodes) {
            try {
                $url = "$baseUrl/Condition?patient=$patientId&code=$code"
                $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
                
                if ($response.entry -and $response.entry.Count -gt 0) {
                    # Check if it's C94.4 or C94.6 (these should be excluded from exclusion)
                    if ($code -eq "C94.4" -or $code -eq "C94.6") {
                        continue
                    }
                    $hasCancer = $true
                    Write-Host "  Patient $patientId has cancer diagnosis: $code" -ForegroundColor Yellow
                    break
                }
            } catch {
                Write-Host "  Error checking cancer code $code for patient $patientId : $_" -ForegroundColor Red
            }
        }
        
        if (-not $hasCancer) {
            $encountersWithoutCancer += $encounter
        }
    }
    
    Write-Host "  Encounters without cancer: $($encountersWithoutCancer.Count)" -ForegroundColor Cyan
    
    # Step 3: Check for myomectomy or hysterectomy procedures
    Write-Host "`nStep 3: Checking for myomectomy or hysterectomy procedures..." -ForegroundColor Green
    $myomectomyCodes = @("97010K", "97011A", "97012B", "97013B", "80402C", "80420C", "80415B", "97013C", "80415C", "80425C")
    $hysterectomyCodes = @("97025K", "97026A", "97027B", "97020K", "97021A", "97022B", "97035K", "97036A", "97037B", "80403B", "80404B", "80421B", "80416B", "80412B", "97027C", "80404C")
    
    $snomedMyomectomy = @("176697007", "307771009", "447771005")
    $snomedHysterectomy = @("236886002", "116140006", "307771009", "79876008")
    
    $cptMyomectomy = @("58140", "58145", "58146")
    $cptHysterectomy = @("58150", "58152", "58180", "58200", "58210", "58260", "58262", "58263", "58267", "58270", "58275", "58280", "58285", "58290", "58291", "58292", "58293", "58294", "58541", "58542", "58543", "58544", "58570")
    
    $surgeryEncounters = @()
    
    foreach ($encounter in $encountersWithoutCancer) {
        $hasSurgery = $false
        $patientId = $encounter.subject.reference -replace "Patient/", ""
        
        # Check for procedures
        try {
            $url = "$baseUrl/Procedure?patient=$patientId&encounter=$($encounter.id)&_count=100"
            $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
            
            if ($response.entry) {
                foreach ($entry in $response.entry) {
                    $procedure = $entry.resource
                    if ($procedure.code -and $procedure.code.coding) {
                        foreach ($coding in $procedure.code.coding) {
                            $code = $coding.code
                            
                            # Check myomectomy codes
                            if ($myomectomyCodes -contains $code -or 
                                $snomedMyomectomy -contains $code -or 
                                $cptMyomectomy -contains $code) {
                                $hasSurgery = $true
                                Write-Host "  Found myomectomy procedure: $code for patient $patientId" -ForegroundColor Cyan
                                break
                            }
                            
                            # Check hysterectomy codes
                            if ($hysterectomyCodes -contains $code -or 
                                $snomedHysterectomy -contains $code -or 
                                $cptHysterectomy -contains $code) {
                                $hasSurgery = $true
                                Write-Host "  Found hysterectomy procedure: $code for patient $patientId" -ForegroundColor Cyan
                                break
                            }
                        }
                    }
                    if ($hasSurgery) { break }
                }
            }
        } catch {
            Write-Host "  Error checking procedures for patient $patientId : $_" -ForegroundColor Red
        }
        
        if ($hasSurgery) {
            $surgeryEncounters += $encounter
        }
    }
    
    Write-Host "  Surgery encounters (denominator): $($surgeryEncounters.Count)" -ForegroundColor Cyan
    
    if ($surgeryEncounters.Count -eq 0) {
        Write-Host "`n  No surgery encounters found for indicator 14 calculation on $($server.Name)" -ForegroundColor Yellow
        continue
    }
    
    # Step 4: Check for readmissions within 14 days
    Write-Host "`nStep 4: Checking for readmissions within 14 days..." -ForegroundColor Green
    $n70_n85_codes = @("N70", "N71", "N72", "N73", "N74", "N75", "N76", "N77", "N80", "N81", "N82", "N83", "N84", "N85")
    $readmissions = 0
    
    foreach ($encounter in $surgeryEncounters) {
        $patientId = $encounter.subject.reference -replace "Patient/", ""
        
        # Get discharge date
        if ($encounter.period -and $encounter.period.end) {
            $dischargeDate = [DateTime]::Parse($encounter.period.end)
            $readmissionDeadline = $dischargeDate.AddDays(14)
            
            Write-Host "  Checking patient $patientId discharged on $($dischargeDate.ToString('yyyy-MM-dd'))..." -ForegroundColor Gray
            
            # Search for subsequent encounters
            try {
                $url = "$baseUrl/Encounter?patient=$patientId&date=gt$($dischargeDate.ToString('yyyy-MM-dd'))&_count=100"
                $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json"
                
                if ($response.entry) {
                    foreach ($entry in $response.entry) {
                        $readmitEncounter = $entry.resource
                        
                        # Check if within 14 days
                        if ($readmitEncounter.period -and $readmitEncounter.period.start) {
                            $readmitDate = [DateTime]::Parse($readmitEncounter.period.start)
                            
                            if ($readmitDate -le $readmissionDeadline) {
                                Write-Host "    Found readmission on $($readmitDate.ToString('yyyy-MM-dd'))" -ForegroundColor Yellow
                                
                                # Check for N70-N85 diagnosis
                                $hasRelatedDiagnosis = $false
                                
                                foreach ($diagCode in $n70_n85_codes) {
                                    try {
                                        $condUrl = "$baseUrl/Condition?patient=$patientId&encounter=$($readmitEncounter.id)&code=$diagCode"
                                        $condResponse = Invoke-RestMethod -Uri $condUrl -Method Get -ContentType "application/fhir+json"
                                        
                                        if ($condResponse.entry -and $condResponse.entry.Count -gt 0) {
                                            $hasRelatedDiagnosis = $true
                                            Write-Host "    Found related diagnosis: $diagCode" -ForegroundColor Green
                                            break
                                        }
                                    } catch {
                                        Write-Host "    Error checking diagnosis $diagCode : $_" -ForegroundColor Red
                                    }
                                }
                                
                                if ($hasRelatedDiagnosis) {
                                    $readmissions++
                                    Write-Host "    READMISSION CONFIRMED for patient $patientId" -ForegroundColor Magenta
                                    break
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Host "  Error checking readmissions for patient $patientId : $_" -ForegroundColor Red
            }
        }
    }
    
    # Calculate rate
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "Results for $($server.Name)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Denominator (Surgery Cases): $($surgeryEncounters.Count)" -ForegroundColor Cyan
    Write-Host "Numerator (14-Day Readmissions): $readmissions" -ForegroundColor Cyan
    
    if ($surgeryEncounters.Count -gt 0) {
        $rate = [Math]::Round(($readmissions / $surgeryEncounters.Count) * 100, 2)
        Write-Host "14-Day Readmission Rate: $rate%" -ForegroundColor Green
    } else {
        Write-Host "14-Day Readmission Rate: N/A (no denominator)" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
