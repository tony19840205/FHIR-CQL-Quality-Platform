library Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 同醫院門診同藥理用藥日數重疊率-抗思覺失調症(口服)
// 指標代碼: 1726
// 製作日期：2025-11-20
-- 製表日期: 114/05/13 (2025/11/07更新)
-- 製表單位: 衛生福利部 中央健康保險署
-- 
-- 【資料時間範圍】
-- 查詢期間: 2024-01-01 ~ 2025-11-07 (今天)
-- 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
-- ============================================

-- 【資料範圍】
-- (1)醫院總額之門診處方抗思覺失調藥物案件
-- (2)排除代辦案件

-- 【公式說明】(依健保指標代碼 1726)
-- 同醫院門診同藥理用藥日數重疊率-抗思覺失調症 = 
--     分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
--     分母: 各案件之「給藥日數」總和
-- 
-- (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
-- (2)抗思覺失調藥物: ATC前5碼為N05AA、N05AB(排除N05AB04)、N05AD、N05AE、N05AF、N05AH、N05AL、N05AN(排除N05AN01)、N05AX、N05AC、N05AG
-- 
-- 排除條件:
--   1.排除特定ATC代碼: N05AB04、N05AN01
--   2.排除代辦案件

-- ============================================
-- 備註:
-- 1.資料來源：醫療給付檔案分析系統，指標代碼：1726
-- 
-- 2.資料範圍：醫院總額之門診處方抗思覺失調藥物案件，排除代辦案件。
-- 
-- 3.公式說明：
--   分子：同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)。
--   分母：各案件之「給藥日數」總和。
--   (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
--   (2)抗思覺失調藥物: ATC前5碼為N05AA、N05AB(排除N05AB04)、N05AD、N05AE、N05AF、N05AH、N05AL、N05AN(排除N05AN01)、N05AX、N05AC、N05AG。
-- 
-- 4.製表日期：114/05/13
-- 
-- 5.製表單位：衛生福利部 中央健康保險署
-- ============================================

-- CQL Code Systems Definition (依健保標準代碼對照國際標準)
codesystem "NHI_INDICATOR": 'NHI_INDICATOR'  -- 健保指標代碼：同醫院門診同藥理用藥日數重疊率-抗思覺失調症
codesystem "SNOMEDCT": 'http://snomed.info/sct'  -- 劑型代碼對照
codesystem "ATC": 'http://www.whocc.no/atc'  -- ATC藥品分類代碼
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'  -- 就醫類型代碼
codesystem "NHI": 'NHI'  -- 健保專用代碼系統
-- 
-- 註: 健保代碼與國際標準完全相容，支援 SMART on FHIR

-- FHIR Resource Mapping
-- MedicationRequest → drug_details
-- Encounter → outpatient_claims  
-- Patient → patient_master
-- Organization → hospital_master

-- 建立季度時間表
WITH quarters AS (
    SELECT '2024Q1' as quarter, '2024-01-01' as start_date, '2024-03-31' as end_date
    UNION ALL SELECT '2024Q2', '2024-04-01', '2024-06-30'
    UNION ALL SELECT '2024Q3', '2024-07-01', '2024-09-30'
    UNION ALL SELECT '2024Q4', '2024-10-01', '2024-12-31'
    UNION ALL SELECT '2025Q1', '2025-01-01', '2025-03-31'
    UNION ALL SELECT '2025Q2', '2025-04-01', '2025-06-30'
    UNION ALL SELECT '2025Q3', '2025-07-01', '2025-09-30'
    UNION ALL SELECT '2025Q4', '2025-10-01', CURRENT_DATE()  -- 計算到當前日期
),

-- 健保代碼與標準代碼系統對照表
-- 依據健保指標代碼 1726 (同醫院門診同藥理用藥日數重疊率-抗思覺失調症) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1726', '1726', 'NHI', 'Antipsychotic Drug Overlap Rate - 同醫院門診同藥理用藥日數重疊率-抗思覺失調症'),
        
        -- ATC碼對照 (抗思覺失調藥物)
        -- N05A: Antipsychotics (抗精神病藥物)
        ('ATC', 'N05AA', 'N05AA', 'http://www.whocc.no/atc', 'Phenothiazines with aliphatic side-chain - 酚噻嗪類(脂肪族側鏈)'),
        ('ATC', 'N05AB', 'N05AB', 'http://www.whocc.no/atc', 'Phenothiazines with piperazine structure - 酚噻嗪類(哌嗪結構)'),
        ('ATC', 'N05AC', 'N05AC', 'http://www.whocc.no/atc', 'Phenothiazines with piperidine structure - 酚噻嗪類(哌啶結構)'),
        ('ATC', 'N05AD', 'N05AD', 'http://www.whocc.no/atc', 'Butyrophenone derivatives - 丁苯酮類'),
        ('ATC', 'N05AE', 'N05AE', 'http://www.whocc.no/atc', 'Indole derivatives - 吲哚類'),
        ('ATC', 'N05AF', 'N05AF', 'http://www.whocc.no/atc', 'Thioxanthene derivatives - 噻噸類'),
        ('ATC', 'N05AG', 'N05AG', 'http://www.whocc.no/atc', 'Diphenylbutylpiperidine derivatives - 二苯丁基哌啶類'),
        ('ATC', 'N05AH', 'N05AH', 'http://www.whocc.no/atc', 'Diazepines, oxazepines, thiazepines and oxepines - 二氮䓬類'),
        ('ATC', 'N05AL', 'N05AL', 'http://www.whocc.no/atc', 'Benzamides - 苯甲醯胺類'),
        ('ATC', 'N05AN', 'N05AN', 'http://www.whocc.no/atc', 'Lithium - 鋰鹽'),
        ('ATC', 'N05AX', 'N05AX', 'http://www.whocc.no/atc', 'Other antipsychotics - 其他抗精神病藥'),
        
        -- 排除的特定ATC代碼
        ('ATC_EXCLUDE', 'N05AB04', 'N05AB04', 'http://www.whocc.no/atc', 'Prochlorperazine - 應排除'),
        ('ATC_EXCLUDE', 'N05AN01', 'N05AN01', 'http://www.whocc.no/atc', 'Lithium - 應排除'),
        
        -- 劑型代碼 (SNOMED CT)
        ('DOSAGE_FORM', '1', '385219001', 'http://snomed.info/sct', 'Injection - 注射劑'),
        ('DOSAGE_FORM', '2', '385268001', 'http://snomed.info/sct', 'Oral - 口服'),
        ('DOSAGE_FORM', '3', '385194003', 'http://snomed.info/sct', 'Topical - 外用'),
        
        -- 就醫類型代碼
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選抗思覺失調藥物
-- 條件: ATC前5碼為 N05AA、N05AB(排除N05AB04)、N05AD、N05AE、N05AF、N05AH、N05AL、N05AN(排除N05AN01)、N05AX、N05AC、N05AG
antipsychotic_drugs AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        o.patient_id,
        o.claim_id,
        o.visit_date,
        d.drug_code,
        d.drug_name,
        d.atc_code,
        d.order_code,
        -- 給藥日數: 優先取 ORDER_DRUG_DAY，若為空則取 DRUG_DAYS
        COALESCE(d.order_drug_day, d.drug_days, 0) as drug_days,
        -- 給藥開始日期: 處方開始日期
        d.prescription_date as start_date,
        -- 給藥結束日期: 處方開始日期 + 給藥日數 - 1
        DATE_ADD(d.prescription_date, INTERVAL (COALESCE(d.order_drug_day, d.drug_days, 0) - 1) DAY) as end_date,
        SUBSTRING(d.atc_code, 1, 5) as atc_class_5,
        ncm.standard_code as atc_standard_code,
        ncm.description as atc_description
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診
    INNER JOIN drug_details d 
        ON o.claim_id = d.claim_id
    LEFT JOIN nhi_code_mapping ncm 
        ON SUBSTRING(d.atc_code, 1, 5) = ncm.nhi_code 
        AND ncm.code_type = 'ATC'
    WHERE 
        -- 條件1: 抗思覺失調藥物 ATC 代碼 (前5碼)
        (SUBSTRING(d.atc_code, 1, 5) IN ('N05AA', 'N05AB', 'N05AC', 'N05AD', 'N05AE', 'N05AF', 'N05AG', 'N05AH', 'N05AL', 'N05AN', 'N05AX'))
        
        -- 條件2: 排除特定ATC代碼
        AND d.atc_code NOT IN ('N05AB04', 'N05AN01')
        
        -- 條件3: 給藥日數 > 0
        AND COALESCE(d.order_drug_day, d.drug_days, 0) > 0
        
        -- 排除代辦案件
        AND (o.agency_case_flag IS NULL OR o.agency_case_flag <> 'Y')
),

