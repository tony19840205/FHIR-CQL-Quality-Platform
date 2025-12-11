# 醫院總額醫療品質資訊 - 門診用藥指標系統

## 專案概述

本專案實作了醫院總額醫療品質資訊系統的兩個關鍵指標，使用 SMART on FHIR 標準進行資料查詢與分析。

### 已完成指標

| 指標編號 | 指標名稱 | 指標代碼 | 參考基準(2022Q1) |
|---------|---------|---------|----------------|
| 1 | 門診注射劑使用率 | 3127 | 0.94% |
| 2 | 門診抗生素使用率 | 3128 | 19.84% |

## 檔案結構

```
醫院總額醫療品質資訊/
├── 1_門診注射劑使用率.cql                    # 注射劑指標 CQL 查詢
├── 2_門診抗生素使用率.cql                    # 抗生素指標 CQL 查詢
├── run_cql_query.py                          # 注射劑查詢執行腳本
├── run_antibiotic_query.py                   # 抗生素查詢執行腳本
├── display_injection_report.ps1              # 注射劑報表顯示
├── display_antibiotic_report_simple.ps1      # 抗生素報表顯示
├── 2_門診抗生素使用率_README.md              # 抗生素指標文件
└── results/                                  # 查詢結果目錄
    ├── fhir_injection_usage_report.csv       # 注射劑詳細報表
    ├── injection_usage_detailed_report.csv   # 注射劑統計摘要
    ├── fhir_antibiotic_usage_report.csv      # 抗生素詳細報表
    └── antibiotic_usage_summary_report.csv   # 抗生素統計摘要
```

## 指標比較

### 1. 門診注射劑使用率

#### 核心定義
- **分子**: 針劑藥品案件數（醫令代碼第8碼為'2'）
- **分母**: 給藥案件數
- **參考值**: 0.94% (2022Q1)

#### 排除條件
1. 門診化療注射劑（特定藥品碼）
2. 化療相關ATC碼（L01, L02等）
3. 急診案件
4. 門診手術案件
5. 事前審查藥品
6. STAT藥品
7. 病人可攜回注射藥品

#### 關鍵代碼系統
- SNOMED CT: 385219001 (Injection procedure)
- 醫令代碼格式: 10碼，第8碼='2'

### 2. 門診抗生素使用率

#### 核心定義
- **分子**: 抗生素藥品案件數（ATC碼前1碼='J'，排除疫苗與免疫球蛋白）
- **分母**: 給藥案件數
- **參考值**: 19.84% (2022Q1)

#### 排除條件
1. 疫苗（ATC碼前3碼='J07'）
2. 免疫球蛋白（ATC碼前5碼='J06BA'）
3. 急診案件
4. 門診手術案件
5. 事前審查藥品
6. STAT藥品

#### 關鍵代碼系統
- SNOMED CT: 419889007 (Antibiotic therapy)
- ATC碼: J01-J05 (抗感染劑)

## 使用方式

### 步驟1: 執行注射劑查詢
```bash
python run_cql_query.py
```

### 步驟2: 執行抗生素查詢
```bash
python run_antibiotic_query.py
```

### 步驟3: 查看注射劑報表
```powershell
.\display_injection_report.ps1
```

### 步驟4: 查看抗生素報表
```powershell
.\display_antibiotic_report_simple.ps1
```

### 步驟5: 檢視輸出檔案
報表儲存在 `results/` 目錄下的 CSV 檔案

## FHIR資源對應

### 共用資源映射
| FHIR Resource | 健保資料表 | 欄位對應 |
|--------------|-----------|---------|
| MedicationRequest | drug_details | 藥品處方明細 |
| Encounter | outpatient_claims | 門診就醫記錄 |
| Patient | patient_master | 病人基本資料 |
| Organization | hospital_master | 醫療機構資料 |
| Medication | drug_master | 藥品主檔 |

### FHIR伺服器配置
- **伺服器1**: https://fhir.nhi.gov.tw/fhir (健保署)
- **伺服器2**: https://fhir.hospitals.tw/fhir (醫院總額)

## 資料處理流程

```
1. FHIR Server 1 (健保署)
   └─> MedicationRequest (藥品處方)
   
2. FHIR Server 2 (醫院總額)
   └─> Encounter (就醫記錄)
   
3. 資料整合
   ├─> 合併處方與就醫記錄
   ├─> 套用排除條件
   └─> 計算使用率
   
4. 產生報表
   ├─> 詳細報表 (CSV)
   ├─> 統計摘要 (CSV)
   └─> 視覺化顯示 (PowerShell)
```

## 計算公式對比

### 注射劑使用率
```
使用率 = (針劑藥品案件數 / 給藥案件數) × 100%

條件:
- 醫令代碼長度 = 10
- 醫令代碼第8碼 = '2'
- 排除化療注射劑
```

