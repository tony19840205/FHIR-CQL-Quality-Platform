library Indicator_10_Inpatient_3Day_ED_After_Discharge_108_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 108.01
// 條件依據：住院案件出院後三日以內急診率
// 製作日期：2025-11-20
 * 
 * 公式說明:
 * 住院案件出院後三日以內急診率 = 
 *     分子: 3日內再急診案件數
 *     分母: 出院案件數
 * 
 * 排除下列案件:
 * (1)腫瘤科個案(就醫科別=13)
 * (2)乳癌試辦案件(案件分類4+疾患來源N或R或C)
 * (3)化學治療及放射線治療、安寧接受抗腫瘤免疫療法(主、次診斷ICD-10-CM Z510、Z5111、Z51.12)
 * (4)早產安胎個案(主診斷ICD-10-CM：前五碼O4291及全碼O4410~O4413、O4690~O4693、O4702~O4703、O6002、O6003)
 * (5)罕見疾病(主診斷E760-E763)點多醣症
 * (6)轉院案件(轉歸代碼5、6或7)
 * (7)新生兒床號(部分負擔計費903)
 * (8)血友病(主診斷D66、D67、D681、D682)
 * (9)器官移植(骨髓移植、肺臟移植、肝臟移植：68035肺臟移植：68037（雙肺）、68047（雙肺）肝臟移植：75020腎臟移植：76020)
 * (10)病患死亡或病危自動出院案件(轉歸代碼4或A)
 * 
 * 臨床意義:
 * - 評估出院計畫的適當性
 * - 監測出院後病患狀況穩定性
 * - 辨識可能過早出院的案件
 * - 提升醫療照護連續性
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 住院紀錄、急診紀錄
 * - Condition: 診斷資料 (主診斷、次診斷)
 * - Procedure: 手術處置資料
 * - Claim: 醫療費用申報
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 108.01 (指標代碼)

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- Z510, Z5111, Z51.12: 化學治療及放射線治療、抗腫瘤免疫療法
    -- O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003: 早產安胎
    -- E760-E763: 罕見疾病(點多醣症)
    -- D66, D67, D681, D682: 血友病

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 32485007: Hospital admission (住院)
    -- 58000006: Patient discharge (病患出院)
    -- 50849002: Emergency room admission (急診就醫)
    -- 183452005: Emergency hospital admission (緊急住院)
    -- 304561000: Chemotherapy (化學治療)
    -- 33195004: Radiotherapy (放射線治療)
    -- 76334006: Immunotherapy (免疫療法)
    -- 82433008: Organ transplantation (器官移植)
    -- 23719005: Bone marrow transplantation (骨髓移植)
    -- 52213001: Transplantation of lung (肺臟移植)
    -- 32413006: Transplantation of liver (肝臟移植)
    -- 18027006: Transplantation of kidney (腎臟移植)
    -- 309884000: Oncology specialty (腫瘤科)
    -- 419099009: Dead (死亡)
    -- 271594007: Patient died in hospital (病患死於醫院)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode 代碼系統
    -- IMP: 住院 (Inpatient)
    -- EMER: 急診 (Emergency)
    -- AMB: 門診 (Ambulatory)

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
    -- 台灣健保局專用代碼系統
    -- 醫事機構代碼
    -- 醫療服務代碼
    -- 案件類別代碼

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- I: 住院
    -- E: 急診
    -- O: 門診

codesystem "NHI_DEPARTMENT": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-department'
    -- 健保科別代碼系統
    -- 13: 腫瘤科

codesystem "NHI_CASE_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-case-type'
    -- 健保案件分類代碼系統
    -- 案件分類4: 特殊案件

codesystem "NHI_DISEASE_SOURCE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-disease-source'
    -- 健保疾患來源代碼系統
    -- N: 新生兒
    -- R: 再住院
    -- C: 慢性病

codesystem "NHI_DISCHARGE_STATUS": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-discharge-status'
    -- 健保出院轉歸代碼系統
    -- 4: 死亡
    -- 5: 轉院(計畫性)
    -- 6: 轉院(緊急)
    -- 7: 轉院(其他)
    -- A: 病危自動出院

codesystem "NHI_COPAYMENT": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-copayment'
    -- 健保部分負擔計費代碼系統
    -- 903: 新生兒床號

codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
    -- 健保手術處置代碼系統
    -- 68035: 肺臟移植
    -- 68037: 雙肺移植
    -- 68047: 雙肺移植
    -- 75020: 肝臟移植
    -- 76020: 腎臟移植
    -- 骨髓移植相關代碼

-- ==================== 值集定義 ====================

valueset "Inpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/inpatient-encounter-types'
    -- 住院就醫類別值集
    -- ActCode: IMP (住院)
    -- NHI: I (住院)

valueset "Emergency Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/emergency-encounter-types'
    -- 急診就醫類別值集
    -- ActCode: EMER (急診)
    -- NHI: E (急診)

valueset "Cancer Treatment Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-treatment-codes'
    -- 腫瘤治療代碼值集
    -- ICD-10-CM: Z510 (化學治療), Z5111 (化學治療), Z51.12 (免疫療法)

valueset "Preterm Labor Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/preterm-labor-codes'
    -- 早產安胎代碼值集
    -- ICD-10-CM: O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003

valueset "Rare Disease Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/rare-disease-codes'
    -- 罕見疾病代碼值集
    -- ICD-10-CM: E760-E763 (點多醣症)

valueset "Hemophilia Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hemophilia-codes'
    -- 血友病代碼值集
    -- ICD-10-CM: D66, D67, D681, D682

valueset "Organ Transplant Procedures": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/organ-transplant-procedures'
    -- 器官移植手術代碼值集
    -- NHI_PROCEDURE: 68035, 68037, 68047, 75020, 76020, 骨髓移植

valueset "Death Discharge Status": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/death-discharge-status'
    -- 死亡/病危出院轉歸值集
    -- NHI_DISCHARGE_STATUS: 4 (死亡), A (病危自動出院)

valueset "Transfer Discharge Status": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/transfer-discharge-status'
    -- 轉院出院轉歸值集
    -- NHI_DISCHARGE_STATUS: 5, 6, 7

-- ==================== NHI指標代碼對照 ====================

/*
 * 指標代碼定義
 * 108.01: 住院案件出院後三日以內急診率
 */
code "Indicator_108_01": '108.01' from "NHI_INDICATOR" display '住院案件出院後三日以內急診率'

-- ==================== ICD-10-CM診斷代碼對照 ====================

/*
 * 腫瘤治療代碼 (Z510, Z5111, Z51.12)
 * 早產安胎代碼 (O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003)
 * 罕見疾病代碼 (E760-E763)
 * 血友病代碼 (D66, D67, D681, D682)
 */

-- ==================== 健保科別代碼對照 ====================

code "Oncology_Department": '13' from "NHI_DEPARTMENT" display '腫瘤科'

-- ==================== 健保案件分類代碼對照 ====================

code "Special_Case_Type": '4' from "NHI_CASE_TYPE" display '特殊案件'

-- ==================== 健保疾患來源代碼對照 ====================

code "Disease_Source_N": 'N' from "NHI_DISEASE_SOURCE" display '新生兒'
code "Disease_Source_R": 'R' from "NHI_DISEASE_SOURCE" display '再住院'
code "Disease_Source_C": 'C' from "NHI_DISEASE_SOURCE" display '慢性病'

-- ==================== 健保出院轉歸代碼對照 ====================

code "Death_Status": '4' from "NHI_DISCHARGE_STATUS" display '死亡'
code "Critical_Discharge_Status": 'A' from "NHI_DISCHARGE_STATUS" display '病危自動出院'
code "Transfer_Status_5": '5' from "NHI_DISCHARGE_STATUS" display '轉院(計畫性)'
code "Transfer_Status_6": '6' from "NHI_DISCHARGE_STATUS" display '轉院(緊急)'
code "Transfer_Status_7": '7' from "NHI_DISCHARGE_STATUS" display '轉院(其他)'

-- ==================== 健保部分負擔計費代碼對照 ====================

code "Newborn_Copayment": '903' from "NHI_COPAYMENT" display '新生兒床號'

-- ==================== 參數定義 ====================

parameter "Measurement Period" Interval<DateTime>
    -- 統計期間（季度或年度）

parameter "Emergency Visit Days" Integer default 3
    -- 急診觀察天數（預設3天）

-- ==================== 統計期間定義 ====================

