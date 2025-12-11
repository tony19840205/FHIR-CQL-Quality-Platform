library Indicator_03_6_Same_Hospital_Sedative_Overlap_1728 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 同醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服)
// 指標代碼: 1728
// 製作日期：2025-11-20
-- 製表日期: 114/05/13 (2025/11/07更新)
-- 製表單位: 衛生福利部 中央健康保險署
-- 
-- 【資料時間範圍】
-- 查詢期間: 2024-01-01 ~ 2025-11-07 (今天)
-- 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
-- ============================================

-- 【資料範圍】
-- (1)醫院總額之門診處方安眠鎮靜藥物(口服)案件
-- (2)排除代辦案件

-- 【公式說明】(依健保指標代碼 1728)
-- 同醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服) = 
--     分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
--     分母: 各案件之「給藥日數」總和
-- 
-- (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
-- (2)安眠鎮靜藥物(口服): 醫療總額之門診處方安眠鎮靜藥物(口服)案件
-- 
-- 排除條件:
--   1.排除代辦案件
--   2.僅包含口服劑型

-- ============================================
-- 備註:
-- 1.資料來源：醫療給付檔案分析系統，指標代碼：1728
-- 
-- 2.資料範圍：醫院總額之門診處方安眠鎮靜藥物(口服)案件，排除代辦案件。
-- 
-- 3.公式說明：
--   分子：同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)。
--   分母：各案件之「給藥日數」總和。
--   (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
-- 
-- 4.製表日期：114/05/13
-- 
-- 5.製表單位：衛生福利部 中央健康保險署
-- ============================================

-- CQL Code Systems Definition (依健保標準代碼對照國際標準)
codesystem "NHI_INDICATOR": 'NHI_INDICATOR'  -- 健保指標代碼：同醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服)
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
-- 依據健保指標代碼 1728 (同醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服)) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1728', '1728', 'NHI', 'Sedative-Hypnotic Drug Overlap Rate (Oral) - 同醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服)'),
        
        -- 劑型代碼 (SNOMED CT) - 僅口服
        ('DOSAGE_FORM', '2', '385268001', 'http://snomed.info/sct', 'Oral - 口服'),
        ('DOSAGE_FORM', 'ORAL', '385268001', 'http://snomed.info/sct', 'Oral dose form - 口服劑型'),
        
        -- 就醫類型代碼
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選安眠鎮靜藥物(口服)
-- 條件: 醫院總額之門診處方安眠鎮靜藥物(口服)案件
sedative_hypnotic_drugs AS (
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
        d.dosage_form,
        -- 給藥日數: 優先取 ORDER_DRUG_DAY，若為空則取 DRUG_DAYS
        COALESCE(d.order_drug_day, d.drug_days, 0) as drug_days,
        -- 給藥開始日期: 處方開始日期
        d.prescription_date as start_date,
        -- 給藥結束日期: 處方開始日期 + 給藥日數 - 1
        DATE_ADD(d.prescription_date, INTERVAL (COALESCE(d.order_drug_day, d.drug_days, 0) - 1) DAY) as end_date,
        ncm.standard_code as dosage_form_standard_code,
        ncm.description as dosage_form_description
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診
    INNER JOIN drug_details d 
        ON o.claim_id = d.claim_id
    LEFT JOIN nhi_code_mapping ncm 
        ON d.dosage_form = ncm.nhi_code 
        AND ncm.code_type = 'DOSAGE_FORM'
    WHERE 
        -- 條件1: 安眠鎮靜藥物(依健保藥品分類)
        -- 這裡需要根據實際的健保藥品分類代碼或ATC代碼來篩選
        -- 常見的安眠鎮靜藥物包括: Benzodiazepines (N05BA, N05CD), Z-drugs (N05CF), 等等
        (
            -- Benzodiazepines anxiolytics
            SUBSTRING(d.atc_code, 1, 5) LIKE 'N05BA%'
            -- Benzodiazepine hypnotics
            OR SUBSTRING(d.atc_code, 1, 5) LIKE 'N05CD%'
            -- Benzodiazepine-related drugs (Z-drugs)
            OR SUBSTRING(d.atc_code, 1, 5) LIKE 'N05CF%'
            -- Other hypnotics and sedatives
            OR SUBSTRING(d.atc_code, 1, 4) = 'N05C'
        )
        
        -- 條件2: 僅口服劑型
        AND (
            d.dosage_form IN ('2', 'ORAL', 'TAB', 'CAP', 'SYR', 'SOL', 'SUSP')
            OR d.dosage_form_description LIKE '%口服%'
            OR d.dosage_form_description LIKE '%Oral%'
            OR d.dosage_form_description LIKE '%tablet%'
            OR d.dosage_form_description LIKE '%capsule%'
        )
        
        -- 條件3: 給藥日數 > 0
        AND COALESCE(d.order_drug_day, d.drug_days, 0) > 0
        
        -- 排除代辦案件
        AND (o.agency_case_flag IS NULL OR o.agency_case_flag <> 'Y')
),

