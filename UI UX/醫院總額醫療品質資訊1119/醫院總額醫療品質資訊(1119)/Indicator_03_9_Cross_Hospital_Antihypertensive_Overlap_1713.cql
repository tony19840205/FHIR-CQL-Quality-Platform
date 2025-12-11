library Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-降血壓(口服)
// 指標代碼: 1713
// 製作日期：2025-11-20
-- 製表日期: 114/05/13 (2025/11/07更新)
-- 製表單位: 衛生福利部 中央健康保險署
-- 
-- 【資料時間範圍】
-- 查詢期間: 2024-01-01 ~ 2025-11-07 (今天)
-- 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
-- ============================================

-- 【資料範圍】
-- (1)醫院總額之門診處方降血壓藥物(口服)案件
-- (2)排除代辦案件

-- 【公式說明】(依健保指標代碼 1713)
-- 跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服) = 
--     分子: 全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
--     分母: 各案件之「給藥日數」總和
-- 
-- (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
-- (2)降血壓藥物(口服): ATC前3碼為C07(排除C07AA05)或ATC前5碼為C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA，且醫令代碼第8碼為1
-- 
-- 排除條件:
--   1.排除特定ATC代碼: C07AA05、C08CA06
--   2.排除代辦案件
--   3.僅包含口服劑型(醫令代碼第8碼為1)
--
-- 【重點差異】
--   與指標3(同院門診)不同，本指標計算「跨醫院」的用藥重疊
--   即：同一病患在不同醫院就診時的降血壓藥物重疊情況

-- ============================================
-- 備註:
-- 1.資料來源：醫療給付檔案分析系統，指標代碼：1713
-- 
-- 2.資料範圍：醫院總額之門診處方降血壓藥物(口服)案件，排除代辦案件。
-- 
-- 3.公式說明：
--   分子：全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)。
--   分母：各案件之「給藥日數」總和。
--   (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
--   (2)降血壓藥物(口服): ATC前3碼為C07(排除C07AA05)或ATC前5碼為C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA，且醫令代碼第8碼為1。
-- 
-- 4.製表日期：114/05/13
-- 
-- 5.製表單位：衛生福利部 中央健康保險署
-- ============================================

-- CQL Code Systems Definition (依健保標準代碼對照國際標準)
codesystem "NHI_INDICATOR": 'NHI_INDICATOR'  -- 健保指標代碼：跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服)
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
-- 依據健保指標代碼 1713 (跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服)) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1713', '1713', 'NHI', 'Cross-Hospital Antihypertensive Drug Overlap Rate (Oral) - 跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服)'),
        
        -- ATC碼對照 (降血壓藥物) - 共14類
        -- C02: Antihypertensives (降血壓藥)
        ('ATC', 'C02CA', 'C02CA', 'http://www.whocc.no/atc', 'Alpha-adrenoreceptor antagonists - α受體阻斷劑'),
        ('ATC', 'C02DB', 'C02DB', 'http://www.whocc.no/atc', 'Hydrazinophthalazine derivatives - 肼屈嗪類'),
        ('ATC', 'C02DC', 'C02DC', 'http://www.whocc.no/atc', 'Pyrimidine derivatives - 嘧啶類'),
        ('ATC', 'C02DD', 'C02DD', 'http://www.whocc.no/atc', 'Nitroferricyanide derivatives - 硝普鹽類'),
        
        -- C03: Diuretics (利尿劑)
        ('ATC', 'C03AA', 'C03AA', 'http://www.whocc.no/atc', 'Thiazides, plain - 噻嗪類利尿劑'),
        ('ATC', 'C03BA', 'C03BA', 'http://www.whocc.no/atc', 'Sulfonamides, plain - 磺胺類利尿劑'),
        ('ATC', 'C03CA', 'C03CA', 'http://www.whocc.no/atc', 'Sulfonamides, plain - 磺胺類'),
        ('ATC', 'C03DA', 'C03DA', 'http://www.whocc.no/atc', 'Aldosterone antagonists - 醛固酮拮抗劑'),
        
        -- C07: Beta blocking agents (β阻斷劑) - 使用前3碼
        ('ATC', 'C07', 'C07', 'http://www.whocc.no/atc', 'Beta blocking agents - β阻斷劑'),
        
        -- C08: Calcium channel blockers (鈣離子阻斷劑)
        ('ATC', 'C08CA', 'C08CA', 'http://www.whocc.no/atc', 'Dihydropyridine derivatives - 二氫吡啶類'),
        ('ATC', 'C08DA', 'C08DA', 'http://www.whocc.no/atc', 'Phenylalkylamine derivatives - 苯烷基胺類'),
        ('ATC', 'C08DB', 'C08DB', 'http://www.whocc.no/atc', 'Benzothiazepine derivatives - 苯並硫氮䓬類'),
        
        -- C09: Agents acting on the renin-angiotensin system (作用於腎素-血管張力素系統)
        ('ATC', 'C09AA', 'C09AA', 'http://www.whocc.no/atc', 'ACE inhibitors, plain - 血管張力素轉化酶抑制劑'),
        ('ATC', 'C09CA', 'C09CA', 'http://www.whocc.no/atc', 'Angiotensin II receptor blockers (ARBs), plain - 血管張力素II受體阻斷劑'),
        
        -- 排除的特定ATC代碼
        ('ATC_EXCLUDE', 'C07AA05', 'C07AA05', 'http://www.whocc.no/atc', 'Propranolol - 應排除'),
        ('ATC_EXCLUDE', 'C08CA06', 'C08CA06', 'http://www.whocc.no/atc', 'Nimodipine - 應排除'),
        
        -- 劑型代碼 (SNOMED CT) - 僅口服
        ('DOSAGE_FORM', '2', '385268001', 'http://snomed.info/sct', 'Oral - 口服'),
        ('DOSAGE_FORM', 'ORAL', '385268001', 'http://snomed.info/sct', 'Oral dose form - 口服劑型'),
        ('DOSAGE_FORM', '1', '385268001', 'http://snomed.info/sct', 'Oral (order_code 8th digit = 1) - 口服(醫令代碼第8碼為1)'),
        
        -- 就醫類型代碼
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選降血壓藥物(口服)
-- 條件: ATC前3碼為C07(排除C07AA05)或ATC前5碼為C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA，且醫令代碼第8碼為1
antihypertensive_drugs AS (
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
        SUBSTRING(d.atc_code, 1, 3) as atc_class_3,
        SUBSTRING(d.atc_code, 1, 5) as atc_class_5,
        -- 醫令代碼第8碼
        SUBSTRING(d.order_code, 8, 1) as order_code_8th_digit,
        ncm.standard_code as atc_standard_code,
        ncm.description as atc_description
    FROM quarters q
    CROSS JOIN outpatient_claims o
    INNER JOIN drug_details d ON o.claim_id = d.claim_id
    LEFT JOIN nhi_code_mapping ncm ON 
        (ncm.code_type = 'ATC' AND 
         (SUBSTRING(d.atc_code, 1, 3) = ncm.nhi_code OR SUBSTRING(d.atc_code, 1, 5) = ncm.nhi_code))
    WHERE 
        -- 時間範圍: 在查詢季度內
        d.prescription_date BETWEEN q.start_date AND q.end_date
        -- 門診案件
        AND o.claim_type = 'O'
        -- 醫院總額
        AND o.fee_type IN ('01', '02', '03')  -- 醫院總額(住院、門診、急診)
        -- 降血壓藥物(口服): 
        -- (1) ATC前3碼為C07(排除C07AA05) 或
        -- (2) ATC前5碼為C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA
        AND (
            -- C07: Beta blocking agents (排除C07AA05)
            (SUBSTRING(d.atc_code, 1, 3) = 'C07' AND d.atc_code NOT LIKE 'C07AA05%')
            -- C02: Antihypertensives
            OR SUBSTRING(d.atc_code, 1, 5) = 'C02CA'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C02DB'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C02DC'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C02DD'
            -- C03: Diuretics
            OR SUBSTRING(d.atc_code, 1, 5) = 'C03AA'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C03BA'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C03CA'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C03DA'
            -- C08: Calcium channel blockers (C08CA排除C08CA06)
            OR (SUBSTRING(d.atc_code, 1, 5) = 'C08CA' AND d.atc_code NOT LIKE 'C08CA06%')
            OR SUBSTRING(d.atc_code, 1, 5) = 'C08DA'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C08DB'
            -- C09: Agents acting on the renin-angiotensin system
            OR SUBSTRING(d.atc_code, 1, 5) = 'C09AA'
            OR SUBSTRING(d.atc_code, 1, 5) = 'C09CA'
        )
        -- 口服劑型: 醫令代碼第8碼為1
        AND SUBSTRING(d.order_code, 8, 1) = '1'
        -- 排除代辦案件
        AND (o.agency_flag IS NULL OR o.agency_flag != 'Y')
        -- 給藥日數必須大於0
        AND COALESCE(d.order_drug_day, d.drug_days, 0) > 0
),

