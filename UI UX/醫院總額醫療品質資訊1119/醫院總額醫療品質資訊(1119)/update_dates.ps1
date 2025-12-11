# Update all Indicator CQL files to have date: 2025-11-20
$today = "2025-11-20"
$files = Get-ChildItem -Filter "Indicator_*.cql" | Sort-Object Name

$stats = @{
    Total = $files.Count
    Updated = 0
    Added = 0
    AlreadyCorrect = 0
}

foreach ($file in $files) {
    $lines = Get-Content $file.FullName -Encoding UTF8
    $newLines = @()
    $modified = $false
    $hasDate = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Check if line has date and update if needed
        if ($line -match '^// 製作日期：\d{4}-\d{2}-\d{2}') {
            $hasDate = $true
            if ($line -notmatch $today) {
                $newLines += "// 製作日期：$today"
                $modified = $true
                Write-Host "[UPDATE] $($file.Name)" -ForegroundColor Yellow
                $stats.Updated++
            } else {
                $newLines += $line
                $stats.AlreadyCorrect++
            }
        }
        # Add date after 指標代碼 if not exists
        elseif ($line -match '^// 指標代碼:') {
            $newLines += $line
            # Check next line
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -notmatch '製作日期：') {
                # Check if we haven't found date yet
                $foundDateLater = $false
                for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                    if ($lines[$j] -match '製作日期：') {
                        $foundDateLater = $true
                        break
                    }
                }
                if (-not $foundDateLater) {
                    $newLines += "// 製作日期：$today"
                    $modified = $true
                    $hasDate = $true
                    Write-Host "[ADD] $($file.Name)" -ForegroundColor Green
                    $stats.Added++
                }
            }
        }
        else {
            $newLines += $line
        }
    }
    
    if ($modified) {
        $newLines | Set-Content $file.FullName -Encoding UTF8 -Force
    }
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Date Update Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Total files checked: $($stats.Total)" -ForegroundColor White
Write-Host "Updated existing date: $($stats.Updated)" -ForegroundColor Yellow
Write-Host "Added new date: $($stats.Added)" -ForegroundColor Green  
Write-Host "Already correct: $($stats.AlreadyCorrect)" -ForegroundColor Gray
Write-Host "Target date: $today" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