-- 計算同院同病人不同處方之間的用藥日期重疊
-- 使用自我連接找出同院、同病人、不同處方且日期有重疊的案件
drug_overlaps AS (
    SELECT 
        a1.quarter,
        a1.hospital_id,
        a1.patient_id,
        a1.claim_id as claim_id_1,
        a2.claim_id as claim_id_2,
        a1.drug_code as drug_code_1,
        a2.drug_code as drug_code_2,
        a1.start_date as start_date_1,
        a1.end_date as end_date_1,
        a2.start_date as start_date_2,
        a2.end_date as end_date_2,
        a1.drug_days as drug_days_1,
        a2.drug_days as drug_days_2,
        -- 計算重疊日數
        -- 重疊開始日 = MAX(start_date_1, start_date_2)
        -- 重疊結束日 = MIN(end_date_1, end_date_2)
        -- 重疊日數 = 重疊結束日 - 重疊開始日 + 1 (如果 > 0)
        CASE 
            WHEN GREATEST(a1.start_date, a2.start_date) <= LEAST(a1.end_date, a2.end_date)
            THEN DATEDIFF(LEAST(a1.end_date, a2.end_date), GREATEST(a1.start_date, a2.start_date)) + 1
            ELSE 0
        END as overlap_days
    FROM antipsychotic_drugs a1
    INNER JOIN antipsychotic_drugs a2
        ON a1.quarter = a2.quarter
        AND a1.hospital_id = a2.hospital_id  -- 同醫院
        AND a1.patient_id = a2.patient_id    -- 同病人
        AND a1.claim_id < a2.claim_id        -- 不同處方 (避免重複計算)
    WHERE 
        -- 有日期重疊: start_date_1 <= end_date_2 AND start_date_2 <= end_date_1
        a1.start_date <= a2.end_date
        AND a2.start_date <= a1.end_date
),

