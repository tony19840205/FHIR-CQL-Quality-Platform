library Indicator_05_Prescription_10_Plus_Drugs_Rate_3128 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 3128
// 條件依據：門診每張處方箋開藥品項數大於等於十項之案件比率
// 製作日期：2025-11-20

// 【公式說明】
// 分子: 分母案件中藥品品項數≧10項之案件數
// 分母: 給藥案件數（藥費不為0，或給藥天數不為0，或處方調劑方式為1、0、6）
// 藥品品項數: 醫令檔別1或4且醫令代碼為10碼且醫令數量>0，同處方下同醫令代碼計數
// 排除: 代辦案件、插報原因註記為2之案件

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'

// Helper function: 檢查醫令代碼是否為10碼
define function Is10DigitDrugCode(drugCode String):
  Length(drugCode) = 10

// 1. 門診給藥案件（分母）
define "Outpatient Medication Cases":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'AMB'
    and exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and MR.dispenseRequest is not null
    )
    // 排除代辦案件
    and not exists (
      E.type T where exists (T.coding C where C.code.value = 'AGENCY')
    )
    // 排除插報原因註記為2之案件
    and not exists (
      E.type T where exists (T.coding C where C.code.value = 'REPORT_REASON_2')
    )

// 2. 計算每個案件的藥品品項數
define function GetDrugItemCount(encounter FHIR.Encounter):
  Count(
    distinct (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + encounter.id.value
        and MR.status.value = 'completed'
        and exists (
          MR.medicationCodeableConcept.coding MC
            where Is10DigitDrugCode(MC.code.value)
        )
        and MR.dispenseRequest.quantity.value > 0
      return MR.medicationCodeableConcept.coding[0].code.value
    )
  )

// 3. 藥品品項數≧10項的案件（分子）
define "Cases With 10 Or More Drugs":
  "Outpatient Medication Cases" E
    where GetDrugItemCount(E) >= 10

// 4. 分母：給藥案件數
define "Denominator":
  Count(
    distinct "Outpatient Medication Cases" E
      return E.id.value
  )

// 5. 分子：藥品品項數≧10項之案件數
define "Numerator":
  Count(
    distinct "Cases With 10 Or More Drugs" E
      return E.id.value
  )

// 6. 指標計算結果：藥品品項數≧10項之案件占率
define "Prescription With 10 Or More Drugs Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null

    SELECT '2024Q1' as quarter, '2024-01-01' as start_date, '2024-03-31' as end_date
    UNION ALL SELECT '2024Q2', '2024-04-01', '2024-06-30'
    UNION ALL SELECT '2024Q3', '2024-07-01', '2024-09-30'
    UNION ALL SELECT '2024Q4', '2024-10-01', '2024-12-31'
    UNION ALL SELECT '2025Q1', '2025-01-01', '2025-03-31'
    UNION ALL SELECT '2025Q2', '2025-04-01', '2025-06-30'
    UNION ALL SELECT '2025Q3', '2025-07-01', '2025-09-30'
    UNION ALL SELECT '2025Q4', '2025-10-01', '2025-11-08'  -- 計算到今天 2025-11-08
),

-- 健保代碼與標準代碼系統對照表
-- 依據健保指標代碼 3128 (藥品品項數≧10項之案件占率) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '3128', '3128', 'NHI_INDICATOR', 'Cases with ≧10 Drug Items Rate - 藥品品項數≧10項之案件占率'),
        
        -- 醫令檔別 (Order Type)
        ('ORDER_TYPE', '1', 'medication-order', 'NHI_ORDER_TYPE', 'Medication Order - 藥品醫令(檔別1)'),
        ('ORDER_TYPE', '4', 'medication-supply', 'NHI_ORDER_TYPE', 'Medication Supply - 藥品供應(檔別4)'),
        
        -- 處方調劑方式 (Dispense Method) - SNOMED CT對照
        ('DISPENSE_METHOD', '0', '182836005', 'http://snomed.info/sct', 'Review of medication - 處方調劑方式0'),
        ('DISPENSE_METHOD', '1', '182836005', 'http://snomed.info/sct', 'Review of medication - 處方調劑方式1'),
        ('DISPENSE_METHOD', '6', '182836005', 'http://snomed.info/sct', 'Review of medication - 處方調劑方式6'),
        
        -- 插報原因註記 (Report Reason)
        ('REPORT_REASON', '2', 'supplementary-report', 'NHI_REPORT_REASON', 'Supplementary Report - 插報原因註記2(應排除)'),
        
        -- 就醫類型代碼 (HL7 ActCode)
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)'),
        ('AGENCY', 'N', 'N', 'NHI', 'Non-Agency Case - 非代辦案件')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選給藥案件