-- 計算藥物重疊 (跨醫院)
-- 【重點】同一病患、不同醫院、不同處方之間的給藥期間重疊
drug_overlaps AS (
    SELECT 
        a.quarter,
        a.patient_id,
        a.hospital_id as hospital_id_1,
        b.hospital_id as hospital_id_2,
        a.claim_id as claim_id_1,
        b.claim_id as claim_id_2,
        a.drug_code as drug_code_1,
        b.drug_code as drug_code_2,
        a.atc_class_5 as atc_class_1,
        b.atc_class_5 as atc_class_2,
        a.start_date as start_date_1,
        a.end_date as end_date_1,
        b.start_date as start_date_2,
        b.end_date as end_date_2,
        a.drug_days as drug_days_1,
        b.drug_days as drug_days_2,
        -- 計算重疊日數
        -- 重疊日數 = MIN(結束日期1, 結束日期2) - MAX(開始日期1, 開始日期2) + 1
        -- 若無重疊則為0 (使用GREATEST確保不為負數)
        GREATEST(0, 
            DATEDIFF(
                LEAST(a.end_date, b.end_date),
                GREATEST(a.start_date, b.start_date)
            ) + 1
        ) as overlap_days
    FROM antihypertensive_drugs a
    INNER JOIN antihypertensive_drugs b ON 
        a.quarter = b.quarter
        AND a.patient_id = b.patient_id
        AND a.hospital_id != b.hospital_id  -- 【關鍵】不同醫院
        AND a.claim_id < b.claim_id  -- 避免重複計算 (只計算一次)
    WHERE 
        -- 確保是不同處方
        a.claim_id != b.claim_id
        -- 確保日期有重疊 (開始日期1 <= 結束日期2 AND 開始日期2 <= 結束日期1)
        AND a.start_date <= b.end_date
        AND b.start_date <= a.end_date
)

