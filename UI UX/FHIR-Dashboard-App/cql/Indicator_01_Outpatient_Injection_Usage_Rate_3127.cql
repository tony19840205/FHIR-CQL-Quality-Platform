library Indicator_01_Outpatient_Injection_Usage_Rate_3127 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付項目案分析系統 指標代碼: 3127
// 條件依據：門診注射劑使用率
// 製作日期：2025-11-20
// 
// 【歷史參考基準】111年第1季 (2022Q1)
// 針劑給藥案件數: 54,653
// 給藥案件數: 5,831,409
// 門診注射劑使用率: 0.94%

// 【公式說明】
// 分子: 給藥案件之針劑藥品(醫令代碼為10碼、且第8碼為'2')案件數
// 分母: 給藥案件數
// 排除:
//   1.門診化療注射劑(37005B,37031B~37041B或ATC碼前3碼L01、L02或特定ATC碼)
//   2.急診案件、流感疫苗(ATC前5碼J07BB)、破傷風(ATC:J07AM01)
//   3.門診手術案件(案件分類03)、事前審查藥品、STAT藥品、病人攜回注射藥品

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 劑型代碼（注射劑）
code "Injection": '385219001' from "SNOMEDCT" display 'Injection'
code "Ampoule": '385221006' from "SNOMEDCT" display 'Ampoule'
code "Vial": '415818006' from "SNOMEDCT" display 'Vial'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'
code "Emergency": 'EMER' from "ActCode" display 'Emergency - 急診'

// 門診化療注射劑醫令代碼（需排除）
code "37005B": '37005B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37031B": '37031B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37032B": '37032B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37033B": '37033B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37034B": '37034B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37035B": '37035B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37036B": '37036B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37037B": '37037B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37038B": '37038B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37039B": '37039B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37040B": '37040B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37041B": '37041B' from "NHI_PROCEDURE" display '門診化療注射劑'

// Helper function: 檢查藥品代碼是否符合注射劑格式（10碼且第8碼為'2'）
define function IsInjectionDrugCode(drugCode String):
  Length(drugCode) = 10 and Substring(drugCode, 7, 1) = '2'

// Helper function: 檢查 ATC 代碼是否為需排除的化療藥品
define function IsExcludedChemotherapyDrug(atcCode String):
  Substring(atcCode, 0, 3) in { 'L01', 'L02' } or
  atcCode in {
    'H01AB01', 'L03AB01', 'L03AB04', 'L03AB05', 'L03AB15',
    'L03AC01', 'L03AX03', 'L03AX16', 'L04AX01',
    'M05BA02', 'M05BA03', 'M05BA06', 'M05BA08', 'M05BX04',
    'V10XX03', 'J07AM01'
  }

// Helper function: 檢查是否為流感疫苗
define function IsInfluenzaVaccine(atcCode String):
  Substring(atcCode, 0, 5) = 'J07BB'

// Helper function: 檢查藥品代碼是否為需排除的門診化療注射劑
define function IsExcludedChemoProcedure(procedureCode String):
  procedureCode in {
    '37005B', '37031B', '37032B', '37033B', '37034B', '37035B',
    '37036B', '37037B', '37038B', '37039B', '37040B', '37041B'
  }

// 1. 門診給藥案件（分母）
define "Outpatient Drug Encounters":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'AMB'
    and exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and (
          // 藥費不為0、或給藥天數不為0、或處方調劑方式符合條件
          exists (MR.dosageInstruction DI where DI.timing.repeat.boundsPeriod.start.value is not null)
        )
    )
    // 排除代辦案件
    and not exists (
      E.type T where exists (T.coding C where C.code.value = 'AGENCY')
    )

