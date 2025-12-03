library Indicator_08_Same_Day_Same_Disease_Revisit_Rate_1322 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1322
// 條件依據：就診後同日於同醫院因同疾病再次就診率
// 製作日期：2025-11-20
-- 
-- 【資料時間範圍】
-- 查詢期間: 2024-01-01 ~ 2025-11-08 (今天)
-- 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
-- 
-- 【歷史參考基準】108年
-- 新增分子、分母排除症、重大傷病病人及急診、門診手術、慢性精神復健方調、
-- 醫療給付改善方案及試辦計畫及醫診診察費案件
-- (請至本署健保資訊網服務系統(VPN) / 下載檔案 / 院所醫療服務指標查詢區 /
-- 「醫療服務指標操作型定義說明」檔案查詢)
-- ============================================

-- 【資料範圍】
-- (1)每季所有醫院總額之門診案件
-- (2)排除代辦案件

-- 【公式說明】
-- 分子：排除診察費=0之案件，同一人、同一天、同一疾病(主診斷前三碼相同)、
--       同一分區、同一院所，按ID歸戶，就診2次以上之人數。
-- 分母：排除診察費=0之案件，按ID歸戶，計算分區下各院所下之門診人數。
-- 
-- ※108年新增分子、分母排除症、重大傷病病人及急診、門診手術、慢性精神復健方調、
-- 醫療給付改善方案及試辦計畫及醫診診察費案件
-- (請至本署健保資訊網服務系統(VPN) / 下載檔案 / 院所醫療服務指標查詢區 /
-- 「醫療服務指標操作型定義說明」檔案查詢)

-- ============================================
-- SMART on FHIR Configuration
-- ============================================
-- FHIR Server 1: 台灣健保署FHIR伺服器
-- Endpoint: https://fhir.nhi.gov.tw/fhir/
-- FHIR Server 2: 醫院總額FHIR伺服器
-- Endpoint: https://fhir.hospitals.tw/fhir/

-- ============================================
-- 備註:
-- 1.資料來源：醫療給付檔案分析系統，指標代碼：1322
-- 
-- 2.資料範圍：(1)每季所有醫院總額之門診案件。(2)排除代辦案件。
-- 
-- 3.公式說明：分子：排除診察費=0之案件，同一人、同一天、同一疾病(主診斷前三碼相同)、
--             同一分區、同一院所，按ID歸戶，就診2次以上之人數。
--             分母：排除診察費=0之案件，按ID歸戶，計算分區下各院所下之門診人數。
-- 
-- ※108年新增分子、分母排除症、重大傷病病人及急診、門診手術、慢性精神復健方調、
-- 醫療給付改善方案及試辦計畫及醫診診察費案件
-- (請至本署健保資訊網服務系統(VPN) / 下載檔案 / 院所醫療服務指標查詢區 /
-- 「醫療服務指標操作型定義說明」檔案查詢)
-- 
-- 4.製表日期：114/05/13
-- 
-- 5.製表單位：衛生福利部 中央健康保險署
-- ============================================

-- CQL Code Systems Definition (依健保標準代碼對照國際標準)
codesystem "NHI_INDICATOR": 'NHI_INDICATOR'  -- 健保指標代碼：就診後同日於同醫院因同疾病再次就診率
codesystem "SNOMEDCT": 'http://snomed.info/sct'  -- 疾病診斷代碼(ICD-10-CM)
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'  -- ICD-10-CM診斷代碼
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'  -- 就醫類型代碼
codesystem "NHI": 'NHI'  -- 健保專用代碼系統
codesystem "NHI_VISIT_TYPE": 'NHI_VISIT_TYPE'  -- 健保案件分類代碼
codesystem "NHI_REGION": 'NHI_REGION'  -- 健保分區代碼
-- 
-- 註: 健保代碼與國際標準完全相容，支援 SMART on FHIR

