# SMART on FHIR Data Fetch Script
# PowerShell version for Windows
# Date Range: 2024Q1 - 2025Q4 (to 2025-11-06)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMART on FHIR Data Fetch Tool" -ForegroundColor Cyan
Write-Host "Date Range: 2024-01-01 to 2025-11-06" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# FHIR Servers
$servers = @(
    @{
        Name = 'HAPI FHIR Test Server'
        BaseUrl = 'https://hapi.fhir.org/baseR4'
    },
    @{
        Name = 'SMART Health IT'
        BaseUrl = 'https://launch.smarthealthit.org/v/r4/fhir'
    }
)

# Quarters
$quarters = @(
    @{Q='2024Q1'; Start='2024-01-01'; End='2024-03-31'},
    @{Q='2024Q2'; Start='2024-04-01'; End='2024-06-30'},
    @{Q='2024Q3'; Start='2024-07-01'; End='2024-09-30'},
    @{Q='2024Q4'; Start='2024-10-01'; End='2024-12-31'},
    @{Q='2025Q1'; Start='2025-01-01'; End='2025-03-31'},
    @{Q='2025Q2'; Start='2025-04-01'; End='2025-06-30'},
    @{Q='2025Q3'; Start='2025-07-01'; End='2025-09-30'},
    @{Q='2025Q4'; Start='2025-10-01'; End='2025-11-06'}
)

# Baseline (111Q1 = 2022Q1)
$baseline = @{Injection=54653; Total=5831409; Rate=0.94}

# Test FHIR Connection
function Test-Connection {
    param([string]$url, [string]$name)
    
    try {
        Write-Host "Testing: $name" -ForegroundColor Yellow
        $metaUrl = "$url/metadata"
        $response = Invoke-RestMethod -Uri $metaUrl -Method Get -TimeoutSec 10
        
        if ($response.resourceType -eq 'CapabilityStatement') {
            Write-Host "Connected! FHIR: $($response.fhirVersion)" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get MedicationRequest
function Get-Medications {
    param([string]$url, [string]$start, [string]$end)
    
    try {
        $queryUrl = $url + '/MedicationRequest?date=ge' + $start + '&date=le' + $end + '&status=completed&_count=50'
        $response = Invoke-RestMethod -Uri $queryUrl -Method Get -TimeoutSec 30
        
        if ($response.resourceType -eq 'Bundle') {
            Write-Host "  Found $($response.entry.Count) MedicationRequests" -ForegroundColor Gray
            return $response.entry.Count
        }
        return 0
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        return 0
    }
}

# Get Encounters
function Get-Encounters {
    param([string]$url, [string]$start, [string]$end)
    
    try {
        $queryUrl = $url + '/Encounter?date=ge' + $start + '&date=le' + $end + '&class=AMB&status=finished&_count=50'
        $response = Invoke-RestMethod -Uri $queryUrl -Method Get -TimeoutSec 30
        
        if ($response.resourceType -eq 'Bundle') {
            Write-Host "  Found $($response.entry.Count) Encounters" -ForegroundColor Gray
            return $response.entry.Count
        }
        return 0
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        return 0
    }
}

# Main
$allResults = @()

foreach ($server in $servers) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Server: $($server.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $connected = Test-Connection -url $server.BaseUrl -name $server.Name
    
    if (-not $connected) {
        Write-Host "Skipping...`n" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`nFetching data..." -ForegroundColor Yellow
    
    $results = @()
    $totalMeds = 0
    $totalEncs = 0
    
    foreach ($q in $quarters) {
        Write-Host "`n  Processing $($q.Q)..." -ForegroundColor White
        
        $meds = Get-Medications -url $server.BaseUrl -start $q.Start -end $q.End
        $encs = Get-Encounters -url $server.BaseUrl -start $q.Start -end $q.End
        
        $totalMeds += $meds
        $totalEncs += $encs
        
        $rate = if ($encs -gt 0) { ($meds / $encs) * 100 } else { 0 }
        $diff = $rate - $baseline.Rate
        
        $rating = if ($rate -le $baseline.Rate) { 'Good' } 
                 elseif ($rate -le 1.5) { 'OK' } 
                 else { 'High' }
        
        $results += [PSCustomObject]@{
            Quarter = $q.Q
            Injections = $meds
            Encounters = $encs
            Rate = [math]::Round($rate, 2)
            Diff = [math]::Round($diff, 2)
            Rating = $rating
        }
    }
    
    Write-Host "`nTotal fetched:" -ForegroundColor Green
    Write-Host "  Medications: $totalMeds" -ForegroundColor White
    Write-Host "  Encounters: $totalEncs`n" -ForegroundColor White
    
    # Display results
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Results for $($server.Name)" -ForegroundColor Cyan
    Write-Host "Baseline: $($baseline.Rate)% ($($baseline.Injection)/$($baseline.Total))" -ForegroundColor White
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $results | Format-Table -AutoSize
    
    # Save CSV
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $csvFile = "results_$($server.Name.Replace(' ','_'))_$timestamp.csv"
    $results | Export-Csv -Path $csvFile -Encoding UTF8 -NoTypeInformation
    Write-Host "Saved to: $csvFile`n" -ForegroundColor Green
    
    $allResults += @{Server=$server.Name; Total=$totalMeds}
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "COMPLETED!" -ForegroundColor Green
Write-Host "Fetched from $($allResults.Count) FHIR servers" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($r in $allResults) {
    Write-Host "  $($r.Server): $($r.Total) medications" -ForegroundColor White
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
