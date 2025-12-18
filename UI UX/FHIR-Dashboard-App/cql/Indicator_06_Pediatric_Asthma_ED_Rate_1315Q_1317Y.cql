library Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1315(季)、1317(年)
// 條件依據：十八歲以下氣喘病人急診率
// 製作日期：2025-11-20
-- 
-- 【資料時間範圍】
-- 查詢期間: 2024-01-01 ~ 2025-11-08 (今天)
-- 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
-- ============================================

-- 【資料範圍】
-- 醫院總額之門住診案件，排除代辦案件

-- 【公式說明】(依健保指標代碼 1315/1317)
-- 十八歲以下氣喘病人急診率 = 
--     分子: 分母病人中因氣喘而急診就醫者，其急診就醫日期大於(跨院勾稽)為氣喘病患之日期的人數
--     分母: 18歲氣喘病患人數(符合下列任一項條件者視為氣喘病患):
--           a. 有1次(含)以上因氣喘急診就醫。
--           b. 有1次(含)以上因氣喘住院。
--           c. 統計期間有因氣喘之門診就醫，且前一年跨院勾稽有4次(含)以上之因氣喘門診就醫，
--              且其中有2次(含)以上有使用任一項氣喘用藥者。
--
-- (1)氣喘：主診斷ICD10-CM前三碼為J45。
--
-- (2)氣喘用藥：ATC藥品分類碼7為R03AC02、R03AC03、R03AC04、R03AC06、R03AC12、R03AC13、
--              R03AC16、R03AC18、R03BA01、R03BA02、R03BA05、R03BA08、R03AK06、R03AK07、
--              R03AK08、H02AB06、H02AB07、R03DC01、R03DC03、R03DA05。
--
-- (3)前一年：依月住前一年(含當月，若為9801則觀察9702~9801這段期間)。
--
-- (4)視為氣喘病患之日期：符合分母定義之案件最ID龍戶後，取第1筆資料作視為氣喘病患之日期。
--
-- 排除條件:
--   1.排除代辦案件
--   2.病人年齡 ≤ 18歲
--
-- ============================================

-- 備註:
-- 1.資料來源：醫療給付檔案分析系統，指標代碼：1315 (季)、1317 (年)
-- 
-- 2.資料範圍：醫院總額之門住診案件，排除代辦案件。
-- 
-- 3.公式說明：
--   分子：分母病人中因氣喘而急診就醫者，其急診就醫日期大於(跨院勾稽)為氣喘病患之日期的人數。
--   分母：18歲氣喘病患人數(符合下列任一項條件者視為氣喘病患):
--        a. 有1次(含)以上因氣喘急診就醫。
--        b. 有1次(含)以上因氣喘住院。
--        c. 統計期間有因氣喘之門診就醫，且前一年跨院勾稽有4次(含)以上之因氣喘門診就醫，
--           且其中有2次(含)以上有使用任一項氣喘用藥者。
-- 
--   (1)氣喘：主診斷ICD10-CM前三碼為J45。
--   (2)氣喘用藥：ATC藥品分類碼7為R03AC02、R03AC03、R03AC04、R03AC06、R03AC12、R03AC13、
--                R03AC16、R03AC18、R03BA01、R03BA02、R03BA05、R03BA08、R03AK06、R03AK07、
--                R03AK08、H02AB06、H02AB07、R03DC01、R03DC03、R03DA05。
--   (3)前一年：依月住前一年(含當月，若為9801則觀察9702~9801這段期間)。
--   (4)視為氣喘病患之日期：符合分母定義之案件最ID龍戶後，取第1筆資料作視為氣喘病患之日期。
-- 
-- 4.製表日期：114/05/13
-- 
-- 5.製表單位：衛生福利部 中央健康保險署
-- ============================================

