library Indicator_03_16_Cross_Hospital_Prostate_Overlap_3378 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-前列腺肥大(口服)
// 指標代碼: 3378
// 製作日期：2025-11-20
-- 製表日期: 114/05/13 (2025-11-08更新)
-- 製表單位: 衛生福利部 中央健康保險署
-- 
-- 【資料時間範圍】
-- 查詢期間: 2024-01-01 ~ 2025-11-08 (今天)
-- 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
-- ============================================

-- 【資料範圍】
-- (1)醫院總額之門診處方前列腺肥大藥物(口服)案件
-- (2)排除代辦案件

-- 【公式說明】(依健保指標代碼 3378)
-- 跨醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服) = 
--     分子: 全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數(允許遞延早拿藥)
--     分母: 各案件之「給藥日數」總和
-- 
-- (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
-- (2)前列腺肥大藥物(口服)：ATC前5碼為G04CA、G04CB，且醫令令代碼第8碼為1
-- 
-- 排除條件:
--   1.排除代辦案件
--   2.限制口服劑型 (劑型代碼第8碼為1)
--
-- 【重點差異】
--   與指標10(同院門診)不同，本指標計算「跨醫院」的用藥重疊
--   即：同一病患在不同醫院就診時的前列腺肥大藥物(口服)重疊情況

-- ============================================
-- 備註:
-- 1.資料來源：醫療給付檔案分析系統，指標代碼：3378
-- 
-- 2.資料範圍：醫院總額之門診處方前列腺肥大藥物(口服)案件，排除代辦案件。
-- 
-- 3.公式說明：
--   分子：全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數(允許遞延早拿藥)。
--   分母：各案件之「給藥日數」總和。
--   (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
--   (2)前列腺肥大藥物(口服)：ATC前5碼為G04CA、G04CB，且醫令令代碼第8碼為1。
-- 
-- 4.製表日期：114/05/13
-- 
-- 5.製表單位：衛生福利部 中央健康保險署
-- ============================================

-- CQL Code Systems Definition (依健保標準代碼對照國際標準)
codesystem "NHI_INDICATOR": 'NHI_INDICATOR'  -- 健保指標代碼系統
codesystem "SNOMEDCT": 'http://snomed.info/sct'  -- SNOMED CT 劑型代碼對照
codesystem "ATC": 'http://www.whocc.no/atc'  -- ATC 藥品分類代碼
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'  -- HL7 就醫類型代碼
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
    UNION ALL SELECT '2025Q4', '2025-10-01', '2025-11-08'  -- 計算到今天 2025-11-08
),

-- 健保代碼與標準代碼系統對照表
-- 依據健保指標代碼 3378 (跨醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服)) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '3378', '3378', 'NHI_INDICATOR', 'Cross-Hospital BPH Drug (Oral) Overlap Rate - 跨醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服)'),
        
        -- 劑型代碼 (SNOMED CT) - 限制口服劑型
        ('DOSAGE_FORM', '1', '385268001', 'http://snomed.info/sct', 'Oral dose form - 口服劑型'),
        ('DOSAGE_FORM', 'ORAL', '385268001', 'http://snomed.info/sct', 'Oral dose form - 口服劑型'),
        
        -- ATC藥品分類代碼 (前列腺肥大藥物)
        ('ATC', 'G04CA', 'G04CA', 'http://www.whocc.no/atc', 'Alpha-adrenoreceptor antagonists - α受體阻斷劑'),
        ('ATC', 'G04CB', 'G04CB', 'http://www.whocc.no/atc', 'Testosterone-5-alpha reductase inhibitors - 5α還原酶抑制劑'),
        
        -- 就醫類型代碼 (HL7 ActCode)
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)'),
        ('AGENCY', 'N', 'N', 'NHI', 'Non-Agency Case - 非代辦案件')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選前列腺肥大藥物(口服)