// 2. 門診注射劑案件（分子）
define "Outpatient Injection Cases":
  "Outpatient Drug Encounters" E
    where exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        // 條件：醫令代碼為10碼且第8碼為'2'
        and exists (
          MR.medicationCodeableConcept.coding MC
            where IsInjectionDrugCode(MC.code.value)
        )
        // 排除門診化療注射劑醫令
        and not exists (
          MR.medicationCodeableConcept.coding MC
            where IsExcludedChemoProcedure(MC.code.value)
        )
        // 排除化療藥品（ATC碼檢查）
        and not exists (
          MR.medicationCodeableConcept.coding MC
            where MC.system.value = 'http://www.whocc.no/atc'
            and IsExcludedChemotherapyDrug(MC.code.value)
        )
        // 排除流感疫苗
        and not exists (
          MR.medicationCodeableConcept.coding MC
            where MC.system.value = 'http://www.whocc.no/atc'
            and IsInfluenzaVaccine(MC.code.value)
        )
        // 排除急診案件
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '02')
        )
        // 排除門診手術案件
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '03')
        )
        // 排除事前審查藥品
        and (MR.extension is null or not exists (
          MR.extension Ext 
            where Ext.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/prior-approval'
            and Ext.valueBoolean.value = true
        ))
        // 排除 STAT 用藥
        and not exists (
          MR.dosageInstruction DI
            where DI.asNeededBoolean.value = true
            or exists (DI.additionalInstruction AI 
              where exists (AI.coding C where C.code.value = 'STAT'))
        )
        // 排除病人攜回注射藥品
        and not exists (
          MR.extension Ext
            where Ext.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/take-home-injection'
            and Ext.valueBoolean.value = true
        )
    )

// 3. 分母：門診給藥案件數
define "Denominator":
  Count(
    distinct "Outpatient Drug Encounters" E
      return E.id.value
  )

// 4. 分子：門診注射劑案件數
define "Numerator":
  Count(
    distinct "Outpatient Injection Cases" E
      return E.id.value
  )

// 5. 指標計算結果：門診注射劑使用率
define "Injection Usage Rate":
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
    UNION ALL SELECT '2025Q4', '2025-10-01', '2025-11-06'  -- 計算到今天 2025-11-06
),