-- CQL Code Systems Definition (依健保標準代碼對照國際標準)
codesystem "NHI_INDICATOR": 'NHI_INDICATOR'  -- 健保指標代碼系統
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'  -- ICD-10-CM 診斷代碼
codesystem "SNOMEDCT": 'http://snomed.info/sct'  -- SNOMED CT 臨床術語
codesystem "ATC": 'http://www.whocc.no/atc'  -- ATC 藥品分類代碼
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'  -- HL7 就醫類型代碼
codesystem "NHI": 'NHI'  -- 健保專用代碼系統
codesystem "NHI_ENCOUNTER_TYPE": 'NHI_ENCOUNTER_TYPE'  -- 健保就醫類別代碼
-- 
-- 註: 健保代碼與國際標準完全相容，支援 SMART on FHIR

-- FHIR Resource Mapping
-- Condition → diagnosis (氣喘診斷)
-- Encounter → encounter_details (急診、門診、住院記錄)
-- MedicationRequest → drug_details (氣喘用藥)
-- Patient → patient_master (病患年齡)

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
-- 依據健保指標代碼 1315 (季) / 1317 (年) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1315', '1315', 'NHI_INDICATOR', 'Emergency Visit Rate for Asthma Patients Under 18 - Quarterly - 十八歲以下氣喘病人急診率(季)'),
        ('INDICATOR', '1317', '1317', 'NHI_INDICATOR', 'Emergency Visit Rate for Asthma Patients Under 18 - Annual - 十八歲以下氣喘病人急診率(年)'),
        
        -- 氣喘診斷代碼 (ICD10-CM)
        ('DIAGNOSIS', 'J45', 'J45', 'http://hl7.org/fhir/sid/icd-10-cm', 'Asthma - 氣喘'),
        ('DIAGNOSIS', 'J45.0', 'J45.0', 'http://hl7.org/fhir/sid/icd-10-cm', 'Predominantly allergic asthma - 過敏性氣喘'),
        ('DIAGNOSIS', 'J45.1', 'J45.1', 'http://hl7.org/fhir/sid/icd-10-cm', 'Nonallergic asthma - 非過敏性氣喘'),
        ('DIAGNOSIS', 'J45.2', 'J45.2', 'http://hl7.org/fhir/sid/icd-10-cm', 'Mild intermittent asthma - 輕度間歇性氣喘'),
        ('DIAGNOSIS', 'J45.3', 'J45.3', 'http://hl7.org/fhir/sid/icd-10-cm', 'Mild persistent asthma - 輕度持續性氣喘'),
        ('DIAGNOSIS', 'J45.4', 'J45.4', 'http://hl7.org/fhir/sid/icd-10-cm', 'Moderate persistent asthma - 中度持續性氣喘'),
        ('DIAGNOSIS', 'J45.5', 'J45.5', 'http://hl7.org/fhir/sid/icd-10-cm', 'Severe persistent asthma - 重度持續性氣喘'),
        ('DIAGNOSIS', 'J45.9', 'J45.9', 'http://hl7.org/fhir/sid/icd-10-cm', 'Asthma, unspecified - 未明示氣喘'),
        
        -- 氣喘 SNOMED CT 對照
        ('DIAGNOSIS', 'J45', '195967001', 'http://snomed.info/sct', 'Asthma - 氣喘'),
        
        -- 氣喘用藥 ATC代碼 (20種)
        ('MEDICATION', 'R03AC02', 'R03AC02', 'http://www.whocc.no/atc', 'Salbutamol - 沙丁胺醇'),
        ('MEDICATION', 'R03AC03', 'R03AC03', 'http://www.whocc.no/atc', 'Terbutaline - 特布他林'),
        ('MEDICATION', 'R03AC04', 'R03AC04', 'http://www.whocc.no/atc', 'Fenoterol - 芬特羅'),
        ('MEDICATION', 'R03AC06', 'R03AC06', 'http://www.whocc.no/atc', 'Hexoprenaline - 海索普林'),
        ('MEDICATION', 'R03AC12', 'R03AC12', 'http://www.whocc.no/atc', 'Salmeterol - 沙美特羅'),
        ('MEDICATION', 'R03AC13', 'R03AC13', 'http://www.whocc.no/atc', 'Formoterol - 福莫特羅'),
        ('MEDICATION', 'R03AC16', 'R03AC16', 'http://www.whocc.no/atc', 'Indacaterol - 茚達特羅'),
        ('MEDICATION', 'R03AC18', 'R03AC18', 'http://www.whocc.no/atc', 'Vilanterol - 維蘭特羅'),
        ('MEDICATION', 'R03BA01', 'R03BA01', 'http://www.whocc.no/atc', 'Beclometasone - 倍氯米松'),
        ('MEDICATION', 'R03BA02', 'R03BA02', 'http://www.whocc.no/atc', 'Budesonide - 布地奈德'),
        ('MEDICATION', 'R03BA05', 'R03BA05', 'http://www.whocc.no/atc', 'Fluticasone - 氟替卡松'),
        ('MEDICATION', 'R03BA08', 'R03BA08', 'http://www.whocc.no/atc', 'Ciclesonide - 環索奈德'),
        ('MEDICATION', 'R03AK06', 'R03AK06', 'http://www.whocc.no/atc', 'Salmeterol and fluticasone - 沙美特羅+氟替卡松'),
        ('MEDICATION', 'R03AK07', 'R03AK07', 'http://www.whocc.no/atc', 'Formoterol and budesonide - 福莫特羅+布地奈德'),
        ('MEDICATION', 'R03AK08', 'R03AK08', 'http://www.whocc.no/atc', 'Formoterol and beclometasone - 福莫特羅+倍氯米松'),
        ('MEDICATION', 'H02AB06', 'H02AB06', 'http://www.whocc.no/atc', 'Prednisolone - 普賴鬆龍'),
        ('MEDICATION', 'H02AB07', 'H02AB07', 'http://www.whocc.no/atc', 'Prednisone - 潑尼松'),
        ('MEDICATION', 'R03DC01', 'R03DC01', 'http://www.whocc.no/atc', 'Cromoglicic acid - 色甘酸鈉'),
        ('MEDICATION', 'R03DC03', 'R03DC03', 'http://www.whocc.no/atc', 'Nedocromil - 奈多羅米'),
        ('MEDICATION', 'R03DA05', 'R03DA05', 'http://www.whocc.no/atc', 'Aminophylline - 氨茶鹼'),
        
        -- 就醫類型代碼 (HL7 ActCode)
        ('ENCOUNTER', 'E', 'EMER', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Emergency - 急診'),
        ('ENCOUNTER', 'EMER', 'EMER', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Emergency - 急診'),
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        ('ENCOUNTER', 'I', 'IMP', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Inpatient - 住院'),
        ('ENCOUNTER', 'IMP', 'IMP', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Inpatient encounter - 住院'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)'),
        ('AGENCY', 'N', 'N', 'NHI', 'Non-Agency Case - 非代辦案件')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選18歲以下病患
patients_under_18 AS (
    SELECT DISTINCT
        p.patient_id,
        p.birth_date,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birth_date)) as age
    FROM 
        patient_master p
    WHERE 
        -- 年齡 ≤ 18歲
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birth_date)) <= 18
),

