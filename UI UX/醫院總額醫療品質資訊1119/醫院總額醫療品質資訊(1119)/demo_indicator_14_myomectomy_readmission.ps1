# ==================================================================================
# Demo Script for Indicator 14: Readmission Rate within 14 Days after Uterine Myomectomy
# 指標14: 子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率
# ==================================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 14: 14-Day Readmission Rate after Uterine Myomectomy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data Source: Simulated hospital admission data" -ForegroundColor Yellow
Write-Host "Calculation Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Simulated data based on typical readmission patterns
$simulatedData = @{
    "113Y-Q1" = @{
        Surgery = [int](Get-Random -Minimum 450 -Maximum 550)
        Readmission = [int](Get-Random -Minimum 12 -Maximum 18)
    }
    "113Y-Q2" = @{
        Surgery = [int](Get-Random -Minimum 480 -Maximum 580)
        Readmission = [int](Get-Random -Minimum 13 -Maximum 19)
    }
    "113Y-Q3" = @{
        Surgery = [int](Get-Random -Minimum 520 -Maximum 620)
        Readmission = [int](Get-Random -Minimum 14 -Maximum 20)
    }
    "113Y-Q4" = @{
        Surgery = [int](Get-Random -Minimum 490 -Maximum 590)
        Readmission = [int](Get-Random -Minimum 13 -Maximum 19)
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Calculation Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$grandTotalSurgery = 0
$grandTotalReadmission = 0

foreach ($quarter in $simulatedData.Keys | Sort-Object) {
    $data = $simulatedData[$quarter]
    $grandTotalSurgery += $data.Surgery
    $grandTotalReadmission += $data.Readmission
    
    $rate = [math]::Round(($data.Readmission / $data.Surgery) * 100, 2)
    
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| $quarter                              " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| Uterine Myomectomy Cases           | " -NoNewline
    Write-Host ("{0,8}" -f $data.Surgery) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| 14-Day Readmissions                | " -NoNewline
    Write-Host ("{0,8}" -f $data.Readmission) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| Readmission Rate                   | " -NoNewline
    Write-Host ("{0,7:F2}%" -f $rate) -ForegroundColor Cyan -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host ""
}

# Annual summary
$overallRate = [math]::Round(($grandTotalReadmission / $grandTotalSurgery) * 100, 2)

Write-Host "+-------------------------------------+" -ForegroundColor White
Write-Host "| 113Y                                 " -ForegroundColor Yellow -NoNewline
Write-Host "|" -ForegroundColor White
Write-Host "+-------------------------------------+" -ForegroundColor White
Write-Host "| Uterine Myomectomy Cases           | " -NoNewline
Write-Host ("{0,8}" -f $grandTotalSurgery) -ForegroundColor Green -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "| 14-Day Readmissions                | " -NoNewline
Write-Host ("{0,8}" -f $grandTotalReadmission) -ForegroundColor Green -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "| Readmission Rate                   | " -NoNewline
Write-Host ("{0,7:F2}%" -f $overallRate) -ForegroundColor Cyan -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "+-------------------------------------+" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Uterine Myomectomy Cases: $grandTotalSurgery" -ForegroundColor White
Write-Host "Total 14-Day Readmissions: $grandTotalReadmission" -ForegroundColor Yellow
Write-Host "Overall Readmission Rate: ${overallRate}%" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Readmission within 14 days after discharge with related diagnosis (N70-N85)" -ForegroundColor Gray
Write-Host "Denominator: D25 diagnosis with myomectomy/hysterectomy, excluding cancer" -ForegroundColor Gray
Write-Host ""
$completionTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Calculation completed at: $completionTime" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
