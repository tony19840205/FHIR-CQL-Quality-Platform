# FHIR CQL 整合平台 - 網頁版 APP

## 📋 專案簡介

這是一個基於 FHIR 標準和 CQL (Clinical Quality Language) 的醫療數據分析平台，專注於疾病管制與流行病學監測。

### 主要功能

- ✅ **首頁** - FHIR 伺服器設定與系統總覽
- ✅ **疾管儀表板** - 5 種傳染病監測（COVID-19、流感、登革熱、腸病毒、腹瀉）
- 🔄 **國民健康** - （即將推出）
- 🔄 **ESG 指標** - （即將推出）
- 🔄 **醫療品質** - （即將推出）

## 🚀 快速開始

### 1. 開啟應用程式

直接在瀏覽器中開啟 `index.html` 即可使用。

### 2. 設定 FHIR 伺服器

在首頁設定您的 FHIR 伺服器連線：

**預設伺服器選項：**
- HAPI FHIR R4: `https://hapi.fhir.org/baseR4`
- SMART Health IT R4: `https://r4.smarthealthit.org`
- Firely Server: `https://server.fire.ly`
- 自訂伺服器

**測試連線：**
1. 選擇或輸入 FHIR 伺服器 URL
2. （選填）輸入驗證令牌
3. 點擊「測試連線」按鈕
4. 確認連線狀態顯示為「已連線」

### 3. 使用疾管儀表板

1. 點擊導航欄的「疾管儀表板」
2. 選擇要執行的 CQL 查詢模組
3. 點擊「執行查詢」按鈕
4. 查看結果與分析圖表

## 📁 專案結構

```
FHIR-Dashboard-App/
├── index.html              # 首頁
├── disease-control.html    # 疾管儀表板
├── css/
│   ├── styles.css         # 全域樣式
│   └── dashboard.css      # 儀表板樣式
├── js/
│   ├── main.js           # 主要邏輯
│   ├── fhir-connection.js # FHIR 連線管理
│   ├── cql-engine.js     # CQL 執行引擎
│   └── dashboard.js      # 儀表板邏輯
└── cql/                  # CQL 查詢檔案（參考用）
```

## 🏥 疾管儀表板 - CQL 模組

### 1. COVID-19 監測 (COVID19Cohort_NoID)

**診斷碼：**
- ICD-10: U07.1, U07.2
- SNOMED CT: 840539006

**檢驗碼：**
- LOINC: 94500-6, 94558-4, 94559-2, 94745-7

**功能：**
- COVID-19 確診病例追蹤
- PCR/快篩檢驗結果分析
- 急診與住院案例統計

### 2. 流感監測 (InfluenzaCohort_NoID)

**診斷碼：**
- ICD-10: J09.X1-J09.X9, J10.00-J10.89, J11.00-J11.89
- SNOMED CT: 6142004, 442438000

**檢驗碼：**
- LOINC: 80382-5, 92142-9, 94500-6

**功能：**
- 流感病例追蹤
- Episode 聚合分析（30天視窗）
- 重症案例監測

### 3. 登革熱監測 (DengueCohort_NoID)

**診斷碼：**
- ICD-10: A90, A91
- SNOMED CT: 38344005, 16541001, 719914004

**檢驗碼：**
- LOINC: 7974-9, 7975-6, 56868-9, 49520-9, 75663-2

**功能：**
- 登革熱疫情監控
- NS1 快篩追蹤
- IgG/IgM 抗體檢測

### 4. 腸病毒監測 (EnterovirusCohort_NoID)

**診斷碼：**
- ICD-10: B084, B085, A870, B341
- SNOMED CT: 36989005, 441866009, 240569000, 11227006

**檢驗碼：**
- LOINC: 48507-2, 37362-1, 13267-0, 82184-1

**功能：**
- 腸病毒疫情追蹤
- 手足口症、疱疹性咽峽炎監測
- 重症案例警示

### 5. 腹瀉群聚監測 (DiarrheaCohort_NoID)

**診斷碼：**
- ICD-10: R19.7, A08.0-A08.4, A09
- SNOMED CT: 62315008, 25374005, 235595009

**檢驗碼：**
- LOINC: 34468-9, 22810-1, 80382-5

**功能：**
- 腹瀉疫情監控
- 諾羅病毒、輪狀病毒追蹤
- 群聚感染偵測

## 🔧 技術架構

### 前端技術
- **HTML5 / CSS3** - 響應式網頁設計
- **JavaScript (ES6+)** - 原生 JavaScript，無框架依賴
- **Chart.js** - 數據視覺化圖表
- **Font Awesome** - 圖標系統

