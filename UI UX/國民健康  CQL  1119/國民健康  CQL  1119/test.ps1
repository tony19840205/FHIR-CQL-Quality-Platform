# CQL Test System
Write-Host ""
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                               CQL Test System" -ForegroundColor Yellow
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""

# Load config
$config = Get-Content (Join-Path $PSScriptRoot "config.json") -Raw | ConvertFrom-Json

# Get max records setting (0 = unlimited)
$maxRecordsPerResource = if ($config.filters.max_records_per_resource) { 
    $config.filters.max_records_per_resource 
} else { 
    0  # Default to unlimited
}

$maxRecordsLabel = if ($maxRecordsPerResource -eq 0) { "無限制" } else { "$maxRecordsPerResource 筆" }
Write-Host "[1/5] Config loaded: $($config.fhir_servers.Count) servers, $($config.cql_libraries.Count) CQL libraries, 資料上限: $maxRecordsLabel" -ForegroundColor Green

# Initialize
$allPatients = @()
$allImmunizations = @()
$allConditions = @()
$allObservations = @()

# Connect to servers
Write-Host "[2/5] Connecting to FHIR servers..." -ForegroundColor Green

# Filter only enabled servers
$enabledServers = $config.fhir_servers | Where-Object { 
    -not $_.PSObject.Properties['enabled'] -or $_.enabled -eq $true 
}

foreach ($server in $enabledServers) {
    Write-Host "  Connecting to: $($server.name)" -ForegroundColor Yellow
    
    try {
        # Test connection
        $metaUrl = "$($server.base_url)/metadata"
        $meta = Invoke-RestMethod -Uri $metaUrl -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 10
        Write-Host "    [OK] FHIR $($meta.fhirVersion)" -ForegroundColor Green
        
        # Get Patient
        try {
            $url = "$($server.base_url)/Patient"
            $pageCount = 0
            $totalCount = 0
            
            $limitLabel = if ($maxRecordsPerResource -eq 0) { "無限制" } else { "上限 $maxRecordsPerResource 筆" }
            Write-Host "    正在擷取 Patient 資料 ($limitLabel)..." -ForegroundColor Gray
            
            do {
                $bundle = Invoke-RestMethod -Uri $url -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 60
                
                if ($bundle.entry) {
                    $allPatients += $bundle.entry
                    $totalCount += $bundle.entry.Count
                    $pageCount++
                    if ($pageCount % 5 -eq 0) {
                        Write-Host "      已擷取 $totalCount 筆 (第 $pageCount 頁)..." -ForegroundColor Gray
                    }
                }
                
                # 檢查是否有下一頁
                $nextLink = $null
                if ($bundle.link) {
                    foreach ($link in $bundle.link) {
                        if ($link.relation -eq "next") {
                            $nextLink = $link.url
                            break
                        }
                    }
                }
                
                $url = $nextLink
            } while ($nextLink -and ($maxRecordsPerResource -eq 0 -or $totalCount -lt $maxRecordsPerResource))
            
            if ($totalCount -gt 0) {
                Write-Host "    [OK] Patient: $totalCount ($pageCount 頁)" -ForegroundColor Green
            } else {
                Write-Host "    [INFO] Patient: 資料庫無相關資料" -ForegroundColor Cyan
            }
        } catch { Write-Host "    [WARN] Patient unavailable" -ForegroundColor Yellow }
        
        # Get Immunization (上限 1000 筆)
        try {
            $url = "$($server.base_url)/Immunization"
            $pageCount = 0
            $totalCount = 0
            # Max records handled by global $maxRecordsPerResource
            
            Write-Host "    正在擷取 Immunization 資料 ($limitLabel)..." -ForegroundColor Gray
            
            do {
                $bundle = Invoke-RestMethod -Uri $url -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 60
                
                if ($bundle.entry) {
                    $allImmunizations += $bundle.entry
                    $totalCount += $bundle.entry.Count
                    $pageCount++
                    if ($pageCount % 5 -eq 0) {
                        Write-Host "      已擷取 $totalCount 筆 (第 $pageCount 頁)..." -ForegroundColor Gray
                    }
                }
                
                $nextLink = $null
                if ($bundle.link) {
                    foreach ($link in $bundle.link) {
                        if ($link.relation -eq "next") {
                            $nextLink = $link.url
                            break
                        }
                    }
                }
                
                $url = $nextLink
            } while ($nextLink -and ($maxRecordsPerResource -eq 0 -or $totalCount -lt $maxRecordsPerResource))
            
            if ($totalCount -gt 0) {
                Write-Host "    [OK] Immunization: $totalCount ($pageCount 頁)" -ForegroundColor Green
            } else {
                Write-Host "    [INFO] Immunization: 資料庫無相關資料" -ForegroundColor Cyan
            }
        } catch { Write-Host "    [WARN] Immunization unavailable" -ForegroundColor Yellow }
        
        # Get Condition (上限 1000 筆)
        try {
            $url = "$($server.base_url)/Condition"
            $pageCount = 0
            $totalCount = 0
            # Max records handled by global $maxRecordsPerResource
            
            Write-Host "    正在擷取 Condition 資料 ($limitLabel)..." -ForegroundColor Gray
            
            do {
                $bundle = Invoke-RestMethod -Uri $url -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 60
                
                if ($bundle.entry) {
                    $allConditions += $bundle.entry
                    $totalCount += $bundle.entry.Count
                    $pageCount++
                    if ($pageCount % 5 -eq 0) {
                        Write-Host "      已擷取 $totalCount 筆 (第 $pageCount 頁)..." -ForegroundColor Gray
                    }
                }
                
                $nextLink = $null
                if ($bundle.link) {
                    foreach ($link in $bundle.link) {
                        if ($link.relation -eq "next") {
                            $nextLink = $link.url
                            break
                        }
                    }
                }
                
                $url = $nextLink
            } while ($nextLink -and ($maxRecordsPerResource -eq 0 -or $totalCount -lt $maxRecordsPerResource))
            
            if ($totalCount -gt 0) {
                Write-Host "    [OK] Condition: $totalCount ($pageCount 頁)" -ForegroundColor Green
            } else {
                Write-Host "    [INFO] Condition: 資料庫無相關資料" -ForegroundColor Cyan
            }
        } catch { Write-Host "    [WARN] Condition unavailable" -ForegroundColor Yellow }
        
        # Get Observation (上限 1000 筆)
        try {
            $url = "$($server.base_url)/Observation"
            $pageCount = 0
            $totalCount = 0
            # Max records handled by global $maxRecordsPerResource
            
            Write-Host "    正在擷取 Observation 資料 ($limitLabel)..." -ForegroundColor Gray
            
            do {
                $bundle = Invoke-RestMethod -Uri $url -Headers @{"Accept"="application/fhir+json"} -TimeoutSec 60
                
                if ($bundle.entry) {
                    $allObservations += $bundle.entry
                    $totalCount += $bundle.entry.Count
                    $pageCount++
                    if ($pageCount % 5 -eq 0) {
                        Write-Host "      已擷取 $totalCount 筆 (第 $pageCount 頁)..." -ForegroundColor Gray
                    }
                }
                
                $nextLink = $null
                if ($bundle.link) {
                    foreach ($link in $bundle.link) {
                        if ($link.relation -eq "next") {
                            $nextLink = $link.url
                            break
                        }
                    }
                }
                
                $url = $nextLink
            } while ($nextLink -and ($maxRecordsPerResource -eq 0 -or $totalCount -lt $maxRecordsPerResource))
            
            if ($totalCount -gt 0) {
                Write-Host "    [OK] Observation: $totalCount ($pageCount 頁)" -ForegroundColor Green
            } else {
                Write-Host "    [INFO] Observation: 資料庫無相關資料" -ForegroundColor Cyan
            }
        } catch { Write-Host "    [WARN] Observation unavailable" -ForegroundColor Yellow }
        
    } catch {
        Write-Host "    [ERROR] Connection failed" -ForegroundColor Red
    }
}