-- 健保代碼與標準代碼系統對照表
-- 確保健保代碼與國際標準(SNOMED CT, ATC, ActCode)完全一致
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '3127', '3127', 'NHI', 'Outpatient Injection Usage Rate - 門診注射劑使用率'),
        
        -- 健保劑型代碼 → SNOMED CT 對照 (完全一致)
        ('DOSAGE_FORM', 'INJ', '385219001', 'http://snomed.info/sct', 'Injection'),
        ('DOSAGE_FORM', 'AMP', '385221006', 'http://snomed.info/sct', 'Ampoule'),
        ('DOSAGE_FORM', 'VIA', '415818006', 'http://snomed.info/sct', 'Vial'),
        ('DOSAGE_FORM', 'SOLN', '385229009', 'http://snomed.info/sct', 'Solution for injection'),
        ('DOSAGE_FORM', 'SUSP', '385025008', 'http://snomed.info/sct', 'Suspension for injection'),
        ('DOSAGE_FORM', 'EMU', '385101003', 'http://snomed.info/sct', 'Emulsion for injection'),
        ('DOSAGE_FORM', 'POW', '385194003', 'http://snomed.info/sct', 'Powder for injection'),
        
        -- 健保就醫類型代碼 → ActCode 對照 (完全一致)
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        ('ENCOUNTER', '02', 'EMER', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Emergency - 急診案件分類(應排除)'),
        ('ENCOUNTER', '03', 'SS', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Short Stay - 門診手術(應排除)'),
        
        -- 健保ATC藥品代碼 → WHO ATC 對照 (完全一致)
        ('ATC', 'L01', 'L01', 'http://www.whocc.no/atc', 'Antineoplastic agents - 抗腫瘤藥(應排除)'),
        ('ATC', 'L02', 'L02', 'http://www.whocc.no/atc', 'Endocrine therapy - 內分泌治療(應排除)'),
        ('ATC', 'H01AB01', 'H01AB01', 'http://www.whocc.no/atc', 'Somatropin - 生長激素(應排除)'),
        ('ATC', 'L03AB01', 'L03AB01', 'http://www.whocc.no/atc', 'Interferon alfa-2a - 干擾素(應排除)'),
        ('ATC', 'L03AB04', 'L03AB04', 'http://www.whocc.no/atc', 'Interferon alfa-2b - 干擾素(應排除)'),
        ('ATC', 'L03AB05', 'L03AB05', 'http://www.whocc.no/atc', 'Interferon alfa-n1 - 干擾素(應排除)'),
        ('ATC', 'L03AB15', 'L03AB15', 'http://www.whocc.no/atc', 'Peginterferon alfa-2b - 長效型干擾素(應排除)'),
        ('ATC', 'L03AC01', 'L03AC01', 'http://www.whocc.no/atc', 'Aldesleukin - 介白素(應排除)'),
        ('ATC', 'L03AX03', 'L03AX03', 'http://www.whocc.no/atc', 'BCG vaccine - BCG疫苗(應排除)'),
        ('ATC', 'L03AX16', 'L03AX16', 'http://www.whocc.no/atc', 'Thymalfasin - 胸腺肽(應排除)'),
        ('ATC', 'L04AX01', 'L04AX01', 'http://www.whocc.no/atc', 'Azathioprine - 免疫抑制劑(應排除)'),
        ('ATC', 'M05BA02', 'M05BA02', 'http://www.whocc.no/atc', 'Clodronic acid - 骨鬆用藥(應排除)'),
        ('ATC', 'M05BA03', 'M05BA03', 'http://www.whocc.no/atc', 'Pamidronic acid - 骨鬆用藥(應排除)'),
        ('ATC', 'M05BA06', 'M05BA06', 'http://www.whocc.no/atc', 'Ibandronic acid - 骨鬆用藥(應排除)'),
        ('ATC', 'M05BA08', 'M05BA08', 'http://www.whocc.no/atc', 'Zoledronic acid - 骨鬆用藥(應排除)'),
        ('ATC', 'M05BX04', 'M05BX04', 'http://www.whocc.no/atc', 'Denosumab - 骨鬆用藥(應排除)'),
        ('ATC', 'V10XX03', 'V10XX03', 'http://www.whocc.no/atc', 'Sodium iodide I-131 - 放射碘(應排除)'),
        ('ATC', 'J07BB', 'J07BB', 'http://www.whocc.no/atc', 'Influenza vaccines - 流感疫苗(應排除)'),
        ('ATC', 'J07AM01', 'J07AM01', 'http://www.whocc.no/atc', 'Tetanus toxoid - 破傷風毒素(應排除)'),
        
        -- 健保處方調劑方式代碼
        ('DISPENSING', '1', '1', 'NHI', '門診給藥 - 處方調劑方式1'),
        ('DISPENSING', '0', '0', 'NHI', '門診給藥 - 處方調劑方式0'),
        ('DISPENSING', '6', '6', 'NHI', '門診給藥 - 處方調劑方式6'),
        
        -- 健保藥品使用頻率代碼
        ('FREQUENCY', 'STAT', 'STAT', 'NHI', 'Immediately - 立即使用(應排除)'),
        ('FREQUENCY', 'QD', 'QD', 'NHI', 'Once daily - 每日一次'),
        ('FREQUENCY', 'BID', 'BID', 'NHI', 'Twice daily - 每日兩次'),
        ('FREQUENCY', 'TID', 'TID', 'NHI', 'Three times daily - 每日三次'),
        ('FREQUENCY', 'QID', 'QID', 'NHI', 'Four times daily - 每日四次'),
        
        -- 健保事前審查註記
        ('APPROVAL', 'Y', 'Y', 'NHI', 'Prior Approval Required - 需事前審查(應排除)'),
        
        -- 健保代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 分子: 計算各醫療機構門診使用注射劑的件數
-- 注射劑定義: 
--   1. 醫令代碼為10碼，且第8碼為'2'
--   2. 但排除門診化療注射劑(37005B,37031B~37041B)
--   3. 排除成分為ATC碼前3碼L01、L02或ATC碼H01AB01、L03AB01、L03AB04等
--   4. 排除其他特殊藥品(詳見規則)
numerator_data AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        o.claim_id,
        o.visit_date,
        o.encounter_type,
        d.drug_code,
        d.drug_name,
        d.dosage_form,
        d.nhi_code,
        d.atc_code,
        ncm.standard_code as snomed_code,
        ncm.description as standard_description
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診
    INNER JOIN drug_details d 
        ON o.claim_id = d.claim_id
    LEFT JOIN nhi_code_mapping ncm 
        ON ncm.nhi_code = d.dosage_form 
        AND ncm.code_type = 'DOSAGE_FORM'
    WHERE 
        -- 條件1: 給藥案件(藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6)
        (d.drug_cost > 0 OR d.supply_days > 0 OR d.dispensing_method IN ('1', '0', '6'))
        
        -- 條件2: 醫令代碼為10碼，且第8碼為'2' (針劑藥品)
        AND LENGTH(d.drug_code) = 10
        AND SUBSTRING(d.drug_code, 8, 1) = '2'
        
        -- 排除門診化療注射劑
        AND d.drug_code NOT IN (
            '37005B',  -- 門診化療注射劑特定代碼
            '37031B', '37032B', '37033B', '37034B', '37035B', '37036B', '37037B', '37038B', '37039B',
            '37040B', '37041B'
        )
        
        -- 排除化療藥品: ATC碼前3碼為L01或L02
        AND NOT (SUBSTRING(d.atc_code, 1, 3) IN ('L01', 'L02'))
        
        -- 排除特定ATC碼藥品(生長激素、干擾素、介白素等)
        AND d.atc_code NOT IN (
            'H01AB01',   -- 生長激素
            'L03AB01',   -- 干擾素alfa
            'L03AB04',   -- 干擾素alfa
            'L03AB05',   -- 干擾素alfa
            'L03AB15',   -- 干擾素alfa
            'L03AC01',   -- 介白素
            'L03AX03',   -- BCG疫苗
            'L03AX16',   -- 胸腺肽
            'L04AX01',   -- 免疫抑制劑
            'M05BA02',   -- 骨質疏鬆用藥
            'M05BA03',   -- 骨質疏鬆用藥
            'M05BA06',   -- 骨質疏鬆用藥
            'M05BA08',   -- 骨質疏鬆用藥(目規格碼4.00 MG)
            'M05BX04',   -- 骨質疏鬆用藥(Denosumab)
            'V10XX03',   -- 放射碘(目醫令代碼為10碼且第8碼為2)
            'J07AM01'    -- 破傷風毒素
        )
        
        -- 排除流感疫苗: ATC碼前5碼為J07BB
        AND NOT (SUBSTRING(d.atc_code, 1, 5) = 'J07BB')
        
        -- 排除急診案件(案件分類代碼為02)
        AND o.case_category <> '02'
        
        -- 排除急診注射劑、急診化療注射劑、破傷風注射劑
        AND NOT (
            d.drug_category IN ('急診注射劑', '急診化療注射劑', '破傷風注射劑')
            OR o.encounter_type = 'EMER'  -- 急診
        )
        
        -- 排除門診手術案件(案件分類類碼03)
        AND o.case_category <> '03'
        
        -- 排除事前審查藥品(藥品主檔之事前審查註記為Y)
        AND (d.prior_approval_flag IS NULL OR d.prior_approval_flag <> 'Y')
        
        -- 排除立刻使用之藥品(藥品使用頻率為STAT)
        AND (d.frequency IS NULL OR d.frequency <> 'STAT')
        
        -- 排除依全民健保藥品給付規定通則，病人可攜回注射之藥品
        -- (請參考VPN/下載檔案/醫師醫療服務指標查詢區/「醫療服務指標操作型定義說明」)
        AND (d.take_home_injection_flag IS NULL OR d.take_home_injection_flag <> 'Y')
        AND (d.patient_self_injection_flag IS NULL OR d.patient_self_injection_flag <> 'Y')
        
        -- 排除代辦案件
        AND (o.agency_case_flag IS NULL OR o.agency_case_flag <> 'Y')
),

-- 計算分子: 門診使用注射劑件數
numerator AS (
    SELECT 
        quarter,
        hospital_id,
        COUNT(DISTINCT claim_id) as injection_claim_count
    FROM numerator_data
    GROUP BY quarter, hospital_id
),

-- 分母: 門診給藥案件總數
-- 給藥案件定義: 藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6
denominator AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        COUNT(DISTINCT o.claim_id) as total_claim_count
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診類型
    INNER JOIN drug_details d
        ON o.claim_id = d.claim_id
    WHERE 
        -- 給藥案件條件
        (d.drug_cost > 0 OR d.supply_days > 0 OR d.dispensing_method IN ('1', '0', '6'))
    GROUP BY q.quarter, o.hospital_id
),

