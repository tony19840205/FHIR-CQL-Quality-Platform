# 快速測試腳本
# 自動安裝套件並執行測試

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ESG CQL 測試系統 - 快速啟動腳本" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查Python版本
Write-Host "[1/4] 檢查Python版本..." -ForegroundColor Yellow
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "✗ 未找到Python，請先安裝Python 3.8或以上版本" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 升級pip
Write-Host "[2/4] 升級pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ pip已升級至最新版本" -ForegroundColor Green
} else {
    Write-Host "! pip升級失敗，但將繼續執行" -ForegroundColor Yellow
}

Write-Host ""

# 安裝相依套件
Write-Host "[3/4] 安裝相依套件..." -ForegroundColor Yellow
Write-Host "這可能需要幾分鐘..." -ForegroundColor Gray

pip install -r requirements.txt --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 所有套件安裝完成" -ForegroundColor Green
} else {
    Write-Host "✗ 套件安裝失敗，請查看錯誤訊息" -ForegroundColor Red
    Write-Host ""
    Write-Host "請嘗試手動執行: pip install -r requirements.txt" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 執行主程式
Write-Host "[4/4] 執行ESG CQL測試..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

python main.py

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "測試完成！" -ForegroundColor Green
Write-Host ""
Write-Host "結果已儲存至: esg_cql_results.json" -ForegroundColor Cyan
Write-Host "日誌已儲存至: esg_cql_test.log" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
