# 🐛 Bug Fix: MedicationRequest Status 查詢錯誤

## 問題描述

所有醫療品質指標顯示 0%,即使已上傳包含正確 WHO ATC 代碼的測試數據。

## 根本原因

**JavaScript 查詢條件與測試數據狀態不匹配:**

- **JavaScript 查詢**: `status: 'completed'`
- **測試數據狀態**: `status: 'active'`
- **結果**: 查詢無法找到任何 MedicationRequest 資源

### 技術細節

檔案: `js/quality-indicators.js`  
問題代碼(修復前):
```javascript
const medications = await conn.query('MedicationRequest', {
    encounter: `Encounter/${encounterId}`,
    status: 'completed',  // ❌ 只查詢 completed 狀態
    _count: 50
});
```

測試數據範例(`test-patient-001-hypertension.json`):
```json
{
  "resourceType": "MedicationRequest",
  "status": "active",  // ⚠️ 測試數據使用 active 狀態
  "medicationCodeableConcept": {
    "coding": [{
      "system": "http://www.whocc.no/atc",
      "code": "C09AA01",
      "display": "Captopril"
    }]
  }
}
```

## 解決方案

將所有 MedicationRequest 查詢改為同時接受 `active` 和 `completed` 狀態:

```javascript
const medications = await conn.query('MedicationRequest', {
    encounter: `Encounter/${encounterId}`,
    status: 'active,completed',  // ✅ 同時接受兩種狀態
    _count: 50
});
```

## 修復範圍

**檔案**: `js/quality-indicators.js`  
**修改數量**: 21 處

修改位置(行號):
- Line 603: 門診注射使用率(Indicator 01)
- Line 805: 門診抗生素使用率(Indicator 02)
- Line 1103: 同醫院藥品重疊率(Indicator 03-1 至 03-8)
- Line 1223, 1390, 1537: 降血糖控制不佳率(Indicator 04)
- Line 1780, 1857, 1938, 2019: 各類疾病控制指標(Indicator 05-08)
- Line 2098, 2110, 2164: Statin 治療率(Indicator 09-11)
- Line 2269, 2359, 2394, 2444, 2477, 2525, 2558, 2627: 其他用藥相關指標(Indicator 12-19)

## 測試驗證

修復後應該要能查詢到以下測試數據:

### Patient 001 (陳大明) - 高血壓重複用藥
- Captopril 25mg (C09AA01) - `status: "active"`
- Amlodipine 5mg (C08CA01) - `status: "active"`
- **預期觸發**: Indicator 03-1 (同醫院降壓藥重疊率)

### Patient 002 (林小華) - 門診抗生素使用
- Amoxicillin 500mg (J01CA04) - `status: "active"`
- **預期觸發**: Indicator 02 (門診抗生素使用率)

### Patient 003 (黃志明) - 糖尿病控制不佳
- Metformin 500mg (A10BA02) - `status: "active"`
- Sitagliptin 100mg (A10BH01) - `status: "active"`
- HbA1c: 9.5% (> 9.0% 閾值)
- **預期觸發**: Indicator 04 (降血糖控制不佳率), Indicator 03-3 (降血糖藥重疊率)

### Patient 004 (張美玲) - 跨院重複用藥
- Hospital A: Enalapril (C09AA02), Simvastatin (C10AA01) - `status: "active"`
- Hospital B: Metoprolol (C07AB02), Atorvastatin (C10AA05) - `status: "active"`
- **預期觸發**: Indicator 03-9 (跨院降壓藥重疊率), Indicator 03-10 (跨院降血脂藥重疊率)

## FHIR 標準參考

根據 [FHIR R4 MedicationRequest](https://www.hl7.org/fhir/medicationrequest.html) 規範:

**status 欄位可能值**:
- `active`: 處方目前有效且正在執行
- `completed`: 處方已完成給藥
- `on-hold`: 處方暫停
- `cancelled`: 處方已取消
- `stopped`: 處方已停止
- `draft`: 草稿
- `entered-in-error`: 錯誤輸入

**最佳實務**: 查詢藥品相關統計時應包含 `active` 和 `completed` 兩種狀態,因為:
1. 正在執行的處方(active)可能尚未完成但已在用藥期間內
2. 已完成的處方(completed)是歷史用藥記錄
3. 重疊用藥檢查需要涵蓋所有有效期間的處方

## 修復執行

```powershell
# 批量替換命令
(Get-Content "js\quality-indicators.js" -Raw) `
  -replace "status: 'completed',", "status: 'active,completed'," `
  | Set-Content "js\quality-indicators.js" -NoNewline
```

## 驗證步驟

1. ✅ 確認 JavaScript 已修改(21處)
2. ⏳ 清除瀏覽器緩存
3. ⏳ 重新載入 Dashboard
4. ⏳ 點擊「醫療品質指標」
5. ⏳ 驗證以下指標顯示非零值:
   - Indicator 02: 門診抗生素使用率 (應 > 0%)
   - Indicator 03-1: 同醫院降壓藥重疊率 (應 > 0%)
   - Indicator 03-3: 同醫院降血糖藥重疊率 (應 > 0%)
   - Indicator 03-9: 跨院降壓藥重疊率 (應 > 0%)
   - Indicator 03-10: 跨院降血脂藥重疊率 (應 > 0%)
   - Indicator 04: 降血糖控制不佳率 (應 > 0%)

## 相關文件

- 測試數據: `Synthea-Mock-Data/custom-test-data/README.md`
- 上傳腳本: `Synthea-Mock-Data/custom-test-data/upload-test-data.ps1`
- CQL 規範: `FHIR-Dashboard-App/cql/Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql`

---

**修復日期**: 2024-11-22  
**修復人員**: GitHub Copilot  
**問題類型**: 查詢條件錯誤 / 資料狀態不匹配  
**影響範圍**: 所有 39 個醫療品質指標  
**嚴重程度**: 🔴 Critical (完全無法計算指標)
