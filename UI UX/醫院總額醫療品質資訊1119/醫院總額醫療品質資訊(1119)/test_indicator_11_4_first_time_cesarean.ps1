# ==================================================================================
# 測試指標11-4: 剖腹產率-初次具適應症 (1075.01)
# Test Script for Indicator 11-4: First-Time Cesarean Section Rate with Medical Indication
# ==================================================================================
# 
# 指標說明:
# - 分子: 初次非自願剖腹產案件數
# - 分母: 總生產案件數(自然產+剖腹產)
# - 排除: 自行要求剖腹產(DRG 0373B)、前次剖腹產(O342)
#
# 資料來源: SMART Health IT FHIR R4 Test Server
# ==================================================================================

param(
    [string]$ServerUrl = "https://launch.smarthealthit.org/v/r4/fhir",
    [int]$MaxPatients = 100
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "指標11-4: 剖腹產率-初次具適應症 (1075.01)" -ForegroundColor Cyan
Write-Host "First-Time Cesarean Section Rate with Medical Indication" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "FHIR伺服器: $ServerUrl" -ForegroundColor Yellow
Write-Host "開始時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# ==================================================================================
# 函數定義
# ==================================================================================

function Get-FHIRResource {
    param(
        [string]$ResourceType,
        [string]$Query = "",
        [int]$Count = 100
    )
    
    $url = "$ServerUrl/$ResourceType"
    if ($Query) {
        $url += "?$Query&_count=$Count"
    } else {
        $url += "?_count=$Count"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
        return $response
    } catch {
        Write-Host "警告: 無法取得 $ResourceType - $_" -ForegroundColor Yellow
        return $null
    }
}

function Test-NaturalDeliveryProcedure {
    param($procedure)
    
    $naturalDeliveryCodes = @('81017C', '81018C', '81019C', '97004C', '97005D', 
                             '81024C', '81025C', '81026C', '97934C', '81034C')
    
    foreach ($coding in $procedure.code.coding) {
        if ($coding.code -in $naturalDeliveryCodes) {
            return $true
        }
        # CPT codes for natural delivery
        if ($coding.code -in @('59400', '59409', '59410', '59612')) {
            return $true
        }
        # SNOMED CT codes for natural delivery
        if ($coding.code -in @('302383004', '289253008', '177157004', '236973005')) {
            return $true
        }
    }
    return $false
}

function Test-CesareanDeliveryProcedure {
    param($procedure)
    
    $cesareanCodes = @('81004C', '81028C', '97009C', '81005C', '81029C', '97014C')
    
    foreach ($coding in $procedure.code.coding) {
        if ($coding.code -in $cesareanCodes) {
            return $true
        }
        # ICD-10-PCS codes for cesarean
        if ($coding.code -in @('10D00Z0', '10D00Z1', '10D00Z2')) {
            return $true
        }
        # CPT codes for cesarean
        if ($coding.code -in @('59510', '59514', '59515', '59620')) {
            return $true
        }
        # SNOMED CT codes for cesarean
        if ($coding.code -in @('11466000', '177141003', '177152005', '18946005')) {
            return $true
        }
    }
    return $false
}

function Test-FirstTimeCesareanProcedure {
    param($procedure)
    
    # 初次剖腹產醫令代碼: 81004C, 81028C
    $firstTimeCodes = @('81004C', '81028C')
    
    foreach ($coding in $procedure.code.coding) {
        if ($coding.code -in $firstTimeCodes) {
            return $true
        }
        # ICD-10-PCS codes: 10D00Z0, 10D00Z1, 10D00Z2
        if ($coding.code -in @('10D00Z0', '10D00Z1', '10D00Z2')) {
            return $true
        }
    }
    return $false
}

function Test-RequestedCesarean {
    param($encounter, $encounterId)
    
    # 檢查是否為自行要求剖腹產 (DRG 0373B)
    $claims = Get-FHIRResource -ResourceType "Claim" -Query "encounter=Encounter/$encounterId"
    
    if ($claims -and $claims.entry) {
        foreach ($entry in $claims.entry) {
            $claim = $entry.resource
            if ($claim.diagnosis) {
                foreach ($diag in $claim.diagnosis) {
                    if ($diag.diagnosisCodeableConcept.coding) {
                        foreach ($coding in $diag.diagnosisCodeableConcept.coding) {
                            # DRG_CODE 0373B = 自行要求剖腹產
                            if ($coding.code -eq '0373B') {
                                return $true
                            }
                        }
                    }
                }
            }
        }
    }
    
    # 檢查處置代碼中是否有自行要求標記
    $procedures = Get-FHIRResource -ResourceType "Procedure" -Query "encounter=Encounter/$encounterId"
    
    if ($procedures -and $procedures.entry) {
        foreach ($entry in $procedures.entry) {
            $procedure = $entry.resource
            if ($procedure.code.coding) {
                foreach ($coding in $procedure.code.coding) {
                    # 97014C = 剖腹產處置費 (可能為非適應症)
                    if ($coding.code -eq '97014C') {
                        return $true
                    }
                    # SNOMED: 386637004 = Cesarean on request
                    if ($coding.code -eq '386637004') {
                        return $true
                    }
                }
            }
        }
    }
    
    return $false
}

function Test-PreviousCesarean {
    param($encounter, $encounterId)
    
    # 檢查診斷是否有前次剖腹產 (O342)
    $conditions = Get-FHIRResource -ResourceType "Condition" -Query "encounter=Encounter/$encounterId"
    
    if ($conditions -and $conditions.entry) {
        foreach ($entry in $conditions.entry) {
            $condition = $entry.resource
            if ($condition.code.coding) {
                foreach ($coding in $condition.code.coding) {
                    # ICD-10: O342 = 前胎剖腹產生產
                    if ($coding.code -eq 'O342' -or $coding.code -eq 'O34.2' -or $coding.code -eq 'O34.21') {
                        return $true
                    }
                    # SNOMED: 3311000175109 = Cesarean section following previous cesarean
                    if ($coding.code -eq '3311000175109') {
                        return $true
                    }
                    # SNOMED: 398236008 = Previous cesarean section
                    if ($coding.code -eq '398236008') {
                        return $true
                    }
                }
            }
        }
    }
    
    return $false
}

function Get-QuarterFromDate {
    param([DateTime]$date)
    
    $year = $date.Year - 1911  # ROC year
    $quarter = [Math]::Ceiling($date.Month / 3)
    
    return "${year}Y-Q${quarter}"
}

# ==================================================================================
# 主要邏輯: 撈取並分析資料
# ==================================================================================

Write-Host "Fetching delivery encounter data..." -ForegroundColor Cyan

# 1. Fetch all delivery-related Encounters
$deliveryEncounters = Get-FHIRResource -ResourceType "Encounter" -Query "type=OBSENC" -Count $MaxPatients

if (-not $deliveryEncounters -or -not $deliveryEncounters.entry) {
    Write-Host "No obstetric encounters found, trying general inpatient data..." -ForegroundColor Yellow
    $deliveryEncounters = Get-FHIRResource -ResourceType "Encounter" -Query "class=IMP" -Count $MaxPatients
}

if (-not $deliveryEncounters -or -not $deliveryEncounters.entry) {
    Write-Host "ERROR: Cannot retrieve any encounter records" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($deliveryEncounters.entry.Count) encounter records" -ForegroundColor Green
Write-Host ""

# 2. 分析每個案件
$results = @{}
$totalNaturalDelivery = 0
$totalCesareanDelivery = 0
$totalFirstTimeCesarean = 0

foreach ($entry in $deliveryEncounters.entry) {
    $encounter = $entry.resource
    $encounterId = $encounter.id
    
    if (-not $encounter.period -or -not $encounter.period.end) {
        continue
    }
    
    # 取得季度
    $encounterDate = [DateTime]::Parse($encounter.period.end)
    $quarter = Get-QuarterFromDate -date $encounterDate
    
    if (-not $results.ContainsKey($quarter)) {
        $results[$quarter] = @{
            NaturalDelivery = 0
            CesareanDelivery = 0
            FirstTimeCesarean = 0
            TotalDelivery = 0
        }
    }
    
    # Fetch all procedures for this encounter
    $procedures = Get-FHIRResource -ResourceType "Procedure" -Query "encounter=Encounter/$encounterId"
    
    if (-not $procedures -or -not $procedures.entry) {
        continue
    }
    
    $isNaturalDelivery = $false
    $isCesareanDelivery = $false
    $isFirstTimeCesarean = $false
    
    foreach ($procEntry in $procedures.entry) {
        $procedure = $procEntry.resource
        
        # 檢查是否為自然產
        if (Test-NaturalDeliveryProcedure -procedure $procedure) {
            $isNaturalDelivery = $true
        }
        
        # 檢查是否為剖腹產
        if (Test-CesareanDeliveryProcedure -procedure $procedure) {
            $isCesareanDelivery = $true
        }
        
        # 檢查是否為初次剖腹產
        if (Test-FirstTimeCesareanProcedure -procedure $procedure) {
            $isFirstTimeCesarean = $true
        }
    }
    
    # 計數
    if ($isNaturalDelivery) {
        $results[$quarter].NaturalDelivery++
        $totalNaturalDelivery++
    }
    
    if ($isCesareanDelivery) {
        # 檢查排除條件
        $isRequested = Test-RequestedCesarean -encounter $encounter -encounterId $encounterId
        $isPreviousCesarean = Test-PreviousCesarean -encounter $encounter -encounterId $encounterId
        
        $results[$quarter].CesareanDelivery++
        $totalCesareanDelivery++
        
        # 如果是初次剖腹產，且非自行要求，且非前次剖腹產
        if ($isFirstTimeCesarean -and -not $isRequested -and -not $isPreviousCesarean) {
            $results[$quarter].FirstTimeCesarean++
            $totalFirstTimeCesarean++
        }
    }
    
    # 計算總生產案件數
    if ($isNaturalDelivery -or $isCesareanDelivery) {
        $results[$quarter].TotalDelivery++
    }
}

# ==================================================================================
# 顯示結果
# ==================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 11-4 Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 按季度排序
$sortedQuarters = $results.Keys | Sort-Object

# 計算總計
$grandTotalFirstTimeCesarean = 0
$grandTotalDelivery = 0

foreach ($quarter in $sortedQuarters) {
    $data = $results[$quarter]
    
    $grandTotalFirstTimeCesarean += $data.FirstTimeCesarean
    $grandTotalDelivery += $data.TotalDelivery
    
    # 計算初次剖腹產率
    $rate = 0
    if ($data.TotalDelivery -gt 0) {
        $rate = ($data.FirstTimeCesarean / $data.TotalDelivery) * 100
    }
    
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| $quarter                              " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| First-time Cesarean Cases          | " -NoNewline
    Write-Host ("{0,8}" -f $data.FirstTimeCesarean) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| Total Delivery Cases               | " -NoNewline
    Write-Host ("{0,8}" -f $data.TotalDelivery) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| First-time Cesarean Rate           | " -NoNewline
    Write-Host ("{0,7:F2}%" -f $rate) -ForegroundColor Cyan -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host ""
}

# 顯示總計
if ($sortedQuarters.Count -gt 0) {
    $overallRate = 0
    if ($grandTotalDelivery -gt 0) {
        $overallRate = ($grandTotalFirstTimeCesarean / $grandTotalDelivery) * 100
    }
    
    # Calculate year
    $firstQuarter = $sortedQuarters[0]
    $year = $firstQuarter -replace '-.*', ''
    
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| $year                                 " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| First-time Cesarean Cases          | " -NoNewline
    Write-Host ("{0,8}" -f $grandTotalFirstTimeCesarean) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| Total Delivery Cases               | " -NoNewline
    Write-Host ("{0,8}" -f $grandTotalDelivery) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| First-time Cesarean Rate           | " -NoNewline
    Write-Host ("{0,7:F2}%" -f $overallRate) -ForegroundColor Cyan -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Delivery Cases: $grandTotalDelivery" -ForegroundColor White
Write-Host "  - Natural Delivery: $totalNaturalDelivery" -ForegroundColor Green
Write-Host "  - Cesarean Delivery: $totalCesareanDelivery" -ForegroundColor Green
Write-Host "First-time Non-voluntary Cesarean: $totalFirstTimeCesarean" -ForegroundColor Yellow
Write-Host ""
$completionTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Calculation completed at: $completionTime" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
