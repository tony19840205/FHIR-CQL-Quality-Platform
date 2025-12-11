# ESG CQL 測試系統使用說明

## 📋 系統概述

這是一個完整的ESG CQL測試系統，能夠：
1. 連接2個外部SMART on FHIR伺服器
2. 擷取完整FHIR資料（範圍開很大）
3. 執行3個CQL檔案進行ESG指標計算
4. 在VS Code中過濾並顯示結果

## 🚀 快速開始

### 1. 安裝相依套件

```powershell
# 在專案目錄下執行
pip install -r requirements.txt
```

### 2. 設定配置檔

配置檔 `config.yaml` 已預先設定好，包含：
- 2個公開的SMART on FHIR測試伺服器
- 3個CQL檔案路徑
- 資料過濾條件（2年內、顯示總人數、年齡、性別、居住地）

如需修改，請直接編輯 `config.yaml`。

### 3. 執行測試

```powershell
python main.py
```

## 📂 檔案結構

```
ESG CQL 1116/
├── main.py                          # 主程式
├── fhir_client.py                   # FHIR伺服器連線模組
├── cql_processor.py                 # CQL處理器
├── data_filter.py                   # 資料過濾與顯示控制
├── config.yaml                      # 系統設定檔
├── requirements.txt                 # Python套件相依
├── Antibiotic_Utilization.cql      # 抗生素使用率CQL
├── EHR_Adoption_Rate.cql           # 電子病歷採用率CQL
├── Waste.cql                        # 廢棄物管理CQL
├── esg_cql_test.log                # 執行日誌（自動生成）
└── esg_cql_results.json            # 結果輸出（自動生成）
```

## ⚙️ 系統配置說明

### config.yaml 重點設定

#### 1. FHIR伺服器設定
```yaml
fhir_servers:
  server1:
    name: "HAPI FHIR Test Server"
    base_url: "https://hapi.fhir.org/baseR4"
    enabled: true
  
  server2:
    name: "SMART Health IT Sandbox"
    base_url: "https://launch.smarthealthit.org/v/r4/fhir"
    enabled: true
```

#### 2. 資料過濾條件（VS Code控制）
```yaml
data_filters:
  time_range:
    years: 2  # 擷取2年內資料
  
  display_fields:
    total_patient_count: true  # 顯示總人數
    patient_age: true          # 顯示年齡統計
    patient_gender: true       # 顯示性別統計
    patient_location: true     # 顯示居住地統計
```

## 🔧 執行流程

系統執行分為5個步驟：

### 步驟1: 設定FHIR伺服器連線
- 建立與2個SMART on FHIR伺服器的連線
- 驗證連線狀態

### 步驟2: 擷取FHIR資料
- 從所有伺服器擷取以下資源（無時間限制，範圍開很大）：
  - Patient（病患）
  - Encounter（就醫記錄）
  - MedicationRequest（藥物醫囑）
  - MedicationAdministration（給藥記錄）
  - Observation（觀察記錄）
  - Procedure（處置記錄）
  - DocumentReference（文件參照）
  - DiagnosticReport（診斷報告）
- 合併並去重所有伺服器的資料

### 步驟3: 執行CQL Libraries
執行3個CQL檔案：
- **Antibiotic_Utilization**: 抗生素使用率計算
- **EHR_Adoption_Rate**: 電子病歷採用率計算
- **Waste**: 廢棄物管理指標計算

### 步驟4: 資料過濾與顯示（VS Code控制）
- 過濾2年內的資料
- 提取病患統計資訊：
  - 總人數
  - 年齡分布（0-17歲、18-30歲、31-50歲、51-65歲、66歲以上）
  - 性別分布
  - 居住地分布（前10名）

### 步驟5: 輸出結果
- 在終端機顯示美化的結果
- 儲存完整結果至 `esg_cql_results.json`
- 記錄執行日誌至 `esg_cql_test.log`

## 📊 輸出結果說明

### 1. 病患基本資料統計
```
總病患人數: XXX 人

年齡分布:
  0-17歲     XX 人
  18-30歲    XX 人
  31-50歲    XX 人
  51-65歲    XX 人
  66歲以上   XX 人
  平均年齡: XX.X 歲

性別分布:
  male       XX 人 (XX%)
  female     XX 人 (XX%)

居住地分布（前10名）:
  City1      XX 人
  City2      XX 人
  ...
```

### 2. CQL執行結果

#### Antibiotic_Utilization（抗生素使用率）
- 總病患數
- 總就醫次數
- 抗生素醫囑數
- 抗生素給藥次數
- 抗生素使用率 (%)
- DDD per 100 Bed-Days

#### EHR_Adoption_Rate（電子病歷採用率）
- 總病患數
- 總就醫次數
- EHR文件數
- 電子處方數
- EHR採用率 (%)
- HIMSS EMRAM等級

#### Waste（廢棄物管理）
- 總病患數
- 總就醫次數
- 總廢棄物量 (kg)
- 可回收廢棄物 (kg)
- 回收率 (%)

## 🔍 進階使用

### 修改時間範圍

編輯 `config.yaml`:
```yaml
data_filters:
  time_range:
    years: 3  # 改為3年
```

### 新增FHIR伺服器

編輯 `config.yaml`:
```yaml
fhir_servers:
  server3:
    name: "Your Server Name"
    base_url: "https://your-fhir-server.com/fhir"
    auth_type: "oauth"  # 如需認證
    enabled: true
```

### 控制顯示欄位

編輯 `config.yaml`:
```yaml
data_filters:
  display_fields:
    total_patient_count: true
    patient_age: false        # 關閉年齡顯示
    patient_gender: true
    patient_location: false   # 關閉居住地顯示
```

### 查看詳細日誌

執行後查看 `esg_cql_test.log` 檔案，包含完整的執行過程記錄。

### JSON結果檔案

`esg_cql_results.json` 包含完整的結構化結果，可供其他程式或分析工具使用。

## ⚠️ 注意事項

1. **網路連線**: 需要網際網路連線以存取外部FHIR伺服器
2. **Python版本**: 建議使用 Python 3.8 或以上版本
3. **CQL執行**: 由於Python缺乏完整的CQL引擎，本系統使用模擬執行（基於FHIR資料進行計算）
4. **資料範圍**: 
   - FHIR擷取階段：範圍開很大（無時間限制）
   - VS Code控制階段：過濾2年內資料並顯示
5. **公開伺服器**: 預設使用公開測試伺服器，資料可能為測試資料

## 🐛 疑難排解

### 問題1: 套件安裝失敗
```powershell
# 升級pip
python -m pip install --upgrade pip

# 重新安裝
pip install -r requirements.txt
```

### 問題2: 無法連接FHIR伺服器
- 檢查網路連線
- 確認防火牆設定
- 查看 `esg_cql_test.log` 的錯誤訊息

### 問題3: CQL執行錯誤
- 確認CQL檔案存在
- 檢查CQL檔案語法
- 查看日誌檔案的詳細錯誤

### 問題4: 沒有資料
- 公開測試伺服器的資料量可能有限
- 嘗試調整時間範圍
- 查看日誌確認資料擷取狀況

## 📞 技術支援

如有問題，請查看：
1. `esg_cql_test.log` - 執行日誌
2. `esg_cql_results.json` - 結果輸出
3. 終端機輸出的錯誤訊息

## 📝 版本資訊

- **版本**: 1.0.0
- **日期**: 2024-11-16
- **Python**: 3.8+
- **FHIR**: R4
- **CQL**: Standard 1.5
