# 傳染病統計監測系統 - CQL 測試框架

## 📋 專案概述

此專案整合 **CQL (Clinical Quality Language)** 與 **SMART on FHIR** 標準，用於傳染病統計監測。系統連接外部 SMART FHIR 伺服器，檢索臨床資料，並根據自訂條件進行過濾與彙總分析。

## 🎯 功能特點

1. **多 CQL 函式庫支援**
   - COVID-19 監測
   - 流感監測
   - 急性結膜炎（紅眼症）監測
   - 腸病毒監測
   - 急性腹瀉監測

2. **外部 SMART FHIR 連線**
   - 連接 2 個 SMART FHIR 測試伺服器
   - 自動檢索 Patient, Condition, Observation, Encounter 資源

3. **資料過濾與彙總**
   - ⏰ 時間範圍：過去 2 年內資料
   - 👥 總人數統計
   - 📊 年齡分佈（0-4歲、5-17歲、18-44歲、45-64歲、65歲以上）
   - 👤 性別分佈
   - 🏥 就醫類型（門診/急診/住院）
   - 🦠 病毒類型識別
   - 📍 患者居住地分佈（僅城市/州層級，不含詳細個資）
   - 🚫 排除患者個資（ID、姓名等）

4. **多格式輸出**
   - 控制台顯示
   - JSON 檔案
   - CSV 檔案

## 📁 檔案結構

```
傳染病統計資料CQL1115/
├── COVID19.cql              # COVID-19 監測 CQL
├── 流感.cql                 # 流感監測 CQL
├── 紅眼症.cql               # 急性結膜炎監測 CQL
├── 腸病毒.cql               # 腸病毒監測 CQL
├── 腹瀉.cql                 # 急性腹瀉監測 CQL
├── config.json              # 系統設定檔
├── smartFhirConnector.js    # SMART FHIR 連線模組
├── dataFilterDisplay.js     # 資料過濾與顯示模組
├── testRunner.js            # 主測試程式
├── package.json             # Node.js 專案設定
└── README.md                # 本說明文件
```

## 🚀 安裝與設定

### 1. 安裝相依套件

```powershell
npm install
```

### 2. 設定 config.json

編輯 `config.json` 以自訂：
- SMART 伺服器 URL
- 啟用/停用特定 CQL 函式庫
- 過濾條件（時間範圍、顯示欄位等）
- 輸出格式與路徑

```json
{
  "smartServers": [
    {
      "name": "SMART Server 1",
      "fhirBaseUrl": "https://r4.smarthealthit.org",
      "enabled": true
    }
  ],
  "filterCriteria": {
    "timeRangeYears": 2,
    "displayFields": [
      "totalCount",
      "ageDistribution",
      "genderDistribution",
      "encounterTypeDistribution",
      "virusTypeDistribution",
      "residenceLocation"
    ],
    "excludePatientIdentifiers": true
  }
}
```

## 📊 使用方法

### 執行所有測試

```powershell
npm test
```

或

```powershell
node testRunner.js
```

### 執行特定 CQL 函式庫測試

```powershell
# 測試 COVID-19
npm run test:covid

# 測試流感
npm run test:flu

# 測試紅眼症
npm run test:conjunctivitis

# 測試腸病毒
npm run test:enterovirus

# 測試腹瀉
npm run test:diarrhea
```

## 📈 輸出範例

### 控制台輸出

```
================================================================================
📋 COVID-19 監測結果
⏰ 時間範圍: 過去 2 年
================================================================================

👥 總人數: 125

📊 年齡分佈:
  0-4歲: 15 (12.0%)
  5-17歲: 25 (20.0%)
  18-44歲: 45 (36.0%)
  45-64歲: 30 (24.0%)
  65歲以上: 10 (8.0%)

👤 性別分佈:
  男性: 60 (48.0%)
  女性: 65 (52.0%)

🏥 就醫類型分佈:
  門診: 80 (64.0%)
  急診: 30 (24.0%)
  住院: 15 (12.0%)

🦠 病毒類型分佈:
  COVID-19: 125 (100.0%)

📍 居住地分佈 (前10名):
  Massachusetts, Boston: 30 (24.0%)
  New York, New York: 25 (20.0%)
  ...

🔗 資料來源:
  ✅ SMART Server 1: 75 筆資料
  ✅ SMART Server 2: 50 筆資料
```

### 檔案輸出

結果會自動儲存到 `./results/` 目錄：
- `COVID-19_2025-11-15T10-30-45.json`
- `COVID-19_2025-11-15T10-30-45.csv`

## 🔧 進階設定

### 修改時間範圍

在 `config.json` 中修改：

```json
"filterCriteria": {
  "timeRangeYears": 3  // 改為 3 年
}
```

### 新增 SMART 伺服器

在 `config.json` 的 `smartServers` 陣列中新增：

```json
{
  "name": "My Hospital FHIR Server",
  "fhirBaseUrl": "https://myhospital.org/fhir",
  "enabled": true
}
```

### 自訂顯示欄位

在 `config.json` 中調整 `displayFields`：

```json
"displayFields": [
  "totalCount",
  "ageDistribution",
  "genderDistribution"
  // 移除不需要的欄位
]
```

## 🛡️ 隱私保護

系統設計遵循以下隱私原則：

1. ✅ **不顯示患者識別資訊**（ID、姓名、身分證號等）
2. ✅ **地址僅顯示城市/州層級**（不含街道地址）
3. ✅ **資料彙總呈現**（統計圖表，非個別記錄）
4. ✅ **可設定排除個資選項** (`excludePatientIdentifiers: true`)

## 📝 CQL 運作邏輯

CQL 檔案會：
1. 定義疾病相關的診斷代碼（ICD-9/10, SNOMED CT）
2. 定義實驗室檢驗代碼（LOINC）
3. 從 FHIR 伺服器檢索所有符合代碼的資料（範圍開很大）
4. 由 VS Code 的 JavaScript 程式進行：
   - 時間過濾（2年內）
   - 資料彙總
   - 統計計算
   - 格式化顯示

## 🐛 疑難排解

### 無法連接 SMART 伺服器

- 檢查網路連線
- 確認伺服器 URL 正確
- 查看防火牆設定

### CQL 檔案找不到

- 確認檔案路徑正確
- 檢查 `config.json` 中的檔案名稱

### 沒有資料

- SMART 測試伺服器的資料可能有限
- 嘗試連接其他 FHIR 伺服器
- 調整時間範圍

## 📚 相關文件

- [SMART on FHIR](https://smarthealthit.org/)
- [CQL Specification](https://cql.hl7.org/)
- [FHIR R4](https://www.hl7.org/fhir/)

## 📞 聯絡資訊

如有問題或建議，請建立 Issue 或 Pull Request。

---

**版本**: 1.0.0  
**最後更新**: 2025-11-15