-- 計算同院同病人不同處方之間的用藥日期重疊
-- 使用自我連接找出同院、同病人、不同處方且日期有重疊的案件
drug_overlaps AS (
    SELECT 
        s1.quarter,
        s1.hospital_id,
        s1.patient_id,
        s1.claim_id as claim_id_1,
        s2.claim_id as claim_id_2,
        s1.drug_code as drug_code_1,
        s2.drug_code as drug_code_2,
        s1.start_date as start_date_1,
        s1.end_date as end_date_1,
        s2.start_date as start_date_2,
        s2.end_date as end_date_2,
        s1.drug_days as drug_days_1,
        s2.drug_days as drug_days_2,
        -- 計算重疊日數
        -- 重疊開始日 = MAX(start_date_1, start_date_2)
        -- 重疊結束日 = MIN(end_date_1, end_date_2)
        -- 重疊日數 = 重疊結束日 - 重疊開始日 + 1 (如果 > 0)
        CASE 
            WHEN GREATEST(s1.start_date, s2.start_date) <= LEAST(s1.end_date, s2.end_date)
            THEN DATEDIFF(LEAST(s1.end_date, s2.end_date), GREATEST(s1.start_date, s2.start_date)) + 1
            ELSE 0
        END as overlap_days
    FROM sedative_hypnotic_drugs s1
    INNER JOIN sedative_hypnotic_drugs s2
        ON s1.quarter = s2.quarter
        AND s1.hospital_id = s2.hospital_id  -- 同醫院
        AND s1.patient_id = s2.patient_id    -- 同病人
        AND s1.claim_id < s2.claim_id        -- 不同處方 (避免重複計算)
    WHERE 
        -- 有日期重疊: start_date_1 <= end_date_2 AND start_date_2 <= end_date_1
        s1.start_date <= s2.end_date
        AND s2.start_date <= s1.end_date
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
        SUM(drug_days) as total_drug_days
    FROM sedative_hypnotic_drugs
    GROUP BY quarter, hospital_id
),

-- 計算重疊率
overlap_rate AS (
    SELECT 
        d.quarter,
        d.hospital_id,
        h.hospital_name,
        h.hospital_level,
        h.hospital_region,
        COALESCE(n.total_overlap_days, 0) as overlap_days,
        d.total_drug_days as total_drug_days,
        CASE 
            WHEN d.total_drug_days > 0 
            THEN ROUND((COALESCE(n.total_overlap_days, 0) * 100.0 / d.total_drug_days), 4)
            ELSE 0
        END as overlap_rate_percent
    FROM denominator d
    LEFT JOIN numerator n
        ON d.quarter = n.quarter
        AND d.hospital_id = n.hospital_id
    LEFT JOIN hospital_master h
        ON d.hospital_id = h.hospital_id
)

