library Indicator_04_Chronic_Continuous_Prescription_Rate_1318 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1318
// 條件依據：慢性病連續處方箋開立率
// 製作日期：2025-11-20

// 【公式說明】
// 分子: 開立慢性病連續處方箋件數
// 分母: 慢性病案件數
// 慢性病案件: 診察費項目代碼為慢性病代碼，或案件分類=04、E1
// 排除: 婦產科/小兒科專科醫院、呼吸照護病房申請點數≧80%之醫院

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'

// 慢性病診察費代碼
code "00155A": '00155A' from "NHI_PROCEDURE" display '慢性病診察費'
code "00157A": '00157A' from "NHI_PROCEDURE" display '慢性病診察費'
code "00170A": '00170A' from "NHI_PROCEDURE" display '慢性病診察費'
code "00171A": '00171A' from "NHI_PROCEDURE" display '慢性病診察費'
code "00131B": '00131B' from "NHI_PROCEDURE" display '慢性病診察費'
code "00132B": '00132B' from "NHI_PROCEDURE" display '慢性病診察費'
code "00172B": '00172B' from "NHI_PROCEDURE" display '慢性病診察費'
code "00173B": '00173B' from "NHI_PROCEDURE" display '慢性病診察費'
code "00135B": '00135B' from "NHI_PROCEDURE" display '慢性病診察費'
code "00136B": '00136B' from "NHI_PROCEDURE" display '慢性病診察費'

// Helper function: 檢查是否為慢性病診察費代碼
define function IsChronicConsultationCode(code String):
  code in {
    '00155A', '00157A', '00170A', '00171A', '00131B', '00132B', '00172B', '00173B',
    '00135B', '00136B', '00174B', '00175B', '00138B', '00176B', '00177B', '00139C',
    '00140C', '00159C', '00141C', '00142C', '00160C', '00161C', '00143C', '00144C',
    '00162C', '00163C', '00145C', '00146C', '00164C', '00165C', '00147C', '00148C',
    '00166C', '00167C', '00149C', '00150C', '00168C', '00169C', '00178B', '00179B',
    '00180B', '00181B', '00182C', '00183C', '00184C', '00185C', '00187C', '00189C',
    '00190C', '00191C'
  }

// Helper function: 檢查是否為慢性病案件分類
define function IsChronicClaimType(claimType String):
  claimType in { '04', 'E1' }

// 1. 慢性病案件（分母）
define "Chronic Disease Cases":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'AMB'
    and (
      // 條件1: 診察費項目代碼為慢性病代碼
      exists (
        [Procedure] P
          where P.encounter.reference.value = 'Encounter/' + E.id.value
          and exists (
            P.code.coding C
              where C.system.value = 'http://www.nhi.gov.tw/codes'
              and IsChronicConsultationCode(C.code.value)
          )
      )
      // 條件2: 案件分類為04或E1
      or exists (
        E.type T
          where exists (
            T.coding C
              where IsChronicClaimType(C.code.value)
          )
      )
    )
    // 排除代辦案件
    and not exists (
      E.type T where exists (T.coding C where C.code.value = 'AGENCY')
    )

// 2. 慢性病連續處方箋案件（分子）
define "Chronic Continuous Prescription Cases":
  "Chronic Disease Cases" E
    where 
      // 條件1: 診察費項目代碼為慢性病代碼
      exists (
        [Procedure] P
          where P.encounter.reference.value = 'Encounter/' + E.id.value
          and exists (
            P.code.coding C
              where C.system.value = 'http://www.nhi.gov.tw/codes'
              and IsChronicConsultationCode(C.code.value)
          )
      )
      // 條件2: 案件分類=E1且連續處方箋有效期間 > 給藥天數
      or (
        exists (E.type T where exists (T.coding C where C.code.value = 'E1'))
        and exists (
          [MedicationRequest] MR
            where MR.encounter.reference.value = 'Encounter/' + E.id.value
            and MR.dispenseRequest.validityPeriod is not null
            and MR.dispenseRequest.expectedSupplyDuration is not null
            and MR.dispenseRequest.validityPeriod.start.value < MR.dispenseRequest.validityPeriod.end.value
        )
      )

// 3. 分母：慢性病案件數
define "Denominator":
  Count(
    distinct "Chronic Disease Cases" E
      return E.id.value
  )

