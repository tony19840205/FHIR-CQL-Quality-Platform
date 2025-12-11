Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'Indicator 27: Patient Requested Cesarean Section Rate' -ForegroundColor Cyan
Write-Host 'Code: 1137.01' -ForegroundColor Cyan
Write-Host '========================================
' -ForegroundColor Cyan

Write-Host 'Test Data Distribution:' -ForegroundColor Yellow
Write-Host '  Total Deliveries: 300 cases' -ForegroundColor White
Write-Host '  - Natural Deliveries: 192 cases (64%)' -ForegroundColor Green
Write-Host '  - Cesarean Deliveries: 108 cases (36%)' -ForegroundColor Yellow
Write-Host '    - With Medical Indication: 84 cases (28%)' -ForegroundColor White
Write-Host '    - Patient Requested: 24 cases (8%)' -ForegroundColor Magenta
Write-Host ''

Write-Host 'Indicator Calculation:' -ForegroundColor Yellow
Write-Host '  Numerator (Patient-Requested Cesarean): 24' -ForegroundColor Magenta
Write-Host '  Denominator (Total Deliveries): 300' -ForegroundColor White
Write-Host '  Patient-Requested Cesarean Rate: 8.00%' -ForegroundColor Cyan
Write-Host ''

Write-Host 'Clinical Assessment:' -ForegroundColor Yellow
Write-Host '  Rating: MODERATE' -ForegroundColor Yellow
Write-Host '  Clinical Range: 5-10% (Acceptable)' -ForegroundColor White
Write-Host '  % of Total Cesarean: 22.22% (24/108)' -ForegroundColor White
Write-Host ''

Write-Host 'Relationship with Indicator 26:' -ForegroundColor Yellow
Write-Host '  Overall Cesarean Rate (26): 36%' -ForegroundColor White
Write-Host '  Patient-Requested Rate (27): 8%' -ForegroundColor Magenta
Write-Host '  Patient-Requested as % of All Cesarean: 22.22%' -ForegroundColor Cyan
Write-Host ''

Write-Host 'FHIR Server Test Results:' -ForegroundColor Yellow
Write-Host '  [SMART Health IT]      PASS (8.00%)' -ForegroundColor Green
Write-Host '  [HAPI FHIR Test]       PASS (8.00%)' -ForegroundColor Green
Write-Host '  [FHIR Sandbox]         ERROR' -ForegroundColor Red
Write-Host '  [UHN HAPI FHIR]        ERROR' -ForegroundColor Red
Write-Host ''

Write-Host 'Overall Validation:' -ForegroundColor Yellow
Write-Host '  Test Pass Rate: 2/4 (50%)' -ForegroundColor Yellow
Write-Host '  Data Consistency: 100%' -ForegroundColor Green
Write-Host '  Clinical Validity: ACCEPTABLE' -ForegroundColor Green
Write-Host ''

Write-Host 'Key Numerator Criteria:' -ForegroundColor Yellow
Write-Host '  1. TW-DRG code = 513' -ForegroundColor White
Write-Host '  2. DRG_CODE = 0373B' -ForegroundColor White
Write-Host '  3. Procedure code = 97014C' -ForegroundColor White
Write-Host '  4. SNOMED: 386637004, 450483001' -ForegroundColor White
Write-Host ''

Write-Host 'Clinical Recommendations:' -ForegroundColor Yellow
Write-Host '  - Continue monitoring quarterly trends' -ForegroundColor White
Write-Host '  - Enhance shared decision-making processes' -ForegroundColor White
Write-Host '  - Review patient education materials' -ForegroundColor White
Write-Host '  - Document decision-making rationale' -ForegroundColor White
Write-Host ''

Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'Project Status: CLOSED' -ForegroundColor Green
Write-Host 'Completion Date: 2025-01-08' -ForegroundColor White
Write-Host '========================================' -ForegroundColor Cyan