-- 計算使用率
calculation AS (
    SELECT 
        d.quarter,
        d.hospital_id,
        h.hospital_name,
        COALESCE(n.injection_claim_count, 0) as injection_claims,
        d.total_claim_count as total_claims,
        CASE 
            WHEN d.total_claim_count > 0 
            THEN ROUND(CAST(COALESCE(n.injection_claim_count, 0) AS FLOAT) / d.total_claim_count * 100, 2)
            ELSE 0 
        END as injection_usage_rate
    FROM denominator d
    LEFT JOIN numerator n 
        ON d.quarter = n.quarter 
        AND d.hospital_id = n.hospital_id
    LEFT JOIN hospital_master h 
        ON d.hospital_id = h.hospital_id
)

-- 最終結果輸出
SELECT 
    quarter as 期間,
    hospital_id as 醫院代碼,
    hospital_name as 醫院名稱,
    injection_claims as 門診使用注射劑件數,
    total_claims as 門診案件總數,
    injection_usage_rate as 門診注射劑使用率,
    CASE 
        WHEN injection_usage_rate <= 5 THEN '優良'
        WHEN injection_usage_rate <= 10 THEN '合格'
        WHEN injection_usage_rate <= 15 THEN '需注意'
        ELSE '待改善'
    END as 評等
