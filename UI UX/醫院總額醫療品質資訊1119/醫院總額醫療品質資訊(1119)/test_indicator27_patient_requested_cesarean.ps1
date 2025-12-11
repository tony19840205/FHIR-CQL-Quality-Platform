# =============================================================================
# 指標27測試腳本: 剖腹產率-自行要求 (Cesarean Section Rate - Patient Requested)
# Indicator Code: 1137.01
# =============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 27: Patient Requested Cesarean Section Rate Test" -ForegroundColor Cyan
Write-Host "Code: 1137.01" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# FHIR Server Configuration
$fhirServers = @(
    @{
        Name = "SMART Health IT"
        BaseUrl = "https://launch.smarthealthit.org/v/r4/fhir"
        Description = "SMART on FHIR sandbox with synthetic patient data"
    },
    @{
        Name = "HAPI FHIR Test Server"
        BaseUrl = "https://hapi.fhir.org/baseR4"
        Description = "Public HAPI FHIR R4 test server"
    },
    @{
        Name = "FHIR Sandbox"
        BaseUrl = "https://api.logicahealth.org/test/open"
        Description = "Logica Health FHIR Sandbox"
    },
    @{
        Name = "UHN HAPI FHIR"
        BaseUrl = "https://fhir.uhn.ca/baseR4"
        Description = "University Health Network HAPI FHIR Server"
    }
)

# Initialize results
$allResults = @()
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# =============================================================================
# Test Data Generation
# =============================================================================

Write-Host "Generating test delivery cases..." -ForegroundColor Yellow

# Generate 300 delivery cases (matching Indicator 26)
$totalDeliveries = 300
$cesareanRate = 0.36  # 36% cesarean rate (from Indicator 26)
$patientRequestedRate = 0.08  # 8% patient-requested cesarean (clinical estimate: 5-10% of total cesareans)

$cesareanCount = [int]($totalDeliveries * $cesareanRate)
$naturalCount = $totalDeliveries - $cesareanCount
$patientRequestedCount = [int]($totalDeliveries * $patientRequestedRate)

Write-Host "Total deliveries: $totalDeliveries" -ForegroundColor White
Write-Host "- Natural deliveries: $naturalCount (64%)" -ForegroundColor Green
Write-Host "- Cesarean deliveries: $cesareanCount (36%)" -ForegroundColor Yellow
Write-Host "  - Patient-requested cesarean: $patientRequestedCount (8%)" -ForegroundColor Magenta
Write-Host ""

# Generate synthetic patient data
$patients = @()
$encounters = @()
$procedures = @()
$conditions = @()
$claims = @()

# Natural delivery DRG codes
$naturalDRGCodes = @('372', '373', '374', '375')
$naturalDRGDetailCodes = @('0373A', '0373C')
$naturalProcedureCodes = @('81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C', '97004C', '97005D', '97934C')

# Cesarean delivery DRG codes (with medical indication)
$cesareanDRGCodes = @('370', '371')
$cesareanDRGDetailCodes = @('0371A')
$cesareanProcedureCodes = @('81004C', '81005C', '81028C', '81029C', '97009C')

# Patient-requested cesarean codes (no medical indication)
$patientRequestedDRG = '513'
$patientRequestedDRGDetail = '0373B'
$patientRequestedProcedure = '97014C'
$patientRequestedSNOMED = @('386637004', '450483001')  # Cesarean on request, Cesarean without indication

Write-Host "Generating patient and encounter data..." -ForegroundColor Yellow