// 4. 分子：慢性病連續處方箋案件數
define "Numerator":
  Count(
    distinct "Chronic Continuous Prescription Cases" E
      return E.id.value
  )

// 5. 指標計算結果：慢性病連續處方箋開立率
define "Continuous Prescription Rate":
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
-- 依據健保指標代碼 1318 (慢性病連續處方箋開立率) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1318', '1318', 'NHI_INDICATOR', 'Chronic Disease Continuous Prescription Rate - 慢性病連續處方箋開立率'),
        
        -- 診察費項目代碼 (慢性病) - SNOMED CT 對照
        ('PROCEDURE', '00155A', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(155A)'),
        ('PROCEDURE', '00157A', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(157A)'),
        ('PROCEDURE', '00170A', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(170A)'),
        ('PROCEDURE', '00171A', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(171A)'),
        ('PROCEDURE', '00131B', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(131B)'),
        ('PROCEDURE', '00132B', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(132B)'),
        ('PROCEDURE', '00172B', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(172B)'),
        ('PROCEDURE', '00173B', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(173B)'),
        ('PROCEDURE', '00135B', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(135B)'),
        ('PROCEDURE', '00136B', '185349003', 'http://snomed.info/sct', 'Chronic disease management - 慢性病診察(136B)'),
        
        -- 案件分類代碼
        ('CLAIM_TYPE', '04', 'chronic-rx', 'NHI_CLAIM_TYPE', 'Chronic Disease Prescription - 慢性病處方'),
        ('CLAIM_TYPE', 'E1', 'chronic-continuous-rx', 'NHI_CLAIM_TYPE', 'Chronic Disease Continuous Prescription - 慢性病連續處方'),
        
        -- 醫院型態代碼
        ('HOSPITAL_TYPE', '03', 'specialty-hospital', 'NHI_HOSPITAL_TYPE', 'Specialty Hospital - 專科醫院'),
        
        -- 科別代碼
        ('SPECIALTY', '04', '394537008', 'http://snomed.info/sct', 'Pediatrics - 小兒科'),
        ('SPECIALTY', '05', '394586005', 'http://snomed.info/sct', 'Obstetrics and Gynecology - 婦產科'),
        
        -- 呼吸照護病房令碼
        ('PROCEDURE', 'P1011C', '385268001', 'http://snomed.info/sct', 'Respiratory Care Ward - 呼吸照護病房(P1011C)'),
        ('PROCEDURE', 'P1012C', '385268001', 'http://snomed.info/sct', 'Respiratory Care Ward - 呼吸照護病房(P1012C)'),
        
        -- 就醫類型代碼 (HL7 ActCode)
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)'),
        ('AGENCY', 'N', 'N', 'NHI', 'Non-Agency Case - 非代辦案件')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 定義所有慢性病診察費代碼
chronic_consultation_codes AS (
    SELECT code FROM (
        VALUES 
        ('00155A'), ('00157A'), ('00170A'), ('00171A'), ('00131B'), ('00132B'), ('00172B'), ('00173B'),
        ('00135B'), ('00136B'), ('00174B'), ('00175B'), ('00138B'), ('00176B'), ('00177B'), ('00139C'),
        ('00140C'), ('00159C'), ('00141C'), ('00142C'), ('00160C'), ('00161C'), ('00143C'), ('00144C'),
        ('00162C'), ('00163C'), ('00145C'), ('00146C'), ('00164C'), ('00165C'), ('00147C'), ('00148C'),
        ('00166C'), ('00167C'), ('00149C'), ('00150C'), ('00168C'), ('00169C'), ('00178B'), ('00179B'),
        ('00180B'), ('00181B'), ('00182C'), ('00183C'), ('00184C'), ('00185C'), ('00187C'), ('00189C'),
        ('00190C'), ('00191C')
    ) AS t(code)
),

-- 排除的醫院清單
excluded_hospitals AS (
    SELECT DISTINCT h.hospital_id
    FROM hospital_master h
    LEFT JOIN (
        SELECT 
            o.hospital_id,
            o.specialty_code,
            SUM(o.claim_amount) as specialty_amount,
            SUM(SUM(o.claim_amount)) OVER (PARTITION BY o.hospital_id) as total_amount
        FROM outpatient_claims o
        WHERE o.encounter_type IN ('O', 'AMB')
        GROUP BY o.hospital_id, o.specialty_code
    ) specialty_stats ON h.hospital_id = specialty_stats.hospital_id
    LEFT JOIN (
        SELECT 
            o.hospital_id,
            SUM(CASE WHEN p.procedure_code IN ('P1011C', 'P1012C') THEN o.claim_amount ELSE 0 END) as resp_care_amount,
            SUM(o.claim_amount) as total_amount
        FROM outpatient_claims o
        LEFT JOIN procedure_details p ON o.claim_id = p.claim_id
        GROUP BY o.hospital_id
    ) resp_care_stats ON h.hospital_id = resp_care_stats.hospital_id
    WHERE 
        -- 排除條件A: 婦產科專科醫院
        (h.hospital_type = '03' AND specialty_stats.specialty_code = '05' 
         AND specialty_stats.specialty_amount = (
             SELECT MAX(s2.specialty_amount) 
             FROM (
                 SELECT hospital_id, specialty_code, SUM(claim_amount) as specialty_amount
                 FROM outpatient_claims
                 WHERE hospital_id = h.hospital_id
                 GROUP BY hospital_id, specialty_code
             ) s2
             WHERE s2.hospital_id = h.hospital_id
         ))
        -- 排除條件B: 小兒科專科醫院
        OR (h.hospital_type = '03' AND specialty_stats.specialty_code = '04' 
            AND specialty_stats.specialty_amount = (
                SELECT MAX(s2.specialty_amount) 
                FROM (
                    SELECT hospital_id, specialty_code, SUM(claim_amount) as specialty_amount
                    FROM outpatient_claims
                    WHERE hospital_id = h.hospital_id
                    GROUP BY hospital_id, specialty_code
                ) s2
                WHERE s2.hospital_id = h.hospital_id
            ))
        -- 排除條件C: 呼吸照護病房占80%以上
        OR (resp_care_stats.resp_care_amount >= resp_care_stats.total_amount * 0.8)
),

-- 篩選慢性病案件
chronic_disease_cases AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        o.patient_id,
        o.claim_id,
        o.visit_date,
        o.claim_type,
        o.specialty_code,
        -- 檢查是否有慢性病診察費代碼
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM procedure_details p 
                INNER JOIN chronic_consultation_codes ccc ON p.procedure_code = ccc.code
                WHERE p.claim_id = o.claim_id
            ) THEN 1
            ELSE 0
        END as has_chronic_consultation,
        -- 檢查案件分類是否為慢性病
        CASE 
            WHEN o.claim_type IN ('04', 'E1') THEN 1
            ELSE 0
        END as is_chronic_claim_type
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
        
        -- 4. 排除特定醫院
        AND o.hospital_id NOT IN (SELECT hospital_id FROM excluded_hospitals)
        
        -- 5. 至少符合一項慢性病條件
        AND (
            -- 條件1: 有慢性病診察費代碼
            EXISTS (
                SELECT 1 FROM procedure_details p 
                INNER JOIN chronic_consultation_codes ccc ON p.procedure_code = ccc.code
                WHERE p.claim_id = o.claim_id
            )
            -- 條件2: 案件分類為慢性病
            OR o.claim_type IN ('04', 'E1')
        )
),

-- 判斷是否開立慢性病連續處方箋
chronic_continuous_prescriptions AS (
    SELECT 
        c.*,
        -- 判斷是否開立慢性病連續處方箋
        CASE 
            -- 方法1: 有慢性病診察費代碼
            WHEN c.has_chronic_consultation = 1 THEN 1
            -- 方法2: 案件分類=E1 且符合給藥條件
            WHEN c.claim_type = 'E1' THEN
                CASE 
                    WHEN EXISTS (
                        SELECT 1 FROM drug_details d
                        WHERE d.claim_id = c.claim_id
                        -- 慢性病連續處方箋有效期間處方日份 > 給藥天數
                        AND d.prescription_total_days > d.drug_days
                        -- 慢性病連續處方箋有效日份為給藥天數的倍數
                        AND d.prescription_total_days % d.drug_days = 0
                    ) THEN 1
                    ELSE 0
                END
            ELSE 0
        END as is_continuous_prescription
    FROM 
        chronic_disease_cases c
),

-- 計算每季的統計數據
quarterly_summary AS (
    SELECT 
        q.quarter,
        -- 分母: 慢性病案件數
        COUNT(DISTINCT c.claim_id) as total_chronic_cases,
        -- 分子: 開立慢性病連續處方箋件數
        SUM(CASE WHEN c.is_continuous_prescription = 1 THEN 1 ELSE 0 END) as continuous_prescription_cases,
        -- 開立率 (%)
        CASE 
            WHEN COUNT(DISTINCT c.claim_id) > 0 THEN 
                ROUND(SUM(CASE WHEN c.is_continuous_prescription = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT c.claim_id), 2)
            ELSE 0
        END as continuous_prescription_rate,
        -- 統計數量
        COUNT(DISTINCT c.patient_id) as total_patients,
        COUNT(DISTINCT c.hospital_id) as total_hospitals
    FROM 
        quarters q
    LEFT JOIN 
        chronic_continuous_prescriptions c ON q.quarter = c.quarter
    GROUP BY 
        q.quarter
)

-- 最終結果輸出
SELECT 
    quarter as '季度',
    total_patients as '總病患數',
    total_hospitals as '總醫院數',
    continuous_prescription_cases as '開立慢性病連續處方箋件數',
    total_chronic_cases as '慢性病案件數',
    continuous_prescription_rate as '慢性病連續處方箋開立率(%)'
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
-- 預期開立率範圍: 約 30-50% (依據一般醫院慢性病管理情況)
-- ============================================

-- ============================================
-- 診察費代碼說明
-- ============================================
-- 慢性病診察費代碼 (共51個):
-- 
-- A類 (00155A-00171A): 基層慢性病診察費
-- B類 (00131B-00191C): 不同層級醫院慢性病診察費
-- 
-- 完整清單:
-- 00155A、00157A、00170A、00171A、00131B、00132B、00172B、00173B、00135B、00136B、
-- 00174B、00175B、00138B、00176B、00177B、00139C、00140C、00159C、00141C、00142C、
-- 00160C、00161C、00143C、00144C、00162C、00163C、00145C、00146C、00164C、00165C、
-- 00147C、00148C、00166C、00167C、00149C、00150C、00168C、00169C、00178B、00179B、
-- 00180B、00181B、00182C、00183C、00184C、00185C、00187C、00189C、00190C、00191C
-- ============================================

-- ============================================
-- 案件分類說明
-- ============================================
-- 04: 慢性病處方 (一般慢性病給藥)
-- E1: 慢性病連續處方 (可分次調劑)
-- 
-- 慢性病連續處方箋條件:
-- 1. 有效期間處方日份 > 給藥天數
-- 2. 有效日份為給藥天數的倍數
-- 例如: 總處方90天，每次給藥30天 (90 > 30 且 90 % 30 = 0)
-- ============================================

-- ============================================
-- 排除醫院條件說明
-- ============================================
-- A. 婦產科專科醫院:
--    - 醫院型態別 = 03 (專科醫院)
--    - 日門診婦產科(05)申請點數占全科別最高
--
-- B. 小兒科專科醫院:
--    - 醫院型態別 = 03 (專科醫院)
--    - 日門診小兒科(04)申請點數占全科別最高
--
-- C. 呼吸照護病房為主的醫院:
--    - 有申請 P1011C 或 P1012C
--    - 呼吸照護點數 ≥ 全院點數 80%
-- ============================================

-- ============================================
-- 代碼系統對照
-- ============================================
-- NHI_INDICATOR: 健保指標代碼 (1318)
-- SNOMEDCT: http://snomed.info/sct (診療代碼、科別代碼)
-- ICD10: http://hl7.org/fhir/sid/icd-10 (疾病分類)
-- ActCode: http://terminology.hl7.org/CodeSystem/v3-ActCode (就醫類型)
-- NHI: 健保專用代碼 (代辦案件標記等)
-- NHI_PROCEDURE: 健保診療項目代碼 (診察費代碼)
-- NHI_CLAIM_TYPE: 健保案件分類代碼 (04, E1)
-- NHI_SPECIALTY: 健保科別代碼 (04小兒科, 05婦產科)
-- NHI_HOSPITAL_TYPE: 健保醫院型態代碼 (03專科醫院)
-- ============================================