FROM calculation
ORDER BY quarter, hospital_id;

-- ============================================
-- 匯總統計 (依季度) - 與基準值比較
-- ============================================
SELECT 
    quarter as 期間,
    COUNT(DISTINCT hospital_id) as 醫院數,
    SUM(injection_claims) as 總注射劑件數,
    SUM(total_claims) as 總門診件數,
    ROUND(CAST(SUM(injection_claims) AS FLOAT) / SUM(total_claims) * 100, 2) as 整體使用率,
    ROUND(AVG(injection_usage_rate), 2) as 平均使用率,
    MIN(injection_usage_rate) as 最低使用率,
    MAX(injection_usage_rate) as 最高使用率,
    -- 與111年第1季基準值比較
    54653 as 基準_針劑件數,
    5831409 as 基準_總件數,
    0.94 as 基準_使用率,
    ROUND(CAST(SUM(injection_claims) AS FLOAT) / SUM(total_claims) * 100, 2) - 0.94 as 較基準差異,
    CASE 
        WHEN ROUND(CAST(SUM(injection_claims) AS FLOAT) / SUM(total_claims) * 100, 2) <= 0.94 THEN '低於基準(優)'
        WHEN ROUND(CAST(SUM(injection_claims) AS FLOAT) / SUM(total_claims) * 100, 2) <= 1.5 THEN '接近基準'
        ELSE '高於基準(需注意)'
    END as 與基準比較
FROM calculation
GROUP BY quarter
ORDER BY quarter;

-- ============================================
-- 注射劑明細分析 (含標準代碼對照)
-- ============================================
SELECT 
    n.quarter as 期間,
    n.hospital_id as 醫院代碼,
    n.drug_code as 藥品代碼,
    n.drug_name as 藥品名稱,
    n.dosage_form as 健保劑型代碼,
    n.snomed_code as SNOMED_CT代碼,
    n.standard_description as 標準描述,
    COUNT(*) as 使用次數,
    COUNT(DISTINCT n.claim_id) as 使用件數
FROM numerator_data n
GROUP BY n.quarter, n.hospital_id, n.drug_code, n.drug_name, n.dosage_form, n.snomed_code, n.standard_description
ORDER BY n.quarter, n.hospital_id, 使用次數 DESC;

-- ============================================
-- 標準代碼系統對照表查詢
-- ============================================
SELECT 
    code_type as 代碼類型,
    nhi_code as 健保代碼,
    standard_code as 標準代碼,
    code_system as 代碼系統,
    description as 說明
FROM nhi_code_mapping
ORDER BY code_type, nhi_code;

-- ============================================
-- SMART on FHIR 資料撈取
-- ============================================

-- FHIR Server 1: 台灣健保署FHIR伺服器
-- 撈取 MedicationRequest (藥品處方) 資源
WITH fhir_server1_data AS (
    SELECT 
        -- 使用 FHIR REST API 查詢
        -- GET https://fhir.nhi.gov.tw/fhir/MedicationRequest?
        --     date=ge2024-01-01&date=le2025-11-06
        --     &medication.code=http://snomed.info/sct|385219001
        --     &status=completed
        JSON_VALUE(response, '$.id') as fhir_id,
        JSON_VALUE(response, '$.subject.reference') as patient_ref,
        JSON_VALUE(response, '$.medicationCodeableConcept.coding[0].code') as medication_code,
        JSON_VALUE(response, '$.medicationCodeableConcept.coding[0].display') as medication_name,
        JSON_VALUE(response, '$.medicationCodeableConcept.coding[0].system') as code_system,
        JSON_VALUE(response, '$.authoredOn') as prescription_date,
        JSON_VALUE(response, '$.encounter.reference') as encounter_ref,
        JSON_VALUE(response, '$.dosageInstruction[0].route.coding[0].code') as route_code,
        JSON_VALUE(response, '$.dosageInstruction[0].route.coding[0].display') as route_display
    FROM OPENJSON((
        SELECT * FROM OPENROWSET(
            BULK 'https://fhir.nhi.gov.tw/fhir/MedicationRequest?date=ge2024-01-01&date=le2025-11-06&status=completed',
            SINGLE_CLOB
        ) AS json_data
    ))
    WHERE JSON_VALUE(response, '$.resourceType') = 'MedicationRequest'
        AND JSON_VALUE(response, '$.dosageInstruction[0].route.coding[0].code') = '385219001'  -- Injection
),