define quarters AS (
    List<Tuple {
        id: Integer,
        label: String,
        start_date: DateTime,
        end_date: DateTime
    }> {
        { id: 1, label: '113年第1季', start_date: @2024-01-01T00:00:00, end_date: @2024-03-31T23:59:59 },
        { id: 2, label: '113年第2季', start_date: @2024-04-01T00:00:00, end_date: @2024-06-30T23:59:59 },
        { id: 3, label: '113年第3季', start_date: @2024-07-01T00:00:00, end_date: @2024-09-30T23:59:59 },
        { id: 4, label: '113年第4季', start_date: @2024-10-01T00:00:00, end_date: @2024-12-31T23:59:59 }
    }
)

define annual_period AS (
    Tuple {
        id: 5,
        label: '113年',
        start_date: @2024-01-01T00:00:00,
        end_date: @2024-12-31T23:59:59
    }
)

-- ==================== FHIR資源查詢 ====================

-- 1. 所有住院出院案件（未過濾）
-- 按「院所、ID、生日、住院日」歸戶，以最晚之出院日為準
define all_inpatient_discharges AS (
    [Encounter: type in "Inpatient Encounter Types"] E
    where E.status = 'finished'
        and E.period.end during "Measurement Period"
        and E.hospitalization.dischargeDisposition is not null
)

-- 按病患、醫院、住院日歸戶，取最晚出院日
define grouped_discharges AS (
    all_inpatient_discharges E
    return {
        patient_id: E.subject.reference,
        organization_id: E.serviceProvider.reference,
        admission_date: E.period.start,
        discharge_date: E.period.end,
        encounter_id: E.id,
        discharge_status: E.hospitalization.dischargeDisposition.coding[0].code,
        diagnoses: E.diagnosis
    }
    group by patient_id, organization_id, ToDate(admission_date)
    return Max(discharge_date) as latest_discharge_date
)

-- 2. 排除條件1：腫瘤科個案（就醫科別=13）
define oncology_cases AS (
    all_inpatient_discharges E
    where exists (
        E.participant P
        where P.individual.resolve().specialty.coding contains Code { code: '13', system: "NHI_DEPARTMENT" }
    )
)

-- 3. 排除條件2：乳癌試辦案件（案件分類4+疾患來源N或R或C）
define breast_cancer_pilot_cases AS (
    all_inpatient_discharges E
    where E.class = "IMP"
        and exists (
            E.type T
            where T.coding contains Code { code: '4', system: "NHI_CASE_TYPE" }
        )
        and exists (
            E.diagnosis D
            where D.condition.resolve().code.coding C
                where C.code in { 'N', 'R', 'C' }
                    and C.system = "NHI_DISEASE_SOURCE"
        )
)

-- 4. 排除條件3：化學治療及放射線治療、抗腫瘤免疫療法
define cancer_treatment_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and C.code in { 'Z510', 'Z5111', 'Z51.12' }
            )
    )
)

-- 5. 排除條件4：早產安胎個案
define preterm_labor_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (
                        C.code = 'O4291'
                        or (C.code >= 'O4410' and C.code <= 'O4413')
                        or (C.code >= 'O4690' and C.code <= 'O4693')
                        or (C.code >= 'O4702' and C.code <= 'O4703')
                        or C.code in { 'O6002', 'O6003' }
                    )
            )
    )
)

-- 6. 排除條件5：罕見疾病（點多醣症）
define rare_disease_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (C.code >= 'E760' and C.code <= 'E763')
            )
    )
)

-- 7. 排除條件6：轉院案件（轉歸代碼5、6或7）
define transfer_cases AS (
    all_inpatient_discharges E
    where E.hospitalization.dischargeDisposition.coding C
        where C.system = "NHI_DISCHARGE_STATUS"
            and C.code in { '5', '6', '7' }
)

-- 8. 排除條件7：新生兒床號（部分負擔計費903）
define newborn_bed_cases AS (
    all_inpatient_discharges E
    where exists (
        [Claim] Cl
        where Cl.encounter.reference = ('Encounter/' + E.id)
            and exists (
                Cl.item I
                where I.revenue.coding contains Code { code: '903', system: "NHI_COPAYMENT" }
            )
    )
)

-- 9. 排除條件8：血友病
define hemophilia_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and C.code in { 'D66', 'D67', 'D681', 'D682' }
            )
    )
)

