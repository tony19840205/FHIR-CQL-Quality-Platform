# ============================================
# 門診抗生素使用率報表顯示腳本
# ============================================

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                    門診抗生素使用率查詢報表" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# 檢查results目錄是否存在
if (-not (Test-Path "results")) {
    Write-Host "❌ results目錄不存在，請先執行查詢腳本" -ForegroundColor Red
    Write-Host ""
    Write-Host "執行方式:" -ForegroundColor Yellow
    Write-Host "  python run_antibiotic_query.py" -ForegroundColor White
    Write-Host ""
    exit
}

# 檢查報表檔案是否存在
$reportFile = "results\fhir_antibiotic_usage_report.csv"
$summaryFile = "results\antibiotic_usage_summary_report.csv"

if (-not (Test-Path $reportFile)) {
    Write-Host "❌ 報表檔案不存在: $reportFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "請先執行查詢腳本:" -ForegroundColor Yellow
    Write-Host "  python run_antibiotic_query.py" -ForegroundColor White
    Write-Host ""
    exit
}

# ============================================
# 讀取並顯示詳細報表
# ============================================
Write-Host "[1] 抗生素使用詳細報表" -ForegroundColor Green
Write-Host "-" -NoNewline
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

try {
    $data = Import-Csv $reportFile -Encoding UTF8
    
    if ($data.Count -eq 0) {
        Write-Host "  ⚠️  無資料" -ForegroundColor Yellow
    } else {
        Write-Host "  總計: " -NoNewline -ForegroundColor Cyan
        Write-Host "$($data.Count) 筆抗生素處方記錄" -ForegroundColor White
        Write-Host ""
        
        # 顯示前10筆
        Write-Host "  前10筆記錄:" -ForegroundColor Cyan
        $data | Select-Object -First 10 | Format-Table -AutoSize `
            @{Label="處方ID"; Expression={$_.id_med}}, `
            @{Label="病人"; Expression={$_.patient}}, `
            @{Label="藥品名稱"; Expression={$_.medication_name}}, `
            @{Label="ATC碼"; Expression={$_.atc_code}}, `
            @{Label="日期"; Expression={$_.date_med}}, `
            @{Label="途徑"; Expression={$_.route}}, `
            @{Label="頻率"; Expression={$_.frequency}}, `
            @{Label="天數"; Expression={$_.supply_days}}
        
        Write-Host ""
    }
} catch {
    Write-Host "  ❌ 讀取報表失敗: $_" -ForegroundColor Red
}

# ============================================
# 讀取並顯示統計摘要
# ============================================
if (Test-Path $summaryFile) {
    Write-Host ""
    Write-Host "[2] 統計摘要報表" -ForegroundColor Green
    Write-Host "-" -NoNewline
    Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $content = Get-Content $summaryFile -Encoding UTF8
        
        foreach ($line in $content) {
            if ($line -match "^門診抗生素使用率統計摘要") {
                Write-Host "  $line" -ForegroundColor Yellow
            }
            elseif ($line -match "^查詢期間:") {
                Write-Host "  $line" -ForegroundColor Cyan
            }
            elseif ($line -match "^製表時間:") {
                Write-Host "  $line" -ForegroundColor Cyan
            }
            elseif ($line -match "^各季度抗生素使用統計:|^依ATC碼分類統計:|^依給藥途徑統計:") {
                Write-Host ""
                Write-Host "  $line" -ForegroundColor Green
            }
            elseif ($line.Trim() -ne "") {
                Write-Host "  $line" -ForegroundColor White
            }
        }
        
        Write-Host ""
    } catch {
        Write-Host "  ❌ 讀取統計摘要失敗: $_" -ForegroundColor Red
    }
}

# ============================================
# 資料品質檢查
# ============================================
Write-Host ""
Write-Host "[3] 資料品質檢查" -ForegroundColor Green
Write-Host "-" -NoNewline
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

