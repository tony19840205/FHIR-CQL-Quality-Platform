# ==================================================================================
# Indicator 11-4: First-Time Cesarean Section Rate with Medical Indication (1075.01)
# Demo with Simulated Data
# ==================================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 11-4: First-Time Cesarean Section Rate" -ForegroundColor Cyan
Write-Host "with Medical Indication (1075.01)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data Source: Simulated delivery cases" -ForegroundColor Yellow
Write-Host "Calculation Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Simulated data based on typical cesarean delivery patterns
$simulatedData = @{
    "113Y-Q1" = @{
        FirstTimeCesarean = [int](Get-Random -Minimum 1500 -Maximum 1700)
        TotalDelivery = [int](Get-Random -Minimum 6000 -Maximum 6300)
    }
    "113Y-Q2" = @{
        FirstTimeCesarean = [int](Get-Random -Minimum 1600 -Maximum 1800)
        TotalDelivery = [int](Get-Random -Minimum 6300 -Maximum 6600)
    }
    "113Y-Q3" = @{
        FirstTimeCesarean = [int](Get-Random -Minimum 1900 -Maximum 2100)
        TotalDelivery = [int](Get-Random -Minimum 6900 -Maximum 7200)
    }
    "113Y-Q4" = @{
        FirstTimeCesarean = [int](Get-Random -Minimum 1950 -Maximum 2150)
        TotalDelivery = [int](Get-Random -Minimum 7500 -Maximum 7800)
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Calculation Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$grandTotalFirstTime = 0
$grandTotalDelivery = 0

foreach ($quarter in $simulatedData.Keys | Sort-Object) {
    $data = $simulatedData[$quarter]
    $grandTotalFirstTime += $data.FirstTimeCesarean
    $grandTotalDelivery += $data.TotalDelivery
    
    $rate = ($data.FirstTimeCesarean / $data.TotalDelivery) * 100
    
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

# Annual summary
$overallRate = ($grandTotalFirstTime / $grandTotalDelivery) * 100

Write-Host "+-------------------------------------+" -ForegroundColor White
Write-Host "| 113Y                                 " -ForegroundColor Yellow -NoNewline
Write-Host "|" -ForegroundColor White
Write-Host "+-------------------------------------+" -ForegroundColor White
Write-Host "| First-time Cesarean Cases          | " -NoNewline
Write-Host ("{0,8}" -f $grandTotalFirstTime) -ForegroundColor Green -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "| Total Delivery Cases               | " -NoNewline
Write-Host ("{0,8}" -f $grandTotalDelivery) -ForegroundColor Green -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "| First-time Cesarean Rate           | " -NoNewline
Write-Host ("{0,7:F2}%" -f $overallRate) -ForegroundColor Cyan -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "+-------------------------------------+" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Delivery Cases: $grandTotalDelivery" -ForegroundColor White
Write-Host "First-time Cesarean Cases: $grandTotalFirstTime" -ForegroundColor Yellow
Write-Host "Overall Rate: $("{0:F2}%" -f $overallRate)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: This indicator includes first-time cesarean with medical indication" -ForegroundColor Gray
Write-Host "Excluded: Cesarean on request (DRG 0373B), Previous cesarean (O342)" -ForegroundColor Gray
Write-Host ""
$completionTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Calculation completed at: $completionTime" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
