# 以病患為單位上傳到衛福部SAND-BOX
# 每次上傳1位病患及其所有相關資源

$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "=========================================="
Write-Host "以病患為單位上傳FHIR資源"
Write-Host "=========================================="

# 要上傳的Bundle檔案（按順序）
$bundleFiles = @(
    "CGMH_test_data_taiwan_100_bundle.json",
    "CGMH_test_data_vaccine_100_bundle.json",
    "CGMH_test_data_antibiotic_49_bundle.json",
    "CGMH_test_data_waste_9_bundle.json",
    "CGMH_test_data_quality_50_bundle.json",
    "CGMH_test_data_outpatient_quality_53_bundle.json",
    "CGMH_test_data_inpatient_quality_46_bundle.json",
    "CGMH_test_data_surgical_quality_46_bundle.json",
    "CGMH_test_data_outcome_quality_12_bundle.json",
    "CGMH_test_data_same_hospital_overlap_42_bundle.json"
)

# 統計
$totalPatientsProcessed = 0
$totalResourcesUploaded = 0
$totalResourcesFailed = 0

# 處理每個Bundle
foreach ($bundleFile in $bundleFiles) {
    if (-not (Test-Path $bundleFile)) {
        Write-Host "檔案不存在: $bundleFile" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`n處理Bundle: $bundleFile" -ForegroundColor Cyan
    
    # 讀取Bundle
    $jsonContent = Get-Content $bundleFile -Raw -Encoding UTF8
    $bundle = $jsonContent | ConvertFrom-Json
    
    # 以Patient為單位分組資源
    $patientGroups = @{}
    
    foreach ($entry in $bundle.entry) {
        $resource = $entry.resource
        $resourceType = $resource.resourceType
        
        if ($resourceType -eq "Patient") {
            $patientId = $resource.id
            if (-not $patientGroups.ContainsKey($patientId)) {
                $patientGroups[$patientId] = @()
            }
            $patientGroups[$patientId] += $resource
        }
        else {
            # 找到此資源屬於哪位Patient
            $patientRef = $null
            if ($resource.subject -and $resource.subject.reference) {
                $patientRef = $resource.subject.reference -replace "Patient/", ""
            }
            elseif ($resource.patient -and $resource.patient.reference) {
                $patientRef = $resource.patient.reference -replace "Patient/", ""
            }
            
            if ($patientRef) {
                if (-not $patientGroups.ContainsKey($patientRef)) {
                    $patientGroups[$patientRef] = @()
                }
                $patientGroups[$patientRef] += $resource
            }
        }
    }
    
    Write-Host "  找到 $($patientGroups.Count) 位病患"
    
    # 逐個病患上傳
    foreach ($patientId in $patientGroups.Keys) {
        $resources = $patientGroups[$patientId]
        $totalPatientsProcessed++
        
        Write-Host "`n  [病患 $totalPatientsProcessed] $patientId ($($resources.Count) 個資源)" -ForegroundColor Green
        
        $successCount = 0
        $failCount = 0
        
        # 先上傳Patient
        $patientResource = $resources | Where-Object { $_.resourceType -eq "Patient" } | Select-Object -First 1
        if ($patientResource) {
            $url = "$FHIR_SERVER/Patient/$($patientResource.id)"
            $body = $patientResource | ConvertTo-Json -Depth 10 -Compress
            
            try {
                $response = Invoke-RestMethod -Method PUT -Uri $url `
                    -ContentType "application/fhir+json;charset=UTF-8" `
                    -Body $body `
                    -ErrorAction Stop
                $successCount++
                Write-Host "    ✓ Patient/$($patientResource.id)"
            }
            catch {
                $failCount++
                Write-Host "    ✗ Patient/$($patientResource.id) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # 上傳其他資源
        $otherResources = $resources | Where-Object { $_.resourceType -ne "Patient" }
        foreach ($resource in $otherResources) {
            $resourceType = $resource.resourceType
            $resourceId = $resource.id
            
            # 修正DateTime格式（將+08:00替換為Z）
            if ($resource.authoredOn -and $resource.authoredOn -match '\+08:00$') {
                $resource.authoredOn = $resource.authoredOn -replace '\+08:00$', 'Z'
            }
            if ($resource.period) {
                if ($resource.period.start -and $resource.period.start -match '\+08:00$') {
                    $resource.period.start = $resource.period.start -replace '\+08:00$', 'Z'
                }
                if ($resource.period.end -and $resource.period.end -match '\+08:00$') {
                    $resource.period.end = $resource.period.end -replace '\+08:00$', 'Z'
                }
            }
            
            # 移除可能導致問題的欄位
            if ($resource.serviceProvider) {
                $resource.PSObject.Properties.Remove('serviceProvider')
            }
            if ($resourceType -eq "MedicationRequest") {
                if ($resource.requester) {
                    $resource.PSObject.Properties.Remove('requester')
                }
                if ($resource.dispenseRequest) {
                    $resource.PSObject.Properties.Remove('dispenseRequest')
                }
            }
            
            # 上傳
            $url = "$FHIR_SERVER/$resourceType/$resourceId"
            $body = $resource | ConvertTo-Json -Depth 10 -Compress
            
            try {
                $response = Invoke-RestMethod -Method PUT -Uri $url `
                    -ContentType "application/fhir+json;charset=UTF-8" `
                    -Body $body `
                    -ErrorAction Stop
                $successCount++
                Write-Host "    ✓ $resourceType/$resourceId"
            }
            catch {
                $failCount++
                Write-Host "    ✗ $resourceType/$resourceId" -ForegroundColor Red
            }
        }
        
        $totalResourcesUploaded += $successCount
        $totalResourcesFailed += $failCount
        
        # 每位病患上傳完後稍微延遲，避免過度負載伺服器
        Start-Sleep -Milliseconds 800
    }
}

Write-Host "`n=========================================="
Write-Host "上傳完成"
Write-Host "=========================================="
Write-Host "處理病患數: $totalPatientsProcessed"
Write-Host "成功上傳資源: $totalResourcesUploaded"
Write-Host "失敗資源: $totalResourcesFailed"
Write-Host "=========================================="