-- 條件: 
--   (1) 藥費不為0，或給藥天數不為0，或處方調劑方式為1、0、6
--   (2) 排除代辦案件
--   (3) 排除插報原因註記為2之案件
medication_cases AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        o.patient_id,
        o.claim_id,
        o.visit_date,
        o.drug_cost,
        o.drug_days,
        o.dispense_method,
        o.report_reason
    FROM 
        quarters q
    CROSS JOIN 
        outpatient_claims o
    WHERE 
        -- 1. 時間範圍: 在該季內
        o.visit_date BETWEEN q.start_date AND q.end_date
        
        -- 2. 門診案件 (就醫類別 = O 或 AMB)
        AND o.encounter_type IN ('O', 'AMB')
        
        -- 3. 醫院總額 (排除代辦案件)
        AND (o.agency_flag IS NULL OR o.agency_flag != 'Y')
        AND o.hospital_id IS NOT NULL
        
        -- 4. 排除插報原因註記為2之案件
        AND (o.report_reason IS NULL OR o.report_reason != '2')
        
        -- 5. 給藥案件條件
        AND (
            -- 藥費不為0
            (o.drug_cost IS NOT NULL AND o.drug_cost != 0)
            -- 或 給藥天數不為0
            OR (o.drug_days IS NOT NULL AND o.drug_days != 0)
            -- 或 處方調劑方式為1、0、6
            OR (o.dispense_method IN ('0', '1', '6'))
        )
),

-- 計算每個案件的藥品品項數
-- 條件:
--   (1) 醫令檔別 = 1 或 4
--   (2) 醫令代碼為10碼
--   (3) 醫令數量 > 0
--   (4) 取同處方下同醫令代碼戶數 (DISTINCT)
drug_item_count AS (
    SELECT 
        mc.quarter,
        mc.hospital_id,
        mc.patient_id,
        mc.claim_id,
        mc.visit_date,
        -- 計算藥品品項數 (DISTINCT drug_code)
        COUNT(DISTINCT d.drug_code) as drug_item_count
    FROM 
        medication_cases mc
    LEFT JOIN 
        drug_details d ON mc.claim_id = d.claim_id
    WHERE 
        -- 1. 醫令檔別為1或4
        d.order_type IN ('1', '4')
        
        -- 2. 醫令代碼為10碼
        AND LENGTH(d.order_code) = 10
        
        -- 3. 醫令數量 > 0
        AND (d.order_quantity IS NOT NULL AND d.order_quantity > 0)
    GROUP BY 
        mc.quarter,
        mc.hospital_id,
        mc.patient_id,
        mc.claim_id,
        mc.visit_date
),

-- 判斷藥品品項數是否≧10項
cases_with_10plus_items AS (
    SELECT 
        mc.quarter,
        mc.hospital_id,
        mc.patient_id,
        mc.claim_id,
        mc.visit_date,
        COALESCE(dic.drug_item_count, 0) as drug_item_count,
        -- 判斷是否≧10項
        CASE 
            WHEN COALESCE(dic.drug_item_count, 0) >= 10 THEN 1
            ELSE 0
        END as has_10plus_items
    FROM 
        medication_cases mc
    LEFT JOIN 
        drug_item_count dic 
        ON mc.claim_id = dic.claim_id
),

-- 計算每季的統計數據
quarterly_summary AS (
    SELECT 
        q.quarter,
        -- 分母: 給藥案件數
        COUNT(DISTINCT c.claim_id) as total_medication_cases,
        -- 分子: 藥品品項數≧10項之案件數
        SUM(c.has_10plus_items) as cases_with_10plus_items,
        -- 占率 (%)
        CASE 
            WHEN COUNT(DISTINCT c.claim_id) > 0 THEN 
                ROUND(SUM(c.has_10plus_items) * 100.0 / COUNT(DISTINCT c.claim_id), 2)
            ELSE 0
        END as rate_10plus_items,
        -- 統計數量
        COUNT(DISTINCT c.patient_id) as total_patients,
        COUNT(DISTINCT c.hospital_id) as total_hospitals,
        -- 平均藥品品項數
        AVG(c.drug_item_count) as avg_drug_items
    FROM 
        quarters q
    LEFT JOIN 
        cases_with_10plus_items c ON q.quarter = c.quarter
    GROUP BY 
        q.quarter
)

-- 最終結果輸出
SELECT 
    quarter as '季度',
    total_patients as '總病患數',
    total_hospitals as '總醫院數',
    cases_with_10plus_items as '藥品品項數≧10項之案件數',
    total_medication_cases as '給藥案件數',
    rate_10plus_items as '藥品品項數≧10項之案件占率(%)',
    ROUND(avg_drug_items, 2) as '平均藥品品項數'