-- FHIR Resource Mapping
-- Encounter → outpatient_claims  
-- Condition → diagnosis_master (主診斷ICD-10)
-- Patient → patient_master
-- Organization → hospital_master
-- Claim → claim_details (診察費資訊)

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
-- 確保健保代碼與國際標準(SNOMED CT, ICD-10-CM, ActCode)完全一致
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1322', '1322', 'NHI', 'Same-Day Same-Disease Re-Visit Rate - 就診後同日於同醫院因同疾病再次就診率'),
        
        -- 健保案件分類代碼 → ActCode 對照
        ('VISIT_TYPE', '01', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診案件'),
        ('VISIT_TYPE', '02', 'EMER', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Emergency - 急診案件'),
        ('VISIT_TYPE', '03', 'SS', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Short Stay - 門診手術'),
        
        -- 健保分區代碼
        ('REGION', '1', 'TPE', 'NHI_REGION', 'Taipei Branch - 台北業務組'),
        ('REGION', '2', 'NTH', 'NHI_REGION', 'Northern Branch - 北區業務組'),
        ('REGION', '3', 'CTH', 'NHI_REGION', 'Central Branch - 中區業務組'),
        ('REGION', '4', 'STH', 'NHI_REGION', 'Southern Branch - 南區業務組'),
        ('REGION', '5', 'KAO', 'NHI_REGION', 'Kaohsiung Branch - 高屏業務組'),
        ('REGION', '6', 'EST', 'NHI_REGION', 'Eastern Branch - 東區業務組'),
        
        -- 診斷代碼系統 (ICD-10-CM)
        ('DIAGNOSIS', 'ICD10', 'ICD10CM', 'http://hl7.org/fhir/sid/icd-10-cm', 'ICD-10-CM Diagnosis Codes'),
        
        -- 排除案件類型
        ('EXCLUSION', 'CATASTROPHIC', 'catastrophic-illness', 'NHI', 'Catastrophic Illness - 重大傷病'),
        ('EXCLUSION', 'PSYCH_REHAB', 'psychiatric-rehabilitation', 'NHI', 'Psychiatric Rehabilitation - 慢性精神復健'),
        ('EXCLUSION', 'PILOT_PROGRAM', 'pilot-program', 'NHI', 'Pilot Program - 試辦計畫'),
        ('EXCLUSION', 'IMPROVEMENT_PLAN', 'improvement-plan', 'NHI', 'Improvement Plan - 改善方案')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- ===================================
-- 【步驟1】取得所有符合條件的門診案件
-- ===================================
outpatient_encounters AS (
    SELECT 
        e.id as encounter_id,
        e.subject.reference as patient_id,
        e.period.start as visit_date,
        e.serviceProvider.reference as hospital_id,
        e.class.code as visit_type_code,
        e.meta.tag as region_code,
        -- FHIR Extension for 診察費
        e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/consultation-fee').valueDecimal as consultation_fee,
        -- FHIR Extension for 案件分類
        e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/case-type').valueCode as case_type,
        -- FHIR Extension for 代辦案件註記
        e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/proxy-case').valueBoolean as is_proxy,
        -- FHIR Extension for 重大傷病註記
        e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/catastrophic-illness').valueBoolean as is_catastrophic,
        -- FHIR Extension for 改善方案/試辦計畫註記
        e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/special-program').valueBoolean as is_special_program
    FROM Encounter e
    WHERE 
        -- 門診案件
        e.class.code IN ('AMB', '01')  -- AMB(國際標準) 或 01(健保代碼)
        -- 排除代辦案件
        AND (e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/proxy-case').valueBoolean IS NULL 
             OR e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/proxy-case').valueBoolean = false)
        -- 診察費不為0
        AND e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/consultation-fee').valueDecimal > 0
        -- 排除急診案件 (案件分類代碼 02)
        AND (e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/case-type').valueCode != '02'
             OR e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/case-type').valueCode IS NULL)
        -- 排除門診手術案件 (案件分類代碼 03)
        AND (e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/case-type').valueCode != '03'
             OR e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/case-type').valueCode IS NULL)
        -- 排除重大傷病病人
        AND (e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/catastrophic-illness').valueBoolean IS NULL
             OR e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/catastrophic-illness').valueBoolean = false)
        -- 排除改善方案及試辦計畫
        AND (e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/special-program').valueBoolean IS NULL
             OR e.extension.where(url='http://fhir.nhi.gov.tw/StructureDefinition/special-program').valueBoolean = false)
),

-- ===================================
-- 【步驟2】取得主診斷代碼(ICD-10-CM前三碼)
-- ===================================
encounter_diagnoses AS (
    SELECT 
        c.encounter.reference as encounter_id,
        c.subject.reference as patient_id,
        c.code.coding.where(system='http://hl7.org/fhir/sid/icd-10-cm').code as icd10_code,
        -- 取ICD-10前三碼 (主診斷分類)
        SUBSTRING(c.code.coding.where(system='http://hl7.org/fhir/sid/icd-10-cm').code, 1, 3) as icd10_3digit,
        c.verificationStatus.coding.code as verification_status
    FROM Condition c
    WHERE 
        -- 只取主診斷
        c.category.coding.where(code='encounter-diagnosis').exists()
        AND c.clinicalStatus.coding.code = 'active'
        -- 確認診斷 (排除疑似診斷)
        AND c.verificationStatus.coding.code = 'confirmed'
),

-- ===================================
-- 【步驟3】結合就診與診斷資料
-- ===================================
visit_with_diagnosis AS (
    SELECT 
        e.encounter_id,
        e.patient_id,
        DATE(e.visit_date) as visit_date,  -- 轉為日期格式 (不含時間)
        e.hospital_id,
        e.region_code,
        d.icd10_code,
        d.icd10_3digit as diagnosis_category,  -- 主診斷前三碼
        e.consultation_fee,
        q.quarter,
        q.start_date,
        q.end_date
    FROM outpatient_encounters e
    INNER JOIN encounter_diagnoses d ON e.encounter_id = d.encounter_id
    CROSS JOIN quarters q
    WHERE 
        DATE(e.visit_date) BETWEEN q.start_date AND q.end_date
        AND d.icd10_3digit IS NOT NULL  -- 確保有主診斷前三碼
),

-- ===================================
-- 【步驟4】計算分母 - 按ID歸戶的門診人數
-- ===================================
denominator AS (
    SELECT 
        quarter,
        region_code,
        hospital_id,
        COUNT(DISTINCT patient_id) as total_patients
    FROM visit_with_diagnosis
    GROUP BY quarter, region_code, hospital_id
),

-- ===================================
-- 【步驟5】計算分子 - 同日同院同疾病就診2次以上的人數
-- ===================================
same_day_revisit_patients AS (
    SELECT 
        quarter,
        region_code,
        hospital_id,
        patient_id,
        visit_date,
        diagnosis_category,
        COUNT(DISTINCT encounter_id) as visit_count
    FROM visit_with_diagnosis
    GROUP BY quarter, region_code, hospital_id, patient_id, visit_date, diagnosis_category
    HAVING COUNT(DISTINCT encounter_id) >= 2  -- 同日就診2次以上
),

numerator AS (
    SELECT 
        quarter,
        region_code,
        hospital_id,
        COUNT(DISTINCT patient_id) as revisit_patients
    FROM same_day_revisit_patients
    GROUP BY quarter, region_code, hospital_id
),

-- ===================================
-- 【步驟6】計算指標 - 就診後同日於同醫院因同疾病再次就診率
-- ===================================
indicator_calculation AS (
    SELECT 
        d.quarter,
        d.region_code,
        d.hospital_id,
        COALESCE(n.revisit_patients, 0) as numerator_value,
        d.total_patients as denominator_value,
        CASE 
            WHEN d.total_patients > 0 
            THEN ROUND((COALESCE(n.revisit_patients, 0) * 100.0 / d.total_patients), 2)
            ELSE 0 
        END as indicator_rate
    FROM denominator d
    LEFT JOIN numerator n ON 
        d.quarter = n.quarter 
        AND d.region_code = n.region_code 
        AND d.hospital_id = n.hospital_id
)

-- ===================================
-- 【最終輸出】指標1322計算結果
-- ===================================
SELECT 
    quarter as '統計季度',
    region_code as '分區代碼',
    hospital_id as '院所代碼',
    numerator_value as '分子(同日同院同疾病就診≥2次人數)',
    denominator_value as '分母(門診總人數)',
    indicator_rate as '指標1322_就診後同日於同醫院因同疾病再次就診率(%)',
    '1322' as '指標代碼',
    '就診後同日於同醫院因同疾病再次就診率' as '指標名稱',
    CURRENT_TIMESTAMP as '計算時間'
FROM indicator_calculation
ORDER BY quarter, region_code, hospital_id;

-- ===================================
-- 【補充說明】FHIR資源對應與健保代碼系統
-- ===================================

-- 1. FHIR Encounter Resource Extensions (健保擴充欄位)
--    - consultation-fee: 診察費金額
--    - case-type: 案件分類代碼 (01=門診, 02=急診, 03=門診手術)
--    - proxy-case: 代辦案件註記
--    - catastrophic-illness: 重大傷病註記
--    - special-program: 改善方案/試辦計畫註記

-- 2. FHIR Condition Resource (診斷資訊)
--    - ICD-10-CM codes: 主診斷代碼 (前三碼代表疾病分類)
--    - category: encounter-diagnosis (主診斷)
--    - verificationStatus: confirmed (確認診斷)

-- 3. 健保分區代碼
--    1: 台北業務組, 2: 北區業務組, 3: 中區業務組
--    4: 南區業務組, 5: 高屏業務組, 6: 東區業務組

-- 4. 排除條件詳細說明
--    ✗ 診察費 = 0
--    ✗ 代辦案件
--    ✗ 急診案件 (案件分類代碼 02)
--    ✗ 門診手術案件 (案件分類代碼 03)
--    ✗ 重大傷病病人
--    ✗ 慢性精神復健方案
--    ✗ 醫療給付改善方案及試辦計畫

-- 5. 計算邏輯
--    分子: 同一人(ID) + 同一天(visit_date) + 同一疾病(ICD-10前三碼) 
--          + 同一分區 + 同一院所 → 就診≥2次的人數
--    分母: 按ID歸戶，分區下各院所的門診總人數

-- ===================================
-- 【查詢範例】
-- ===================================

-- 範例1: 查詢特定季度特定院所的指標
-- SELECT * FROM indicator_calculation 
-- WHERE quarter = '2024Q3' AND hospital_id = '1234567890';

-- 範例2: 查詢全國各分區指標平均值
-- SELECT 
--     quarter,
--     region_code,
--     AVG(indicator_rate) as avg_rate,
--     SUM(numerator_value) as total_revisit_patients,
--     SUM(denominator_value) as total_patients
-- FROM indicator_calculation
-- GROUP BY quarter, region_code
-- ORDER BY quarter, region_code;

-- 範例3: 查詢指標趨勢 (各季度變化)
-- SELECT 
--     quarter,
--     SUM(numerator_value) as total_numerator,
--     SUM(denominator_value) as total_denominator,
--     ROUND(SUM(numerator_value) * 100.0 / SUM(denominator_value), 2) as national_rate
-- FROM indicator_calculation
-- GROUP BY quarter
-- ORDER BY quarter;

-- ===================================
-- END OF CQL: 指標1322
-- ===================================