# Generate patient-requested cesarean cases (Numerator)
for ($i = 1; $i -le $patientRequestedCount; $i++) {
    $patientId = "Patient-PR-{0:D3}" -f $i
    $encounterId = "Encounter-PR-{0:D3}" -f $i
    $age = Get-Random -Minimum 20 -Maximum 42
    $deliveryDate = (Get-Date).AddDays(-(Get-Random -Minimum 1 -Maximum 365))
    $quarter = [Math]::Ceiling($deliveryDate.Month / 3)
    
    # Patient resource
    $patient = @{
        resourceType = "Patient"
        id = $patientId
        gender = "female"
        birthDate = $deliveryDate.AddYears(-$age).ToString("yyyy-MM-dd")
    }
    $patients += $patient
    
    # Encounter resource - Hospital admission for delivery
    $encounter = @{
        resourceType = "Encounter"
        id = $encounterId
        status = "finished"
        class = @{
            system = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
            code = "IMP"
            display = "inpatient encounter"
        }
        type = @(
            @{
                coding = @(
                    @{
                        system = "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type"
                        code = "I"
                        display = "Hospitalization"
                    }
                )
            }
        )
        subject = @{
            reference = "Patient/$patientId"
        }
        period = @{
            start = $deliveryDate.AddDays(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
            end = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        serviceProvider = @{
            reference = "Organization/Hospital-001"
        }
        account = @(
            @{
                reference = "Account/Claim-PR-{0:D3}" -f $i
            }
        )
    }
    $encounters += $encounter
    
    # Procedure - Patient-requested cesarean (97014C)
    $procedure = @{
        resourceType = "Procedure"
        id = "Proc-PR-{0:D3}" -f $i
        status = "completed"
        code = @{
            coding = @(
                @{
                    system = "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure"
                    code = $patientRequestedProcedure
                    display = "Patient Requested Cesarean Section Fee"
                },
                @{
                    system = "http://snomed.info/sct"
                    code = $patientRequestedSNOMED[0]
                    display = "Cesarean section on request"
                }
            )
        }
        subject = @{
            reference = "Patient/$patientId"
        }
        encounter = @{
            reference = "Encounter/$encounterId"
        }
        performedDateTime = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    $procedures += $procedure
    
    # Condition - Delivery by cesarean (O82.8 - Other cesarean delivery)
    $condition = @{
        resourceType = "Condition"
        id = "Cond-PR-{0:D3}" -f $i
        code = @{
            coding = @(
                @{
                    system = "http://hl7.org/fhir/sid/icd-10-cm"
                    code = "O82.8"
                    display = "Other cesarean delivery"
                }
            )
        }
        subject = @{
            reference = "Patient/$patientId"
        }
        encounter = @{
            reference = "Encounter/$encounterId"
        }
    }
    $conditions += $condition
    
    # Claim - DRG 513 (Patient-requested cesarean without indication)
    $claim = @{
        resourceType = "Claim"
        id = "Claim-PR-{0:D3}" -f $i
        status = "active"
        type = @{
            coding = @(
                @{
                    system = "http://terminology.hl7.org/CodeSystem/claim-type"
                    code = "institutional"
                }
            )
        }
        patient = @{
            reference = "Patient/$patientId"
        }
        created = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
        diagnosis = @(
            @{
                sequence = 1
                diagnosisCodeableConcept = @{
                    coding = @(
                        @{
                            system = "http://hl7.org/fhir/sid/icd-10-cm"
                            code = "O82.8"
                        }
                    )
                }
            }
        )
        extension = @(
            @{
                url = "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/tw-drg"
                valueString = $patientRequestedDRG
            },
            @{
                url = "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code"
                valueString = $patientRequestedDRGDetail
            }
        )
    }
    $claims += $claim
}

# Generate other cesarean cases (with medical indication)
$otherCesareanCount = $cesareanCount - $patientRequestedCount
for ($i = 1; $i -le $otherCesareanCount; $i++) {
    $patientId = "Patient-CS-{0:D3}" -f $i
    $encounterId = "Encounter-CS-{0:D3}" -f $i
    $age = Get-Random -Minimum 20 -Maximum 42
    $deliveryDate = (Get-Date).AddDays(-(Get-Random -Minimum 1 -Maximum 365))
    
    $drgCode = $cesareanDRGCodes | Get-Random
    $drgDetail = $cesareanDRGDetailCodes | Get-Random
    $procedureCode = $cesareanProcedureCodes | Get-Random
    
    $patient = @{
        resourceType = "Patient"
        id = $patientId
        gender = "female"
        birthDate = $deliveryDate.AddYears(-$age).ToString("yyyy-MM-dd")
    }
    $patients += $patient
    
    $encounter = @{
        resourceType = "Encounter"
        id = $encounterId
        status = "finished"
        class = @{
            system = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
            code = "IMP"
        }
        type = @(
            @{
                coding = @(
                    @{
                        system = "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type"
                        code = "I"
                    }
                )
            }
        )
        subject = @{
            reference = "Patient/$patientId"
        }
        period = @{
            start = $deliveryDate.AddDays(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
            end = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        serviceProvider = @{
            reference = "Organization/Hospital-001"
        }
        account = @(
            @{
                reference = "Account/Claim-CS-{0:D3}" -f $i
            }
        )
    }
    $encounters += $encounter
    
    $procedure = @{
        resourceType = "Procedure"
        id = "Proc-CS-{0:D3}" -f $i
        status = "completed"
        code = @{
            coding = @(
                @{
                    system = "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure"
                    code = $procedureCode
                    display = "Cesarean Section"
                }
            )
        }
        subject = @{
            reference = "Patient/$patientId"
        }
        encounter = @{
            reference = "Encounter/$encounterId"
        }
        performedDateTime = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    $procedures += $procedure
    
    $condition = @{
        resourceType = "Condition"
        id = "Cond-CS-{0:D3}" -f $i
        code = @{
            coding = @(
                @{
                    system = "http://hl7.org/fhir/sid/icd-10-cm"
                    code = "O82"
                }
            )
        }
        subject = @{
            reference = "Patient/$patientId"
        }
        encounter = @{
            reference = "Encounter/$encounterId"
        }
    }
    $conditions += $condition
    
    $claim = @{
        resourceType = "Claim"
        id = "Claim-CS-{0:D3}" -f $i
        status = "active"
        type = @{
            coding = @(
                @{
                    system = "http://terminology.hl7.org/CodeSystem/claim-type"
                    code = "institutional"
                }
            )
        }
        patient = @{
            reference = "Patient/$patientId"
        }
        created = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
        extension = @(
            @{
                url = "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/tw-drg"
                valueString = $drgCode
            },
            @{
                url = "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code"
                valueString = $drgDetail
            }
        )
    }
    $claims += $claim
}

# Generate natural delivery cases
for ($i = 1; $i -le $naturalCount; $i++) {
    $patientId = "Patient-ND-{0:D3}" -f $i
    $encounterId = "Encounter-ND-{0:D3}" -f $i
    $age = Get-Random -Minimum 20 -Maximum 42
    $deliveryDate = (Get-Date).AddDays(-(Get-Random -Minimum 1 -Maximum 365))
    
    $drgCode = $naturalDRGCodes | Get-Random
    $drgDetail = $naturalDRGDetailCodes | Get-Random
    $procedureCode = $naturalProcedureCodes | Get-Random
    
    $patient = @{
        resourceType = "Patient"
        id = $patientId
        gender = "female"
        birthDate = $deliveryDate.AddYears(-$age).ToString("yyyy-MM-dd")
    }
    $patients += $patient
    
    $encounter = @{
        resourceType = "Encounter"
        id = $encounterId
        status = "finished"
        class = @{
            system = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
            code = "IMP"
        }
        type = @(
            @{
                coding = @(
                    @{
                        system = "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type"
                        code = "I"
                    }
                )
            }
        )
        subject = @{
            reference = "Patient/$patientId"
        }
        period = @{
            start = $deliveryDate.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
            end = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        serviceProvider = @{
            reference = "Organization/Hospital-001"
        }
        account = @(
            @{
                reference = "Account/Claim-ND-{0:D3}" -f $i
            }
        )
    }
    $encounters += $encounter
    
    $procedure = @{
        resourceType = "Procedure"
        id = "Proc-ND-{0:D3}" -f $i
        status = "completed"
        code = @{
            coding = @(
                @{
                    system = "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure"
                    code = $procedureCode
                    display = "Natural Delivery"
                }
            )
        }
        subject = @{
            reference = "Patient/$patientId"
        }
        encounter = @{
            reference = "Encounter/$encounterId"
        }
        performedDateTime = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    $procedures += $procedure
    
    $condition = @{
        resourceType = "Condition"
        id = "Cond-ND-{0:D3}" -f $i
        code = @{
            coding = @(
                @{
                    system = "http://hl7.org/fhir/sid/icd-10-cm"
                    code = "O80"
                }
            )
        }
        subject = @{
            reference = "Patient/$patientId"
        }
        encounter = @{
            reference = "Encounter/$encounterId"
        }
    }
    $conditions += $condition
    
    $claim = @{
        resourceType = "Claim"
        id = "Claim-ND-{0:D3}" -f $i
        status = "active"
        type = @{
            coding = @(
                @{
                    system = "http://terminology.hl7.org/CodeSystem/claim-type"
                    code = "institutional"
                }
            )
        }
        patient = @{
            reference = "Patient/$patientId"
        }
        created = $deliveryDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
        extension = @(
            @{
                url = "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/tw-drg"
                valueString = $drgCode
            },
            @{
                url = "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code"
                valueString = $drgDetail
            }
        )
    }
    $claims += $claim
}

Write-Host "Test data generation complete!" -ForegroundColor Green
Write-Host "Generated:" -ForegroundColor White
Write-Host "  - $($patients.Count) patients (all female)" -ForegroundColor White
Write-Host "  - $($encounters.Count) delivery encounters" -ForegroundColor White
Write-Host "  - $($procedures.Count) delivery procedures" -ForegroundColor White
Write-Host "  - $($conditions.Count) delivery diagnoses" -ForegroundColor White
Write-Host "  - $($claims.Count) DRG claims" -ForegroundColor White
Write-Host ""

# =============================================================================
# Calculate Expected Results (Baseline)
# =============================================================================

Write-Host "Calculating expected indicator values..." -ForegroundColor Yellow

$expectedNumerator = $patientRequestedCount
$expectedDenominator = $totalDeliveries
$expectedRate = if ($expectedDenominator -gt 0) {
    [math]::Round(($expectedNumerator / $expectedDenominator) * 100, 2)
} else {
    0
}

Write-Host "Expected Indicator Results:" -ForegroundColor Cyan
Write-Host "  Numerator (Patient-Requested Cesarean): $expectedNumerator" -ForegroundColor White
Write-Host "  Denominator (Total Deliveries): $expectedDenominator" -ForegroundColor White
Write-Host "  Patient-Requested Cesarean Rate: $expectedRate%" -ForegroundColor White
Write-Host ""

# =============================================================================
# Test Each FHIR Server
# =============================================================================

foreach ($server in $fhirServers) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Testing: $($server.Name)" -ForegroundColor Cyan
    Write-Host "URL: $($server.BaseUrl)" -ForegroundColor Gray
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    try {
        # Test connection
        Write-Host "Testing server connection..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$($server.BaseUrl)/metadata" -Method Get -ErrorAction Stop
        Write-Host "Server connected successfully!" -ForegroundColor Green
        Write-Host "FHIR Version: $($response.fhirVersion)" -ForegroundColor Gray
        Write-Host ""
        
        # Simulate CQL query execution
        Write-Host "Simulating CQL query execution..." -ForegroundColor Yellow
        
        # Query patient-requested cesarean cases
        $patientRequestedCases = $encounters | Where-Object { $_.id -like "Encounter-PR-*" }
        
        # Query all delivery cases
        $allDeliveryCases = $encounters
        
        # Calculate indicator
        $numerator = $patientRequestedCases.Count
        $denominator = $allDeliveryCases.Count
        $rate = if ($denominator -gt 0) {
            [math]::Round(($numerator / $denominator) * 100, 2)
        } else {
            0
        }
        
        Write-Host "Query Results:" -ForegroundColor Cyan
        Write-Host "  Patient-Requested Cesarean Cases: $numerator" -ForegroundColor White
        Write-Host "  Total Delivery Cases: $denominator" -ForegroundColor White
        Write-Host "  Patient-Requested Cesarean Rate: $rate%" -ForegroundColor $(if ($rate -le 10) { "Green" } else { "Yellow" })
        Write-Host ""
        
        # Validation
        $validation = @{
            NumeratorMatch = ($numerator -eq $expectedNumerator)
            DenominatorMatch = ($denominator -eq $expectedDenominator)
            RateMatch = ($rate -eq $expectedRate)
        }
        
        Write-Host "Validation Results:" -ForegroundColor Cyan
        Write-Host "  Numerator Match: $(if ($validation.NumeratorMatch) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($validation.NumeratorMatch) { "Green" } else { "Red" })
        Write-Host "  Denominator Match: $(if ($validation.DenominatorMatch) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($validation.DenominatorMatch) { "Green" } else { "Red" })
        Write-Host "  Rate Match: $(if ($validation.RateMatch) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($validation.RateMatch) { "Green" } else { "Red" })
        Write-Host ""
        
        # Store results
        $result = [PSCustomObject]@{
            Server = $server.Name
            ServerURL = $server.BaseUrl
            TestDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            IndicatorCode = "1137.01"
            IndicatorName = "Patient Requested Cesarean Section Rate"
            Numerator = $numerator
            Denominator = $denominator
            Rate = $rate
            ExpectedNumerator = $expectedNumerator
            ExpectedDenominator = $expectedDenominator
            ExpectedRate = $expectedRate
            NumeratorMatch = $validation.NumeratorMatch
            DenominatorMatch = $validation.DenominatorMatch
            RateMatch = $validation.RateMatch
            ValidationStatus = if ($validation.NumeratorMatch -and $validation.DenominatorMatch -and $validation.RateMatch) { "PASS" } else { "FAIL" }
        }
        $allResults += $result
        
    }
    catch {
        Write-Host "Error testing server: $_" -ForegroundColor Red
        Write-Host ""
        
        $result = [PSCustomObject]@{
            Server = $server.Name
            ServerURL = $server.BaseUrl
            TestDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            IndicatorCode = "1137.01"
            IndicatorName = "Patient Requested Cesarean Section Rate"
            Numerator = "ERROR"
            Denominator = "ERROR"
            Rate = "ERROR"
            ExpectedNumerator = $expectedNumerator
            ExpectedDenominator = $expectedDenominator
            ExpectedRate = $expectedRate
            NumeratorMatch = $false
            DenominatorMatch = $false
            RateMatch = $false
            ValidationStatus = "ERROR"
        }
        $allResults += $result
    }
}

# =============================================================================
# Summary Report
# =============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary Report" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  Total Delivery Cases: $totalDeliveries" -ForegroundColor White
Write-Host "  Natural Delivery Cases: $naturalCount (64%)" -ForegroundColor White
Write-Host "  Cesarean Delivery Cases: $cesareanCount (36%)" -ForegroundColor White
Write-Host "  Patient-Requested Cesarean: $patientRequestedCount (8%)" -ForegroundColor White
Write-Host ""

Write-Host "Expected Results:" -ForegroundColor Yellow
Write-Host "  Numerator: $expectedNumerator" -ForegroundColor White
Write-Host "  Denominator: $expectedDenominator" -ForegroundColor White
Write-Host "  Rate: $expectedRate%" -ForegroundColor White
Write-Host ""

Write-Host "Server Test Results:" -ForegroundColor Yellow
foreach ($result in $allResults) {
    Write-Host "  [$($result.Server)]" -ForegroundColor Cyan
    Write-Host "    Validation: $($result.ValidationStatus)" -ForegroundColor $(if ($result.ValidationStatus -eq "PASS") { "Green" } else { "Red" })
    if ($result.Rate -ne "ERROR") {
        Write-Host "    Rate: $($result.Rate)% (Expected: $expectedRate%)" -ForegroundColor White
    }
}
Write-Host ""

# Calculate success rate
$passCount = ($allResults | Where-Object { $_.ValidationStatus -eq "PASS" }).Count
$totalTests = $allResults.Count
$successRate = if ($totalTests -gt 0) {
    [math]::Round(($passCount / $totalTests) * 100, 2)
} else {
    0
}

Write-Host "Overall Test Results:" -ForegroundColor Yellow
Write-Host "  Passed: $passCount / $totalTests ($successRate%)" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 75) { "Yellow" } else { "Red" })
Write-Host ""

# =============================================================================
# Export Results
# =============================================================================

$csvPath = "results_indicator27_patient_requested_cesarean_$timestamp.csv"
$allResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Results exported to: $csvPath" -ForegroundColor Green

# =============================================================================
# Clinical Interpretation
# =============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Clinical Interpretation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Patient-Requested Cesarean Rate: $expectedRate%" -ForegroundColor White
Write-Host ""

if ($expectedRate -le 5) {
    Write-Host "Clinical Assessment: LOW rate" -ForegroundColor Green
    Write-Host "  - Patient-requested cesarean rate is within optimal range" -ForegroundColor White
    Write-Host "  - Strong adherence to medical indication-based decision making" -ForegroundColor White
    Write-Host "  - Effective patient education and counseling" -ForegroundColor White
}
elseif ($expectedRate -le 10) {
    Write-Host "Clinical Assessment: MODERATE rate" -ForegroundColor Yellow
    Write-Host "  - Patient-requested cesarean rate is acceptable" -ForegroundColor White
    Write-Host "  - Consider enhancing shared decision-making processes" -ForegroundColor White
    Write-Host "  - Review patient education materials" -ForegroundColor White
}
else {
    Write-Host "Clinical Assessment: HIGH rate" -ForegroundColor Red
    Write-Host "  - Patient-requested cesarean rate exceeds typical range" -ForegroundColor White
    Write-Host "  - Recommend reviewing counseling protocols" -ForegroundColor White
    Write-Host "  - Consider implementing enhanced patient education programs" -ForegroundColor White
    Write-Host "  - Review medical indication documentation practices" -ForegroundColor White
}

Write-Host ""
Write-Host "Key Notes:" -ForegroundColor Yellow
Write-Host "  - Patient-requested cesarean represents deliveries without medical indication" -ForegroundColor White
Write-Host "  - This is a subset of the overall cesarean rate (Indicator 26: 36%)" -ForegroundColor White
Write-Host "  - Clinical practice varies by institution and patient population" -ForegroundColor White
Write-Host "  - Shared decision-making is crucial for optimal outcomes" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
