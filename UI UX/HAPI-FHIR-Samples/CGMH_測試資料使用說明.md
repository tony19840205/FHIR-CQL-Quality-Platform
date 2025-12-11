# CGMH FHIR測試資料說明文件

**專案**: 醫療品質指標Dashboard測試資料  
**目的**: 為FHIR CQL整合平台提供完整的測試數據  
**日期**: 2025-12-02  
**資料格式**: FHIR R4 Bundle (JSON)  

---

## 📖 什麼是這些資料？

這是一套**完整的醫療測試資料**，用於驗證FHIR Dashboard的各項醫療品質指標查詢功能。

### 為什麼需要這些測試資料？
1. **功能驗證**: 確認Dashboard能正確計算各項醫療品質指標
2. **CQL邏輯測試**: 驗證Clinical Quality Language查詢邏輯
3. **效能測試**: 測試系統處理真實規模資料的能力
4. **展示用途**: 提供Demo環境的真實數據

### 資料來源
- **合成數據**: 所有病患資料均為程式生成的虛構數據
- **符合標準**: 遵循FHIR R4規範和台灣健保局CQL規則
- **隱私保護**: 不含任何真實病患資訊

---

## 📦 資料包內容

### 總覽
- **10個Bundle檔案** (JSON格式)
- **508位虛構病患** (Patient資源)
- **2457個FHIR資源** (包含就診、診斷、用藥、檢驗等)
- **29個醫療指標** 的測試場景

### 檔案清單

| 編號 | 檔案名稱 | 說明 | 病患數 | 資源數 |
|------|---------|------|--------|--------|
| 1 | `CGMH_test_data_taiwan_100_bundle.json` | 傳染病監測資料 | 100 | 200 |
| 2 | `CGMH_test_data_vaccine_100_bundle.json` | 疫苗接種資料 | 100 | 219 |
| 3 | `CGMH_test_data_antibiotic_49_bundle.json` | 抗生素使用資料 | 49 | 241 |
| 4 | `CGMH_test_data_waste_9_bundle.json` | 醫療廢棄物資料 | - | 45 |
| 5 | `CGMH_test_data_quality_50_bundle.json` | 用藥安全指標 | 50 | 502 |
| 6 | `CGMH_test_data_outpatient_quality_53_bundle.json` | 門診品質指標 | 53 | 585 |
| 7 | `CGMH_test_data_inpatient_quality_46_bundle.json` | 住院品質指標 | 46 | 172 |
| 8 | `CGMH_test_data_surgical_quality_46_bundle.json` | 手術品質指標 | 46 | 196 |
| 9 | `CGMH_test_data_outcome_quality_12_bundle.json` | 疾病結果指標 | 12 | 45 |
| 10 | `CGMH_test_data_same_hospital_overlap_42_bundle.json` | 用藥重疊指標 | 42 | 252 |

---

## 🎯 涵蓋的醫療指標

### 一、傳染病管制 (5項)
- COVID-19確診病例數
- 流感確診病例數  
- 腸病毒感染案例數
- 腹瀉疫情統計
- 急性結膜炎案例數

### 二、ESG永續指標 (3項)
- 抗生素使用率
- 醫療廢棄物產生量
- 電子病歷採用率

### 三、醫療品質指標 (21項)

#### A. 用藥安全 (2項)
- 指標01: 門診注射使用率
- 指標02: 門診抗生素使用率

#### B. 用藥重疊安全 (8項)
- 指標03-3: 同院降血糖藥重疊率
- 指標03-4: 同院抗精神病藥重疊率
- 指標03-5: 同院抗憂鬱藥重疊率
- 指標03-6: 同院安眠藥重疊率
- 指標03-7: 同院抗血栓藥重疊率
- 指標03-8: 同院前列腺藥重疊率
- 指標03-9: 跨院降血壓藥重疊率
- 指標03-10: 跨院降血脂藥重疊率

#### C. 門診品質 (5項)
- 指標04: 慢性病連續處方使用率
- 指標05: 處方10種以上藥品率
- 指標06: 小兒氣喘急診率
- 指標07: 糖尿病HbA1c檢驗率
- 指標08: 同日再就診率

#### D. 住院品質 (2項)
- 指標09: 14天再入院率
- 指標10: 出院後3日急診率

#### E. 手術品質 (3項)
- 指標11: 手術預防性抗生素使用率
- 指標12: 手術30天死亡率
- 指標13: 手術30天再住院率

#### F. 疾病結果 (6項)
- 指標14-16: AMI/中風/心衰竭 30天死亡率
- 指標17-19: AMI/中風/心衰竭 再住院率

---

## 🔧 如何使用這些資料？

### 方法1: 使用自動上傳腳本（推薦）