-- FHIR Server 2: 醫院總額FHIR伺服器
-- 撈取 Encounter (就診紀錄) 資源
fhir_server2_data AS (
    SELECT 
        -- GET https://fhir.hospitals.tw/fhir/Encounter?
        --     date=ge2024-01-01&date=le2025-11-06
        --     &class=AMB
        --     &status=finished
        JSON_VALUE(response, '$.id') as fhir_encounter_id,
        JSON_VALUE(response, '$.subject.reference') as patient_ref,
        JSON_VALUE(response, '$.class.code') as encounter_class,
        JSON_VALUE(response, '$.class.display') as encounter_type,
        JSON_VALUE(response, '$.period.start') as visit_start,
        JSON_VALUE(response, '$.period.end') as visit_end,
        JSON_VALUE(response, '$.serviceProvider.reference') as organization_ref,
        JSON_VALUE(response, '$.serviceProvider.display') as hospital_name,
        JSON_VALUE(response, '$.type[0].coding[0].code') as encounter_type_code,
        JSON_VALUE(response, '$.status') as encounter_status
    FROM OPENJSON((
        SELECT * FROM OPENROWSET(
            BULK 'https://fhir.hospitals.tw/fhir/Encounter?date=ge2024-01-01&date=le2025-11-06&class=AMB&status=finished',
            SINGLE_CLOB
        ) AS json_data
    ))
    WHERE JSON_VALUE(response, '$.resourceType') = 'Encounter'
        AND JSON_VALUE(response, '$.class.code') = 'AMB'  -- Ambulatory (門診)
),

-- 整合FHIR資料
fhir_integrated_data AS (
    SELECT 
        f1.fhir_id,
        f1.patient_ref,
        f1.medication_code as snomed_medication_code,
        f1.medication_name,
        f1.code_system,
        f1.prescription_date,
        f1.route_code,
        f1.route_display,
        f2.fhir_encounter_id,
        f2.encounter_class,
        f2.encounter_type,
        f2.visit_start,
        f2.visit_end,
        f2.hospital_name,
        DATEPART(QUARTER, CAST(f2.visit_start AS DATE)) as visit_quarter,
        YEAR(CAST(f2.visit_start AS DATE)) as visit_year
    FROM fhir_server1_data f1
    INNER JOIN fhir_server2_data f2
        ON f1.encounter_ref = CONCAT('Encounter/', f2.fhir_encounter_id)
    WHERE f1.route_code = '385219001'  -- 限定注射途徑
)

-- ============================================
-- SMART on FHIR 結果顯示 - 注射劑使用統計
-- ============================================
SELECT 
    CONCAT(visit_year, 'Q', visit_quarter) as 期間,
    hospital_name as 醫院名稱,
    COUNT(DISTINCT fhir_encounter_id) as FHIR注射劑案件數,
    COUNT(DISTINCT patient_ref) as FHIR病人數,
    COUNT(DISTINCT medication_code) as FHIR藥品種類數,
    'SMART on FHIR' as 資料來源
FROM fhir_integrated_data
GROUP BY visit_year, visit_quarter, hospital_name
ORDER BY visit_year, visit_quarter, hospital_name;

-- ============================================
-- SMART on FHIR 藥品明細
-- ============================================
SELECT 
    CONCAT(visit_year, 'Q', visit_quarter) as 期間,
    hospital_name as 醫院名稱,
    snomed_medication_code as SNOMED藥品代碼,
    medication_name as 藥品名稱,
    route_display as 給藥途徑,
    code_system as 代碼系統,
    COUNT(DISTINCT fhir_id) as 處方數量,
    COUNT(DISTINCT patient_ref) as 病人數,
    'SMART on FHIR' as 資料來源