# Statistics
Write-Host ""
Write-Host "[3/5] Data retrieval summary..." -ForegroundColor Green
Write-Host "========================================================================================================" -ForegroundColor Cyan
if ($allPatients.Count -eq 0 -and $allImmunizations.Count -eq 0 -and $allConditions.Count -eq 0 -and $allObservations.Count -eq 0) {
    Write-Host "  資料庫無相關資料" -ForegroundColor Yellow
} else {
    Write-Host "  Patient:       $($allPatients.Count) $(if ($allPatients.Count -eq 0) { '(資料庫無相關資料)' })"
    Write-Host "  Immunization:  $($allImmunizations.Count) $(if ($allImmunizations.Count -eq 0) { '(資料庫無相關資料)' })"
    Write-Host "  Condition:     $($allConditions.Count) $(if ($allConditions.Count -eq 0) { '(資料庫無相關資料)' })"
    Write-Host "  Observation:   $($allObservations.Count) $(if ($allObservations.Count -eq 0) { '(資料庫無相關資料)' })"
}
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""

# Analysis
Write-Host "[4/5] Data analysis..." -ForegroundColor Green

if ($allPatients.Count -eq 0 -and $allImmunizations.Count -eq 0 -and $allConditions.Count -eq 0 -and $allObservations.Count -eq 0) {
    Write-Host "  資料庫無相關資料，無法進行分析" -ForegroundColor Yellow
} elseif ($allPatients.Count -gt 0) {
    Write-Host "`n  === 病人詳細資料 ===" -ForegroundColor Cyan
    Write-Host "    總病人數: $($allPatients.Count)"
    
    $patients = $allPatients | ForEach-Object { $_.resource }
    
    # 性別分布
    $genders = $patients | Group-Object -Property gender
    Write-Host "`n    性別分布:"
    foreach ($g in $genders) {
        $pct = [math]::Round(($g.Count * 100.0 / $allPatients.Count), 1)
        Write-Host "      $($g.Name): $($g.Count) ($pct%)"
    }
    
    # 年齡分布
    Write-Host "`n    年齡分布:"
    $ageGroups = @{
        "0-17歲" = 0
        "18-39歲" = 0
        "40-64歲" = 0
        "65歲以上" = 0
        "未知" = 0
    }
    
    foreach ($p in $patients) {
        if ($p.birthDate) {
            $birthYear = [datetime]::Parse($p.birthDate).Year
            $age = 2025 - $birthYear
            
            if ($age -lt 18) { $ageGroups["0-17歲"]++ }
            elseif ($age -lt 40) { $ageGroups["18-39歲"]++ }
            elseif ($age -lt 65) { $ageGroups["40-64歲"]++ }
            else { $ageGroups["65歲以上"]++ }
        } else {
            $ageGroups["未知"]++
        }
    }
    
    foreach ($ag in $ageGroups.GetEnumerator() | Sort-Object Name) {
        $pct = [math]::Round(($ag.Value * 100.0 / $allPatients.Count), 1)
        Write-Host "      $($ag.Key): $($ag.Value) ($pct%)"
    }
    
    # 地區分布
    Write-Host "`n    地區分布 (前10名):"
    $locations = @{}
    foreach ($p in $patients) {
        if ($p.address -and $p.address.Count -gt 0) {
            $addr = $p.address[0]
            $city = if ($addr.city) { $addr.city } else { "未知" }
            $state = if ($addr.state) { $addr.state } else { "未知" }
            $location = "$state - $city"
            
            if ($locations.ContainsKey($location)) { $locations[$location]++ }
            else { $locations[$location] = 1 }
        } else {
            if ($locations.ContainsKey("未知地區")) { $locations["未知地區"]++ }
            else { $locations["未知地區"] = 1 }
        }
    }
    
    $locations.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allPatients.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
}

