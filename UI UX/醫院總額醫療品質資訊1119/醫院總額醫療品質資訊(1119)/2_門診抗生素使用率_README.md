# 2. 門診抗生素使用率

## 指標說明

### 基本資訊
- **指標代碼**: 3128
- **計算期間**: 2024年第1季 ~ 2025年第4季 (每季為單位)
- **資料來源**: 醫療給付項目案分析系統
- **製表單位**: 衛生福利部 中央健康保險署
- **製表日期**: 114/05/13 (2025/11/06更新)

### 歷史參考基準 (2022年第1季)
- **抗生素給藥案件數**: 1,156,837
- **給藥案件數**: 5,831,409
- **門診抗生素使用率**: 19.84%

## 計算公式

```
門診抗生素使用率(%) = (抗生素給藥案件數 / 給藥案件數) × 100%
```

### 分子定義
給藥案件之抗生素藥品案件數，須符合以下條件:
- 藥品成分ATC碼前1碼為 `J` (抗感染劑)
- **排除**前3碼為 `J07` (疫苗)
- **排除**前5碼為 `J06BA` (免疫球蛋白)

### 分母定義
門診給藥案件數，符合以下任一條件:
- 藥費不為0，或
- 給藥天數不為0，或
- 處方調劑方式為 1、0、6 其中一種

### 排除條件
以下案件不列入計算:
1. **急診案件**: 案件分類代碼為 `02`
2. **門診手術案件**: 案件分類類碼為 `03`
3. **事前審查藥品**: 藥品主檔之事前審查註記為 `Y`
4. **立刻使用藥品**: 藥品使用頻率為 `STAT`
5. **代辦案件**

## ATC碼分類

### 納入範圍 (J 開頭的抗感染劑)
| ATC碼 | 分類名稱 | 說明 |
|-------|---------|------|
| J01 | Antibacterials for systemic use | 全身性抗細菌劑 |
| J02 | Antimycotics for systemic use | 全身性抗黴菌劑 |
| J04 | Antimycobacterials | 抗結核菌劑 |
| J05 | Antivirals for systemic use | 全身性抗病毒劑 |

### 排除範圍
| ATC碼 | 分類名稱 | 原因 |
|-------|---------|------|
| J07 | Vaccines | 疫苗 - 非治療用抗生素 |
| J06BA | Immunoglobulins | 免疫球蛋白 - 非抗生素 |

## 常見抗生素範例

### 口服抗生素 (J01)
| ATC碼 | 藥品名稱 | 常用劑量 |
|-------|---------|---------|
| J01CA04 | Amoxicillin | 250mg, 500mg |
| J01CR02 | Amoxicillin/Clavulanic acid | 375mg, 625mg |
| J01DC02 | Cefuroxime | 250mg, 500mg |
| J01FA10 | Azithromycin | 250mg, 500mg |
| J01MA02 | Ciprofloxacin | 250mg, 500mg |

### 注射用抗生素 (J01)
| ATC碼 | 藥品名稱 | 常用劑量 |
|-------|---------|---------|
| J01DD04 | Ceftriaxone | 1g, 2g |
| J01DH02 | Meropenem | 500mg, 1g |
| J01CR05 | Piperacillin/Tazobactam | 4.5g |

## 給藥途徑分類

| 代碼 | SNOMED CT | 名稱 | 說明 |
|------|-----------|------|------|
| PO | 26643006 | Oral route | 口服 |
| IV | 47625008 | Intravenous route | 靜脈注射 |
| IM | 78421000 | Intramuscular route | 肌肉注射 |
| SC | 34206005 | Subcutaneous route | 皮下注射 |
| TOP | 6064005 | Topical route | 外用 |

## FHIR資源對應

### 主要資源
| FHIR Resource | 健保資料表 | 用途 |
|--------------|-----------|------|
| MedicationRequest | drug_details | 藥品處方明細 |
| Encounter | outpatient_claims | 門診就醫記錄 |
| Patient | patient_master | 病人基本資料 |
| Organization | hospital_master | 醫療機構資料 |
| Medication | drug_master | 藥品主檔 |

### FHIR查詢範例

#### 1. 查詢抗生素處方
```http
GET {FHIR_SERVER}/MedicationRequest?
    date=ge2024-01-01&
    category=outpatient&
    status=completed&
    medication.code:text=antibiotic&
    _include=MedicationRequest:medication
```

#### 2. 依ATC碼篩選
```http
GET {FHIR_SERVER}/Medication?
    code:text=antibiotic&
    _filter=code.coding.system eq 'http://www.whocc.no/atc' 
        and code.coding.code sw 'J' 
        and code.coding.code ne 'J07' 
        and code.coding.code ne 'J06BA'
```