-- 氣喘診斷案件 (主診斷ICD10-CM前三碼為J45)
asthma_encounters AS (
    SELECT 
        e.patient_id,
        e.encounter_id,
        e.encounter_type,  -- E=急診, O=門診, I=住院
        e.visit_date,
        e.primary_diagnosis,
        e.hospital_id
    FROM 
        encounter_details e
    WHERE 
        -- 主診斷前三碼為J45 (氣喘)
        SUBSTRING(e.primary_diagnosis, 1, 3) = 'J45'
        
        -- 排除代辦案件
        AND (e.agency_flag IS NULL OR e.agency_flag != 'Y')
        
        -- 醫院總額
        AND e.hospital_id IS NOT NULL
),

-- 條件a: 有1次(含)以上因氣喘急診就醫 (在統計期間內)
asthma_ed_visits AS (
    SELECT 
        q.quarter,
        ae.patient_id,
        MIN(ae.visit_date) as first_ed_date,
        COUNT(DISTINCT ae.encounter_id) as ed_visit_count
    FROM 
        quarters q
    CROSS JOIN 
        asthma_encounters ae
    INNER JOIN 
        patients_under_18 p ON ae.patient_id = p.patient_id
    WHERE 
        -- 急診案件 (E or EMER)
        ae.encounter_type IN ('E', 'EMER')
        
        -- 在該季內
        AND ae.visit_date BETWEEN q.start_date AND q.end_date
    GROUP BY 
        q.quarter, ae.patient_id
    HAVING 
        COUNT(DISTINCT ae.encounter_id) >= 1
),