-- 10. 排除條件9：器官移植案件
define organ_transplant_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and (
                P.code.coding C where C.system = "NHI_PROCEDURE"
                    and C.code in { 
                        '68035',  -- 肺臟移植
                        '68037',  -- 雙肺移植
                        '68047',  -- 雙肺移植
                        '75020',  -- 肝臟移植
                        '76020'   -- 腎臟移植
                        -- 骨髓移植相關代碼
                    }
            )
    )
)

-- 11. 排除條件10：病患死亡或病危自動出院（轉歸代碼4或A）
define death_or_critical_discharge_cases AS (
    all_inpatient_discharges E
    where E.hospitalization.dischargeDisposition.coding C
        where C.system = "NHI_DISCHARGE_STATUS"
            and C.code in { '4', 'A' }
)

-- ==================== 非排除案件（有效出院案件） ====================

-- 排除所有條件後的有效出院案件
define valid_discharges AS (
    all_inpatient_discharges E
    where E not in oncology_cases
        and E not in breast_cancer_pilot_cases
        and E not in cancer_treatment_cases
        and E not in preterm_labor_cases
        and E not in rare_disease_cases
        and E not in transfer_cases
        and E not in newborn_bed_cases
        and E not in hemophilia_cases
        and E not in organ_transplant_cases
        and E not in death_or_critical_discharge_cases
)

-- ==================== 3日內急診案件 ====================

-- 查詢出院後3日內的急診案件
define emergency_visits_within_3_days AS (
    valid_discharges D
    let discharge_date := D.period.end,
        patient_id := D.subject.reference
    return {
        discharge_encounter_id: D.id,
        patient_id: patient_id,
        discharge_date: discharge_date,
        organization_id: D.serviceProvider.reference,
        -- 查詢此病患在出院後3日內的急診就醫
        emergency_visits: (
            [Encounter: type in "Emergency Encounter Types"] ER
            where ER.subject.reference = patient_id
                and ER.status in { 'finished', 'in-progress' }
                and ER.period.start > discharge_date
                and days between discharge_date and ER.period.start <= 3
        )
    }
)

-- 有3日內急診的出院案件
define discharges_with_3day_emergency AS (
    emergency_visits_within_3_days EV
    where exists(EV.emergency_visits)
    return {
        discharge_encounter_id: EV.discharge_encounter_id,
        patient_id: EV.patient_id,
        organization_id: EV.organization_id,
        discharge_date: EV.discharge_date,
        emergency_count: Count(EV.emergency_visits),
        first_emergency_date: First(EV.emergency_visits).period.start,
        days_to_emergency: days between EV.discharge_date and First(EV.emergency_visits).period.start
    }
)

-- ==================== 分母計算 (Denominator) ====================

-- 分母：出院案件數（排除條件後）
define denominator_total_discharges AS (
    SELECT 
        COUNT(*) as total_discharge_count,
        COUNT(DISTINCT patient_id) as unique_patient_count,
        COUNT(DISTINCT organization_id) as unique_hospital_count
    FROM 
        valid_discharges
)

-- 按季度統計分母
define denominator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        start_date: Q.start_date,
        end_date: Q.end_date,
        discharge_count: Count(
            valid_discharges D
            where D.period.end >= Q.start_date and D.period.end <= Q.end_date
        ),
        unique_patient_count: Count(
            valid_discharges D
            where D.period.end >= Q.start_date and D.period.end <= Q.end_date
            return distinct D.subject.reference
        )
    }
)

-- 年度統計分母
define denominator_annual AS (
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        start_date: annual_period.start_date,
        end_date: annual_period.end_date,
        discharge_count: Count(
            valid_discharges D
            where D.period.end >= annual_period.start_date 
                and D.period.end <= annual_period.end_date
        ),
        unique_patient_count: Count(
            valid_discharges D
            where D.period.end >= annual_period.start_date 
                and D.period.end <= annual_period.end_date
            return distinct D.subject.reference
        )
    }
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子：3日內再急診案件數
define numerator_3day_emergency_visits AS (
    SELECT 
        COUNT(*) as emergency_visit_count,
        COUNT(DISTINCT patient_id) as unique_patient_count
    FROM 
        discharges_with_3day_emergency
)