-- 分子: 計算各醫院每季的重疊給藥日數總和
numerator AS (
    SELECT 
        quarter,
        hospital_id,
        SUM(overlap_days) as total_overlap_days
    FROM drug_overlaps
    GROUP BY quarter, hospital_id
),

-- 分母: 計算各醫院每季的總給藥日數
denominator AS (
    SELECT 
        quarter,
        hospital_id,
        SUM(drug_days) as total_drug_days,
        COUNT(DISTINCT claim_id) as total_prescriptions,
        COUNT(DISTINCT patient_id) as total_patients
    FROM antipsychotic_drugs
    GROUP BY quarter, hospital_id
),

-- 計算重疊率
calculation AS (
    SELECT 
        d.quarter,
        d.hospital_id,
        h.hospital_name,
        h.hospital_level,
        h.region,
        COALESCE(n.total_overlap_days, 0) as total_overlap_days,
        d.total_drug_days,
        d.total_prescriptions,
        d.total_patients,
        CASE 
            WHEN d.total_drug_days > 0 
            THEN ROUND((COALESCE(n.total_overlap_days, 0) * 100.0 / d.total_drug_days), 2)
            ELSE 0 
        END as overlap_rate
    FROM denominator d
    LEFT JOIN numerator n 
        ON d.quarter = n.quarter 
        AND d.hospital_id = n.hospital_id
    LEFT JOIN hospital_master h 
        ON d.hospital_id = h.hospital_id
),

-- 統計摘要 (依季度)
summary_by_quarter AS (
    SELECT 
        quarter,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(total_overlap_days) as sum_overlap_days,
        SUM(total_drug_days) as sum_drug_days,
        SUM(total_prescriptions) as sum_prescriptions,
        SUM(total_patients) as sum_patients,
        ROUND(AVG(overlap_rate), 2) as avg_overlap_rate,
        MIN(overlap_rate) as min_overlap_rate,
        MAX(overlap_rate) as max_overlap_rate,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY overlap_rate) as q25_overlap_rate,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY overlap_rate) as median_overlap_rate,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY overlap_rate) as q75_overlap_rate
    FROM calculation
    GROUP BY quarter
),

-- 統計摘要 (依醫院層級)
summary_by_level AS (
    SELECT 
        quarter,
        hospital_level,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(total_overlap_days) as sum_overlap_days,
        SUM(total_drug_days) as sum_drug_days,
        ROUND(AVG(overlap_rate), 2) as avg_overlap_rate,
        MIN(overlap_rate) as min_overlap_rate,
        MAX(overlap_rate) as max_overlap_rate
    FROM calculation
    GROUP BY quarter, hospital_level
),