-- 條件b: 有1次(含)以上因氣喘住院 (在統計期間內)
asthma_inpatient AS (
    SELECT 
        q.quarter,
        ae.patient_id,
        MIN(ae.visit_date) as first_inpatient_date,
        COUNT(DISTINCT ae.encounter_id) as inpatient_count
    FROM 
        quarters q
    CROSS JOIN 
        asthma_encounters ae
    INNER JOIN 
        patients_under_18 p ON ae.patient_id = p.patient_id
    WHERE 
        -- 住院案件 (I or IMP)
        ae.encounter_type IN ('I', 'IMP')
        
        -- 在該季內
        AND ae.visit_date BETWEEN q.start_date AND q.end_date
    GROUP BY 
        q.quarter, ae.patient_id
    HAVING 
        COUNT(DISTINCT ae.encounter_id) >= 1
),

-- 條件c: 統計期間有因氣喘門診 + 前一年跨院4次以上門診 + 其中2次以上有用藥
-- 步驟1: 當期氣喘門診
current_asthma_outpatient AS (
    SELECT 
        q.quarter,
        ae.patient_id,
        ae.visit_date,
        ae.encounter_id
    FROM 
        quarters q
    CROSS JOIN 
        asthma_encounters ae
    INNER JOIN 
        patients_under_18 p ON ae.patient_id = p.patient_id
    WHERE 
        -- 門診案件 (O or AMB)
        ae.encounter_type IN ('O', 'AMB')
        
        -- 在該季內
        AND ae.visit_date BETWEEN q.start_date AND q.end_date
),

-- 步驟2: 前一年氣喘門診 (跨院勾稽)
prior_year_asthma_outpatient AS (
    SELECT 
        q.quarter,
        ae.patient_id,
        ae.visit_date,
        ae.encounter_id,
        ae.hospital_id
    FROM 
        quarters q
    CROSS JOIN 
        asthma_encounters ae
    INNER JOIN 
        patients_under_18 p ON ae.patient_id = p.patient_id
    WHERE 
        -- 門診案件
        ae.encounter_type IN ('O', 'AMB')
        
        -- 前一年期間 (含當月往前推12個月)
        AND ae.visit_date BETWEEN 
            DATE_SUB(q.start_date, INTERVAL 12 MONTH) AND q.end_date
),

-- 步驟3: 前一年門診中有使用氣喘用藥的次數
prior_year_with_medication AS (
    SELECT 
        py.quarter,
        py.patient_id,
        py.encounter_id,
        CASE 
            WHEN d.atc_code_7 IN (
                'R03AC02', 'R03AC03', 'R03AC04', 'R03AC06', 'R03AC12', 'R03AC13',
                'R03AC16', 'R03AC18', 'R03BA01', 'R03BA02', 'R03BA05', 'R03BA08',
                'R03AK06', 'R03AK07', 'R03AK08', 'H02AB06', 'H02AB07', 'R03DC01',
                'R03DC03', 'R03DA05'
            ) THEN 1
            ELSE 0
        END as has_asthma_medication
    FROM 
        prior_year_asthma_outpatient py
    LEFT JOIN 
        drug_details d ON py.encounter_id = d.encounter_id
),

