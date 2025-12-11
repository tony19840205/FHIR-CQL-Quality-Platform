# ========================================
# 修復並重新上傳失敗的 Bundle 資源
# 修復問題：
# 1. Encounter.class 格式錯誤（應該是單一 Coding，不是 CodeableConcept）
# 2. 日期格式需要加上時區（Z）
# 3. Organization reference 可能不存在
# ========================================

$FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "修復並重新上傳失敗的 Bundle 資源" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 需要修復的 Bundle 清單
$bundles = @(
    "CGMH_test_data_outpatient_quality_53_bundle.json",
    "CGMH_test_data_inpatient_quality_46_bundle.json",
    "CGMH_test_data_same_hospital_overlap_42_bundle.json"
)

function Fix-EncounterResource {
    param($resource)
    
    # 修復 class 欄位（FHIR R4 Encounter.class 是單一 Coding）
    if ($resource.class) {
        # 如果 class 是正確格式，保留
        if ($resource.class.system -and $resource.class.code) {
            # 已經是正確格式
        } else {
            Write-Host "  警告: Encounter.class 格式需要調整" -ForegroundColor Yellow
        }
    }
    
    # 修復日期格式（加上時區 Z）
    if ($resource.period) {
        if ($resource.period.start -and $resource.period.start -notmatch 'Z$') {
            $resource.period.start = $resource.period.start + "Z"
        }
        if ($resource.period.end -and $resource.period.end -notmatch 'Z$') {
            $resource.period.end = $resource.period.end + "Z"
        }
    }
    
    # 移除可能導致問題的 Organization reference（如果不存在）
    if ($resource.serviceProvider) {
        $resource.PSObject.Properties.Remove('serviceProvider')
    }
    
    return $resource
}

function Fix-ConditionResource {
    param($resource)
    
    # 修復日期格式
    if ($resource.onsetDateTime -and $resource.onsetDateTime -notmatch 'Z$') {
        $resource.onsetDateTime = $resource.onsetDateTime + "Z"
    }
    if ($resource.recordedDate -and $resource.recordedDate -notmatch 'Z$') {
        $resource.recordedDate = $resource.recordedDate + "Z"
    }
    
    return $resource
}

function Fix-MedicationRequestResource {
    param($resource)
    
    # 修復日期格式
    if ($resource.authoredOn -and $resource.authoredOn -notmatch 'Z$') {
        $resource.authoredOn = $resource.authoredOn + "Z"
    }
    
    # 修復 dispenseRequest.validityPeriod
    if ($resource.dispenseRequest -and $resource.dispenseRequest.validityPeriod) {
        if ($resource.dispenseRequest.validityPeriod.start -and $resource.dispenseRequest.validityPeriod.start -notmatch 'Z$') {
            $resource.dispenseRequest.validityPeriod.start = $resource.dispenseRequest.validityPeriod.start + "Z"
        }
        if ($resource.dispenseRequest.validityPeriod.end -and $resource.dispenseRequest.validityPeriod.end -notmatch 'Z$') {
            $resource.dispenseRequest.validityPeriod.end = $resource.dispenseRequest.validityPeriod.end + "Z"
        }
    }
    
    return $resource
}

function Fix-ObservationResource {
    param($resource)
    
    # 修復日期格式
    if ($resource.effectiveDateTime -and $resource.effectiveDateTime -notmatch 'Z$') {
        $resource.effectiveDateTime = $resource.effectiveDateTime + "Z"
    }
    if ($resource.issued -and $resource.issued -notmatch 'Z$') {
        $resource.issued = $resource.issued + "Z"
    }
    
    return $resource
}

function Fix-ProcedureResource {
    param($resource)
    
    # 修復日期格式
    if ($resource.performedDateTime -and $resource.performedDateTime -notmatch 'Z$') {
        $resource.performedDateTime = $resource.performedDateTime + "Z"
    }
    if ($resource.performedPeriod) {
        if ($resource.performedPeriod.start -and $resource.performedPeriod.start -notmatch 'Z$') {
            $resource.performedPeriod.start = $resource.performedPeriod.start + "Z"
        }
        if ($resource.performedPeriod.end -and $resource.performedPeriod.end -notmatch 'Z$') {
            $resource.performedPeriod.end = $resource.performedPeriod.end + "Z"
        }
    }
    
    return $resource
}

$totalSuccess = 0
$totalFailed = 0
$totalSkipped = 0

foreach ($bundleFile in $bundles) {
    Write-Host "`n----------------------------------------" -ForegroundColor Yellow
    Write-Host "處理Bundle: $bundleFile" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    
    if (-not (Test-Path $bundleFile)) {
        Write-Host "❌ 檔案不存在，跳過" -ForegroundColor Red
        continue
    }
    
    # 讀取Bundle
    $bundle = Get-Content $bundleFile -Raw -Encoding UTF8 | ConvertFrom-Json
    
    $success = 0
    $failed = 0
    $skipped = 0
    
    # 遍歷所有資源
    for ($i = 0; $i -lt $bundle.entry.Count; $i++) {
        $resource = $bundle.entry[$i].resource
        $resourceType = $resource.resourceType
        $resourceId = $resource.id
        
        # 跳過已存在的 Patient
        if ($resourceType -eq "Patient") {
            Write-Host "  ⏭️  [$($i+1)/$($bundle.entry.Count)] Patient $resourceId 已存在，跳過" -ForegroundColor Gray
            $skipped++
            continue
        }
        
        # 根據資源類型修復
        try {
            switch ($resourceType) {
                "Encounter" { $resource = Fix-EncounterResource $resource }
                "Condition" { $resource = Fix-ConditionResource $resource }
                "MedicationRequest" { $resource = Fix-MedicationRequestResource $resource }
                "Observation" { $resource = Fix-ObservationResource $resource }
                "Procedure" { $resource = Fix-ProcedureResource $resource }
            }
            
            # 轉換為JSON
            $json = $resource | ConvertTo-Json -Depth 20 -Compress
            
            # PUT上傳
            $url = "$FHIR_SERVER/$resourceType/$resourceId"
            $null = Invoke-RestMethod -Uri $url -Method Put -Body $json -ContentType "application/fhir+json" -ErrorAction Stop
            Write-Host "  ✅ [$($i+1)/$($bundle.entry.Count)] $resourceType/$resourceId 上傳成功" -ForegroundColor Green
            $success++
            
        } catch {
            Write-Host "  ❌ [$($i+1)/$($bundle.entry.Count)] $resourceType/$resourceId 上傳失敗: $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
        
        # 每10個資源暫停一下
        if (($i + 1) % 10 -eq 0) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Host "`n📊 $bundleFile 統計:" -ForegroundColor Cyan
    Write-Host "   成功: $success" -ForegroundColor Green
    Write-Host "   失敗: $failed" -ForegroundColor Red
    Write-Host "   跳過: $skipped" -ForegroundColor Gray
    
    $totalSuccess += $success
    $totalFailed += $failed
    $totalSkipped += $skipped
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "總體統計" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 成功上傳: $totalSuccess" -ForegroundColor Green
Write-Host "❌ 上傳失敗: $totalFailed" -ForegroundColor Red
Write-Host "⏭️  跳過資源: $totalSkipped" -ForegroundColor Gray
Write-Host "`n完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# 驗證Patient總數
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "驗證Patient總數" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "$FHIR_SERVER/Patient?_summary=count" -Method Get
    Write-Host "📊 Patient總數: $($response.total)" -ForegroundColor Green
} catch {
    Write-Host "❌ 無法查詢Patient總數" -ForegroundColor Red
}
