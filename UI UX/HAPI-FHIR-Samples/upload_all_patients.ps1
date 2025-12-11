# 完整上傳所有CGMH Bundle - 以病患為單位
# 自動跳過已存在的Patient

$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

$bundleFiles = @(
    "CGMH_test_data_taiwan_100_bundle.json",
    "CGMH_test_data_vaccine_100_bundle.json",
    "CGMH_test_data_antibiotic_49_bundle.json",
    "CGMH_test_data_quality_50_bundle.json",
    "CGMH_test_data_outpatient_quality_53_bundle.json",
    "CGMH_test_data_inpatient_quality_46_bundle.json",
    "CGMH_test_data_surgical_quality_46_bundle.json",
    "CGMH_test_data_outcome_quality_12_bundle.json",
    "CGMH_test_data_same_hospital_overlap_42_bundle.json"
)

$totalPatients = 0
$totalSuccess = 0
$totalFail = 0
$totalSkipped = 0

foreach ($bundleFile in $bundleFiles) {
    Write-Host "`n=========================================="
    Write-Host "處理: $bundleFile"
    Write-Host "=========================================="
    
    $bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
    
    # 以Patient分組
    $patientGroups = @{}
    foreach ($entry in $bundle.entry) {
        $resource = $entry.resource
        if ($resource.resourceType -eq "Patient") {
            $patientId = $resource.id
            if (-not $patientGroups.ContainsKey($patientId)) { $patientGroups[$patientId] = @() }
            $patientGroups[$patientId] += $resource
        } else {
            $patientRef = $null
            if ($resource.subject) { $patientRef = $resource.subject.reference -replace "Patient/", "" }
            elseif ($resource.patient) { $patientRef = $resource.patient.reference -replace "Patient/", "" }
            if ($patientRef) {
                if (-not $patientGroups.ContainsKey($patientRef)) { $patientGroups[$patientRef] = @() }
                $patientGroups[$patientRef] += $resource
            }
        }
    }
    
    Write-Host "找到 $($patientGroups.Count) 位病患`n"
    
    $bundlePatientCount = 0
    foreach ($patientId in $patientGroups.Keys) {
        $bundlePatientCount++
        $totalPatients++
        
        Write-Host "[$bundlePatientCount/$($patientGroups.Count)] 病患: $patientId" -ForegroundColor Cyan
        
        $patientSuccess = 0
        $patientFail = 0
        
        foreach ($resource in $patientGroups[$patientId]) {
            $resourceType = $resource.resourceType
            $resourceId = $resource.id
            
            # 修正DateTime (+08:00 -> Z)
            if ($resource.authoredOn -and $resource.authoredOn -match '\+08:00$') {
                $resource.authoredOn = $resource.authoredOn -replace '\+08:00$', 'Z'
            }
            if ($resource.period) {
                if ($resource.period.start) {
                    if ($resource.period.start -match '\+08:00$') {
                        $resource.period.start = $resource.period.start -replace '\+08:00$', 'Z'
                    } elseif ($resource.period.start -notmatch 'Z$' -and $resource.period.start -notmatch '\+\d{2}:\d{2}$') {
                        $resource.period.start += "Z"
                    }
                }
                if ($resource.period.end) {
                    if ($resource.period.end -match '\+08:00$') {
                        $resource.period.end = $resource.period.end -replace '\+08:00$', 'Z'
                    } elseif ($resource.period.end -notmatch 'Z$' -and $resource.period.end -notmatch '\+\d{2}:\d{2}$') {
                        $resource.period.end += "Z"
                    }
                }
            }
            
            # 移除問題欄位
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
            
            $url = "$FHIR_SERVER/$resourceType/$resourceId"
            $body = $resource | ConvertTo-Json -Depth 10 -Compress
            
            try {
                Invoke-RestMethod -Method PUT -Uri $url -ContentType "application/fhir+json;charset=UTF-8" -Body $body -ErrorAction Stop | Out-Null
                $patientSuccess++
                $totalSuccess++
                Write-Host "  ✓ $resourceType/$resourceId"
            } catch {
                if ($_.Exception.Message -match "409" -or $_.Exception.Message -match "Conflict") {
                    $totalSkipped++
                    Write-Host "  - $resourceType/$resourceId (已存在)" -ForegroundColor Yellow
                } else {
                    $patientFail++
                    $totalFail++
                    Write-Host "  ✗ $resourceType/$resourceId" -ForegroundColor Red
                }
            }
        }
        
        Write-Host "  → 病患資源: 成功 $patientSuccess, 失敗 $patientFail`n"
        
        # 每位病患間延遲
        Start-Sleep -Milliseconds 800
    }
}

Write-Host "`n=========================================="
Write-Host "全部上傳完成"
Write-Host "=========================================="
Write-Host "處理病患數: $totalPatients"
Write-Host "成功上傳: $totalSuccess"
Write-Host "跳過(已存在): $totalSkipped"
Write-Host "失敗: $totalFail"
Write-Host "=========================================="