-- 按季度統計分子
define numerator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        emergency_visit_count: Count(
            discharges_with_3day_emergency D
            where D.discharge_date >= Q.start_date and D.discharge_date <= Q.end_date
        ),
        unique_patient_count: Count(
            discharges_with_3day_emergency D
            where D.discharge_date >= Q.start_date and D.discharge_date <= Q.end_date
            return distinct D.patient_id
        )
    }
)

-- 年度統計分子
define numerator_annual AS (
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        emergency_visit_count: Count(
            discharges_with_3day_emergency D
            where D.discharge_date >= annual_period.start_date 
                and D.discharge_date <= annual_period.end_date
        ),
        unique_patient_count: Count(
            discharges_with_3day_emergency D
            where D.discharge_date >= annual_period.start_date 
                and D.discharge_date <= annual_period.end_date
            return distinct D.patient_id
        )
    }
)

-- ==================== 指標計算 (Indicator Calculation) ====================

-- 按季度計算3日內急診率
define indicator_by_quarter AS (
    (numerator_by_quarter N join denominator_by_quarter D on N.quarter_id = D.quarter_id)
    return {
        indicator_code: "Indicator_108_01",
        quarter_id: N.quarter_id,
        quarter_label: N.quarter_label,
        numerator: N.emergency_visit_count,
        denominator: D.discharge_count,
        rate: if D.discharge_count > 0 
              then Round((N.emergency_visit_count / D.discharge_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((N.emergency_visit_count / D.discharge_count) * 100, 2)) + '%'
    }
)

-- 年度計算3日內急診率
define indicator_annual AS (
    {
        indicator_code: "Indicator_108_01",
        period_label: numerator_annual.period_label,
        numerator: numerator_annual.emergency_visit_count,
        denominator: denominator_annual.discharge_count,
        rate: if denominator_annual.discharge_count > 0 
              then Round((numerator_annual.emergency_visit_count / denominator_annual.discharge_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((numerator_annual.emergency_visit_count / denominator_annual.discharge_count) * 100, 2)) + '%'
    }
)

-- ==================== 綜合結果 ====================

-- 所有期間的指標結果
define all_periods_results AS (
    indicator_by_quarter 
    union 
    { indicator_annual }
)

-- ==================== 進階分析 ====================

-- 高風險案件分析（出院後1日內急診）
define high_risk_early_emergency AS (
    discharges_with_3day_emergency D
    where D.days_to_emergency <= 1
    return {
        discharge_encounter_id: D.discharge_encounter_id,
        patient_id: D.patient_id,
        organization_id: D.organization_id,
        discharge_date: D.discharge_date,
        first_emergency_date: D.first_emergency_date,
        days_to_emergency: D.days_to_emergency,
        risk_level: if D.days_to_emergency = 0 then '極高風險(當日)'
                    else '高風險(次日)'
    }
)

-- 急診天數分布分析
define emergency_days_distribution AS (
    discharges_with_3day_emergency D
    return {
        days_category: if D.days_to_emergency = 0 then '出院當日'
                      else if D.days_to_emergency = 1 then '出院後1日'
                      else if D.days_to_emergency = 2 then '出院後2日'
                      else '出院後3日',
        case_count: Count(D)
    }
    group by days_category
)

-- 醫院3日內急診率排名
define hospital_emergency_rate_ranking AS (
    discharges_with_3day_emergency D
    return {
        organization_id: D.organization_id,
        emergency_count: Count(D),
        discharge_count: Count(valid_discharges VD where VD.serviceProvider.reference = D.organization_id),
        emergency_rate: Round((Count(D) / Count(valid_discharges VD where VD.serviceProvider.reference = D.organization_id)) * 100, 2)
    }
    group by organization_id
    sort by emergency_rate desc
)

-- ==================== 主要輸出 ====================

/*
 * 主要指標結果
 * 包含季度和年度的3日內急診率
 */
define "Main Output" AS (
    all_periods_results
)

/*
 * 詳細出院案件清單
 * 3日內有急診的出院案件明細
 */
define "Detailed Discharge List" AS (
    discharges_with_3day_emergency
)

/*
 * 高風險案件清單
 * 出院後1日內急診的案件
 */
define "High Risk Cases" AS (
    high_risk_early_emergency
)

/*
 * 醫院急診率排名
 * 各醫院的3日內急診率比較
 */
define "Hospital Ranking" AS (
    hospital_emergency_rate_ranking
)