```powershell
# 1. 進入資料目錄
cd "路徑\HAPI-FHIR-Samples"

# 2. 執行統一上傳腳本
python CGMH_upload_all_test_data.py
```

這個腳本會：
- 依序上傳10個Bundle
- 自動處理每個Bundle的上傳
- 顯示上傳進度和結果
- 統計成功/失敗數量

### 方法2: 使用FHIR API手動上傳

```bash
# 使用curl命令上傳單個Bundle
curl -X POST \
  https://emr-smart.appx.com.tw/v/r4/fhir \
  -H "Content-Type: application/fhir+json" \
  -d @CGMH_test_data_taiwan_100_bundle.json
```

### 方法3: 使用Postman等API工具

1. 設定URL: `https://emr-smart.appx.com.tw/v/r4/fhir`
2. 方法: POST
3. Headers: `Content-Type: application/fhir+json`
4. Body: 選擇JSON檔案上傳

---

## 📊 資料結構說明

### FHIR Bundle格式
每個JSON檔案都是一個FHIR Bundle，包含：

```json
{
  "resourceType": "Bundle",
  "type": "transaction",
  "entry": [
    {
      "resource": { ... },  // Patient, Encounter等資源
      "request": {
        "method": "PUT",     // 使用PUT方法，可覆蓋舊資料
        "url": "Patient/TW00001"
      }
    }
  ]
}
```

### 資源類型
- **Patient**: 病患基本資料
- **Encounter**: 就診記錄（門診/住診/急診）
- **Condition**: 診斷（ICD-10編碼）
- **MedicationRequest**: 處方用藥（含ATC碼）
- **Observation**: 檢驗檢查（如HbA1c）
- **Procedure**: 手術處置
- **Immunization**: 疫苗接種

---

## 🔍 資料驗證

### 上傳後如何確認？

#### 1. 檢查病患數量
```
GET https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1000
```
預期結果: 508位病患

#### 2. 檢查特定病患
```
GET https://emr-smart.appx.com.tw/v/r4/fhir/Patient/TW00001
```

#### 3. 使用Dashboard測試
- 開啟FHIR Dashboard
- 清除瀏覽器快取 (Ctrl+Shift+Delete)
- 重新整理頁面 (F5)
- 點擊各指標的「查詢」按鈕
- 確認能正確顯示統計結果

---

## 📅 資料時間範圍

所有測試資料的日期範圍統一為：
- **2025年第四季度**
- **起始**: 2025-10-01
- **結束**: 2025-12-31

這樣設計是為了：
1. 符合Dashboard的季度查詢邏輯
2. 確保資料在測試時仍為「近期」資料
3. 便於進行時間範圍篩選測試

---

## ⚠️ 重要注意事項

### 1. 資料覆蓋
- 使用PUT方法上傳，會**覆蓋同ID的舊資料**
- 建議先備份FHIR伺服器（如有需要）
- 病患ID範圍: TW00001-TW00507

### 2. 上傳順序
- 建議依照檔案編號順序上傳
- 避免資源參照（reference）錯誤

### 3. 網路要求
- 每個Bundle上傳需1-5分鐘
- 確保網路連線穩定
- 大檔案（如Bundle#6）可能需要較長時間

### 4. 資料隱私
- **這些都是虛構資料**
- 不含任何真實病患資訊
- 僅用於測試和展示目的

---

## 🛠️ 故障排除

### 問題1: 上傳失敗 (504 Timeout)
**原因**: Bundle太大，伺服器處理超時  
**解決**: 
- 增加timeout設定
- 分批上傳（可手動拆分Bundle）
- 稍後重試

### 問題2: 資源參照錯誤
**原因**: 資源之間的reference找不到  
**解決**:
- 確認是否按順序上傳
- 檢查FHIR伺服器是否支援transaction bundle

### 問題3: Dashboard顯示0%
**原因**: 
- 快取問題
- 查詢邏輯錯誤
- 資料格式不符

**解決**:
1. 清除瀏覽器快取
2. 檢查開發者工具Console錯誤訊息
3. 驗證FHIR資源格式

---

## 📞 支援資訊

### 相關文件
- `CGMH_TEST_DATA_README.md` - 資料清單
- `CGMH_UPLOAD_COMPLETE_REPORT.md` - 上傳完成報告
- `CGMH_upload_all_test_data.py` - 自動上傳腳本

### 技術規格
- **FHIR版本**: R4 (4.0.1)
- **CQL引擎**: 符合HL7 CQL標準
- **資料格式**: JSON
- **編碼**: UTF-8

---

## 📝 版本歷史

**v1.0** (2025-12-02)
- 初始版本
- 包含10個Bundle
- 涵蓋29個醫療指標
- 總計508位病患、2457個資源

---

**文件製作**: CGMH FHIR專案團隊  
**最後更新**: 2025-12-02  
**聯絡方式**: [請填寫]