if ($allImmunizations.Count -gt 0) {
    Write-Host "`n  === 疫苗接種詳細資料 ===" -ForegroundColor Cyan
    Write-Host "    總接種紀錄: $($allImmunizations.Count)"
    
    $vaccines = @{}
    $vaccineYears = @{}
    $vaccineStatus = @{}
    
    foreach ($entry in $allImmunizations) {
        $v = $entry.resource
        
        # 疫苗類型
        $name = if ($v.vaccineCode.text) { $v.vaccineCode.text } 
                elseif ($v.vaccineCode.coding) { $v.vaccineCode.coding[0].display } 
                else { "未知" }
        if ($vaccines.ContainsKey($name)) { $vaccines[$name]++ } 
        else { $vaccines[$name] = 1 }
        
        # 接種年份
        if ($v.occurrenceDateTime) {
            $year = [datetime]::Parse($v.occurrenceDateTime).Year
            if ($vaccineYears.ContainsKey($year)) { $vaccineYears[$year]++ }
            else { $vaccineYears[$year] = 1 }
        }
        
        # 接種狀態
        $status = if ($v.status) { $v.status } else { "未知" }
        if ($vaccineStatus.ContainsKey($status)) { $vaccineStatus[$status]++ }
        else { $vaccineStatus[$status] = 1 }
    }
    
    Write-Host "`n    疫苗類型分布 (前10名):"
    $vaccines.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allImmunizations.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
    
    Write-Host "`n    接種年份分布:"
    $vaccineYears.GetEnumerator() | Sort-Object Name -Descending | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allImmunizations.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
    
    Write-Host "`n    接種狀態:"
    $vaccineStatus.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allImmunizations.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
}

