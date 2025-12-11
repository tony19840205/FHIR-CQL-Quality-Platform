# 測試上傳1位病患
$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "測試上傳1位病患及其資源...`n"

# 讀取第一個Bundle
$bundle = Get-Content "CGMH_test_data_taiwan_100_bundle.json" -Raw -Encoding UTF8 | ConvertFrom-Json

# 取得第一位Patient
$firstPatient = $bundle.entry[0].resource
$patientId = $firstPatient.id

Write-Host "病患ID: $patientId`n"

# 找出此病患的所有資源
$patientResources = @()
$patientResources += $firstPatient

foreach ($entry in $bundle.entry) {
    $resource = $entry.resource
    if ($resource.resourceType -ne "Patient") {
        $patientRef = $null
        if ($resource.subject -and $resource.subject.reference) {
            $patientRef = $resource.subject.reference -replace "Patient/", ""
        }
        elseif ($resource.patient -and $resource.patient.reference) {
            $patientRef = $resource.patient.reference -replace "Patient/", ""
        }
        
        if ($patientRef -eq $patientId) {
            $patientResources += $resource
        }
    }
}

Write-Host "找到 $($patientResources.Count) 個資源`n"

# 上傳
$successCount = 0
$failCount = 0

foreach ($resource in $patientResources) {
    $resourceType = $resource.resourceType
    $resourceId = $resource.id
    
    # DateTime修正
    if ($resource.authoredOn -and $resource.authoredOn -notmatch 'Z$' -and $resource.authoredOn -notmatch '\+\d{2}:\d{2}$') {
        $resource.authoredOn = $resource.authoredOn + "Z"
    }
    if ($resource.period) {
        if ($resource.period.start -and $resource.period.start -notmatch 'Z$' -and $resource.period.start -notmatch '\+\d{2}:\d{2}$') {
            $resource.period.start = $resource.period.start + "Z"
        }
        if ($resource.period.end -and $resource.period.end -notmatch 'Z$' -and $resource.period.end -notmatch '\+\d{2}:\d{2}$') {
            $resource.period.end = $resource.period.end + "Z"
        }
    }
    
    # 移除問題欄位
    if ($resource.serviceProvider) {
        $resource.PSObject.Properties.Remove('serviceProvider')
    }
    
    $url = "$FHIR_SERVER/$resourceType/$resourceId"
    $body = $resource | ConvertTo-Json -Depth 10 -Compress
    
    try {
        $response = Invoke-RestMethod -Method PUT -Uri $url `
            -ContentType "application/fhir+json;charset=UTF-8" `
            -Body $body `
            -ErrorAction Stop
        $successCount++
        Write-Host "✓ $resourceType/$resourceId"
    }
    catch {
        $failCount++
        Write-Host "✗ $resourceType/$resourceId - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n結果: 成功 $successCount, 失敗 $failCount"