-- 統計摘要 (依區域)
summary_by_region AS (
    SELECT 
        quarter,
        region,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(total_overlap_days) as sum_overlap_days,
        SUM(total_drug_days) as sum_drug_days,
        ROUND(AVG(overlap_rate), 2) as avg_overlap_rate,
        MIN(overlap_rate) as min_overlap_rate,
        MAX(overlap_rate) as max_overlap_rate
    FROM calculation
    GROUP BY quarter, region
),

-- 依ATC碼分類統計 (抗思覺失調藥物類別)
antipsychotic_by_atc AS (
    SELECT 
        quarter,
        atc_class_5,
        CASE 
            WHEN atc_class_5 = 'N05AA' THEN 'N05AA - Phenothiazines with aliphatic side-chain (酚噻嗪類-脂肪族)'
            WHEN atc_class_5 = 'N05AB' THEN 'N05AB - Phenothiazines with piperazine structure (酚噻嗪類-哌嗪)'
            WHEN atc_class_5 = 'N05AC' THEN 'N05AC - Phenothiazines with piperidine structure (酚噻嗪類-哌啶)'
            WHEN atc_class_5 = 'N05AD' THEN 'N05AD - Butyrophenone derivatives (丁苯酮類)'
            WHEN atc_class_5 = 'N05AE' THEN 'N05AE - Indole derivatives (吲哚類)'
            WHEN atc_class_5 = 'N05AF' THEN 'N05AF - Thioxanthene derivatives (噻噸類)'
            WHEN atc_class_5 = 'N05AG' THEN 'N05AG - Diphenylbutylpiperidine derivatives (二苯丁基哌啶類)'
            WHEN atc_class_5 = 'N05AH' THEN 'N05AH - Diazepines, oxazepines, thiazepines (二氮䓬類)'
            WHEN atc_class_5 = 'N05AL' THEN 'N05AL - Benzamides (苯甲醯胺類)'
            WHEN atc_class_5 = 'N05AN' THEN 'N05AN - Lithium (鋰鹽)'
            WHEN atc_class_5 = 'N05AX' THEN 'N05AX - Other antipsychotics (其他抗精神病藥)'
            ELSE 'Other'
        END as atc_class_name,
        COUNT(DISTINCT claim_id) as prescription_count,
        SUM(drug_days) as total_drug_days,
        COUNT(DISTINCT patient_id) as patient_count
    FROM antipsychotic_drugs
    GROUP BY quarter, atc_class_5
),

-- 趨勢分析 (各季度變化)
trend_analysis AS (
    SELECT 
        c1.quarter as current_quarter,
        c1.hospital_id,
        c1.hospital_name,
        c1.overlap_rate as current_rate,
        c2.quarter as previous_quarter,
        c2.overlap_rate as previous_rate,
        CASE 
            WHEN c2.overlap_rate IS NOT NULL 
            THEN ROUND((c1.overlap_rate - c2.overlap_rate), 2)
            ELSE NULL 
        END as rate_change,
        CASE 
            WHEN c2.overlap_rate IS NOT NULL AND c2.overlap_rate > 0
            THEN ROUND(((c1.overlap_rate - c2.overlap_rate) * 100.0 / c2.overlap_rate), 2)
            ELSE NULL 
        END as rate_change_percent
    FROM calculation c1
    LEFT JOIN calculation c2 
        ON c1.hospital_id = c2.hospital_id
        AND c1.quarter = CASE c2.quarter
            WHEN '2024Q1' THEN '2024Q2'
            WHEN '2024Q2' THEN '2024Q3'
            WHEN '2024Q3' THEN '2024Q4'
            WHEN '2024Q4' THEN '2025Q1'
            WHEN '2025Q1' THEN '2025Q2'
            WHEN '2025Q2' THEN '2025Q3'
            WHEN '2025Q3' THEN '2025Q4'
        END
)

-- ============================================
-- 最終輸出結果
-- ============================================

-- 輸出1: 各醫療機構抗思覺失調藥品用藥日數重疊率
SELECT 
    quarter as '季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    hospital_level as '醫院層級',
    region as '區域',
    total_overlap_days as '重疊給藥日數',
    total_drug_days as '總給藥日數',
    total_prescriptions as '處方件數',
    total_patients as '病人數',
    overlap_rate as '用藥日數重疊率(%)'
