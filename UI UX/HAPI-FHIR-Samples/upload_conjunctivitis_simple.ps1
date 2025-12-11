# Upload Acute Conjunctivitis Test Data
# 4 Patients with 21 FHIR Resources

$ErrorActionPreference = "Continue"
$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"
$JSON_FILE = "Acute_Conjunctivitis_4_Patients.json"

Write-Host "========================================"
Write-Host "Upload Acute Conjunctivitis Data"
Write-Host "========================================"
Write-Host ""

if (-not (Test-Path $JSON_FILE)) {
    Write-Host "ERROR: File not found - $JSON_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Loading file: $JSON_FILE"
$bundle = Get-Content -Path $JSON_FILE -Raw -Encoding UTF8 | ConvertFrom-Json

$totalResources = $bundle.entry.Count
Write-Host "Total resources: $totalResources"
Write-Host ""

$successCount = 0
$failCount = 0

Write-Host "Uploading resources..."
Write-Host ""

foreach ($entry in $bundle.entry) {
    $resource = $entry.resource
    $resourceType = $resource.resourceType
    $resourceId = $resource.id
    
    if (-not $resourceId) {
        continue
    }
    
    $url = "$FHIR_SERVER/$resourceType/$resourceId"
    
    Write-Host "Uploading $resourceType : $resourceId" -NoNewline
    
    try {
        $json = $resource | ConvertTo-Json -Depth 10 -Compress
        $response = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json" -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        $failCount++
    }
    
    if (($successCount + $failCount) % 5 -eq 0) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "Upload Summary"
Write-Host "========================================"
Write-Host "Total: $totalResources"
Write-Host "Success: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host ""

Write-Host "Verifying patients..."
Write-Host ""

$patients = @(
    "conjunctivitis-patient-001",
    "conjunctivitis-patient-002",
    "conjunctivitis-patient-003",
    "conjunctivitis-patient-004"
)

foreach ($pid in $patients) {
    try {
        $p = Invoke-RestMethod -Uri "$FHIR_SERVER/Patient/$pid" -Method Get -ErrorAction Stop
        $name = $p.name[0].family + $p.name[0].given[0]
        Write-Host "[OK] $name - Patient/$pid" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Patient/$pid not found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done!"