try {
    $data = Import-Csv $reportFile -Encoding UTF8
    
    # 檢查ATC碼格式
    $validAtc = $data | Where-Object { 
        $_.atc_code -match "^J" -and 
        $_.atc_code -notmatch "^J07" -and 
        $_.atc_code -notmatch "^J06BA"
    }
    
    Write-Host "  ✓ ATC碼檢查:" -ForegroundColor Cyan
    Write-Host "    - 總記錄數: $($data.Count)" -ForegroundColor White
    Write-Host "    - 符合抗生素定義: $($validAtc.Count)" -ForegroundColor White
    Write-Host "    - 符合率: " -NoNewline -ForegroundColor White
    $validRate = [math]::Round(($validAtc.Count / $data.Count) * 100, 2)
    
    if ($validRate -ge 95) {
        Write-Host "$validRate%" -ForegroundColor Green
    } elseif ($validRate -ge 80) {
        Write-Host "$validRate%" -ForegroundColor Yellow
    } else {
        Write-Host "$validRate%" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # ATC分類分布
    Write-Host "  ✓ ATC分類分布:" -ForegroundColor Cyan
    $atcGroups = $data | Group-Object { $_.atc_code.Substring(0, 3) } | Sort-Object Count -Descending
    
    foreach ($group in $atcGroups) {
        $atcClass = $group.Name
        $count = $group.Count
        $percent = [math]::Round(($count / $data.Count) * 100, 2)
        
        $className = switch ($atcClass) {
            "J01" { "抗細菌劑" }
            "J02" { "抗黴菌劑" }
            "J04" { "抗結核菌劑" }
            "J05" { "抗病毒劑" }
            default { "其他" }
        }
        
        Write-Host "    - $atcClass ($className): $count 筆 ($percent%)" -ForegroundColor White
    }
    
    Write-Host ""
    
    # 給藥途徑分布
    Write-Host "  ✓ 給藥途徑分布:" -ForegroundColor Cyan
    $routeGroups = $data | Group-Object route | Sort-Object Count -Descending
    
    foreach ($group in $routeGroups) {
        $route = $group.Name
        $count = $group.Count
        $percent = [math]::Round(($count / $data.Count) * 100, 2)
        
        $routeName = switch ($route) {
            "PO" { "口服" }
            "IV" { "靜脈注射" }
            "IM" { "肌肉注射" }
            "SC" { "皮下注射" }
            "TOP" { "外用" }
            default { "其他" }
        }
        
        Write-Host "    - $route ($routeName): $count 筆 ($percent%)" -ForegroundColor White
    }
    
    Write-Host ""
    
} catch {
    Write-Host "  ❌ 資料品質檢查失敗: $_" -ForegroundColor Red
}

# ============================================
# 重要提醒
# ============================================
Write-Host ""
Write-Host "[4] 重要提醒" -ForegroundColor Green
Write-Host "-" -NoNewline
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "  📌 抗生素定義:" -ForegroundColor Yellow
Write-Host "     • ATC碼前1碼為'J' (抗感染劑)" -ForegroundColor White
Write-Host "     • 排除前3碼為'J07' (疫苗)" -ForegroundColor White
Write-Host "     • 排除前5碼為'J06BA' (免疫球蛋白)" -ForegroundColor White
Write-Host ""
Write-Host "  📌 排除條件:" -ForegroundColor Yellow
Write-Host "     • 急診案件(案件分類代碼02)" -ForegroundColor White
Write-Host "     • 門診手術案件(案件分類類碼03)" -ForegroundColor White
Write-Host "     • 事前審查藥品(審查註記為Y)" -ForegroundColor White
Write-Host "     • 立刻使用藥品(頻率為STAT)" -ForegroundColor White
Write-Host "     • 代辦案件" -ForegroundColor White
Write-Host ""
Write-Host "  📌 參考基準(2022Q1):" -ForegroundColor Yellow
Write-Host "     • 抗生素給藥案件數: 1,156,837" -ForegroundColor White
Write-Host "     • 給藥案件數: 5,831,409" -ForegroundColor White
Write-Host "     • 門診抗生素使用率: 19.84%" -ForegroundColor White
Write-Host ""

# ============================================
# 結束
# ============================================
Write-Host ""
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                              報表顯示完成" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 提示: 詳細資料請查看 results 目錄下的 CSV 檔案" -ForegroundColor Cyan
Write-Host ""