-- ============================================
-- 輸出報表
-- ============================================

-- 【報表1】各季度總覽 (分子、分母、重疊率)
SELECT 
    quarter as '季度',
    SUM(overlap_days) as '降血壓藥物(口服)跨院重疊用藥日數_分子',
    (SELECT SUM(drug_days) FROM antihypertensive_drugs WHERE quarter = do.quarter) as '降血壓藥物(口服)之給藥日數_分母',
    ROUND(
        (SUM(overlap_days) * 100.0) / 
        NULLIF((SELECT SUM(drug_days) FROM antihypertensive_drugs WHERE quarter = do.quarter), 0),
        2
    ) as '降血壓藥物(口服)跨院不同處方用藥日數重疊率_%'
FROM drug_overlaps do
GROUP BY quarter
ORDER BY quarter;

-- 【報表2】各季度醫院配對統計 (跨院組合)
SELECT 
    quarter as '季度',
    hospital_id_1 as '醫院1',
    hospital_id_2 as '醫院2',
    COUNT(DISTINCT patient_id) as '共同病患人數',
    COUNT(DISTINCT claim_id_1) + COUNT(DISTINCT claim_id_2) as '處方數',
    SUM(overlap_days) as '跨院重疊日數'
FROM drug_overlaps
GROUP BY quarter, hospital_id_1, hospital_id_2
HAVING SUM(overlap_days) > 0
ORDER BY quarter, SUM(overlap_days) DESC
LIMIT 100;

-- 【報表3】各季度ATC類別統計 (14類)
SELECT 
    quarter as '季度',
    CASE 
        WHEN atc_class_3 = 'C07' THEN 'C07*'
        ELSE atc_class_5
    END as 'ATC類別',
    COUNT(DISTINCT patient_id) as '使用人數',
    COUNT(DISTINCT hospital_id) as '醫院數',
    COUNT(DISTINCT claim_id) as '處方數',
    SUM(drug_days) as '總給藥日數'