### FHIR 整合
- **FHIR 版本**: 4.0.1 (R4)
- **支援的資源類型**:
  - Patient（患者）
  - Encounter（就診記錄）
  - Condition（診斷）
  - Observation（檢驗結果）

### CQL 執行邏輯
- 診斷碼對應（ICD-10, SNOMED CT）
- 檢驗碼對應（LOINC）
- Episode 聚合分析
- 時間視窗過濾

## 📊 數據呈現

### 總覽卡片
- 累計病例數
- 本日新增案例
- 疫情趨勢指標

### 圖表分析
- **趨勢圖**: 近7日病例變化
- **來源圖**: 急診/住院/門診分布
- **年齡圖**: 各年齡層病例分布

### 詳細資料表
- 病例清單
- 就診資訊
- 診斷與檢驗結果
- 可搜尋、可匯出（CSV/JSON）

## 🔐 安全性考量

### CORS 支援
本應用程式需要 FHIR 伺服器支援 CORS (Cross-Origin Resource Sharing)。

### 驗證支援
- 支援 Bearer Token 驗證
- 可選填驗證令牌
- 連線資訊儲存於本地瀏覽器

## 📱 響應式設計

完全支援各種裝置：
- 桌面電腦（1920px+）
- 平板電腦（768px-1024px）
- 手機（< 768px）

## 🎨 UI/UX 特色

### 視覺設計
- 現代化漸層背景
- 卡片式設計
- 流暢的動畫效果
- 直覺的配色系統

### 互動體驗
- 即時狀態回饋
- 載入動畫
- 錯誤提示
- 成功通知

## 🚦 使用流程

```
1. 開啟首頁 (index.html)
   ↓
2. 設定 FHIR 伺服器
   ↓
3. 測試連線成功
   ↓
4. 進入疾管儀表板
   ↓
5. 選擇疾病類型
   ↓
6. 執行 CQL 查詢
   ↓
7. 查看分析結果
   ↓
8. 匯出資料（可選）
```

## 📖 CQL 查詢參數

所有 CQL 查詢支援以下參數：

- **Run Date**: 執行日期（預設：今天）
- **Episode Window Days**: Episode 視窗天數（預設：30天）
- **Lookback Days**: 回看天數（預設：60天）

## 🔍 故障排除

### 連線失敗
1. 確認 FHIR 伺服器 URL 正確
2. 檢查伺服器是否支援 CORS
3. 確認網路連線正常
4. 檢查驗證令牌是否有效

### 查詢無結果
1. 確認 FHIR 伺服器有相關資源
2. 檢查診斷碼對應是否正確
3. 嘗試調整查詢參數
4. 查看瀏覽器開發者工具的 Console 日誌

### 圖表不顯示
1. 確認已執行 CQL 查詢
2. 檢查是否有返回資料
3. 重新整理頁面
4. 清除瀏覽器快取

## 🌐 瀏覽器支援

- ✅ Google Chrome (推薦)
- ✅ Microsoft Edge
- ✅ Firefox
- ✅ Safari
- ⚠️ Internet Explorer (不支援)

## 📦 依賴套件

- **Chart.js** v4.4.0 - 從 CDN 載入
- **Font Awesome** v6.4.0 - 從 CDN 載入

無需安裝任何套件，開箱即用！

## 🔮 未來規劃

- [ ] 國民健康模組（疫苗接種分析）
- [ ] ESG 指標模組（醫療廢棄物、抗生素使用）
- [ ] 醫療品質模組（品質指標監控）
- [ ] 使用者權限管理
- [ ] 自訂 CQL 查詢編輯器
- [ ] 報表自動生成功能
- [ ] 多語言支援
- [ ] 深色模式

## 👨‍💻 開發者資訊

### 本地測試
直接用瀏覽器開啟 `index.html` 即可。

### FHIR 測試伺服器
推薦使用以下公開測試伺服器：
- HAPI FHIR: https://hapi.fhir.org/baseR4
- SMART Health IT: https://r4.smarthealthit.org

### 自訂開發
所有 JavaScript 檔案都有詳細註解，可根據需求擴展功能。

## 📄 授權

Copyright © 2025 FHIR CQL Platform. All rights reserved.

## 🙏 致謝

感謝以下開源專案：
- FHIR® (Fast Healthcare Interoperability Resources)
- CQL (Clinical Quality Language)
- Chart.js
- Font Awesome

---

**版本**: 1.0.0  
**最後更新**: 2025-01-12  
**FHIR 版本**: 4.0.1 (R4)
