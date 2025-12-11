# CGMH測試資料清單

## 📋 資料概覽

共10個測試資料Bundle，涵蓋508位病患，所有指標的完整測試資料。

---

## 📦 資料清單

### 1. 傳染病監測資料
- **檔案**: `CGMH_test_data_taiwan_100_bundle.json`
- **病患**: TW00001-TW00100 (100位)
- **指標**: COVID-19, 流感, 腸病毒, 腹瀉, 急性結膜炎
- **資源**: Patient, Encounter, Condition, Observation

### 2. 疫苗接種資料
- **檔案**: `CGMH_test_data_vaccine_100_bundle.json`
- **病患**: TW00101-TW00200 (100位)
- **指標**: COVID-19疫苗接種覆蓋率, 高血壓活動病例數
- **資源**: Patient, Encounter, Condition, Immunization, Observation

### 3. 抗生素使用資料
- **檔案**: `CGMH_test_data_antibiotic_49_bundle.json`
- **病患**: TW00201-TW00249 (49位)
- **指標**: 抗生素使用率
- **資源**: Patient, Encounter, MedicationRequest

### 4. 醫療廢棄物資料
- **檔案**: `CGMH_test_data_waste_9_bundle.json`
- **病患**: N/A (9筆觀察記錄)
- **指標**: 醫療廢棄物產生量
- **資源**: Observation (廢棄物重量)

### 5. 用藥安全品質指標
- **檔案**: `CGMH_test_data_quality_50_bundle.json`
- **病患**: TW00250-TW00299 (50位)
- **指標**: 
  - Indicator-01: 門診注射使用率
  - Indicator-02: 門診抗生素使用率
- **資源**: Patient, Encounter, MedicationRequest

### 6. 門診品質指標
- **檔案**: `CGMH_test_data_outpatient_quality_53_bundle.json`
- **病患**: TW00309-TW00361 (53位)
- **指標**:
  - Indicator-04: 慢性病連續處方箋使用率
  - Indicator-05: 處方10種以上藥品率
  - Indicator-06: 小兒氣喘急診率
  - Indicator-07: 糖尿病HbA1c檢驗率
  - Indicator-08: 同日同院同疾病再就診率
- **資源**: Patient, Encounter, Condition, MedicationRequest, Observation

### 7. 住院品質指標
- **檔案**: `CGMH_test_data_inpatient_quality_46_bundle.json`
- **病患**: TW00404-TW00449 (46位)
- **指標**:
  - Indicator-09: 14天再入院率
  - Indicator-10: 出院後3日內急診率
- **資源**: Patient, Encounter (住院+急診)

### 8. 手術品質指標
- **檔案**: `CGMH_test_data_surgical_quality_46_bundle.json`
- **病患**: TW00450-TW00495 (46位)
- **指標**:
  - Indicator-11: 手術預防性抗生素使用率
  - Indicator-12: 手術後30天內死亡率
  - Indicator-13: 手術後30天內再住院率
- **資源**: Patient, Encounter, Procedure, MedicationRequest

### 9. 疾病結果品質指標
- **檔案**: `CGMH_test_data_outcome_quality_12_bundle.json`
- **病患**: TW00496-TW00507 (12位)
- **指標**:
  - Indicator-14: AMI住院30天死亡率
  - Indicator-15: 中風住院30天死亡率
  - Indicator-16: 心衰竭住院30天死亡率
  - Indicator-17: AMI再住院率
  - Indicator-18: 中風再住院率
  - Indicator-19: 心衰竭再住院率
- **資源**: Patient, Encounter, Condition, Observation

### 10. 同院用藥重疊指標
- **檔案**: `CGMH_test_data_same_hospital_overlap_42_bundle.json`
- **病患**: TW00362-TW00403 (42位)
- **指標**:
  - Indicator-03-3: 同院降血糖藥重疊率
  - Indicator-03-4: 同院抗思覺失調藥重疊率
  - Indicator-03-5: 同院抗憂鬱藥重疊率
  - Indicator-03-6: 同院安眠鎮靜藥重疊率
  - Indicator-03-7: 同院抗血栓藥重疊率
  - Indicator-03-8: 同院前列腺藥重疊率
  - Indicator-03-9: 跨院降血壓藥重疊率
  - Indicator-03-10: 跨院降血脂藥重疊率
- **資源**: Patient, Encounter, Condition, MedicationRequest

---

## 📊 統計總覽

| 項目 | 數量 |
|------|------|
| Bundle檔案 | 10 |
| 病患總數 | 508 |
| 涵蓋指標 | 29個 (疾病監測5 + ESG 3 + 品質21) |
| 日期範圍 | 2025 Q4 (2025-10-01 至 2025-12-31) |

---

## 🚀 上傳方式

### 方法1: 使用統一上傳腳本（推薦）
```powershell
cd "c:\Users\tony1\OneDrive\桌面\UI UX-20251122(0013)\UI UX\HAPI-FHIR-Samples"
py CGMH_upload_all_test_data.py
```

### 方法2: 個別上傳
```powershell
# 範例：上傳單個Bundle
py upload_taiwan_100.py
```

---

## ⚠️ 注意事項

1. **資料覆蓋**: 使用PUT方法，會覆蓋同ID的舊資料
2. **上傳順序**: 建議依照清單順序上傳，避免reference錯誤
3. **網路穩定**: 確保網路連線穩定，每個Bundle上傳需1-3分鐘
4. **備份重要**: 這些檔案是唯一備份，請妥善保存

---

## 📝 資料特性

### 病患ID分配
- TW00001-TW00100: 傳染病
- TW00101-TW00200: 疫苗
- TW00201-TW00249: 抗生素
- TW00250-TW00299: 用藥安全
- TW00309-TW00361: 門診品質
- TW00362-TW00403: 用藥重疊
- TW00404-TW00449: 住院品質
- TW00450-TW00495: 手術品質
- TW00496-TW00507: 疾病結果

### 日期範圍
所有資料統一使用2025年第四季度 (2025-10-01 至 2025-12-31)

---

## 🔍 驗證方式

上傳後可透過FHIR查詢驗證：
```
GET https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1000
```

預期總數：508位病患

---

最後更新: 2025-12-02