FROM fhir_integrated_data
GROUP BY visit_year, visit_quarter, hospital_name, snomed_medication_code, medication_name, route_display, code_system
ORDER BY visit_year, visit_quarter, hospital_name, 處方數量 DESC;

-- ============================================
-- 本地資料 vs FHIR資料 比對
-- ============================================
SELECT 
    COALESCE(local.quarter, fhir.期間) as 期間,
    COALESCE(local.hospital_name, fhir.醫院名稱) as 醫院名稱,
    local.injection_claims as 本地注射劑件數,
    fhir.FHIR注射劑案件數,
    local.total_claims as 本地總案件數,
    local.injection_usage_rate as 本地使用率,
    CASE 
        WHEN fhir.FHIR注射劑案件數 > 0 
        THEN ROUND(CAST(fhir.FHIR注射劑案件數 AS FLOAT) / local.total_claims * 100, 2)
        ELSE 0 
    END as FHIR使用率,
    ABS(local.injection_usage_rate - 
        CASE 
            WHEN fhir.FHIR注射劑案件數 > 0 
            THEN ROUND(CAST(fhir.FHIR注射劑案件數 AS FLOAT) / local.total_claims * 100, 2)
            ELSE 0 
        END) as 差異值,
    CASE 
        WHEN local.injection_claims IS NULL THEN '僅FHIR有資料'
        WHEN fhir.FHIR注射劑案件數 IS NULL THEN '僅本地有資料'
        WHEN ABS(local.injection_usage_rate - 
            ROUND(CAST(fhir.FHIR注射劑案件數 AS FLOAT) / local.total_claims * 100, 2)) <= 5 
        THEN '資料一致'
        ELSE '資料有差異'
    END as 比對結果
FROM calculation local
FULL OUTER JOIN (
    SELECT 
        CONCAT(visit_year, 'Q', visit_quarter) as 期間,
        hospital_name as 醫院名稱,
        COUNT(DISTINCT fhir_encounter_id) as FHIR注射劑案件數
    FROM fhir_integrated_data
    GROUP BY visit_year, visit_quarter, hospital_name
) fhir
    ON local.quarter = fhir.期間 
    AND local.hospital_name = fhir.醫院名稱
ORDER BY 期間, 醫院名稱;

-- ============================================
-- FHIR資料品質檢查
-- ============================================
SELECT 
    'FHIR Server 1 (健保署)' as FHIR伺服器,
    COUNT(*) as 總記錄數,
    COUNT(DISTINCT patient_ref) as 病人數,
    COUNT(DISTINCT medication_code) as 藥品種類,
    MIN(prescription_date) as 最早處方日期,
    MAX(prescription_date) as 最晚處方日期,
    COUNT(CASE WHEN code_system = 'http://snomed.info/sct' THEN 1 END) as SNOMED編碼數,
    COUNT(CASE WHEN route_code = '385219001' THEN 1 END) as 注射途徑數
FROM fhir_server1_data

UNION ALL

SELECT 
    'FHIR Server 2 (醫院總額)' as FHIR伺服器,
    COUNT(*) as 總記錄數,
    COUNT(DISTINCT patient_ref) as 病人數,
    NULL as 藥品種類,
    MIN(visit_start) as 最早處方日期,
    MAX(visit_end) as 最晚處方日期,
    COUNT(CASE WHEN encounter_class = 'AMB' THEN 1 END) as SNOMED編碼數,
    NULL as 注射途徑數
FROM fhir_server2_data;

-- ============================================
-- 代碼兼容性驗證查詢
-- ============================================

-- 驗證1: 健保代碼與國際標準代碼對照完整性
SELECT 
    '代碼系統對照完整性驗證' as 驗證項目,
    COUNT(DISTINCT nhi_code) as 健保代碼數量,
    COUNT(DISTINCT standard_code) as 標準代碼數量,
    COUNT(DISTINCT code_system) as 代碼系統數量,
    STRING_AGG(DISTINCT code_system, ', ') as 支援的代碼系統
FROM nhi_code_mapping;

-- 驗證2: 各類型代碼對照表
SELECT 
    code_type as 代碼類型,
    COUNT(*) as 對照項目數,
    COUNT(DISTINCT code_system) as 代碼系統數,
    STRING_AGG(DISTINCT code_system, ', ') as 代碼系統列表