FROM 
    quarterly_summary
ORDER BY 
    quarter;

-- ============================================
-- 參考數據驗證 (待驗證)
-- ============================================
-- 待補充實際數據後進行驗證
--
-- 驗證狀態: ⏳ 待驗證 (2025-11-08)
-- 
-- 預期占率範圍: 依醫療行為而定，需實際數據驗證
-- ============================================

-- ============================================
-- 給藥案件判斷條件說明
-- ============================================
-- 給藥案件的定義 (三個條件滿足其一):
-- 
-- 1. 藥費不為0 (drug_cost != 0)
-- 2. 給藥天數不為0 (drug_days != 0)
-- 3. 處方調劑方式為1、0、6其中一種
--
-- 處方調劑方式代碼:
-- 0: 一般處方調劑
-- 1: 慢性病連續處方調劑
-- 6: 其他特殊調劑方式
--
-- SNOMED CT對照: 182836005 (Review of medication)
-- ============================================

-- ============================================
-- 藥品品項數計算說明
-- ============================================
-- 藥品品項數的計算條件:
-- 
-- 1. 醫令檔別 = 1 或 4
--    - 檔別1: 藥品醫令 (Medication Order)
--    - 檔別4: 藥品供應 (Medication Supply)
--
-- 2. 醫令代碼為10碼
--    - 確保為有效的藥品代碼
--    - 格式: 10位數字代碼
--
-- 3. 醫令數量 > 0
--    - 確保實際有給藥
--    - 排除數量為0的無效醫令
--
-- 4. 取同處方下同醫令代碼戶數
--    - 使用 COUNT(DISTINCT drug_code)
--    - 同一藥品代碼只計算一次
--    - 避免重複計算
--
-- 範例:
-- 案件A: 5種不同藥品 → 藥品品項數 = 5
-- 案件B: 12種不同藥品 → 藥品品項數 = 12 (≧10項)
-- ============================================

-- ============================================
-- 排除條件說明
-- ============================================
-- 1. 排除代辦案件
--    - agency_flag = 'Y' 的案件應排除
--    - 代辦案件不計入統計
--
-- 2. 排除插報原因註記為2之案件
--    - report_reason = '2' 的案件應排除
--    - 插報案件可能有特殊情況，不納入常規統計
--
-- 原因:
-- - 確保統計數據的準確性
-- - 避免特殊案件影響指標
-- - 符合健保署統計規範
-- ============================================

-- ============================================
-- 代碼系統對照
-- ============================================
-- NHI_INDICATOR: 健保指標代碼 (3128)
-- SNOMEDCT: http://snomed.info/sct (藥品代碼、調劑方式)
-- RxNorm: http://www.nlm.nih.gov/research/umls/rxnorm (藥品標準代碼)
-- ATC: http://www.whocc.no/atc (藥品分類)
-- ActCode: http://terminology.hl7.org/CodeSystem/v3-ActCode (就醫類型)
-- NHI: 健保專用代碼 (代辦案件標記等)
-- NHI_ORDER_TYPE: 健保醫令檔別代碼 (1, 4)
-- NHI_DISPENSE_METHOD: 健保處方調劑方式代碼 (0, 1, 6)
-- NHI_REPORT_REASON: 健保插報原因註記代碼 (2)
-- ============================================

-- ============================================
-- 臨床意義
-- ============================================
-- 本指標用於監測多重用藥情況:
-- 
-- 1. 多重用藥風險:
--    - 藥品品項數≧10項可能增加藥物交互作用風險
--    - 影響病患用藥依從性
--    - 增加不良反應發生機率
--
-- 2. 用藥安全:
--    - 監測過度用藥情況
--    - 促進合理用藥
--    - 提升處方品質
--
-- 3. 醫療品質:
--    - 評估醫師處方習慣
--    - 改善用藥管理
--    - 降低醫療風險
--
-- 建議:
-- - 占率過高需檢討處方合理性
-- - 加強多重用藥管理
-- - 定期檢視用藥必要性
-- ============================================

-- ============================================
-- FHIR Resource 對照
-- ============================================
-- MedicationRequest:
--   - 藥品處方資訊
--   - 醫令代碼 (medication.code)
--   - 醫令數量 (dosageInstruction.doseAndRate)
--   - 給藥天數 (dispenseRequest.expectedSupplyDuration)
--
-- Claim:
--   - 案件資料
--   - 藥費 (total)
--   - 插報原因 (supportingInfo)
--   - 代辦標記 (extension)
--
-- Encounter:
--   - 就醫記錄
--   - 就醫類型 (class)
--   - 就醫日期 (period)
--
-- Medication:
--   - 藥品主檔
--   - 藥品代碼 (code)
--   - ATC分類 (code.coding)
-- ============================================
