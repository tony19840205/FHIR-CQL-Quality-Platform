# ============================================
# SMART on FHIR Real Data Fetch Script
# Target: Public FHIR Test Servers
# Period: 2024Q1 - 2025Q4
# ============================================

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR Data Retrieval - Injection Usage Rate" -ForegroundColor Cyan
Write-Host "Period: 2024Q1 - 2025Q4" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# FHIR Server Endpoints (Public Test Servers)
$fhirServers = @(
    @{
        Name = "HAPI FHIR R4 (UHN)"
        Url = "https://hapi.fhir.org/baseR4"
        Type = "Public Test Server"
    },
    @{
        Name = "Smart Health IT (HSPC)"
        Url = "https://r4.smarthealthit.org"
        Type = "Smart Test Server"
    }
)

# Initialize results
$allResults = @()
$quarterStats = @{}

# Process each FHIR server
foreach ($server in $fhirServers) {
    Write-Host "`n[Server: $($server.Name)]" -ForegroundColor Green
    Write-Host "Endpoint: $($server.Url)" -ForegroundColor Gray
    
    try {
        # Query MedicationRequest for injections (2024-2025)
        $medicationUrl = "$($server.Url)/MedicationRequest?date=ge2024-01-01&date=le2025-11-06&_count=100"
        Write-Host "Fetching MedicationRequest..." -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri $medicationUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        if ($response.total -gt 0) {
            Write-Host "  Found: $($response.total) records" -ForegroundColor Green
            
            # Process entries
            $injectionCount = 0
            $totalCount = 0
            
            foreach ($entry in $response.entry) {
                $resource = $entry.resource
                $totalCount++
                
                # Check if route is injection (SNOMED: 385219001)
                if ($resource.dosageInstruction) {
                    foreach ($dosage in $resource.dosageInstruction) {
                        if ($dosage.route.coding) {
                            foreach ($coding in $dosage.route.coding) {
                                if ($coding.code -eq "385219001" -or $coding.display -like "*inject*") {
                                    $injectionCount++
                                    
                                    # Extract date and quarter
                                    $authDate = $resource.authoredOn
                                    if ($authDate) {
                                        $date = [DateTime]::Parse($authDate)
                                        $year = $date.Year
                                        $quarter = [Math]::Ceiling($date.Month / 3)
                                        $quarterKey = "${year}Q${quarter}"
                                        
                                        if (-not $quarterStats.ContainsKey($quarterKey)) {
                                            $quarterStats[$quarterKey] = @{
                                                Injections = 0
                                                Total = 0
                                            }
                                        }
                                        $quarterStats[$quarterKey].Injections++
                                        $quarterStats[$quarterKey].Total++
                                    }
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            Write-Host "  Injection records: $injectionCount / $totalCount" -ForegroundColor Cyan
        } else {
            Write-Host "  No data found" -ForegroundColor Yellow
        }
        
        # Query Encounter data
        $encounterUrl = "$($server.Url)/Encounter?date=ge2024-01-01&date=le2025-11-06&class=AMB&_count=50"
        Write-Host "Fetching Encounter..." -ForegroundColor Yellow
        
        $encounterResponse = Invoke-RestMethod -Uri $encounterUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        
        if ($encounterResponse.total -gt 0) {
            Write-Host "  Found: $($encounterResponse.total) encounters" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Display Results (like the image format)
Write-Host "`n`n==================================================" -ForegroundColor Cyan
Write-Host "Final Results - Injection Usage Rate by Quarter" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$outputTable = @()

# Reference data from image (111年第1季 = 2022Q1)
Write-Host "`n[Reference Baseline - 2022Q1]" -ForegroundColor Magenta
Write-Host "+------------------+------------------+" -ForegroundColor White
Write-Host "| 項目             | 數值             |" -ForegroundColor White
Write-Host "+------------------+------------------+" -ForegroundColor White
Write-Host "| 針劑給藥案件數   |          54,653  |" -ForegroundColor White
Write-Host "| 給藥案件數       |       5,831,409  |" -ForegroundColor White
Write-Host "| 注射劑使用率     |            0.94% |" -ForegroundColor White
Write-Host "+------------------+------------------+" -ForegroundColor White

# Process 2024-2025 quarters
Write-Host "`n[Current Data - 2024Q1 to 2025Q4]" -ForegroundColor Magenta

$quarters = @("2024Q1", "2024Q2", "2024Q3", "2024Q4", "2025Q1", "2025Q2", "2025Q3", "2025Q4")

foreach ($q in $quarters) {
    if ($quarterStats.ContainsKey($q)) {
        $data = $quarterStats[$q]
        $rate = if ($data.Total -gt 0) { 
            [math]::Round(($data.Injections / $data.Total) * 100, 2) 
        } else { 
            0 
        }
        
        Write-Host "`n[$q]" -ForegroundColor Yellow
        Write-Host "+------------------+------------------+" -ForegroundColor White
        Write-Host "| 項目             | 數值             |" -ForegroundColor White
        Write-Host "+------------------+------------------+" -ForegroundColor White
        Write-Host ("| 針劑給藥案件數   | " + ("{0,15:N0}" -f $data.Injections) + " |") -ForegroundColor White
        Write-Host ("| 給藥案件數       | " + ("{0,15:N0}" -f $data.Total) + " |") -ForegroundColor White
        Write-Host ("| 注射劑使用率     | " + ("{0,14:N2}" -f $rate) + "% |") -ForegroundColor White
        Write-Host "+------------------+------------------+" -ForegroundColor White
        
        # Compare with baseline
        $diff = $rate - 0.94
        $comparison = if ($diff -gt 0) { "高於基準 +$([math]::Round($diff, 2))%" } else { "低於基準 $([math]::Round($diff, 2))%" }
        Write-Host "  vs 基準(0.94%): $comparison" -ForegroundColor $(if ($diff -gt 0) { "Red" } else { "Green" })
    } else {
        Write-Host "`n[$q] - No data available" -ForegroundColor Gray
    }
}

# Export to CSV
$csvPath = ".\results\fhir_injection_usage_report.csv"
New-Item -ItemType Directory -Force -Path ".\results" | Out-Null

$csvData = @()
foreach ($q in $quarters) {
    if ($quarterStats.ContainsKey($q)) {
        $data = $quarterStats[$q]
        $rate = if ($data.Total -gt 0) { 
            [math]::Round(($data.Injections / $data.Total) * 100, 2) 
        } else { 
            0 
        }
        
        $csvData += [PSCustomObject]@{
            Quarter = $q
            InjectionCases = $data.Injections
            TotalCases = $data.Total
            UsageRate = $rate
            Baseline = 0.94
            Difference = [math]::Round($rate - 0.94, 2)
        }
    }
}

$csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "`n`nReport exported to: $csvPath" -ForegroundColor Green

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Data retrieval completed!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