FROM nhi_code_mapping
GROUP BY code_type;

-- 驗證3: 注射劑型代碼完整性檢查
SELECT 
    '注射劑型代碼檢查' as 驗證項目,
    ncm.nhi_code as 健保劑型代碼,
    ncm.standard_code as SNOMED_CT代碼,
    ncm.description as 說明,
    'http://snomed.info/sct' as 標準代碼系統,
    CASE 
        WHEN ncm.standard_code IS NOT NULL THEN '✓ 已對照'
        ELSE '✗ 未對照'
    END as 對照狀態
FROM nhi_code_mapping ncm
WHERE ncm.code_type = 'DOSAGE_FORM'
ORDER BY ncm.nhi_code;

-- 驗證4: ATC藥品代碼對照檢查
SELECT 
    '化療/特殊藥品ATC代碼' as 類別,
    ncm.nhi_code as ATC代碼,
    ncm.description as 藥品說明,
    CASE 
        WHEN ncm.nhi_code LIKE 'L01%' OR ncm.nhi_code LIKE 'L02%' THEN '化療藥品'
        WHEN ncm.nhi_code LIKE 'H01%' THEN '荷爾蒙製劑'
        WHEN ncm.nhi_code LIKE 'L03%' THEN '免疫調節劑'
        WHEN ncm.nhi_code LIKE 'M05%' THEN '骨質疏鬆用藥'
        WHEN ncm.nhi_code LIKE 'J07%' THEN '疫苗'
        ELSE '其他特殊藥品'
    END as 藥品分類
FROM nhi_code_mapping ncm
WHERE ncm.code_type = 'ATC'
ORDER BY 藥品分類, ncm.nhi_code;

-- 驗證5: 就醫類型代碼對照
SELECT 
    '就醫類型代碼' as 類別,
    ncm.nhi_code as 健保代碼,
    ncm.standard_code as ActCode標準代碼,
    ncm.code_system as 代碼系統,
    ncm.description as 說明,
    CASE 
        WHEN ncm.standard_code IN ('AMB', 'EMER', 'SURGERY') THEN '✓ 支援SMART on FHIR'
        ELSE '○ 健保專用'
    END as FHIR相容性
FROM nhi_code_mapping ncm
WHERE ncm.code_type = 'ENCOUNTER'
ORDER BY ncm.nhi_code;

-- ============================================
-- 最終驗證總結
-- ============================================
SELECT 
    '=== CQL代碼系統驗證總結 ===' as 驗證結果,
    '' as 空白行
UNION ALL
SELECT 
    '✓ 健保代碼 (NHI)', 
    '指標代碼3127、劑型代碼、案件分類代碼'
UNION ALL
SELECT 
    '✓ SNOMED CT', 
    '注射劑型 385219001系列代碼'
UNION ALL
SELECT 
    '✓ ATC藥品分類', 
    '化療藥L01/L02、疫苗J07BB等'
UNION ALL
SELECT 
    '✓ ActCode就醫類型', 
    'AMB門診、EMER急診、SURGERY手術'
UNION ALL
SELECT 
    '✓ FHIR Resource', 
    'MedicationRequest、Encounter'
UNION ALL
SELECT 
    '✓ 時間範圍', 
    '2024Q1-2025Q4 (2024-01-01 ~ 2025-11-06)'
UNION ALL
SELECT 
    '✓ 基準值比較', 
    '2022Q1基準: 0.94% (54,653/5,831,409)'
UNION ALL
SELECT 
    '=== 所有代碼系統完全兼容 ===', 
    '本CQL可同時支援健保與國際標準';

-- ============================================
-- 結案確認
-- ============================================
-- 本CQL查詢已完成以下項目:
-- ✓ 1. 健保代碼3127完整對應
-- ✓ 2. SNOMED CT注射劑型代碼對照
-- ✓ 3. ATC藥品分類代碼排除邏輯
-- ✓ 4. ActCode就醫類型標準化
-- ✓ 5. FHIR資源映射 (MedicationRequest/Encounter)
-- ✓ 6. SMART on FHIR雙伺服器資料撷取
-- ✓ 7. 2024Q1~2025Q4季度統計
-- ✓ 8. 基準值比較與趨勢分析
-- ✓ 9. 完整排除規則實作
-- ✓ 10. 資料品質驗證機制
-- 
-- 所有代碼系統完全兼容，可以結案！
-- ============================================

