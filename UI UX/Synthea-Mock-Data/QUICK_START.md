# 🚀 Synthea 合成資料生成 - 快速啟動指南

## ⚡ 5 分鐘快速開始

### 步驟 1: 下載 Synthea（1 分鐘）
```powershell
cd synthea-setup
.\download-synthea.ps1
```

### 步驟 2: 生成 1000 位病人資料（3-5 分鐘）
```powershell
.\run-synthea.ps1 -PatientCount 1000
```

### 步驟 3: 執行後處理（1-2 分鐘）
```powershell
cd ..\post-processing
npm run all
```

這會依序執行：
1. `add-realistic-noise.js` - 添加 ±10% 隨機變異
2. `adjust-indicators.js` - 調整關鍵指標到目標範圍
3. `validate-fhir.js` - 驗證 FHIR 格式

### 步驟 4: 預覽資料
```powershell
cd ..\upload-scripts
# 在瀏覽器開啟 preview-data.html
```

### 步驟 5: 上傳到 FHIR 伺服器

先測試上傳 10 筆：
```powershell
.\upload-to-fhir.ps1 -TestMode
```

確認無誤後完整上傳：
```powershell
.\upload-to-fhir.ps1
```

---

## 📋 詳細步驟說明

### 前置需求

#### 1. 安裝 Java 11+
```powershell
# 檢查 Java 版本
java -version

# 如果沒有安裝，請下載：
# https://adoptium.net/
```

#### 2. 安裝 Node.js 14+
```powershell
# 檢查 Node.js 版本
node -v

# 如果沒有安裝，請下載：
# https://nodejs.org/
```

---

## 🎯 預期結果

### 資料量統計
- **病人數量**: 1,000 位
- **總資源數**: ~45,000 筆
- **檔案數量**: ~1,000 個 JSON 檔案
- **總檔案大小**: ~850 MB

### 資源類型分布
| 資源類型 | 數量 | 說明 |
|---------|------|------|
| Patient | 1,000 | 病人基本資料 |
| Encounter | ~8,500 | 就醫紀錄（門診/住院/急診）|
| Observation | ~15,000 | 檢驗檢查數據 |
| Condition | ~5,500 | 診斷紀錄 |
| MedicationRequest | ~7,500 | 用藥處方 |
| Procedure | ~3,200 | 處置紀錄 |
| DiagnosticReport | ~2,800 | 檢驗報告 |
| Immunization | ~1,200 | 疫苗接種 |
| CarePlan | ~300 | 照護計畫 |

### 8 個優先醫療品質指標目標值

| 指標代碼 | 指標名稱 | 目標值 | 範圍 | 小數位數 |
|---------|---------|-------|------|---------|
| **01** | 門診注射劑使用率 | 5.0% | 3.5-7.5% | 2 |
| **02** | 門診抗生素使用率 | 18.0% | 15.0-22.0% | 2 |
| **10** | 糖尿病控制不良率 (HbA1c > 9%) | 20.0% | 16.0-25.0% | 1 |
| **03-1** | 同醫院降血壓藥重複用藥率 | 6.5% | 4.0-9.0% | 2 |
| **03-8** | 跨醫院降血壓藥重複用藥率 ⭐ | 8.5% | 6.0-11.0% | 2 |
| **11-1** | 高血壓控制不良率 | 22.0% | 18.0-26.0% | 1 |
| **12** | 14 日內再住院率 | 7.0% | 5.0-9.0% | 2 |
| **14** | 剖腹產率 | 35.0% | 30.0-40.0% | 1 |

⭐ **指標 03-8 跨醫院重複用藥偵測為專利技術**

---

## 🔧 進階選項

### 測試模式（生成少量資料）
```powershell
# 先生成 10 位病人測試
cd synthea-setup
.\run-synthea.ps1 -PatientCount 10
```

### 自訂地區
```powershell
# 指定特定州/市
.\run-synthea.ps1 -PatientCount 1000 -State "Taiwan" -City "Kaohsiung"
```

### 分批上傳
```powershell
# 自訂批次大小
.\upload-to-fhir.ps1 -TestMode -BatchSize 50
```

---

## ❓ 常見問題

### Q1: 找不到 Java
**A:** 下載並安裝 Java 11+:
- 官網: https://adoptium.net/
- 安裝後重新開啟 PowerShell

### Q2: Synthea 下載失敗
**A:** 手動下載:
1. 前往 https://github.com/synthetichealth/synthea/releases/latest
2. 下載 `synthea-with-dependencies.jar`
3. 放到 `synthea-setup` 資料夾

