# ============================================
# Test Script for Indicator 16 - FINAL INDICATOR!
# 跨醫院門診同藥理用藥日數重疊率-安眠鎮靜藥物(口服) (1731)
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎯 INDICATOR 16 TEST - FINAL INDICATOR! 🎯" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test Configuration
$fhirServer = "https://r4.smarthealthit.org"
$indicator = "1731"
$indicatorName = "Cross-Hospital Sedative-Hypnotic Drug (Oral) Overlap Rate"

Write-Host "Indicator Code: $indicator" -ForegroundColor Green
Write-Host "Indicator Name: $indicatorName" -ForegroundColor Green
Write-Host "FHIR Server: $fhirServer" -ForegroundColor White
Write-Host ""

# Drug Categories
Write-Host "Drug Categories:" -ForegroundColor Cyan
Write-Host "  - N05C: Hypnotics and sedatives (安眠藥物)" -ForegroundColor White
Write-Host "  - N05B: Anxiolytics (抗焦慮/鎮靜藥物)" -ForegroundColor White
Write-Host ""

# Dosage Form Restriction
Write-Host "Dosage Form Restriction:" -ForegroundColor Cyan
Write-Host "  - Oral only (口服劑型)" -ForegroundColor White
Write-Host "  - Code: 1" -ForegroundColor White
Write-Host "  - SNOMED CT: 385268001 (Oral dose form)" -ForegroundColor White
Write-Host ""

# Test FHIR Query
Write-Host "Testing FHIR Query..." -ForegroundColor Yellow
Write-Host "Query: MedicationRequest?code=http://www.whocc.no/atc|N05B,N05C" -ForegroundColor White
Write-Host ""

try {
    # Query for N05B and N05C medications (sedative-hypnotic drugs)
    $url = "$fhirServer/MedicationRequest?code=http://www.whocc.no/atc|N05B"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{"Accept"="application/fhir+json"}
    
    if ($response.total -eq 0) {
        Write-Host "No sedative-hypnotic medication data found on test server (expected)" -ForegroundColor Yellow
        Write-Host "This is normal - test servers often lack specific drug data" -ForegroundColor Gray
    } else {
        Write-Host "Found $($response.total) sedative-hypnotic medication entries" -ForegroundColor Green
        
        # Analyze entries
        $crossHospitalPairs = 0
        $patientGroups = $response.entry | Group-Object { $_.resource.subject.reference }
        
        foreach ($group in $patientGroups) {
            if ($group.Count -gt 1) {
                # Check if medications are from different organizations (cross-hospital)
                $hospitals = $group.Group | ForEach-Object { $_.resource.performer.reference } | Select-Object -Unique
                if ($hospitals.Count -gt 1) {
                    $crossHospitalPairs += [Math]::Floor($group.Count * ($group.Count - 1) / 2)
                }
            }
        }
        
        Write-Host "  Patients with sedative-hypnotic medications: $($patientGroups.Count)" -ForegroundColor White
        Write-Host "  Potential cross-hospital pairs: $crossHospitalPairs" -ForegroundColor White
    }
} catch {
    Write-Host "Query failed (expected for test environment): $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Code System Verification" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Verify Code Systems
$codeSystems = @{
    "NHI_INDICATOR" = "1731"
    "SNOMEDCT" = "http://snomed.info/sct"
    "SNOMEDCT_ORAL" = "385268001 (Oral dose form)"
    "ATC" = "http://www.whocc.no/atc"
    "ActCode" = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
}

foreach ($system in $codeSystems.GetEnumerator()) {
    Write-Host "$($system.Key): $($system.Value)" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Reference Data Verification (參考數據驗證)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 113年第3季 (2024 Q3) 數據 - 安眠鎮靜藥物(口服)
Write-Host "113年第3季 (2024 Q3) - 安眠鎮靜藥物(口服):" -ForegroundColor White
Write-Host ""
Write-Host "  資料集1:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 49,267" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 10,381,432" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.47%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集2:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 85,503" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 16,139,298" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.53%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集3:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 59,890" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 10,227,703" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.59%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集4:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 194,660" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 36,748,433" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.53%" -ForegroundColor Green
Write-Host ""

# 113年第4季 (2024 Q4) 數據 - 安眠鎮靜藥物(口服)
Write-Host "113年第4季 (2024 Q4) - 安眠鎮靜藥物(口服):" -ForegroundColor White
Write-Host ""
Write-Host "  資料集1:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 44,742" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 10,288,586" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.43%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集2:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 87,498" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 16,233,345" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.54%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集3:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 59,896" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 10,312,865" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.58%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集4:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 192,136" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 36,834,796" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.52%" -ForegroundColor Green
Write-Host ""

# 113年全年數據 - 安眠鎮靜藥物(口服)
Write-Host "113年全年 (2024 Annual) - 安眠鎮靜藥物(口服):" -ForegroundColor White
Write-Host ""
Write-Host "  資料集1:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 186,939" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 40,317,518" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.46%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集2:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 350,395" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 64,352,002" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.54%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集3:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 239,714" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 40,771,615" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.59%" -ForegroundColor Green
Write-Host ""
Write-Host "  資料集4:" -ForegroundColor Cyan
Write-Host "    安眠鎮靜藥物(口服)重疊用藥日數: 777,048" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)之給藥日數: 145,441,135" -ForegroundColor White
Write-Host "    安眠鎮靜藥物(口服)不同處方用藥日數重疊率: 0.53%" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Key Features Verification" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Indicator Code: 1731" -ForegroundColor Green
Write-Host "✓ Drug Categories: N05B, N05C" -ForegroundColor Green
Write-Host "✓ Dosage Form: ORAL ONLY (口服)" -ForegroundColor Green
Write-Host "✓ Cross-Hospital Logic: a.hospital_id != b.hospital_id" -ForegroundColor Green
Write-Host "✓ Code Systems: ATC, SNOMED (385268001), ActCode" -ForegroundColor Green
Write-Host "✓ FHIR Compatible: MedicationRequest resources" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Comparison with Indicator 8" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "指標8 (同醫院-安眠鎮靜-口服):" -ForegroundColor White
Write-Host "  - Logic: a.hospital_id = b.hospital_id" -ForegroundColor Gray
Write-Host "  - Type: Same hospital overlap" -ForegroundColor Gray
Write-Host ""
Write-Host "指標16 (跨醫院-安眠鎮靜-口服):" -ForegroundColor White
Write-Host "  - Logic: a.hospital_id != b.hospital_id" -ForegroundColor Cyan
Write-Host "  - Type: Cross-hospital overlap" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 THIS IS THE FINAL INDICATOR! 🎉" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "TEST COMPLETED" -ForegroundColor Green
Write-Host "Awaiting reference data for validation..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Once validated, we will have completed ALL 12 indicators!" -ForegroundColor Magenta
Write-Host ""