FROM calculation
ORDER BY quarter, overlap_rate DESC;

-- 輸出2: 各季度統計摘要
SELECT 
    quarter as '季度',
    hospital_count as '醫療機構數',
    sum_overlap_days as '總重疊日數',
    sum_drug_days as '總給藥日數',
    sum_prescriptions as '總處方件數',
    sum_patients as '總病人數',
    avg_overlap_rate as '平均重疊率(%)',
    min_overlap_rate as '最低重疊率(%)',
    q25_overlap_rate as '第1四分位數(%)',
    median_overlap_rate as '中位數(%)',
    q75_overlap_rate as '第3四分位數(%)',
    max_overlap_rate as '最高重疊率(%)'
FROM summary_by_quarter
ORDER BY quarter;

-- 輸出3: 依醫院層級統計
SELECT 
    quarter as '季度',
    hospital_level as '醫院層級',
    hospital_count as '醫療機構數',
    sum_overlap_days as '總重疊日數',
    sum_drug_days as '總給藥日數',
    avg_overlap_rate as '平均重疊率(%)',
    min_overlap_rate as '最低重疊率(%)',
    max_overlap_rate as '最高重疊率(%)'
FROM summary_by_level
ORDER BY quarter, hospital_level;

-- 輸出4: 依區域統計
SELECT 
    quarter as '季度',
    region as '區域',
    hospital_count as '醫療機構數',
    sum_overlap_days as '總重疊日數',
    sum_drug_days as '總給藥日數',
    avg_overlap_rate as '平均重疊率(%)',
    min_overlap_rate as '最低重疊率(%)',
    max_overlap_rate as '最高重疊率(%)'
FROM summary_by_region
ORDER BY quarter, region;

-- 輸出5: 依ATC碼分類統計 (抗思覺失調藥物類別)
SELECT 
    quarter as '季度',
    atc_class_5 as 'ATC前5碼',
    atc_class_name as 'ATC分類名稱',
    prescription_count as '處方件數',
    total_drug_days as '總給藥日數',
    patient_count as '病人數'
FROM antipsychotic_by_atc
ORDER BY quarter, prescription_count DESC;

-- 輸出6: 趨勢分析
SELECT 
    current_quarter as '當前季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    current_rate as '當前重疊率(%)',
    previous_quarter as '前一季度',
    previous_rate as '前一季重疊率(%)',
    rate_change as '重疊率變化(百分點)',
    rate_change_percent as '重疊率變化率(%)'
FROM trend_analysis
WHERE previous_quarter IS NOT NULL
ORDER BY current_quarter, rate_change DESC;

-- ============================================
-- FHIR資源查詢說明
-- ============================================
-- 
-- 1. MedicationRequest (抗思覺失調藥品處方)
--    GET {FHIR_SERVER}/MedicationRequest?
--        date=ge2024-01-01&
--        category=outpatient&
--        status=completed&
--        medication.code:text=antipsychotic&
--        _include=MedicationRequest:medication&
--        _include=MedicationRequest:patient
-- 
-- 2. Encounter (就診記錄)
--    GET {FHIR_SERVER}/Encounter?
--        date=ge2024-01-01&
--        class=AMB&
--        status=finished
-- 
-- 3. Medication (抗思覺失調藥品資訊)
--    GET {FHIR_SERVER}/Medication?
--        code:text=antipsychotic&
--        _filter=(code.coding.system eq 'http://www.whocc.no/atc' and 
--                 (code.coding.code sw 'N05AA' or
--                  code.coding.code sw 'N05AB' or
--                  code.coding.code sw 'N05AC' or
--                  code.coding.code sw 'N05AD' or
--                  code.coding.code sw 'N05AE' or
--                  code.coding.code sw 'N05AF' or
--                  code.coding.code sw 'N05AG' or
--                  code.coding.code sw 'N05AH' or
--                  code.coding.code sw 'N05AL' or
--                  code.coding.code sw 'N05AN' or
--                  code.coding.code sw 'N05AX'))
-- 
-- 4. Patient (病人資訊)
--    GET {FHIR_SERVER}/Patient?
--        _id={patient_id}
-- 
-- 5. Organization (醫療機構)
--    GET {FHIR_SERVER}/Organization?
--        type=prov&
--        _id={organization_id}
-- 
-- ============================================
-- 查詢結束
-- ============================================