-- 條件: 
--   (1) ATC前5碼為 G04CA、G04CB
--   (2) 口服劑型 (劑型代碼第8碼 = 1 或 SUBSTRING(order_code, 8, 1) = '1')
bph_drugs AS (
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
        -- 劑型代碼 (從醫令代碼第8位取得)
        SUBSTRING(d.order_code, 8, 1) as dosage_form_code
    FROM 
        quarters q
    CROSS JOIN 
        outpatient_claims o
    INNER JOIN 
        drug_details d ON o.claim_id = d.claim_id
    WHERE 
        -- 1. 時間範圍: 在該季內
        d.prescription_date BETWEEN q.start_date AND q.end_date
        
        -- 2. 門診案件 (就醫類別 = O 或 AMB)
        AND o.encounter_type IN ('O', 'AMB')
        
        -- 3. 醫院總額 (排除代辦案件)
        AND (o.agency_flag IS NULL OR o.agency_flag != 'Y')
        AND o.hospital_id IS NOT NULL
        
        -- 4. 前列腺肥大藥物 (口服)
        -- ATC前5碼為 G04CA、G04CB
        AND (
            LEFT(d.atc_code, 5) = 'G04CA' OR  -- Alpha-adrenoreceptor antagonists (α受體阻斷劑)
            LEFT(d.atc_code, 5) = 'G04CB'     -- Testosterone-5-alpha reductase inhibitors (5α還原酶抑制劑)
        )
        
        -- 5. 限制口服劑型
        -- 劑型代碼第8碼: 1 = 口服 (SNOMED CT: 385268001)
        AND (
            d.dosage_form = '1' OR 
            d.dosage_form = 'ORAL' OR
            SUBSTRING(d.order_code, 8, 1) = '1'
        )
        
        -- 6. 有效的給藥日數
        AND COALESCE(d.order_drug_day, d.drug_days, 0) > 0
),

-- 【跨醫院】配對分析 (不同於指標10的同醫院)
-- 找出同一病人在不同醫院的前列腺肥大藥物(口服)處方配對
cross_hospital_pairs AS (
    SELECT 
        a.quarter,
        a.patient_id,
        a.hospital_id as hospital_id_a,
        b.hospital_id as hospital_id_b,
        a.claim_id as claim_id_a,
        b.claim_id as claim_id_b,
        a.drug_code as drug_code_a,
        b.drug_code as drug_code_b,
        a.drug_name as drug_name_a,
        b.drug_name as drug_name_b,
        a.atc_code as atc_code_a,
        b.atc_code as atc_code_b,
        a.start_date as start_date_a,
        a.end_date as end_date_a,
        a.drug_days as drug_days_a,
        b.start_date as start_date_b,
        b.end_date as end_date_b,
        b.drug_days as drug_days_b
    FROM 
        bph_drugs a
    INNER JOIN 
        bph_drugs b
        ON a.quarter = b.quarter
        AND a.patient_id = b.patient_id
        -- 【關鍵條件】跨醫院: 不同醫院ID
        AND a.hospital_id != b.hospital_id
        -- 避免重複配對: 只取 a < b
        AND a.claim_id < b.claim_id
),

-- 計算【跨醫院】用藥重疊天數 (允許遞延早拿藥)
cross_hospital_overlap AS (
    SELECT 
        quarter,
        patient_id,
        hospital_id_a,
        hospital_id_b,
        claim_id_a,
        claim_id_b,
        drug_name_a,
        drug_name_b,
        atc_code_a,
        atc_code_b,
        start_date_a,
        end_date_a,
        drug_days_a,
        start_date_b,
        end_date_b,
        drug_days_b,
        -- 重疊天數計算 (允許遞延早拿藥，一般為7天)
        -- 公式: GREATEST(LEAST(end_date_a+7, end_date_b+7) - GREATEST(start_date_a, start_date_b) + 1, 0)
        GREATEST(
            DATEDIFF(
                LEAST(DATE_ADD(end_date_a, INTERVAL 7 DAY), DATE_ADD(end_date_b, INTERVAL 7 DAY)),
                GREATEST(start_date_a, start_date_b)
            ) + 1,
            0
        ) as overlap_days
    FROM 
        cross_hospital_pairs
),

