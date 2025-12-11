# 🚀 ESG CQL 測試系統 - 安裝與執行指南

## 📋 系統已完成！

您的ESG CQL測試系統已經建立完成，包含以下功能：

### ✅ 主要功能

1. **連接2個外部SMART on FHIR伺服器**
   - HAPI FHIR Test Server
   - SMART Health IT Sandbox

2. **執行3個CQL檔案**
   - `Antibiotic_Utilization.cql` - 抗生素使用率
   - `EHR_Adoption_Rate.cql` - 電子病歷採用率
   - `Waste.cql` - 廢棄物管理

3. **資料過濾與顯示（VS Code控制）**
   - 時間範圍：2年內資料
   - 顯示總人數
   - 年齡分布統計
   - 性別分布統計
   - 居住地分布統計（前10名）

---

## 🔧 安裝步驟

### 步驟1: 確認Python已安裝

檢查Python是否已安裝：

```powershell
python --version
```

或

```powershell
py --version
```

**如果沒有Python：**

1. 前往 https://www.python.org/downloads/
2. 下載Python 3.8或以上版本
3. 安裝時**務必勾選** "Add Python to PATH"

### 步驟2: 安裝相依套件

在專案目錄下執行：

```powershell
# 方法1: 使用pip
pip install -r requirements.txt

# 方法2: 使用py
py -m pip install -r requirements.txt
```

### 步驟3: 驗證環境

執行環境檢查腳本：

```powershell
python check_env.py
```

如果看到 "✓ 環境檢查完成！所有項目正常"，表示可以開始測試。

---

## 🚀 執行測試

### 方法1: 直接執行主程式（推薦）

```powershell
python main.py
```

或

```powershell
py main.py
```

### 方法2: 使用PowerShell腳本

```powershell
.\run_test.ps1
```

### 方法3: 分步執行

```powershell
# 1. 切換到專案目錄
cd "c:\Users\tony1\OneDrive\桌面\ESG CQL 1116"

# 2. 確認Python環境
python check_env.py

# 3. 執行測試
python main.py
```

---

## 📊 預期輸出

執行後會看到：

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        ESG CQL 測試系統 v1.0.0                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝

步驟 1: 設定FHIR伺服器連線
✓ HAPI FHIR Test Server
✓ SMART Health IT Sandbox

步驟 2: 從SMART on FHIR伺服器擷取資料
  - Patient: XXX 筆
  - Encounter: XXX 筆
  - MedicationRequest: XXX 筆
  ...

步驟 3: 執行CQL Libraries
✓ Antibiotic_Utilization
✓ EHR_Adoption_Rate
✓ Waste

步驟 4: 資料過濾與顯示（2年內資料）

【病患基本資料統計】
總病患人數: XXX 人

年齡分布:
  0-17歲    XX 人
  18-30歲   XX 人
  31-50歲   XX 人
  51-65歲   XX 人
  66歲以上  XX 人
  平均年齡: XX.X 歲

性別分布:
  male      XX 人 (XX%)
  female    XX 人 (XX%)

居住地分布（前10名）:
  City1     XX 人
  City2     XX 人
  ...

【CQL執行結果】
■ Antibiotic_Utilization
  總病患數              XXX
  抗生素使用率          XX.X%
  DDD per 100 Bed-Days  XX.X
  ...

■ EHR_Adoption_Rate
  EHR採用率            XX.X%
  HIMSS EMRAM等級      Level X
  ...

■ Waste
  總廢棄物量           XXX kg
  回收率               XX.X%
  ...

✓ 結果已儲存至: esg_cql_results.json
```

---

## 📁 輸出檔案

執行後會產生以下檔案：

1. **esg_cql_results.json** - 完整的測試結果（JSON格式）
2. **esg_cql_test.log** - 詳細的執行日誌

---

## ⚙️ 自訂設定

### 修改時間範圍

編輯 `config.yaml`：

```yaml
data_filters:
  time_range:
    years: 3  # 改為3年