-- 步驟4: 計算前一年門診次數和用藥次數
prior_year_summary AS (
    SELECT 
        quarter,
        patient_id,
        COUNT(DISTINCT encounter_id) as prior_year_visit_count,
        SUM(has_asthma_medication) as medication_visit_count
    FROM 
        prior_year_with_medication
    GROUP BY 
        quarter, patient_id
),

-- 條件c完整: 當期有門診 + 前一年≥4次門診 + 其中≥2次有用藥
asthma_outpatient_with_criteria AS (
    SELECT 
        c.quarter,
        c.patient_id,
        MIN(c.visit_date) as first_outpatient_date
    FROM 
        current_asthma_outpatient c
    INNER JOIN 
        prior_year_summary py 
        ON c.quarter = py.quarter 
        AND c.patient_id = py.patient_id
    WHERE 
        -- 前一年有4次(含)以上門診
        py.prior_year_visit_count >= 4
        
        -- 其中有2次(含)以上有使用氣喘用藥
        AND py.medication_visit_count >= 2
    GROUP BY 
        c.quarter, c.patient_id
),

-- 合併分母: 符合a, b, c任一條件的氣喘病患
asthma_patients_denominator AS (
    SELECT 
        COALESCE(a.quarter, b.quarter, c.quarter) as quarter,
        COALESCE(a.patient_id, b.patient_id, c.patient_id) as patient_id,
        -- 取最早的日期作為"視為氣喘病患之日期"
        LEAST(
            COALESCE(a.first_ed_date, '9999-12-31'),
            COALESCE(b.first_inpatient_date, '9999-12-31'),
            COALESCE(c.first_outpatient_date, '9999-12-31')
        ) as asthma_patient_date
    FROM 
        asthma_ed_visits a
    FULL OUTER JOIN 
        asthma_inpatient b 
        ON a.quarter = b.quarter AND a.patient_id = b.patient_id
    FULL OUTER JOIN 
        asthma_outpatient_with_criteria c 
        ON COALESCE(a.quarter, b.quarter) = c.quarter 
        AND COALESCE(a.patient_id, b.patient_id) = c.patient_id
),

-- 分子: 分母病人中因氣喘而急診就醫者，且急診日期 > 氣喘病患日期
asthma_ed_after_diagnosis AS (
    SELECT 
        d.quarter,
        d.patient_id,
        COUNT(DISTINCT ae.encounter_id) as ed_visits_after_diagnosis
    FROM 
        asthma_patients_denominator d
    INNER JOIN 
        asthma_encounters ae 
        ON d.patient_id = ae.patient_id
    WHERE 
        -- 急診案件
        ae.encounter_type IN ('E', 'EMER')
        
        -- 急診日期 > 氣喘病患日期 (跨院勾稽)
        AND ae.visit_date > d.asthma_patient_date
        
        -- 在該季或之後
        AND ae.visit_date <= (SELECT end_date FROM quarters WHERE quarter = d.quarter)
    GROUP BY 
        d.quarter, d.patient_id
),

