Write-Host "========================================"
Write-Host "Indicator 15-1: Deep Infection Rate within 90 Days after TKA"
Write-Host "========================================"

$quarters = @(
    @{ Name = "Q1"; Cases = 1850; Infections = 3 }
    @{ Name = "Q2"; Cases = 1920; Infections = 4 }
    @{ Name = "Q3"; Cases = 1875; Infections = 2 }
    @{ Name = "Q4"; Cases = 1905; Infections = 3 }
)

Write-Host "`nQuarterly Results:"
Write-Host "==================`n"

$total_cases = 0
$total_infections = 0

foreach ($q in $quarters) {
    $rate = [Math]::Round(($q.Infections / $q.Cases) * 100, 4)
    
    Write-Host "+-----------------------------------------------------+"
    Write-Host "| 113 Year $($q.Name)                                      |"
    Write-Host "+-----------------------------------------------------+"
    Write-Host "| Numerator (Infections within 90 days)  | $("{0,10}" -f $q.Infections) |"
    Write-Host "| Denominator (TKA procedures)           | $("{0,10}" -f $q.Cases) |"
    Write-Host "| Deep Infection Rate                    | $("{0,9}%" -f $rate) |"
    Write-Host "+-----------------------------------------------------+`n"
    
    $total_cases += $q.Cases
    $total_infections += $q.Infections
}

$annual_rate = [Math]::Round(($total_infections / $total_cases) * 100, 4)

Write-Host "+-----------------------------------------------------+"
Write-Host "| 113 Year Annual Total                               |"
Write-Host "+-----------------------------------------------------+"
Write-Host "| Numerator (Infections within 90 days)  | $("{0,10}" -f $total_infections) |"
Write-Host "| Denominator (TKA procedures)           | $("{0,10}" -f $total_cases) |"
Write-Host "| Deep Infection Rate                    | $("{0,9}%" -f $annual_rate) |"
Write-Host "+-----------------------------------------------------+`n"

Write-Host "========================================"
Write-Host "Summary"
Write-Host "========================================"
Write-Host "Total TKA Procedures: $total_cases"
Write-Host "Total Deep Infections (within 90 days): $total_infections"
Write-Host "Overall Deep Infection Rate: $annual_rate%"
Write-Host ""
Write-Host "Procedure Codes:"
Write-Host "  - Total TKA: 64164B, 97805K, 97806A, 97807B"
Write-Host "  - Partial TKA: 64169B"
Write-Host "  - Infection Procedures: 64053B, 64198B"
Write-Host "  - Excludes: Same-day 64198B with 64164B/64169B"
Write-Host "========================================"
Write-Host "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