```

### 控制顯示欄位

編輯 `config.yaml`：

```yaml
data_filters:
  display_fields:
    total_patient_count: true   # 顯示總人數
    patient_age: true           # 顯示年齡統計
    patient_gender: true        # 顯示性別統計
    patient_location: false     # 不顯示居住地統計
```

### 新增或更換FHIR伺服器

編輯 `config.yaml`：

```yaml
fhir_servers:
  server3:
    name: "Your FHIR Server"
    base_url: "https://your-server.com/fhir"
    auth_type: "none"
    enabled: true
```

---

## 🐛 常見問題

### Q1: 執行時出現 "ModuleNotFoundError"

**解決方法：**
```powershell
pip install -r requirements.txt
```

### Q2: 無法連接FHIR伺服器

**可能原因：**
- 網路連線問題
- 防火牆阻擋
- 伺服器維護中

**解決方法：**
查看 `esg_cql_test.log` 獲取詳細錯誤訊息

### Q3: Python命令無法執行

**解決方法：**

嘗試使用 `py` 代替 `python`：
```powershell
py main.py
```

或安裝Python並將其加入PATH

### Q4: 沒有看到資料

**可能原因：**
- 公開測試伺服器的資料可能有限
- 時間範圍過濾掉所有資料

**解決方法：**
- 查看日誌檔案確認是否有擷取到資料
- 調整 `config.yaml` 的時間範圍

---

## 📚 檔案說明

| 檔案 | 說明 |
|------|------|
| `main.py` | 主程式，執行完整測試流程 |
| `fhir_client.py` | FHIR伺服器連線模組 |
| `cql_processor.py` | CQL處理器，執行CQL邏輯 |
| `data_filter.py` | 資料過濾與顯示控制 |
| `config.yaml` | 系統設定檔 |
| `check_env.py` | 環境檢查工具 |
| `requirements.txt` | Python套件相依 |
| `README.md` | 完整使用說明 |
| `Antibiotic_Utilization.cql` | 抗生素使用率CQL |
| `EHR_Adoption_Rate.cql` | 電子病歷採用率CQL |
| `Waste.cql` | 廢棄物管理CQL |

---

## 🎯 系統架構

```
┌─────────────────────────────────────────────────────┐
│                    main.py                          │
│               (主程式協調器)                          │
└──────────────┬──────────────────────────────────────┘
               │
       ┌───────┴────────┬────────────┬──────────────┐
       ▼                ▼            ▼              ▼
┌─────────────┐  ┌─────────────┐  ┌──────────┐  ┌─────────┐
│ fhir_client │  │cql_processor│  │data_filter│ │ config  │
│  連接伺服器  │  │  執行CQL    │  │  過濾顯示  │ │  設定   │
└─────────────┘  └─────────────┘  └──────────┘  └─────────┘
       │                 │               │
       ▼                 ▼               ▼
   [FHIR資料]       [CQL結果]      [過濾後資料]
       │                 │               │
       └─────────────────┴───────────────┘
                         │
                         ▼
                  [JSON輸出檔案]
                  [終端機顯示]
```

---

## 💡 使用提示

1. **首次執行**：建議先執行 `check_env.py` 確認環境
2. **查看日誌**：如遇問題，查看 `esg_cql_test.log`
3. **結果分析**：查看 `esg_cql_results.json` 獲取完整資料
4. **自訂設定**：通過 `config.yaml` 調整所有參數
5. **網路需求**：需要穩定的網際網路連線

---

## 📞 需要協助？

1. **環境問題**：執行 `python check_env.py`
2. **執行日誌**：查看 `esg_cql_test.log`
3. **詳細文件**：查看 `README.md`

---

## ✅ 快速檢查清單

執行前確認：

- [ ] Python 3.8+ 已安裝
- [ ] 已執行 `pip install -r requirements.txt`
- [ ] 已執行 `python check_env.py` 且通過
- [ ] 有穩定的網路連線
- [ ] 3個CQL檔案都存在

準備就緒後執行：
```powershell
python main.py
```

---

**版本**: 1.0.0  
**日期**: 2024-11-16  
**支援**: FHIR R4, CQL 1.5

🎉 **祝您測試順利！**