if ($allConditions.Count -gt 0) {
    Write-Host "`n  === 診斷詳細資料 ===" -ForegroundColor Cyan
    Write-Host "    總診斷紀錄: $($allConditions.Count)"
    
    $conditionTypes = @{}
    $conditionStatus = @{}
    $conditionCategories = @{}
    
    foreach ($entry in $allConditions) {
        $c = $entry.resource
        
        # 診斷類型
        $name = if ($c.code.text) { $c.code.text }
                elseif ($c.code.coding) { $c.code.coding[0].display }
                else { "未知" }
        if ($conditionTypes.ContainsKey($name)) { $conditionTypes[$name]++ }
        else { $conditionTypes[$name] = 1 }
        
        # 臨床狀態
        $status = if ($c.clinicalStatus -and $c.clinicalStatus.coding) { 
            $c.clinicalStatus.coding[0].code 
        } else { "未知" }
        if ($conditionStatus.ContainsKey($status)) { $conditionStatus[$status]++ }
        else { $conditionStatus[$status] = 1 }
        
        # 診斷類別
        if ($c.category) {
            foreach ($cat in $c.category) {
                $catName = if ($cat.coding) { $cat.coding[0].display } else { "未知" }
                if ($conditionCategories.ContainsKey($catName)) { $conditionCategories[$catName]++ }
                else { $conditionCategories[$catName] = 1 }
            }
        }
    }
    
    Write-Host "`n    診斷類型 (前15名):"
    $conditionTypes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 15 | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allConditions.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) 筆 ($pct%)"
    }
    
    Write-Host "`n    註: 病人去重邏輯已移至 CQL 層級處理" -ForegroundColor Yellow
    
    Write-Host "`n    臨床狀態:"
    $conditionStatus.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allConditions.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
    
    if ($conditionCategories.Count -gt 0) {
        Write-Host "`n    診斷類別:"
        $conditionCategories.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
            Write-Host "      $($_.Key): $($_.Value)"
        }
    }
}

if ($allObservations.Count -gt 0) {
    Write-Host "`n  === 觀察值詳細資料 ===" -ForegroundColor Cyan
    Write-Host "    總觀察紀錄: $($allObservations.Count)"
    
    $obsTypes = @{}
    $obsCategories = @{}
    $obsStatus = @{}
    
    foreach ($entry in $allObservations) {
        $o = $entry.resource
        
        # 觀察類型
        $name = if ($o.code.text) { $o.code.text }
                elseif ($o.code.coding) { $o.code.coding[0].display }
                else { "未知" }
        if ($obsTypes.ContainsKey($name)) { $obsTypes[$name]++ }
        else { $obsTypes[$name] = 1 }
        
        # 觀察類別
        if ($o.category) {
            foreach ($cat in $o.category) {
                $catName = if ($cat.coding) { $cat.coding[0].display } else { "未知" }
                if ($obsCategories.ContainsKey($catName)) { $obsCategories[$catName]++ }
                else { $obsCategories[$catName] = 1 }
            }
        }
        
        # 狀態
        $status = if ($o.status) { $o.status } else { "未知" }
        if ($obsStatus.ContainsKey($status)) { $obsStatus[$status]++ }
        else { $obsStatus[$status] = 1 }
    }
    
    Write-Host "`n    觀察類型 (前15名):"
    $obsTypes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 15 | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allObservations.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
    
    Write-Host "`n    觀察類別:"
    $obsCategories.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allObservations.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
    
    Write-Host "`n    觀察狀態:"
    $obsStatus.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
        $pct = [math]::Round(($_.Value * 100.0 / $allObservations.Count), 1)
        Write-Host "      $($_.Key): $($_.Value) ($pct%)"
    }
}

# Save
Write-Host ""
Write-Host "[5/5] Saving reports..." -ForegroundColor Green

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonFile = Join-Path $PSScriptRoot "fhir_data_$timestamp.json"
$txtFile = Join-Path $PSScriptRoot "report_$timestamp.txt"

# Save JSON
@{
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    patients = $allPatients
    immunizations = $allImmunizations
    conditions = $allConditions
    observations = $allObservations
} | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8

Write-Host "  JSON: $jsonFile" -ForegroundColor Green

# Save TXT Report
$report = @"
========================================================================================================
                            CQL Measurement Report
========================================================================================================

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Time period: Past $($config.filters.time_period_years) years

--------------------------------------------------------------------------------------------------------
Data Summary
--------------------------------------------------------------------------------------------------------
  Patient:       $($allPatients.Count)
  Immunization:  $($allImmunizations.Count)
  Condition:     $($allConditions.Count)
  Observation:   $($allObservations.Count)

--------------------------------------------------------------------------------------------------------
CQL Libraries
--------------------------------------------------------------------------------------------------------
"@

foreach ($cql in $config.cql_libraries) {
    $report += "`n  - $cql"
}

$report += @"


--------------------------------------------------------------------------------------------------------
FHIR Servers
--------------------------------------------------------------------------------------------------------
"@

foreach ($server in $config.fhir_servers) {
    $report += "`n  - $($server.name): $($server.base_url)"
}

$report += @"


========================================================================================================
                                    End of Report
========================================================================================================
"@

$report | Out-File -FilePath $txtFile -Encoding UTF8
Write-Host "  TXT:  $txtFile" -ForegroundColor Green

Write-Host ""
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                               Completed Successfully!" -ForegroundColor Yellow
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""