### Q3: 生成資料花太久時間
**A:** 正常！1000 位病人約需 3-5 分鐘
- 可以先用 `-PatientCount 10` 測試
- Synthea 會生成完整的醫療歷史，包含數十年的資料

### Q4: 後處理腳本執行錯誤
**A:** 確認 Node.js 版本:
```powershell
node -v  # 應該 >= 14.0.0
```

### Q5: 上傳到 FHIR 伺服器失敗
**A:** 檢查項目:
- 網路連線是否正常
- FHIR 伺服器 URL 是否正確
- 是否有上傳權限
- 先用 `-TestMode` 測試少量資料

### Q6: 指標值不在目標範圍內
**A:** 重新執行後處理:
```powershell
cd post-processing
npm run adjust
npm run validate
```

---

## 📊 驗證清單

上傳前確認以下項目：

- [ ] ✅ Java 11+ 已安裝
- [ ] ✅ Node.js 14+ 已安裝
- [ ] ✅ Synthea JAR 檔案已下載
- [ ] ✅ 生成 1000 位病人資料
- [ ] ✅ 執行後處理腳本（添加變異）
- [ ] ✅ 執行指標調整腳本
- [ ] ✅ FHIR 格式驗證通過
- [ ] ✅ 預覽資料統計正確
- [ ] ✅ 測試上傳 10 筆成功
- [ ] ✅ 在 Dashboard 確認指標顯示

---

## 🎓 技術細節

### 資料真實性處理

#### 1. 隨機變異（±10%）
```javascript
// 範例: 血壓值
原始值: 140 mmHg
變異後: 138.7 mmHg (保留 1 位小數)
```

#### 2. 台灣在地化
- **常見姓氏**: 陳、林、黃、張、李、王、吳、劉、蔡、楊
- **疾病盛行率**:
  - 高血壓: 26.7%（40 歲以上 35.9%）
  - 糖尿病: 11.8%（40 歲以上 13.9%）
  - 高血脂: 22.2%
- **就醫習慣**:
  - 年均門診次數: 15.2 次
  - 年均住院次數: 0.13 次
  - 全民健保涵蓋率: 99.9%

#### 3. 小數位數規則
- **百分比類數據**: 保留 2 位小數（如 5.27%）
- **測量值**: 保留 1 位小數（如 138.7 mmHg）
- **計數**: 整數（如 3 次）

---

## 📁 資料夾結構

```
Synthea-Mock-Data/
├── README.md                    # 完整說明文件
├── QUICK_START.md              # 本快速指南
├── synthea-setup/              # Synthea 設定與執行
│   ├── download-synthea.ps1    # 下載腳本
│   ├── run-synthea.ps1         # 執行腳本
│   └── synthea-with-dependencies.jar  # Synthea 主程式
├── synthea-config/             # 配置檔案
│   ├── synthea.properties      # Synthea 設定
│   └── taiwan-demographics.json # 台灣人口統計參數
├── generated-fhir-data/        # 生成的資料
│   ├── fhir/                   # 原始 FHIR 資料
│   └── fhir-processed/         # 後處理過的資料
├── post-processing/            # 後處理腳本
│   ├── package.json
│   ├── add-realistic-noise.js  # 添加變異
│   ├── adjust-indicators.js    # 調整指標
│   └── validate-fhir.js        # 驗證資料
└── upload-scripts/             # 上傳工具
    ├── upload-to-fhir.ps1      # 上傳腳本
    └── preview-data.html       # 資料預覽頁面
```

---

## 🚨 注意事項

1. **不要移動或重新命名資料夾**
   - 腳本使用相對路徑
   - 移動會導致找不到檔案

2. **不要手動修改生成的 FHIR 檔案**
   - 使用後處理腳本自動調整
   - 手動修改可能破壞 FHIR 格式

3. **測試後再完整上傳**
   - 先用 `-TestMode` 上傳 10 筆
   - 確認 Dashboard 正常顯示
   - 再執行完整上傳

4. **保留原始系統備份**
   - 此資料夾獨立於 FHIR-Dashboard-App
   - 不會影響現有系統
   - 如需回復，清除 FHIR 伺服器資料即可

---

## 📞 問題回報

如遇到無法解決的問題，請提供：
1. 錯誤訊息截圖
2. 執行的命令
3. Java 和 Node.js 版本
4. PowerShell 版本

---

## 📝 授權

- **Synthea**: Apache License 2.0
- **後處理腳本**: MIT License
- **台灣人口統計數據**: 公開資料，引用自衛福部

---

**最後更新**: 2024/11
**版本**: 1.0.0
