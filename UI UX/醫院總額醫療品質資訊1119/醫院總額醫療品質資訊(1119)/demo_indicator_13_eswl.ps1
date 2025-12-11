# ==================================================================================
# Demo Script for Indicator 13: Average ESWL Procedures per Patient
# 指標13: 接受體外震波碎石術(ESWL)病人平均利用ESWL之次數 - 模擬資料展示
# ==================================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Indicator 13: Average ESWL Procedures per Patient" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data Source: Simulated ESWL procedure data" -ForegroundColor Yellow
Write-Host "Calculation Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Simulated data based on typical ESWL usage patterns
$simulatedData = @{
    "113Y-Q1" = @{
        ESWLCount = [int](Get-Random -Minimum 2550 -Maximum 2650)
        PatientCount = [int](Get-Random -Minimum 2350 -Maximum 2450)
    }
    "113Y-Q2" = @{
        ESWLCount = [int](Get-Random -Minimum 3450 -Maximum 3550)
        PatientCount = [int](Get-Random -Minimum 3100 -Maximum 3200)
    }
    "113Y-Q3" = @{
        ESWLCount = [int](Get-Random -Minimum 4000 -Maximum 4100)
        PatientCount = [int](Get-Random -Minimum 3600 -Maximum 3700)
    }
    "113Y-Q4" = @{
        ESWLCount = [int](Get-Random -Minimum 3450 -Maximum 3550)
        PatientCount = [int](Get-Random -Minimum 3100 -Maximum 3200)
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Calculation Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$grandTotalESWL = 0
$grandTotalPatients = 0

foreach ($quarter in $simulatedData.Keys | Sort-Object) {
    $data = $simulatedData[$quarter]
    $grandTotalESWL += $data.ESWLCount
    $grandTotalPatients += $data.PatientCount
    
    $average = [math]::Round($data.ESWLCount / $data.PatientCount, 2)
    
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| $quarter                              " -ForegroundColor Yellow -NoNewline
    Write-Host "|" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host "| ESWL Procedure Count               | " -NoNewline
    Write-Host ("{0,8}" -f $data.ESWLCount) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| ESWL Patient Count                 | " -NoNewline
    Write-Host ("{0,8}" -f $data.PatientCount) -ForegroundColor Green -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "| Average ESWL per Patient           | " -NoNewline
    Write-Host ("{0,8:F2}" -f $average) -ForegroundColor Cyan -NoNewline
    Write-Host " |" -ForegroundColor White
    Write-Host "+-------------------------------------+" -ForegroundColor White
    Write-Host ""
}

# Annual summary
$overallAverage = [math]::Round($grandTotalESWL / $grandTotalPatients, 2)

Write-Host "+-------------------------------------+" -ForegroundColor White
Write-Host "| 113Y                                 " -ForegroundColor Yellow -NoNewline
Write-Host "|" -ForegroundColor White
Write-Host "+-------------------------------------+" -ForegroundColor White
Write-Host "| ESWL Procedure Count               | " -NoNewline
Write-Host ("{0,8}" -f $grandTotalESWL) -ForegroundColor Green -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "| ESWL Patient Count                 | " -NoNewline
Write-Host ("{0,8}" -f $grandTotalPatients) -ForegroundColor Green -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "| Average ESWL per Patient           | " -NoNewline
Write-Host ("{0,8:F2}" -f $overallAverage) -ForegroundColor Cyan -NoNewline
Write-Host " |" -ForegroundColor White
Write-Host "+-------------------------------------+" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Data Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total ESWL Procedures: $grandTotalESWL" -ForegroundColor White
Write-Host "Total Unique Patients: $grandTotalPatients" -ForegroundColor Yellow
Write-Host "Overall Average per Patient: $overallAverage" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: This indicator calculates average ESWL procedures per patient" -ForegroundColor Gray
Write-Host "Formula: Total ESWL Procedures / Number of Unique Patients" -ForegroundColor Gray
Write-Host ""
$completionTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Calculation completed at: $completionTime" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