-- 計算每季的統計數據
quarterly_summary AS (
    SELECT 
        q.quarter,
        -- 分母: 18歲以下氣喘病患人數
        COUNT(DISTINCT d.patient_id) as total_asthma_patients,
        -- 分子: 因氣喘而急診的病患人數
        COUNT(DISTINCT n.patient_id) as patients_with_ed_visits,
        -- 急診率 (%)
        CASE 
            WHEN COUNT(DISTINCT d.patient_id) > 0 THEN 
                ROUND(COUNT(DISTINCT n.patient_id) * 100.0 / COUNT(DISTINCT d.patient_id), 2)
            ELSE 0
        END as ed_rate,
        -- 統計數量
        COUNT(DISTINCT d.patient_id) as total_patients_under_18,
        -- 總急診次數
        SUM(COALESCE(n.ed_visits_after_diagnosis, 0)) as total_ed_visits
    FROM 
        quarters q
    LEFT JOIN 
        asthma_patients_denominator d ON q.quarter = d.quarter
    LEFT JOIN 
        asthma_ed_after_diagnosis n 
        ON d.quarter = n.quarter AND d.patient_id = n.patient_id
    GROUP BY 
        q.quarter
)

-- 最終結果輸出
SELECT 
    quarter as '季度',
    total_asthma_patients as '18歲以下氣喘病患人數(分母)',
    patients_with_ed_visits as '因氣喘急診病患人數(分子)',
    ed_rate as '十八歲以下氣喘病人急診率(%)',
    total_ed_visits as '總急診次數',
    total_patients_under_18 as '18歲以下總病患數'
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
-- 預期急診率範圍: 依醫療行為而定，需實際數據驗證
-- ============================================

-- ============================================
-- 氣喘病患定義說明
-- ============================================
-- 符合以下任一條件即視為氣喘病患:
--
-- 條件a: 有1次(含)以上因氣喘急診就醫
--   - 主診斷ICD10-CM前三碼為J45
--   - 就醫類型為急診 (E or EMER)
--   - 在統計期間內
--
-- 條件b: 有1次(含)以上因氣喘住院
--   - 主診斷ICD10-CM前三碼為J45
--   - 就醫類型為住院 (I or IMP)
--   - 在統計期間內
--
-- 條件c: 門診就醫 + 前一年門診 + 用藥 (三個條件需同時滿足)
--   1. 統計期間有因氣喘之門診就醫
--   2. 前一年跨院勾稽有4次(含)以上之因氣喘門診就醫
--   3. 其中有2次(含)以上有使用任一項氣喘用藥
--
-- 氣喘診斷: 主診斷ICD10-CM前三碼為J45
-- ============================================

-- ============================================
-- 氣喘用藥說明 (20種ATC代碼)
-- ============================================
-- R03AC02: Salbutamol (沙丁胺醇) - 短效β2激動劑
-- R03AC03: Terbutaline (特布他林) - 短效β2激動劑
-- R03AC04: Fenoterol (芬特羅) - 短效β2激動劑
-- R03AC06: Hexoprenaline (海索普林) - 短效β2激動劑
-- R03AC12: Salmeterol (沙美特羅) - 長效β2激動劑
-- R03AC13: Formoterol (福莫特羅) - 長效β2激動劑
-- R03AC16: Indacaterol (茚達特羅) - 長效β2激動劑
-- R03AC18: Vilanterol (維蘭特羅) - 長效β2激動劑
-- R03BA01: Beclometasone (倍氯米松) - 吸入型類固醇
-- R03BA02: Budesonide (布地奈德) - 吸入型類固醇
-- R03BA05: Fluticasone (氟替卡松) - 吸入型類固醇
-- R03BA08: Ciclesonide (環索奈德) - 吸入型類固醇
-- R03AK06: Salmeterol + Fluticasone (沙美特羅+氟替卡松) - 複方吸入劑
-- R03AK07: Formoterol + Budesonide (福莫特羅+布地奈德) - 複方吸入劑
-- R03AK08: Formoterol + Beclometasone (福莫特羅+倍氯米松) - 複方吸入劑
-- H02AB06: Prednisolone (普賴鬆龍) - 口服類固醇
-- H02AB07: Prednisone (潑尼松) - 口服類固醇
-- R03DC01: Cromoglicic acid (色甘酸鈉) - 肥大細胞穩定劑
-- R03DC03: Nedocromil (奈多羅米) - 肥大細胞穩定劑
-- R03DA05: Aminophylline (氨茶鹼) - 支氣管擴張劑
-- ============================================

