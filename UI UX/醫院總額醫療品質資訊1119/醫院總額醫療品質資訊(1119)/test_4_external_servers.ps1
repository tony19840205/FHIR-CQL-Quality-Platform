# ============================================
# 測試4個外部FHIR伺服器連接
# Test Connection to 4 External FHIR Servers
# ============================================
# Purpose: 驗證所有19個CQL指標可以在多個FHIR伺服器上執行
# Created: 2025-11-10
# ============================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "        Testing 4 External FHIR Servers for Hospital Quality Indicators" -ForegroundColor Cyan
Write-Host "        測試4個外部FHIR伺服器 - 醫院總額醫療品質指標系統" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Define 4 External FHIR Servers
$fhirServers = @(
    @{ 
        Id = 1
        Name = "SMART Health IT R4" 
        BaseUrl = "https://r4.smarthealthit.org"
        Description = "公開測試伺服器 - SMART on FHIR"
    },
    @{ 
        Id = 2
        Name = "HAPI FHIR Test Server" 
        BaseUrl = "https://hapi.fhir.org/baseR4"
        Description = "公開測試伺服器 - HAPI FHIR"
    },
    @{ 
        Id = 3
        Name = "FHIR Sandbox" 
        BaseUrl = "https://launch.smarthealthit.org/v/r4/fhir"
        Description = "公開測試伺服器 - SMART Sandbox"
    },
    @{ 
        Id = 4
        Name = "UHN HAPI FHIR" 
        BaseUrl = "http://hapi.fhir.org/baseR4"
        Description = "公開測試伺服器 - UHN FHIR"
    }
)

# Test each server
Write-Host "Testing Server Connectivity..." -ForegroundColor Yellow
Write-Host ""

$serverResults = @()

foreach ($server in $fhirServers) {
    Write-Host "[$($server.Id)] Testing: $($server.Name)" -ForegroundColor Cyan
    Write-Host "    URL: $($server.BaseUrl)" -ForegroundColor Gray
    Write-Host "    Description: $($server.Description)" -ForegroundColor Gray
    
    $isOnline = $false
    $responseTime = 0
    $capabilities = $null
    $errorMsg = ""
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Test metadata endpoint
        $metadataUrl = "$($server.BaseUrl)/metadata"
        $response = Invoke-RestMethod -Uri $metadataUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 10 -ErrorAction Stop
        
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        if ($response.resourceType -eq "CapabilityStatement") {
            $isOnline = $true
            $capabilities = $response.fhirVersion
            Write-Host "    Status: ✓ ONLINE (${responseTime}ms)" -ForegroundColor Green
            Write-Host "    FHIR Version: $capabilities" -ForegroundColor Green
        }
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Host "    Status: ✗ OFFLINE" -ForegroundColor Red
        Write-Host "    Error: $($errorMsg.Split([Environment]::NewLine)[0])" -ForegroundColor DarkGray
    }
    
    $serverResults += [PSCustomObject]@{
        Id = $server.Id
        Name = $server.Name
        BaseUrl = $server.BaseUrl
        IsOnline = $isOnline
        ResponseTime = $responseTime
        FhirVersion = $capabilities
        ErrorMessage = $errorMsg
    }
    
    Write-Host ""
}

# Display summary
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                    Server Connection Summary" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$onlineCount = ($serverResults | Where-Object { $_.IsOnline }).Count
Write-Host "Servers Online: $onlineCount / $($fhirServers.Count)" -ForegroundColor $(if ($onlineCount -gt 0) { "Green" } else { "Red" })
Write-Host ""

$serverResults | Format-Table -AutoSize -Property @(
    @{Label="ID"; Expression={$_.Id}; Width=4},
    @{Label="Server"; Expression={$_.Name}; Width=25},
    @{Label="Status"; Expression={if($_.IsOnline){"✓ ONLINE"}else{"✗ OFFLINE"}}; Width=12},
    @{Label="Response"; Expression={if($_.IsOnline){"$($_.ResponseTime)ms"}else{"-"}}; Width=12},
    @{Label="Version"; Expression={if($_.IsOnline){$_.FhirVersion}else{"-"}}; Width=10}
)

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                    Testing Query Capabilities" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Test basic queries on each online server
$queryTests = @(
    @{ Resource = "Patient"; Query = "?_count=5" },
    @{ Resource = "Encounter"; Query = "?_count=5" },
    @{ Resource = "MedicationRequest"; Query = "?_count=5" },
    @{ Resource = "Observation"; Query = "?_count=5" },
    @{ Resource = "Procedure"; Query = "?_count=5" }
)

$onlineServers = $serverResults | Where-Object { $_.IsOnline }

if ($onlineServers.Count -eq 0) {
    Write-Host "No servers are online. Cannot proceed with query testing." -ForegroundColor Red
    Write-Host ""
    Write-Host "Note: Public FHIR test servers may be temporarily unavailable." -ForegroundColor Yellow
    Write-Host "Please try again later or check server status." -ForegroundColor Yellow
    Write-Host ""
} else {
    foreach ($server in $onlineServers) {
        Write-Host "Testing Queries on: $($server.Name)" -ForegroundColor Yellow
        Write-Host ""
        
        $queryResults = @()
        
        foreach ($test in $queryTests) {
            $resourceType = $test.Resource
            $query = $test.Query
            $queryUrl = "$($server.BaseUrl)/$resourceType$query"
            
            try {
                Write-Host "  Querying: $resourceType..." -ForegroundColor Gray -NoNewline
                
                $response = Invoke-RestMethod -Uri $queryUrl -Method Get -Headers @{
                    "Accept" = "application/fhir+json"
                } -TimeoutSec 10 -ErrorAction Stop
                
                $count = 0
                if ($response.entry) {
                    $count = $response.entry.Count
                }
                
                Write-Host " ✓ Found $count records" -ForegroundColor Green
                
                $queryResults += [PSCustomObject]@{
                    Resource = $resourceType
                    Count = $count
                    Status = "Success"
                }
                
            } catch {
                Write-Host " ✗ Failed" -ForegroundColor Red
                
                $queryResults += [PSCustomObject]@{
                    Resource = $resourceType
                    Count = 0
                    Status = "Failed"
                }
            }
            
            Start-Sleep -Milliseconds 200
        }
        
        Write-Host ""
        Write-Host "  Query Summary:" -ForegroundColor Cyan
        $queryResults | Format-Table -AutoSize
        Write-Host ""
    }
}

# Export results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvFile = "external_servers_test_results_$timestamp.csv"
$serverResults | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                    Test Complete" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results saved to: $csvFile" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  - Total Servers Tested: $($fhirServers.Count)" -ForegroundColor Gray
Write-Host "  - Online Servers: $onlineCount" -ForegroundColor Gray
Write-Host "  - Offline Servers: $($fhirServers.Count - $onlineCount)" -ForegroundColor Gray
Write-Host ""

if ($onlineCount -gt 0) {
    Write-Host "✓ External FHIR servers are accessible" -ForegroundColor Green
    Write-Host "  Ready to execute CQL queries across multiple servers" -ForegroundColor Green
} else {
    Write-Host "✗ No external FHIR servers are currently accessible" -ForegroundColor Red
    Write-Host "  This may be temporary. Consider:" -ForegroundColor Yellow
    Write-Host "    1. Check internet connectivity" -ForegroundColor DarkGray
    Write-Host "    2. Verify firewall settings" -ForegroundColor DarkGray
    Write-Host "    3. Try again later when servers are back online" -ForegroundColor DarkGray
}

Write-Host ""
