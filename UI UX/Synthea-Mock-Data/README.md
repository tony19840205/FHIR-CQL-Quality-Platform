# Synthea 模擬醫療數據生成專案

## 📋 專案說明

本專案使用 **Synthea** 生成符合 FHIR R4 標準的模擬醫療數據，用於「基於 FHIR 標準的智慧醫療品質監測系統」的功能展示與驗證。

### ⚠️ 重要說明
- 本資料夾與 `FHIR-Dashboard-App` 完全獨立，不會影響原系統
- 所有數據為合成數據（Synthetic Data），不含真實病患資訊
- 僅用於技術展示與競賽評審用途

---

## 🎯 目標

生成 **1000 個模擬病人**的完整醫療記錄，包含：
- ✅ 病人基本資料（Patient）
- ✅ 就診記錄（Encounter）
- ✅ 藥品處方（MedicationRequest）
- ✅ 檢驗結果（Observation）
- ✅ 診斷記錄（Condition）
- ✅ 手術記錄（Procedure）

針對 **5-8 個重點醫療品質指標** 設計合理的數據分布。

---

## 📂 資料夾結構

```
Synthea-Mock-Data/
├── README.md                      ← 你現在看的檔案
├── synthea-setup/                 ← Synthea 安裝與執行
│   ├── download-synthea.ps1       ← 下載 Synthea（自動）
│   ├── run-synthea.ps1            ← 執行生成（一鍵）
│   └── synthea-with-dependencies.jar  ← Synthea 主程式（自動下載）
│
├── synthea-config/                ← 設定檔案
│   ├── synthea.properties         ← Synthea 基本設定
│   └── taiwan-demographics.json   ← 台灣人口統計參數
│
├── generated-fhir-data/           ← 生成的數據（執行後產生）
│   ├── fhir/                      ← 單個 FHIR 資源檔案
│   └── practitioner123456.json    ← Bundle 格式（全部資料）
│
├── post-processing/               ← 後處理腳本
│   ├── add-realistic-noise.js     ← 加入小數點變異
│   ├── adjust-indicators.js       ← 調整指標數值
│   └── validate-fhir.js           ← 驗證 FHIR 格式
│
└── upload-scripts/                ← 上傳腳本
    ├── upload-to-fhir.ps1         ← 上傳到 FHIR 伺服器
    └── preview-data.html          ← 本地預覽數據
```

---

## 🚀 快速開始

### 步驟 1：下載 Synthea（約 5 分鐘）

```powershell
cd "c:\Users\tony1\OneDrive\桌面\UI UX-20251122(0013)\UI UX\Synthea-Mock-Data\synthea-setup"
.\download-synthea.ps1
```

這會自動下載最新版本的 Synthea（約 150MB）。

### 步驟 2：生成 1000 個病人數據（約 15-20 分鐘）

```powershell
.\run-synthea.ps1 -PatientCount 1000
```

### 步驟 3：後處理（加入真實變異）

```powershell
cd ..\post-processing
node add-realistic-noise.js
node adjust-indicators.js
```

### 步驟 4：本地預覽

在瀏覽器開啟：
```
upload-scripts\preview-data.html
```

### 步驟 5：確認 OK 後上傳（您確認後執行）

```powershell
cd ..\upload-scripts
.\upload-to-fhir.ps1 -TestMode
```

---

## 📊 指標數據設計

### 優先生成的 8 個指標：

| 指標 | 目標值 | 合理範圍 | 小數位數 |
|------|--------|----------|----------|
| 01. 門診注射劑使用率 | 5.0% | 3.5-7.5% | 2 位 |
| 02. 門診抗生素使用率 | 18.0% | 15.0-22.0% | 2 位 |
| 10. 糖尿病血糖控制不良率 | 20.0% | 16.0-25.0% | 1 位 |
| 03-1. 同院降血壓藥物重複用藥率 | 6.5% | 4.0-9.0% | 2 位 |
| 03-8. 跨院降血壓藥物重複用藥率 ⭐ | 8.5% | 6.0-11.0% | 2 位 |
| 11-1. 高血壓血壓控制不良率 | 22.0% | 18.0-26.0% | 1 位 |
| 12. 全院 14 天內再住院率 | 7.0% | 5.0-9.0% | 2 位 |
| 14. 產科剖腹產率 | 35.0% | 30.0-40.0% | 1 位 |

⭐ 展示專利技術

---

## 💡 技術細節

### 為什麼數據不是整數？

我們使用以下技術讓數據更真實：

1. **隨機變異**：每個指標 ±10% 的自然波動
2. **個體差異**：每個病人的檢驗值略有不同
3. **時間序列**：不同月份的數據有季節性變化
4. **四捨五入**：保留 1-2 位小數

範例：
```javascript
// 原本：5.00% → 調整後：4.73%
// 原本：20.00% → 調整後：21.38%
```

### 台灣化設定

- 使用台灣常見姓氏（陳、林、王、李、張等）
- 設定台灣疾病盛行率（高血壓 25%、糖尿病 12%）
- 台灣地址格式

---

## ⚠️ 注意事項

1. **Java 需求**：Synthea 需要 Java 11 或更高版本
   - 檢查：`java -version`
   - 如果沒有，腳本會提示您安裝

2. **硬碟空間**：約需 500MB-1GB
   - 1000 病人約 200-300MB
   - 後處理檔案約 100MB

3. **執行時間**：
   - 生成數據：15-20 分鐘
   - 後處理：5 分鐘
   - 上傳：2-3 分鐘（視網路速度）

4. **記憶體**：建議至少 4GB RAM

---

## 🔍 驗證數據品質

執行驗證腳本：

```powershell
cd post-processing
node validate-fhir.js
```

會檢查：
- ✅ FHIR R4 格式正確性
- ✅ 必要欄位完整性
- ✅ 資源之間的關聯正確
- ✅ 指標計算結果合理

---

## 📞 需要協助？

如果遇到問題：

1. **Java 未安裝**
   - Windows：從 https://adoptium.net/ 下載
   - 安裝後重新啟動 PowerShell

2. **下載失敗**
   - 檢查網路連接
   - 手動下載：https://github.com/synthetichealth/synthea/releases

3. **生成錯誤**
   - 查看 `synthea-setup/logs/` 資料夾
   - 確認 Java 版本 >= 11

4. **數據不符合預期**
   - 調整 `synthea-config/synthea.properties`
   - 重新執行生成

---

## 📄 授權說明

- Synthea: Apache License 2.0
- 本專案腳本：僅供競賽展示使用
- 生成的數據：合成數據，無版權限制

---

**建立日期**：2025-12-01  
**用途**：醫療品質監測系統競賽展示  
**狀態**：準備中 → 執行中 → 完成

---

## 🎯 下一步

執行 `synthea-setup\download-synthea.ps1` 開始！