-- ============================================
-- 輸出1: 各醫療機構安眠鎮靜藥品(口服)重疊率
-- ============================================
SELECT 
    quarter as '季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    hospital_level as '醫院層級',
    hospital_region as '區域別',
    overlap_days as '安眠鎮靜藥物重疊用藥日數(分子)',
    total_drug_days as '安眠鎮靜藥物之給藥日數(分母)',
    overlap_rate_percent as '安眠鎮靜藥物(口服)不同處方用藥日數重疊率(%)',
    CASE 
        WHEN overlap_rate_percent > 1.0 THEN '需關注'
        WHEN overlap_rate_percent > 0.5 THEN '持續監測'
        ELSE '正常範圍'
    END as '評估結果'
FROM overlap_rate
ORDER BY quarter, overlap_rate_percent DESC;

-- ============================================
-- 輸出2: 各季度統計摘要
-- ============================================
SELECT 
    quarter as '季度',
    COUNT(DISTINCT hospital_id) as '醫院數',
    SUM(overlap_days) as '總重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '整體重疊率(%)',
    ROUND(AVG(overlap_rate_percent), 4) as '平均重疊率(%)',
    MIN(overlap_rate_percent) as '最小重疊率(%)',
    MAX(overlap_rate_percent) as '最大重疊率(%)'
FROM overlap_rate
GROUP BY quarter
ORDER BY quarter;

-- ============================================
-- 輸出3: 依醫院層級統計
-- ============================================
SELECT 
    quarter as '季度',
    hospital_level as '醫院層級',
    COUNT(DISTINCT hospital_id) as '醫院數',
    SUM(overlap_days) as '重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '重疊率(%)'
FROM overlap_rate
GROUP BY quarter, hospital_level
ORDER BY quarter, hospital_level;

-- ============================================
-- 輸出4: 依區域統計
-- ============================================
SELECT 
    quarter as '季度',
    hospital_region as '區域',
    COUNT(DISTINCT hospital_id) as '醫院數',
    SUM(overlap_days) as '重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '重疊率(%)'
FROM overlap_rate
GROUP BY quarter, hospital_region
ORDER BY quarter, hospital_region;

-- ============================================
-- 輸出5: 依劑型分類統計(僅口服)
-- ============================================
SELECT 
    s.quarter as '季度',
    s.dosage_form as '劑型代碼',
    s.dosage_form_description as '劑型說明',
    COUNT(DISTINCT s.patient_id) as '病人數',
    COUNT(DISTINCT s.claim_id) as '處方數',
    SUM(s.drug_days) as '總給藥日數'
FROM sedative_hypnotic_drugs s
GROUP BY s.quarter, s.dosage_form, s.dosage_form_description
ORDER BY s.quarter, SUM(s.drug_days) DESC;

-- ============================================
-- 輸出6: 趨勢分析
-- ============================================
SELECT 
    quarter as '季度',
    SUM(overlap_days) as '重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '重疊率(%)',
    LAG(ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4)) 
        OVER (ORDER BY quarter) as '前一季重疊率(%)',
    ROUND(
        (ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) - 
         LAG(ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4)) 
            OVER (ORDER BY quarter)) * 100.0 / 
        NULLIF(LAG(ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4)) 
            OVER (ORDER BY quarter), 0),
        2
    ) as '變化率(%)'
FROM overlap_rate
GROUP BY quarter
ORDER BY quarter;

-- ============================================
-- 查詢結束
-- ============================================
-- 製表日期: 2025-11-07
-- 指標代碼: 1728
-- 指標名稱: 同醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服)
-- 
-- FHIR Resource Mapping Summary:
-- - MedicationRequest (藥品處方) → drug_details
-- - Encounter (就醫紀錄) → outpatient_claims
-- - Patient (病人資料) → patient_master  
-- - Organization (醫療機構) → hospital_master
-- 
-- Code Systems Used:
-- - SNOMEDCT: http://snomed.info/sct (劑型代碼)
-- - ATC: http://www.whocc.no/atc (藥品分類)
-- - ActCode: http://terminology.hl7.org/CodeSystem/v3-ActCode (就醫類型)
-- ============================================
