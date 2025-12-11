# 上傳急性結膜炎假病人資料到衛福部 SAND-BOX
# 檔案: Acute_Conjunctivitis_4_Patients.json
# 包含: 4位病人 × 5-6個資源 = 21個 FHIR 資源

$ErrorActionPreference = "Continue"
$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"
$JSON_FILE = "Acute_Conjunctivitis_4_Patients.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳急性結膜炎假病人資料" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查檔案是否存在
if (-not (Test-Path $JSON_FILE)) {
    Write-Host "錯誤: 找不到檔案 $JSON_FILE" -ForegroundColor Red
    exit 1
}

# 讀取 JSON 檔案
Write-Host "讀取檔案: $JSON_FILE" -ForegroundColor Yellow
$bundle = Get-Content -Path $JSON_FILE -Raw -Encoding UTF8 | ConvertFrom-Json

# 計算資源數量
$totalResources = $bundle.entry.Count
Write-Host "總共 $totalResources 個 FHIR 資源" -ForegroundColor Yellow
Write-Host ""

# 統計變數
$successCount = 0
$failCount = 0
$patientCount = 0

# 遍歷每個資源並上傳
Write-Host "開始上傳資源..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $bundle.entry) {
    $resource = $entry.resource
    $resourceType = $resource.resourceType
    $resourceId = $resource.id
    
    if (-not $resourceId) {
        Write-Host "[跳過] $resourceType 沒有 ID" -ForegroundColor Yellow
        continue
    }
    
    $url = "$FHIR_SERVER/$resourceType/$resourceId"
    
    # 顯示正在上傳的資源
    $displayName = $resourceId
    if ($resourceType -eq "Patient" -and $resource.name) {
        $familyName = $resource.name[0].family
        $givenName = $resource.name[0].given[0]
        $displayName = "$familyName$givenName ($resourceId)"
        $patientCount++
    }
    
    Write-Host "上傳 $resourceType : $displayName" -ForegroundColor White -NoNewline
    
    try {
        # 轉換為 JSON 並上傳
        $json = $resource | ConvertTo-Json -Depth 10 -Compress
        
        $response = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json" -ErrorAction Stop
        
        Write-Host " [OK]" -ForegroundColor Green
        $successCount++
        
    } catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
    
    # 每5個資源暫停一下，避免請求過快
    if (($successCount + $failCount) % 5 -eq 0) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳完成統計" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "總資源數: $totalResources" -ForegroundColor White
Write-Host "病患數量: $patientCount" -ForegroundColor White
Write-Host "成功上傳: $successCount" -ForegroundColor Green
Write-Host "失敗數量: $failCount" -ForegroundColor Red
Write-Host ""

# 驗證上傳結果
Write-Host "驗證上傳的病患..." -ForegroundColor Cyan
Write-Host ""

$patientIds = @(
    "conjunctivitis-patient-001",
    "conjunctivitis-patient-002",
    "conjunctivitis-patient-003",
    "conjunctivitis-patient-004"
)

foreach ($patientId in $patientIds) {
    try {
        $result = Invoke-RestMethod -Uri "$FHIR_SERVER/Patient/$patientId" -Method Get -ErrorAction Stop
        $pName = $result.name[0].family + $result.name[0].given[0]
        Write-Host "[OK] $pName (Patient/$patientId)" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Patient/$patientId - Not found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "後續驗證查詢" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "查詢所有急性結膜炎病患 (ICD-10 H10.3):" -ForegroundColor Yellow
Write-Host "GET $FHIR_SERVER/Condition?code=H10.3" -ForegroundColor Gray
Write-Host ""
Write-Host "查詢特定病患的所有資源:" -ForegroundColor Yellow
Write-Host "GET $FHIR_SERVER/Patient/conjunctivitis-patient-001/`$everything" -ForegroundColor Gray
Write-Host ""
Write-Host "查詢病患的診斷記錄:" -ForegroundColor Yellow
Write-Host "GET $FHIR_SERVER/Condition?subject=Patient/conjunctivitis-patient-001" -ForegroundColor Gray
Write-Host ""
Write-Host "查詢病患的用藥記錄:" -ForegroundColor Yellow
Write-Host "GET $FHIR_SERVER/MedicationRequest?subject=Patient/conjunctivitis-patient-001" -ForegroundColor Gray
Write-Host ""
