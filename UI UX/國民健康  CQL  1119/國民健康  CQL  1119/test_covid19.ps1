# COVID-19 Vaccine Search Script
# 搜尋多個 FHIR 伺服器以找到 COVID-19 疫苗資料

Write-Host "`n========================================================================================================" -ForegroundColor Green
Write-Host "                          COVID-19 疫苗資料搜尋工具" -ForegroundColor Yellow
Write-Host "========================================================================================================`n" -ForegroundColor Green

# Define FHIR servers to test
$servers = @(
    @{
        name = "SMART Server 1"
        url = "https://launch.smarthealthit.org/v/r4/fhir"
    },
    @{
        name = "SMART Server 2"
        url = "https://r4.smarthealthit.org"
    },
    @{
        name = "HAPI FHIR Public"
        url = "https://hapi.fhir.org/baseR4"
    },
    @{
        name = "Firely Server"
        url = "https://server.fire.ly"
    }
)

# COVID-19 vaccine search terms
$searchTerms = @(
    "COVID",
    "covid",
    "SARS-CoV-2",
    "coronavirus",
    "Pfizer",
    "Moderna",
    "AstraZeneca",
    "Janssen",
    "BioNTech"
)

# SNOMED and CVX codes for COVID-19 vaccines
$covidCodes = @{
    "SNOMED" = @("840539006", "840534001", "1119305005", "1119349007")
    "CVX" = @("207", "208", "210", "211", "212", "213")
}

Write-Host "[1/4] 測試伺服器連線..." -ForegroundColor Cyan
$activeServers = @()

foreach ($server in $servers) {
    Write-Host "`n  測試: $($server.name)" -ForegroundColor Yellow
    try {
        $metaUrl = "$($server.url)/metadata"
        $meta = Invoke-RestMethod -Uri $metaUrl -Method Get -TimeoutSec 10
        Write-Host "    [OK] FHIR $($meta.fhirVersion)" -ForegroundColor Green
        $activeServers += $server
    } catch {
        Write-Host "    [失敗] $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[2/4] 使用文字搜尋 COVID-19 疫苗..." -ForegroundColor Cyan
$foundByText = @{}

foreach ($server in $activeServers) {
    Write-Host "`n  搜尋: $($server.name)" -ForegroundColor Yellow
    
    try {
        # Try to get some immunization records
        $url = "$($server.url)/Immunization?_count=100"
        $bundle = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 30
        
        if ($bundle.entry) {
            Write-Host "    取得 $($bundle.entry.Count) 筆疫苗紀錄" -ForegroundColor White
            
            $covidVaccines = @()
            foreach ($entry in $bundle.entry) {
                $vaccine = $entry.resource
                $vaccineText = ""
                
                if ($vaccine.vaccineCode.text) {
                    $vaccineText = $vaccine.vaccineCode.text
                } elseif ($vaccine.vaccineCode.coding) {
                    $vaccineText = $vaccine.vaccineCode.coding[0].display
                }
                
                # Check if vaccine name contains COVID-19 related terms
                foreach ($term in $searchTerms) {
                    if ($vaccineText -like "*$term*") {
                        $covidVaccines += @{
                            id = $vaccine.id
                            name = $vaccineText
                            date = $vaccine.occurrenceDateTime
                            status = $vaccine.status
                        }
                        break
                    }
                }
            }
            
            if ($covidVaccines.Count -gt 0) {
                Write-Host "    [找到] $($covidVaccines.Count) 筆 COVID-19 疫苗!" -ForegroundColor Green
                $foundByText[$server.name] = $covidVaccines
                
                # Show sample
                Write-Host "    範例:" -ForegroundColor White
                $covidVaccines | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      - $($_.name)" -ForegroundColor Gray
                }
            } else {
                Write-Host "    [未找到] 文字搜尋無結果" -ForegroundColor Gray
            }
        } else {
            Write-Host "    [無資料] 此伺服器沒有疫苗紀錄" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    [錯誤] $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[3/4] 使用疫苗代碼搜尋..." -ForegroundColor Cyan

foreach ($server in $activeServers) {
    Write-Host "`n  搜尋: $($server.name)" -ForegroundColor Yellow
    $foundCode = $false
    
    # Try SNOMED codes
    foreach ($code in $covidCodes["SNOMED"]) {
        try {
            $searchUrl = "$($server.url)/Immunization"
            $params = @{
                Uri = $searchUrl
                Method = "Get"
                TimeoutSec = 10
                Body = @{
                    "vaccine-code" = $code
                    "_count" = 10
                }
            }
            $bundle = Invoke-RestMethod @params
            
            if ($bundle.entry -and $bundle.entry.Count -gt 0) {
                Write-Host "    [找到] SNOMED $code : $($bundle.entry.Count) 筆" -ForegroundColor Green
                $foundCode = $true
                if ($bundle.total) {
                    Write-Host "    總數: $($bundle.total)" -ForegroundColor White
                }
            }
        } catch {
            # Silently continue
        }
    }
    
    if (-not $foundCode) {
        Write-Host "    [未找到] 使用疫苗代碼無結果" -ForegroundColor Gray
    }
}

Write-Host "`n[4/4] 搜尋結果摘要" -ForegroundColor Cyan
Write-Host "========================================================================================================" -ForegroundColor Green

if ($foundByText.Count -gt 0) {
    Write-Host "`n找到 COVID-19 疫苗資料的伺服器:" -ForegroundColor Green
    foreach ($server in $foundByText.Keys) {
        Write-Host "`n  $server" -ForegroundColor Yellow
        Write-Host "    疫苗筆數: $($foundByText[$server].Count)" -ForegroundColor White
        
        # Show all unique vaccine names
        $uniqueNames = $foundByText[$server] | ForEach-Object { $_.name } | Select-Object -Unique
        Write-Host "    疫苗種類:" -ForegroundColor White
        foreach ($name in $uniqueNames) {
            Write-Host "      - $name" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n建議動作:" -ForegroundColor Yellow
    Write-Host "  1. 在 config.json 中啟用找到 COVID-19 疫苗的伺服器" -ForegroundColor White
    Write-Host "  2. 執行 test.ps1 來擷取完整資料" -ForegroundColor White
    Write-Host "  3. 使用 COVID19VaccinationCoverage.cql 進行分析" -ForegroundColor White
} else {
    Write-Host "`n未在任何測試伺服器中找到 COVID-19 疫苗資料" -ForegroundColor Red
    Write-Host "`n可能的原因:" -ForegroundColor Yellow
    Write-Host "  1. 測試用 FHIR 伺服器使用的是較舊的測試資料 (COVID-19 疫苗於 2020 年底開始)" -ForegroundColor White
    Write-Host "  2. 需要使用有真實或更新測試資料的伺服器" -ForegroundColor White
    Write-Host "  3. 某些伺服器需要認證才能存取完整資料" -ForegroundColor White
    
    Write-Host "`n建議替代方案:" -ForegroundColor Yellow
    Write-Host "  1. 使用現有的流感疫苗資料 (2,538 筆) 測試 CQL 邏輯" -ForegroundColor White
    Write-Host "  2. 修改 COVID19VaccinationCoverage.cql 改為 InfluenzaVaccinationCoverage.cql" -ForegroundColor White
    Write-Host "  3. 尋找其他有 COVID-19 資料的公開 FHIR 伺服器" -ForegroundColor White
    Write-Host "  4. 使用機構內部的 FHIR 伺服器 (如有的話)" -ForegroundColor White
}

Write-Host "`n========================================================================================================" -ForegroundColor Green
Write-Host ""
