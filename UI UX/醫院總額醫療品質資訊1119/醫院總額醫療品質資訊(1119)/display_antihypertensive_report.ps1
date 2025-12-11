# ============================================
# 顯示降血壓藥品用藥重疊率報告
# 指標3: 同醫院門診同藥理用藥日數重疊率-降血壓(口服)
# ============================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   指標3: 同醫院門診同藥理用藥日數重疊率-降血壓(口服)" -ForegroundColor Yellow
Write-Host "   健保指標代碼: 1710" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 找最新的報告檔案
$reportFile = Get-ChildItem -Path "results\antihypertensive_quarterly_report_*.csv" | 
              Sort-Object LastWriteTime -Descending | 
              Select-Object -First 1

if ($null -eq $reportFile) {
    Write-Host "❌ 找不到報告檔案" -ForegroundColor Red
    exit
}

Write-Host "📊 報告檔案: $($reportFile.Name)" -ForegroundColor Green
Write-Host "📅 產生時間: $($reportFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green
Write-Host ""

# 讀取報告
$report = Import-Csv -Path $reportFile.FullName -Encoding UTF8

# 顯示報告表格
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   季度統計報告" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 建立表格格式
$report | ForEach-Object {
    Write-Host "第$($_.'季度')季" -ForegroundColor White -NoNewline
    Write-Host " | " -NoNewline
    Write-Host "降血壓(口服)總給藥日數: " -NoNewline
    Write-Host $($_.'降血壓(口服)總給藥日數') -ForegroundColor Green -NoNewline
    Write-Host " | " -NoNewline
    Write-Host "重疊日數: " -NoNewline
    Write-Host $($_.'降血壓(口服)之給藥口數') -ForegroundColor Yellow -NoNewline
    Write-Host " | " -NoNewline
    Write-Host "重疊率: " -NoNewline
    Write-Host "$($_.'降血壓(口服)不同處方用藥日數重疊率')%" -ForegroundColor $(if ([double]$_.'降血壓(口服)不同處方用藥日數重疊率' -gt 0.1) { "Red" } else { "Green" })
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 統計摘要
$totalDrugDays = ($report | Measure-Object -Property '降血壓(口服)總給藥日數' -Sum).Sum
$totalOverlapDays = ($report | Measure-Object -Property '降血壓(口服)之給藥口數' -Sum).Sum
$avgOverlapRate = if ($totalDrugDays -gt 0) { [Math]::Round(($totalOverlapDays / $totalDrugDays * 100), 2) } else { 0 }

Write-Host "📈 統計摘要" -ForegroundColor Yellow
Write-Host "   總給藥日數: " -NoNewline
Write-Host $totalDrugDays -ForegroundColor Green
Write-Host "   總重疊日數: " -NoNewline
Write-Host $totalOverlapDays -ForegroundColor Yellow
Write-Host "   平均重疊率: " -NoNewline
Write-Host "$avgOverlapRate%" -ForegroundColor $(if ($avgOverlapRate -gt 0.1) { "Red" } else { "Green" })
Write-Host ""

# 讀取詳細數據
$detailFile = Get-ChildItem -Path "results\antihypertensive_medications_*.csv" | 
              Sort-Object LastWriteTime -Descending | 
              Select-Object -First 1

if ($null -ne $detailFile) {
    $details = Import-Csv -Path $detailFile.FullName -Encoding UTF8
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "   降血壓藥品分類統計 (依 ATC 代碼)" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # ATC 分類統計
    $atcStats = $details | Group-Object -Property atc_code | ForEach-Object {
        [PSCustomObject]@{
            'ATC代碼' = $_.Name
            '處方數' = $_.Count
            '總給藥日數' = ($_.Group | Measure-Object -Property drug_days -Sum).Sum
            '病人數' = ($_.Group | Select-Object -ExpandProperty patient_id -Unique).Count
        }
    } | Sort-Object -Property '處方數' -Descending
    
    $atcStats | Format-Table -AutoSize
    
    # ATC 代碼說明
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "   ATC 代碼說明" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $atcDescriptions = @{
        'C03AA03' = 'Thiazides (噻嗪類利尿劑) - Hydrochlorothiazide'
        'C07AB02' = 'Beta Blocking Agents (β阻斷劑) - Metoprolol'
        'C08CA01' = 'Dihydropyridine (鈣離子阻斷劑) - Amlodipine'
        'C09AA02' = 'ACE Inhibitors (ACE抑制劑) - Enalapril'
        'C09CA01' = 'Angiotensin II Antagonists (ARB) - Losartan'
    }
    
    $details | Select-Object -ExpandProperty atc_code -Unique | ForEach-Object {
        if ($atcDescriptions.ContainsKey($_)) {
            Write-Host "  $_ : " -NoNewline -ForegroundColor Cyan
            Write-Host $atcDescriptions[$_] -ForegroundColor White
        }
    }
    Write-Host ""
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "✅ 報告顯示完成" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