### 抗生素使用率
```
使用率 = (抗生素案件數 / 給藥案件數) × 100%

條件:
- ATC碼前1碼 = 'J'
- ATC碼前3碼 ≠ 'J07'
- ATC碼前5碼 ≠ 'J06BA'
```

## 報表輸出內容

### 兩個指標都包含

1. **各醫療機構使用率**
   - 季度
   - 醫療機構代碼/名稱
   - 醫院層級
   - 區域
   - 案件數（分子/分母）
   - 使用率

2. **各季度統計摘要**
   - 醫療機構數
   - 總案件數
   - 平均使用率
   - 四分位數
   - 最大/最小值

3. **依醫院層級統計**
   - 醫學中心
   - 區域醫院
   - 地區醫院

4. **依區域統計**
   - 台北區
   - 北區
   - 中區
   - 南區
   - 高屏區
   - 東區

5. **趨勢分析**
   - 各季度變化
   - 環比成長率
   - 異常值偵測

### 抗生素指標額外報表

6. **依ATC碼分類統計**
   - J01: 抗細菌劑
   - J02: 抗黴菌劑
   - J04: 抗結核菌劑
   - J05: 抗病毒劑

7. **依給藥途徑統計**
   - 口服 (PO)
   - 靜脈注射 (IV)
   - 肌肉注射 (IM)
   - 皮下注射 (SC)
   - 外用 (TOP)

## 資料品質控制

### 共同檢查項目
1. 日期範圍驗證
2. 必填欄位檢查
3. 數值範圍驗證
4. 排除條件套用
5. 重複資料檢查

### 注射劑特定檢查
- 醫令代碼格式驗證
- 劑型代碼檢查
- 化療藥品排除驗證

### 抗生素特定檢查
- ATC碼格式驗證
- 疫苗排除驗證
- 免疫球蛋白排除驗證
- 給藥途徑分布檢查

## 技術架構

### 後端技術
- **查詢語言**: CQL (Clinical Quality Language)
- **資料標準**: FHIR R4
- **程式語言**: Python 3.x
- **資料處理**: Pandas

### 前端顯示
- **腳本語言**: PowerShell 5.1+
- **輸出格式**: CSV (UTF-8 with BOM)
- **視覺化**: 彩色終端輸出

### 資料格式
- **輸入**: FHIR JSON
- **處理**: Python DataFrame
- **輸出**: CSV, 統計摘要

## 系統需求

### 軟體需求
- Python 3.7+
- PowerShell 5.1+
- pandas library
- requests library

### 安裝相依套件
```bash
pip install pandas requests
```

### 系統權限
- FHIR伺服器存取權限
- OAuth2認證token
- 健保資料存取授權

## 注意事項

### 🔒 資料安全
- 本系統處理敏感醫療資料
- 需遵守個資法及相關法規
- 實際使用需要適當授權
- OAuth2認證必須正確配置

### ⚠️ 使用限制
- 範例使用模擬資料
- 實際環境需連接真實FHIR伺服器
- 需要健保署授權的API金鑰
- 查詢結果僅供參考

### 📊 資料解讀
- 使用率計算基於健保申報資料
- 排除條件依健保署規定
- 參考基準為2022Q1數據
- 建議進行趨勢分析而非單點比較

## 未來擴充

### 計畫新增指標
3. 門診用藥品項數
4. 門診慢性病連續處方箋使用率
5. 門診抗生素使用天數
6. 門診用藥安全指標

### 功能增強
- 即時資料視覺化
- 自動化異常偵測
- 機器學習預測模型
- Web介面開發

## 參考文件

### 官方文件
- [醫療服務指標操作型定義說明](https://www.nhi.gov.tw/)
- [醫療給付項目案分析系統](https://www.nhi.gov.tw/)
- [全民健保藥品給付規定](https://www.nhi.gov.tw/)

### 標準規範
- [FHIR R4 Specification](https://www.hl7.org/fhir/)
- [CQL Language Specification](https://cql.hl7.org/)
- [WHO ATC Classification](https://www.whocc.no/atc_ddd_index/)
- [SNOMED CT Browser](https://browser.ihtsdotools.org/)

## 版本記錄

### v1.0 (2025-11-06)
- ✅ 實作門診注射劑使用率指標
- ✅ 實作門診抗生素使用率指標
- ✅ 建立CQL查詢邏輯
- ✅ 實作FHIR資料撈取
- ✅ 建立報表顯示功能
- ✅ 撰寫完整文件

## 授權資訊

本系統依據衛生福利部中央健康保險署之醫療品質指標規範實作。
實際使用需遵守相關法規及授權規定。

---

**製作單位**: 衛生福利部 中央健康保險署  
**更新日期**: 2025年11月6日  
**版本**: v1.0
