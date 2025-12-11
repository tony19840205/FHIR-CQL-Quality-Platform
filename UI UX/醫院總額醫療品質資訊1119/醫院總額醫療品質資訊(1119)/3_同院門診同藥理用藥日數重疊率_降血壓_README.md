# 3. 同醫院門診同藥理用藥日數重疊率-降血壓(口服)

## 指標資訊

- **指標代碼**: 1710
- **指標名稱**: 同醫院門診同藥理用藥日數重疊率-降血壓(口服)
- **資料來源**: 醫療給付檔案分析系統
- **製表單位**: 衛生福利部 中央健康保險署
- **製表日期**: 114/05/13

## 計算公式

```
用藥日數重疊率 = (重疊給藥日數 / 總給藥日數) × 100%
```

### 分子
同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數

### 分母
各案件之「給藥日數」總和

**給藥日數定義**: 
- 優先取醫令檔之給藥日份 (ORDER_DRUG_DAY)
- 若為空值則取清檔之給藥日份 (DRUG_DAYS)

## 降血壓藥品定義

### ATC 代碼條件

**方案一**: ATC前3碼為 **C07** (排除 **C07AA05**)
- C07: BETA BLOCKING AGENTS (β阻斷劑)
- 排除: C07AA05 (propranolol)

**方案二**: ATC前5碼為以下任一代碼 (排除 **C08CA06**)
- **C02CA**: Alpha-adrenoreceptor antagonists (α受體拮抗劑)
- **C02DB**: Hydrazinophthalazine derivatives (肼苯噠嗪衍生物)
- **C02DC**: Pyrimidine derivatives (嘧啶衍生物)
- **C02DD**: Nitroferricyanide derivatives (亞硝基鐵氰化物衍生物)
- **C03AA**: Thiazides, plain (噻嗪類利尿劑)
- **C03BA**: Sulfonamides, plain (磺胺類利尿劑)
- **C03CA**: Sulfonamides, plain (磺胺類)
- **C03DA**: Aldosterone antagonists (醛固酮拮抗劑)
- **C08CA**: Dihydropyridine derivatives (二氫吡啶類鈣離子阻斷劑) - 排除 C08CA06 (nimodipine)
- **C08DA**: Phenylalkylamine derivatives (苯烷胺衍生物)
- **C08DB**: Benzothiazepine derivatives (苯并硫氮䓬衍生物)
- **C09AA**: ACE inhibitors, plain (血管收縮素轉化酶抑制劑)
- **C09CA**: Angiotensin II antagonists, plain (血管收縮素II拮抗劑/ARB)

### 劑型條件
- **口服藥品**: 醫令代碼第8碼 **不為2** (排除注射劑)

## 資料範圍

### 納入條件
1. 醫院總額之門診案件
2. 同院ID不同處方之間
3. 給用藥日期與結束用藥日期有重覆

### 排除條件
1. 注射劑 (醫令代碼第8碼為2)
2. 代辦案件

## 重疊日數計算邏輯

### 給藥期間定義
- **開始日期**: 處方開始日期 (prescription_date)
- **結束日期**: 處方開始日期 + 給藥日數 - 1

### 重疊判斷
兩個處方期間重疊的條件:
```
start_date_1 <= end_date_2 AND start_date_2 <= end_date_1
```

### 重疊日數計算
```
重疊開始日 = MAX(start_date_1, start_date_2)
重疊結束日 = MIN(end_date_1, end_date_2)
重疊日數 = 重疊結束日 - 重疊開始日 + 1
```

## 統計輸出

### 1. 各醫療機構統計
- 季度
- 醫療機構代碼/名稱
- 醫院層級
- 區域
- 重疊給藥日數
- 總給藥日數
- 處方件數
- 病人數
- **用藥日數重疊率(%)**

### 2. 季度統計摘要
- 醫療機構數
- 總重疊日數
- 總給藥日數
- 總處方件數
- 總病人數
- 平均/最低/最高重疊率
- 四分位數統計

### 3. 依醫院層級統計
按醫學中心、區域醫院、地區醫院分類統計

### 4. 依區域統計
按台北、北區、中區、南區、高屏、東區分類統計

### 5. 依ATC碼分類統計
按降血壓藥品類別統計使用情形:
- β阻斷劑 (C07)
- ACE抑制劑 (C09AA)
- ARB (C09CA)
- 鈣離子阻斷劑 (C08CA/C08DA/C08DB)
- 利尿劑 (C03AA/C03BA/C03CA/C03DA)
- 其他降血壓藥品

### 6. 趨勢分析
各季度變化與成長率分析

## 查詢期間

- **起始**: 2024年第1季 (2024-01-01)
- **結束**: 2025年第4季 (2025-11-06，至今日)
- **統計單位**: 每季

## 資料表對應

| CQL 資料表 | FHIR Resource | 說明 |
|-----------|---------------|------|
| outpatient_claims | Encounter | 門診就醫記錄 |
| drug_details | MedicationRequest | 藥品處方明細 |
| patient_master | Patient | 病人基本資料 |
| hospital_master | Organization | 醫療機構資料 |

## 執行方式

### 1. 執行 CQL 查詢
```sql
-- 載入 CQL 檔案
source 3_同院門診同藥理用藥日數重疊率_降血壓.cql

-- 或使用資料庫工具執行
```

### 2. 查看結果
查詢會產生 6 個輸出表格:
1. 各醫療機構重疊率
2. 各季度統計摘要
3. 依醫院層級統計
4. 依區域統計
5. 依ATC碼分類統計
6. 趨勢分析

## FHIR 查詢範例

### 查詢降血壓藥品處方
```
GET {FHIR_SERVER}/MedicationRequest?
    date=ge2024-01-01&
    category=outpatient&
    status=completed&
    medication.code:text=antihypertensive&
    _include=MedicationRequest:medication&
    _include=MedicationRequest:patient
```

### 過濾降血壓藥品 ATC 代碼
```
GET {FHIR_SERVER}/Medication?
    code:text=antihypertensive&
    _filter=(code.coding.code sw 'C07') or
            (code.coding.code sw 'C09AA') or
            (code.coding.code sw 'C09CA') or
            ...
```

## 注意事項

1. **ATC 代碼排除**:
   - C07AA05 (propranolol) 需排除
   - C08CA06 (nimodipine) 需排除

2. **劑型限制**:
   - 僅計算口服藥品
   - 醫令代碼第8碼不為2 (排除注射劑)

3. **重疊計算**:
   - 僅計算同醫院、同病人、不同處方間的重疊
   - 避免重複計算 (claim_id_1 < claim_id_2)

4. **給藥日數**:
   - 優先使用 ORDER_DRUG_DAY
   - 若為空則使用 DRUG_DAYS
   - 必須 > 0 才納入計算

## 品質指標意義

此指標用於監測醫療機構開立降血壓藥品時的重複用藥情形:

- **重疊率越低**: 表示用藥管理越好,減少重複用藥風險
- **重疊率過高**: 可能表示:
  - 藥品管理系統待改善
  - 跨科就診協調不足
  - 病人用藥遵從性問題

## 相關指標

- 1_門診注射劑使用率.cql
- 2_門診抗生素使用率.cql

---

**更新日期**: 2025-11-06  
**版本**: v1.0