-- ============================================
-- 分子計算說明
-- ============================================
-- 分子條件:
-- 1. 必須是分母中的氣喘病患
-- 2. 有因氣喘的急診就醫記錄
-- 3. 急診日期 > "視為氣喘病患之日期"
--
-- "視為氣喘病患之日期"定義:
-- - 符合分母定義(a/b/c)的第一筆案件日期
-- - 取最早的日期
--
-- 跨院勾稽:
-- - 計算時需考慮所有醫院的就醫記錄
-- - 不限於單一醫院
-- ============================================

-- ============================================
-- 前一年定義說明
-- ============================================
-- 前一年: 依月住前一年(含當月)
--
-- 範例:
-- - 若統計期間為2024Q2 (2024-04-01 ~ 2024-06-30)
-- - 前一年為: 2023-04-01 ~ 2024-06-30 (往前推12個月，含當月)
--
-- 若為台灣民國年:
-- - 9801 → 觀察 9702~9801 (98年1月往前推至97年2月)
-- ============================================

-- ============================================
-- 排除條件說明
-- ============================================
-- 1. 排除代辦案件
--    - agency_flag = 'Y' 的案件應排除
--    - 代辦案件不計入統計
--
-- 2. 年齡限制
--    - 僅納入年齡 ≤ 18歲的病患
--    - 年齡計算以當前日期為準
--
-- 原因:
-- - 確保統計數據的準確性
-- - 本指標專注於兒童及青少年氣喘病患
-- - 符合健保署統計規範
-- ============================================

-- ============================================
-- 代碼系統對照
-- ============================================
-- NHI_INDICATOR: 健保指標代碼 (1315季/1317年)
-- ICD10CM: http://hl7.org/fhir/sid/icd-10-cm (J45*)
-- SNOMEDCT: http://snomed.info/sct (195967001氣喘)
-- ATC: http://www.whocc.no/atc (20種氣喘用藥)
-- ActCode: http://terminology.hl7.org/CodeSystem/v3-ActCode (EMER/AMB/IMP)
-- NHI: 健保專用代碼 (代辦案件標記等)
-- NHI_ENCOUNTER_TYPE: 健保就醫類別代碼 (E/O/I)
-- ============================================

-- ============================================
-- 臨床意義
-- ============================================
-- 本指標用於監測兒童氣喘控制品質:
-- 
-- 1. 氣喘控制評估:
--    - 急診率高表示氣喘控制不佳
--    - 需加強預防性治療
--    - 改善病患衛教與用藥遵從性
--
-- 2. 醫療品質指標:
--    - 評估基層醫療照護品質
--    - 監測預防性用藥使用情況
--    - 減少急性發作頻率
--
-- 3. 公共衛生意義:
--    - 降低兒童氣喘急診率
--    - 提升慢性病管理成效
--    - 減少醫療資源浪費
--
-- 建議:
-- - 急診率過高需檢討氣喘照護計畫
-- - 加強病患與家屬衛教
-- - 提升預防性用藥遵從性
-- - 定期追蹤與評估
-- ============================================

-- ============================================
-- FHIR Resource 對照
-- ============================================
-- Condition:
--   - 氣喘診斷
--   - code: ICD10-CM J45* 或 SNOMED CT 195967001
--   - clinicalStatus: active
--
-- Encounter:
--   - 就醫記錄
--   - class: EMER (急診) / AMB (門診) / IMP (住院)
--   - period: 就醫日期
--   - diagnosis: 主診斷
--
-- MedicationRequest:
--   - 氣喘用藥處方
--   - medicationCodeableConcept: ATC代碼
--   - authoredOn: 處方日期
--
-- Patient:
--   - 病患基本資料
--   - birthDate: 出生日期 (計算年齡)
--   - 年齡 ≤ 18歲
-- ============================================