-- 篩選實際有重疊的案件
actual_cross_hospital_overlap AS (
    SELECT *
    FROM cross_hospital_overlap
    WHERE overlap_days > 0
),

-- 計算每季的統計數據
quarterly_summary AS (
    SELECT 
        q.quarter,
        -- 分母: 各案件之「給藥日數」總和
        SUM(d.drug_days) as total_drug_days,
        -- 分子: 跨院同ID不同處方之重疊給藥日數總和
        COALESCE(SUM(o.overlap_days), 0) as total_overlap_days,
        -- 重疊率 (%)
        CASE 
            WHEN SUM(d.drug_days) > 0 THEN 
                ROUND(COALESCE(SUM(o.overlap_days), 0) * 100.0 / SUM(d.drug_days), 2)
            ELSE 0
        END as overlap_rate,
        -- 統計數量
        COUNT(DISTINCT d.patient_id) as total_patients,
        COUNT(DISTINCT d.claim_id) as total_prescriptions,
        COUNT(DISTINCT o.patient_id) as patients_with_cross_hospital_overlap,
        COUNT(DISTINCT CONCAT(o.claim_id_a, '-', o.claim_id_b)) as cross_hospital_overlap_pairs
    FROM 
        quarters q
    LEFT JOIN 
        bph_drugs d ON q.quarter = d.quarter
    LEFT JOIN 
        actual_cross_hospital_overlap o ON q.quarter = o.quarter
    GROUP BY 
        q.quarter
)

-- 最終結果輸出
SELECT 
    quarter as '季度',
    total_patients as '總病人數',
    total_prescriptions as '總處方數',
    total_drug_days as '前列腺肥大藥物(口服)之給藥日數',
    total_overlap_days as '前列腺肥大藥物(口服)不同處方用藥日數重疊',
    overlap_rate as '前列腺肥大藥物(口服)不同處方用藥日數重疊率',
    patients_with_cross_hospital_overlap as '有跨院重疊的病人數',
    cross_hospital_overlap_pairs as '跨院重疊配對數'
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
-- 與同院指標對照:
--   指標10 (同院): 待補充 (Q4 2024)
--   指標18 (跨院): 待補充 (Q4 2024)
--   預期: 跨院重疊率應高於同院重疊率
-- ============================================

-- ============================================
-- 與其他指標的差異
-- ============================================
-- 指標10 (同醫院-前列腺肥大-口服): a.hospital_id = b.hospital_id
-- 指標18 (跨醫院-前列腺肥大-口服): a.hospital_id != b.hospital_id
-- 
-- 關鍵SQL條件差異:
-- 同院: AND a.hospital_id = b.hospital_id
-- 跨院: AND a.hospital_id != b.hospital_id
-- 
-- ATC代碼範圍:
-- G04CA: Alpha-adrenoreceptor antagonists (α受體阻斷劑)
--   例如: Tamsulosin, Alfuzosin, Doxazosin, Terazosin
-- G04CB: Testosterone-5-alpha reductase inhibitors (5α還原酶抑制劑)
--   例如: Finasteride, Dutasteride
-- 
-- 劑型限制:
-- 口服劑型: SUBSTRING(order_code, 8, 1) = '1'
-- SNOMED CT: 385268001 (Oral dose form)
-- 
-- 代碼系統對照:
-- NHI_INDICATOR: 健保指標代碼 (3378)
-- SNOMEDCT: http://snomed.info/sct (劑型代碼)
-- ATC: http://www.whocc.no/atc (藥品分類)
-- ActCode: http://terminology.hl7.org/CodeSystem/v3-ActCode (就醫類型)
-- NHI: 健保專用代碼 (代辦案件標記等)
-- ============================================