FROM antihypertensive_drugs
GROUP BY quarter, CASE WHEN atc_class_3 = 'C07' THEN 'C07*' ELSE atc_class_5 END
ORDER BY quarter, ATC類別;

-- 【報表4】排除案件統計
SELECT 
    q.quarter as '季度',
    COUNT(DISTINCT CASE WHEN o.agency_flag = 'Y' THEN o.claim_id END) as '代辦案件數_已排除',
    COUNT(DISTINCT CASE WHEN d.atc_code LIKE 'C07AA05%' THEN d.claim_id END) as 'C07AA05案件數_已排除',
    COUNT(DISTINCT CASE WHEN d.atc_code LIKE 'C08CA06%' THEN d.claim_id END) as 'C08CA06案件數_已排除',
    COUNT(DISTINCT CASE WHEN SUBSTRING(d.order_code, 8, 1) != '1' THEN d.claim_id END) as '非口服劑型案件數_已排除',
    COUNT(DISTINCT o.claim_id) as '符合條件案件總數'
FROM quarters q
CROSS JOIN outpatient_claims o
INNER JOIN drug_details d ON o.claim_id = d.claim_id
WHERE 
    d.prescription_date BETWEEN q.start_date AND q.end_date
    AND o.claim_type = 'O'
    AND o.fee_type IN ('01', '02', '03')
    AND (
        (SUBSTRING(d.atc_code, 1, 3) = 'C07' AND d.atc_code NOT LIKE 'C07AA05%')
        OR SUBSTRING(d.atc_code, 1, 5) IN ('C02CA', 'C02DB', 'C02DC', 'C02DD', 'C03AA', 'C03BA', 'C03CA', 'C03DA', 'C08DA', 'C08DB', 'C09AA', 'C09CA')
        OR (SUBSTRING(d.atc_code, 1, 5) = 'C08CA' AND d.atc_code NOT LIKE 'C08CA06%')
    )
    AND (o.agency_flag IS NULL OR o.agency_flag != 'Y')
    AND SUBSTRING(d.order_code, 8, 1) = '1'
    AND COALESCE(d.order_drug_day, d.drug_days, 0) > 0
GROUP BY q.quarter
ORDER BY q.quarter;

-- 【報表5】劑型驗證 (應全為口服)
SELECT 
    quarter as '季度',
    order_code_8th_digit as '醫令代碼第8碼',
    COUNT(*) as '案件數',
    SUM(drug_days) as '總給藥日數',
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY quarter), 2) as '占比_%'
FROM antihypertensive_drugs
GROUP BY quarter, order_code_8th_digit
ORDER BY quarter, order_code_8th_digit;

-- 【報表6】跨院重疊明細 (前100筆範例)
SELECT 
    quarter as '季度',
    patient_id as '病患ID',
    hospital_id_1 as '醫院1',
    hospital_id_2 as '醫院2',
    claim_id_1 as '處方1',
    claim_id_2 as '處方2',
    atc_class_1 as 'ATC類別1',
    atc_class_2 as 'ATC類別2',
    start_date_1 as '開始日期1',
    end_date_1 as '結束日期1',
    start_date_2 as '開始日期2',
    end_date_2 as '結束日期2',
    drug_days_1 as '給藥日數1',
    drug_days_2 as '給藥日數2',
    overlap_days as '跨院重疊日數'
FROM drug_overlaps
WHERE overlap_days > 0
ORDER BY quarter, patient_id, overlap_days DESC
LIMIT 100;

-- ============================================
-- 查詢結束
-- 指標代碼: 1713
-- 指標名稱: 跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服)
-- 
-- 【重點特色】
--   本指標計算「跨醫院」的用藥重疊，與指標3(同醫院)不同
--   關鍵條件: a.hospital_id != b.hospital_id
-- 
-- Code Systems (與指標5-10完全一致):
--   - SNOMEDCT: http://snomed.info/sct
--   - ATC: http://www.whocc.no/atc
--   - ActCode: http://terminology.hl7.org/CodeSystem/v3-ActCode
-- 
-- FHIR Resource Mapping:
--   - MedicationRequest (藥品處方)
--   - Encounter (就診記錄)
--   - Patient (病患資料)
--   - Organization (醫療機構)
-- ============================================