#### 3. 查詢門診記錄
```http
GET {FHIR_SERVER}/Encounter?
    date=ge2024-01-01&
    class=AMB&
    status=finished&
    _include=Encounter:patient
```

## 檔案說明

### 1. CQL查詢檔案
- **檔名**: `2_門診抗生素使用率.cql`
- **用途**: 定義完整的CQL查詢邏輯
- **輸出**: 7個查詢結果集
  1. 各醫療機構門診抗生素使用率
  2. 各季度統計摘要
  3. 依醫院層級統計
  4. 依區域統計
  5. 依ATC碼分類統計
  6. 依給藥途徑統計
  7. 趨勢分析

### 2. Python執行腳本
- **檔名**: `run_antibiotic_query.py`
- **用途**: 執行FHIR資料查詢與分析
- **功能**:
  - 連接FHIR伺服器
  - 撈取MedicationRequest和Encounter資料
  - 計算抗生素使用率
  - 產生統計報表

### 3. PowerShell顯示腳本
- **檔名**: `display_antibiotic_report.ps1`
- **用途**: 顯示查詢結果報表
- **功能**:
  - 顯示抗生素使用詳細報表
  - 顯示統計摘要
  - 資料品質檢查
  - ATC碼分布分析
  - 給藥途徑分析

## 使用方式

### 步驟1: 執行CQL查詢
```bash
# 使用Python執行
python run_antibiotic_query.py
```

### 步驟2: 查看報表
```powershell
# 使用PowerShell顯示
.\display_antibiotic_report.ps1
```

### 步驟3: 檢視輸出檔案
查詢結果會儲存在 `results/` 目錄:
- `fhir_antibiotic_usage_report.csv` - 詳細報表
- `antibiotic_usage_summary_report.csv` - 統計摘要

## 輸出報表格式

### 主報表欄位
| 欄位名稱 | 說明 | 範例 |
|---------|------|------|
| 季度 | 統計季度 | 2024Q1 |
| 醫療機構代碼 | 醫院代碼 | 1501050017 |
| 醫療機構名稱 | 醫院名稱 | 臺大醫院 |
| 醫院層級 | 醫學中心/區域/地區 | 醫學中心 |
| 區域 | 分區 | 台北區 |
| 抗生素給藥案件數 | 分子 | 1,156,837 |
| 給藥案件數 | 分母 | 5,831,409 |
| 門診抗生素使用率(%) | 計算結果 | 19.84 |

### 統計摘要欄位
| 欄位名稱 | 說明 |
|---------|------|
| 平均使用率(%) | 所有醫院平均值 |
| 最低使用率(%) | 最小值 |
| 第1四分位數(%) | Q1 (25%) |
| 中位數(%) | Q2 (50%) |
| 第3四分位數(%) | Q3 (75%) |
| 最高使用率(%) | 最大值 |

## 資料品質控制

### 檢查項目
1. **ATC碼格式驗證**
   - 確認前1碼為 'J'
   - 確認非 'J07' (疫苗)
   - 確認非 'J06BA' (免疫球蛋白)

2. **排除條件檢查**
   - 急診案件已排除
   - 門診手術案件已排除
   - STAT藥品已排除
   - 事前審查藥品已排除

3. **資料完整性**
   - 檢查必填欄位
   - 驗證日期格式
   - 確認數值範圍

## 注意事項

### 🔒 資料安全
- 實際使用需要OAuth2認證
- 需要健保署授權的存取權限
- 遵守個資法規定

### ⚠️ 特別說明
1. **本範例使用模擬資料**，實際環境需連接真實FHIR伺服器
2. ATC碼需依照WHO ATC分類標準
3. 排除條件需嚴格遵守健保署定義
4. 詳細操作型定義請參考健保署「醫療服務指標操作型定義說明」

### 📊 參考基準比較
- 與2022Q1基準(19.84%)比較
- 觀察季度趨勢變化
- 分析異常值原因
- 區域差異分析

## 相關文件
- [醫療服務指標操作型定義說明](https://www.nhi.gov.tw/)
- [WHO ATC分類系統](https://www.whocc.no/atc_ddd_index/)
- [FHIR MedicationRequest Resource](https://www.hl7.org/fhir/medicationrequest.html)
- [SNOMED CT Browser](https://browser.ihtsdotools.org/)

## 版本記錄
- v1.0 (2025-11-06): 初版建立
  - 建立CQL查詢邏輯
  - 實作FHIR資料撈取
  - 建立報表顯示功能
