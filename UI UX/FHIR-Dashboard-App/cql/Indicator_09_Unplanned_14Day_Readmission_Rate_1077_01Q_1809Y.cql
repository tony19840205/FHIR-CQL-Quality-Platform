library Indicator_09_Unplanned_14Day_Readmission_Rate_1077_01Q_1809Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1077.01(季)、1809(年)
// 條件依據：非計畫性住院案件出院後十四日內再住院率
// 製作日期：2025-11-20
 * 
 * 公式說明:
 * 非計畫性住院案件出院後十四日內再住院率 = 
 *     分子: 病人14日再住院人數
 *     分母: 當季出院人數
 * 
 * 分母分子均排除下列計畫性再住院案件:
 * (1)腫瘤科個案(就醫科別=13)
 * (2)乳癌試辦案件(案件分類4+疾患來源N或R或C)
 * (3)癌症、性態未明腫瘤治療(主、次診斷ICD-10-CM前3碼為C00-C96(排除C94.4、C94.6)、D37-D48、全碼Z51.0、Z51.11、Z51.12、Z08)
 * (4)早產安胎個案(主診斷ICD-10-CM：前五碼O4291及全碼O4410~O4413、O4690~O4693、O4702~O4703、O6002、O6003)
 * (5)罕見疾病(主診斷E760~E763)一點多醣症
 * (6)轉院案件(轉歸代碼5、6或7)
 * (7)新生兒床號(部分負擔計費903)
 * (8)血友病(主診斷D66、D67、D681、D682)
 * (9)執行心導管(心導管線碼手術或尿膜置換術或支架置放術)
 * (10)與手術有關之代碼前5碼為0.甲臟移植:75010、乙.腎臟移植:68003到68037(肺、肝、腎臟移植合併麻醉管理)、68043或骨髓移植後續追蹤(肺、肝、心臟、腎移植、骨髓移植:75020 d.腎臟移植:76020 e.胰臟移植:75418 f.骨髓移植:85213)
 * (11)急性後期整合照護計畫案件(住院案件分類4 + 試辦計畫代碼1 腦中風、2燒燙傷、3創傷性神經損傷、4腦弱性骨折、6衰弱高齡)
 * (12)安寧照護(給付類別A)
 * 心導管: 醫令代碼前5碼為18020、18021、97501、97502、97503、97506、97507、97508
 * 心血管線道手術: 以冠狀動脈線道手術為主，主次處置代碼(手術代碼計2)日醫令代碼前5碼為68023或68024或68025
 * 瓣膜置換術: 醫令代碼前5碼為68016、68017、68018且主診斷碼前3碼為I00-I99且主處置代碼(手術代碼計2)
 * 
 * 支架置放術: 同時申報「經皮冠狀動脈擴張術(PTCA)」及放置血管支架之案件。經皮冠狀動脈擴張術(PTCA): 主次處置代碼(手術代碼)為02703ZZ、02704ZZ、3E07317、02713ZZ、02714ZZ、02723ZZ、02733ZZ、02734ZZ且醫令代碼前5碼為33076、33077、33078。
 * 放置血管支架: 主次處置代碼(手術代碼計2)且特材代碼前7碼為CBP02A1、CBP06A1、CBP06A2及CBP06A3
 * 
 * 註1: 新增1809就行年指標統計，自統計期間101年開始產製。
 * 註2: 手術代碼請至本署健保資訊網服務系統(VPN)/下載檔案/院所醫療服務指標查詢書版「醫療服務指標操作型定義說明」檔案查詢。
 * 
 * 臨床意義:
 * - 評估出院計畫的完整性
 * - 監測醫療品質與連續性照護
 * - 辨識高風險再住院病患
 * - 降低非必要再住院
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 住院紀錄 (住院、出院)
 * - Condition: 診斷資料 (主診斷、次診斷)
 * - Procedure: 手術處置資料
 * - MedicationRequest: 用藥資料
 * - Claim: 醫療費用申報
 * - Device: 特殊材料 (支架等)
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 1077.01 (季度)
    -- 1809 (年度)

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- 用於主診斷和次診斷識別
    -- C00-C96: 惡性腫瘤 (排除C94.4、C94.6)
    -- D37-D48: 性態未明腫瘤
    -- Z51.0, Z51.11, Z51.12: 放射線治療、化學治療
    -- Z08: 惡性腫瘤治療後追蹤檢查
    -- O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003: 早產安胎
    -- E760-E763: 罕見疾病(一點多醣症)
    -- D66, D67, D681, D682: 血友病
    -- I00-I99: 心臟疾病 (配合瓣膜置換術)

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 32485007: Hospital admission (住院)
    -- 58000006: Patient discharge (病患出院)
    -- 417005: Hospital readmission (再住院)
    -- 183452005: Emergency hospital admission (緊急住院)
    -- 71388002: Procedure (手術處置)
    -- 304561000: Chemotherapy (化學治療)
    -- 33195004: Radiotherapy (放射線治療)
    -- 82433008: Organ transplantation (器官移植)
    -- 18027006: Transplantation of kidney (腎臟移植)
    -- 32413006: Transplantation of liver (肝臟移植)
    -- 32413006: Transplantation of heart (心臟移植)
    -- 52213001: Transplantation of lung (肺臟移植)
    -- 23719005: Transplantation of pancreas (胰臟移植)
    -- 23719005: Bone marrow transplantation (骨髓移植)
    -- 119565006: Malignant tumor (惡性腫瘤)
    -- 309884000: Oncology specialty (腫瘤科)
    -- 392021009: Lapsed planned readmission (計畫性再住院)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode 代碼系統
    -- IMP: 住院 (Inpatient)
    -- AMB: 門診 (Ambulatory)
    -- EMER: 急診 (Emergency)

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
    -- 台灣健保局專用代碼系統
    -- 醫事機構代碼
    -- 醫療服務代碼
    -- 案件類別代碼
    -- 醫令代碼
    -- 特材代碼

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- I: 住院
    -- O: 門診
    -- E: 急診

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
    -- 5: 轉院(計畫性)
    -- 6: 轉院(緊急)
    -- 7: 轉院(其他)

codesystem "NHI_COPAYMENT": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-copayment'
    -- 健保部分負擔計費代碼系統
    -- 903: 新生兒床號

codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
    -- 健保手術處置代碼系統
    -- 75010: 甲臟移植
    -- 68003-68037: 腎臟移植(肺、肝、腎臟移植合併麻醉管理)
    -- 68043: 骨髓移植後續追蹤
    -- 75020: 肺移植
    -- 76020: 腎臟移植
    -- 75418: 胰臟移植
    -- 85213: 骨髓移植

codesystem "NHI_ORDER": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-order'
    -- 健保醫令代碼系統
    -- 18020, 18021, 97501, 97502, 97503, 97506, 97507, 97508: 心導管
    -- 68023, 68024, 68025: 冠狀動脈線道手術
    -- 68016, 68017, 68018: 瓣膜置換術
    -- 33076, 33077, 33078: 經皮冠狀動脈擴張術(PTCA)

codesystem "NHI_MATERIAL": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-material'
    -- 健保特材代碼系統
    -- CBP02A1, CBP06A1, CBP06A2, CBP06A3: 血管支架

codesystem "NHI_PAYMENT_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-payment-type'
    -- 健保給付類別代碼系統
    -- A: 安寧照護

codesystem "NHI_PILOT_PROGRAM": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-pilot-program'
    -- 健保試辦計畫代碼系統
    -- 1: 腦中風
    -- 2: 燒燙傷
    -- 3: 創傷性神經損傷
    -- 4: 腦弱性骨折
    -- 6: 衰弱高齡

codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
    -- Current Procedural Terminology
    -- 用於手術處置代碼對照
    -- 02703ZZ, 02704ZZ, 3E07317, 02713ZZ, 02714ZZ, 02723ZZ, 02733ZZ, 02734ZZ: PTCA

-- ==================== 值集定義 ====================

valueset "Inpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/inpatient-encounter-types'
    -- 住院就醫類別值集
    -- ActCode: IMP (住院)
    -- NHI: I (住院)

valueset "Cancer Diagnosis Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-diagnosis-codes'
    -- 惡性腫瘤診斷代碼值集
    -- ICD-10-CM: C00-C96 (排除C94.4, C94.6)
    -- ICD-10-CM: D37-D48 (性態未明腫瘤)

valueset "Cancer Treatment Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-treatment-codes'
    -- 腫瘤治療代碼值集
    -- ICD-10-CM: Z51.0, Z51.11, Z51.12, Z08

valueset "Preterm Labor Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/preterm-labor-codes'
    -- 早產安胎代碼值集
    -- ICD-10-CM: O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003

valueset "Rare Disease Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/rare-disease-codes'
    -- 罕見疾病代碼值集
    -- ICD-10-CM: E760-E763 (一點多醣症)

valueset "Hemophilia Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hemophilia-codes'
    -- 血友病代碼值集
    -- ICD-10-CM: D66, D67, D681, D682

valueset "Cardiac Catheterization Orders": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cardiac-catheterization-orders'
    -- 心導管醫令代碼值集
    -- NHI_ORDER: 18020, 18021, 97501, 97502, 97503, 97506, 97507, 97508

valueset "Coronary Bypass Orders": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/coronary-bypass-orders'
    -- 冠狀動脈線道手術醫令代碼值集
    -- NHI_ORDER: 68023, 68024, 68025

valueset "Valve Replacement Orders": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/valve-replacement-orders'
    -- 瓣膜置換術醫令代碼值集
    -- NHI_ORDER: 68016, 68017, 68018

valueset "Organ Transplant Procedures": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/organ-transplant-procedures'
    -- 器官移植手術代碼值集
    -- NHI_PROCEDURE: 75010, 68003-68037, 68043, 75020, 76020, 75418, 85213

valueset "PTCA Procedures": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/ptca-procedures'
    -- 經皮冠狀動脈擴張術代碼值集
    -- CPT: 02703ZZ, 02704ZZ, 3E07317, 02713ZZ, 02714ZZ, 02723ZZ, 02733ZZ, 02734ZZ

valueset "Vascular Stent Materials": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/vascular-stent-materials'
    -- 血管支架特材代碼值集
    -- NHI_MATERIAL: CBP02A1, CBP06A1, CBP06A2, CBP06A3

valueset "Post-Acute Care Programs": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/post-acute-care-programs'
    -- 急性後期整合照護計畫值集
    -- NHI_PILOT_PROGRAM: 1(腦中風), 2(燒燙傷), 3(創傷性神經損傷), 4(腦弱性骨折), 6(衰弱高齡)

valueset "Hospice Care Payment Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hospice-care-payment-types'
    -- 安寧照護給付類別值集
    -- NHI_PAYMENT_TYPE: A

-- ==================== NHI指標代碼對照 ====================

/*
 * 指標代碼定義
 * 1077.01: 季度指標
 * 1809: 年度指標
 */
code "Indicator_1077_01": '1077.01' from "NHI_INDICATOR" display '非計畫性住院案件出院後十四日內再住院率(季)'
code "Indicator_1809": '1809' from "NHI_INDICATOR" display '非計畫性住院案件出院後十四日內再住院率(年)'

-- ==================== ICD-10-CM診斷代碼對照 ====================

/*
 * 惡性腫瘤代碼 (C00-C96, 排除C94.4, C94.6)
 * 性態未明腫瘤代碼 (D37-D48)
 * 腫瘤治療代碼 (Z51.0, Z51.11, Z51.12, Z08)
 * 早產安胎代碼 (O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003)
 * 罕見疾病代碼 (E760-E763)
 * 血友病代碼 (D66, D67, D681, D682)
 * 心臟疾病代碼 (I00-I99)
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

code "Transfer_Status_5": '5' from "NHI_DISCHARGE_STATUS" display '轉院(計畫性)'
code "Transfer_Status_6": '6' from "NHI_DISCHARGE_STATUS" display '轉院(緊急)'
code "Transfer_Status_7": '7' from "NHI_DISCHARGE_STATUS" display '轉院(其他)'

-- ==================== 健保部分負擔計費代碼對照 ====================

code "Newborn_Copayment": '903' from "NHI_COPAYMENT" display '新生兒床號'

-- ==================== 健保給付類別代碼對照 ====================

code "Hospice_Payment": 'A' from "NHI_PAYMENT_TYPE" display '安寧照護'

-- ==================== 健保試辦計畫代碼對照 ====================

code "Pilot_Stroke": '1' from "NHI_PILOT_PROGRAM" display '腦中風'
code "Pilot_Burn": '2' from "NHI_PILOT_PROGRAM" display '燒燙傷'
code "Pilot_Trauma": '3' from "NHI_PILOT_PROGRAM" display '創傷性神經損傷'
code "Pilot_Fracture": '4' from "NHI_PILOT_PROGRAM" display '腦弱性骨折'
code "Pilot_Frailty": '6' from "NHI_PILOT_PROGRAM" display '衰弱高齡'

-- ==================== 參數定義 ====================

parameter "Measurement Period" Interval<DateTime>
    -- 統計期間（季度或年度）

parameter "Readmission Days" Integer default 14
    -- 再住院觀察天數（預設14天）

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
define all_inpatient_discharges AS (
    [Encounter: type in "Inpatient Encounter Types"] E
    where E.status = 'finished'
        and E.period.end during "Measurement Period"
        and E.hospitalization.dischargeDisposition is not null
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

-- 4. 排除條件3：癌症、性態未明腫瘤治療
define cancer_treatment_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                -- C00-C96 (排除C94.4, C94.6)
                (D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (C.code >= 'C00' and C.code <= 'C96')
                    and C.code not in { 'C94.4', 'C94.6' }
                )
                -- D37-D48
                or (D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (C.code >= 'D37' and C.code <= 'D48')
                )
                -- Z51.0, Z51.11, Z51.12, Z08
                or (D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and C.code in { 'Z51.0', 'Z51.11', 'Z51.12', 'Z08' }
                )
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

-- 6. 排除條件5：罕見疾病（一點多醣症）
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

-- 10. 排除條件9：執行心導管
define cardiac_catheterization_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and (
                -- 心導管醫令代碼
                P.code.coding C where C.system = "NHI_ORDER"
                    and Substring(C.code, 0, 5) in { '18020', '18021', '97501', '97502', '97503', '97506', '97507', '97508' }
            )
    )
)

-- 11. 排除條件10：心血管線道手術
define coronary_bypass_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and P.code.coding C where C.system = "NHI_ORDER"
                and Substring(C.code, 0, 5) in { '68023', '68024', '68025' }
    )
)

-- 12. 排除條件11：瓣膜置換術
define valve_replacement_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and P.code.coding C where C.system = "NHI_ORDER"
                and Substring(C.code, 0, 5) in { '68016', '68017', '68018' }
    )
    and exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and Substring(C.code, 0, 3) >= 'I00' and Substring(C.code, 0, 3) <= 'I99'
            )
    )
)

-- 13. 排除條件12：器官移植案件
define organ_transplant_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and (
                P.code.coding C where C.system = "NHI_PROCEDURE"
                    and (
                        C.code = '75010'  -- 甲臟移植
                        or (C.code >= '68003' and C.code <= '68037')  -- 腎臟移植合併麻醉
                        or C.code = '68043'  -- 骨髓移植後續追蹤
                        or C.code = '75020'  -- 肺移植
                        or C.code = '76020'  -- 腎臟移植
                        or C.code = '75418'  -- 胰臟移植
                        or C.code = '85213'  -- 骨髓移植
                    )
            )
    )
)

-- 14. 排除條件13：支架置放術（PTCA + 血管支架）
define stent_placement_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            -- PTCA手術代碼
            and P.code.coding C where C.system = "CPT"
                and C.code in { '02703ZZ', '02704ZZ', '3E07317', '02713ZZ', '02714ZZ', '02723ZZ', '02733ZZ', '02734ZZ' }
    )
    and exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            -- 醫令代碼前5碼為33076, 33077, 33078
            and P.code.coding C where C.system = "NHI_ORDER"
                and Substring(C.code, 0, 5) in { '33076', '33077', '33078' }
    )
    and exists (
        [Device] D
        where D.patient.reference = ('Patient/' + E.subject.reference)
            -- 特材代碼前7碼為CBP02A1, CBP06A1, CBP06A2, CBP06A3
            and D.deviceName.name.coding C where C.system = "NHI_MATERIAL"
                and Substring(C.code, 0, 7) in { 'CBP02A1', 'CBP06A1', 'CBP06A2', 'CBP06A3' }
    )
)

-- 15. 排除條件14：急性後期整合照護計畫案件
define post_acute_care_cases AS (
    all_inpatient_discharges E
    where E.class = "IMP"
        and exists (
            E.type T
            where T.coding contains Code { code: '4', system: "NHI_CASE_TYPE" }
        )
        and exists (
            [Claim] Cl
            where Cl.encounter.reference = ('Encounter/' + E.id)
                and exists (
                    Cl.item I
                    where I.programCode.coding C
                        where C.system = "NHI_PILOT_PROGRAM"
                            and C.code in { '1', '2', '3', '4', '6' }
                )
        )
)

-- 16. 排除條件15：安寧照護（給付類別A）
define hospice_care_cases AS (
    all_inpatient_discharges E
    where exists (
        [Claim] Cl
        where Cl.encounter.reference = ('Encounter/' + E.id)
            and Cl.type.coding contains Code { code: 'A', system: "NHI_PAYMENT_TYPE" }
    )
)

-- ==================== 非計畫性住院案件 ====================

-- 排除所有計畫性再住院條件後的非計畫性住院案件
define unplanned_discharges AS (
    all_inpatient_discharges E
    where E not in oncology_cases
        and E not in breast_cancer_pilot_cases
        and E not in cancer_treatment_cases
        and E not in preterm_labor_cases
        and E not in rare_disease_cases
        and E not in transfer_cases
        and E not in newborn_bed_cases
        and E not in hemophilia_cases
        and E not in cardiac_catheterization_cases
        and E not in coronary_bypass_cases
        and E not in valve_replacement_cases
        and E not in organ_transplant_cases
        and E not in stent_placement_cases
        and E not in post_acute_care_cases
        and E not in hospice_care_cases
)

-- ==================== 14日內再住院案件 ====================

-- 查詢14日內的再住院案件
define readmissions_within_14_days AS (
    unplanned_discharges D
    let discharge_date := D.period.end,
        patient_id := D.subject.reference
    return {
        discharge_encounter_id: D.id,
        patient_id: patient_id,
        discharge_date: discharge_date,
        -- 查詢此病患在出院後14日內的再住院
        readmission_encounters: (
            [Encounter: type in "Inpatient Encounter Types"] R
            where R.subject.reference = patient_id
                and R.status = 'finished'
                and R.id != D.id
                and R.period.start > discharge_date
                and days between discharge_date and R.period.start <= 14
                -- 排除計畫性再住院
                and R not in oncology_cases
                and R not in breast_cancer_pilot_cases
                and R not in cancer_treatment_cases
                and R not in preterm_labor_cases
                and R not in rare_disease_cases
                and R not in transfer_cases
                and R not in newborn_bed_cases
                and R not in hemophilia_cases
                and R not in cardiac_catheterization_cases
                and R not in coronary_bypass_cases
                and R not in valve_replacement_cases
                and R not in organ_transplant_cases
                and R not in stent_placement_cases
                and R not in post_acute_care_cases
                and R not in hospice_care_cases
        )
    }
)

-- 有14日內再住院的病患
define patients_with_14day_readmission AS (
    readmissions_within_14_days R
    where exists(R.readmission_encounters)
    return {
        patient_id: R.patient_id,
        discharge_encounter_id: R.discharge_encounter_id,
        discharge_date: R.discharge_date,
        readmission_count: Count(R.readmission_encounters),
        first_readmission_date: First(R.readmission_encounters).period.start,
        days_to_readmission: days between R.discharge_date and First(R.readmission_encounters).period.start
    }
)

-- ==================== 分母計算 (Denominator) ====================

-- 分母：當季出院人數（排除計畫性再住院案件）
define denominator_discharge_patients AS (
    SELECT 
        COUNT(DISTINCT patient_id) as unique_patient_count,
        COUNT(*) as total_discharge_count
    FROM 
        unplanned_discharges
)

-- 按季度統計分母
define denominator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        start_date: Q.start_date,
        end_date: Q.end_date,
        discharge_patient_count: Count(
            unplanned_discharges D
            where D.period.end >= Q.start_date and D.period.end <= Q.end_date
            return distinct D.subject.reference
        ),
        total_discharge_count: Count(
            unplanned_discharges D
            where D.period.end >= Q.start_date and D.period.end <= Q.end_date
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
        discharge_patient_count: Count(
            unplanned_discharges D
            where D.period.end >= annual_period.start_date 
                and D.period.end <= annual_period.end_date
            return distinct D.subject.reference
        ),
        total_discharge_count: Count(
            unplanned_discharges D
            where D.period.end >= annual_period.start_date 
                and D.period.end <= annual_period.end_date
        )
    }
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子：病人14日再住院人數
define numerator_14day_readmission_patients AS (
    SELECT 
        COUNT(DISTINCT patient_id) as readmission_patient_count,
        COUNT(*) as total_readmission_count
    FROM 
        patients_with_14day_readmission
)

-- 按季度統計分子
define numerator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        readmission_patient_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= Q.start_date and P.discharge_date <= Q.end_date
            return distinct P.patient_id
        ),
        total_readmission_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= Q.start_date and P.discharge_date <= Q.end_date
        )
    }
)

-- 年度統計分子
define numerator_annual AS (
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        readmission_patient_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= annual_period.start_date 
                and P.discharge_date <= annual_period.end_date
            return distinct P.patient_id
        ),
        total_readmission_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= annual_period.start_date 
                and P.discharge_date <= annual_period.end_date
        )
    }
)

-- ==================== 指標計算 (Indicator Calculation) ====================

-- 按季度計算14日內再住院率
define indicator_by_quarter AS (
    (numerator_by_quarter N join denominator_by_quarter D on N.quarter_id = D.quarter_id)
    return {
        indicator_code: "Indicator_1077_01",
        quarter_id: N.quarter_id,
        quarter_label: N.quarter_label,
        numerator: N.readmission_patient_count,
        denominator: D.discharge_patient_count,
        rate: if D.discharge_patient_count > 0 
              then Round((N.readmission_patient_count / D.discharge_patient_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((N.readmission_patient_count / D.discharge_patient_count) * 100, 2)) + '%'
    }
)

-- 年度計算14日內再住院率
define indicator_annual AS (
    {
        indicator_code: "Indicator_1809",
        period_label: numerator_annual.period_label,
        numerator: numerator_annual.readmission_patient_count,
        denominator: denominator_annual.discharge_patient_count,
        rate: if denominator_annual.discharge_patient_count > 0 
              then Round((numerator_annual.readmission_patient_count / denominator_annual.discharge_patient_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((numerator_annual.readmission_patient_count / denominator_annual.discharge_patient_count) * 100, 2)) + '%'
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

-- 高風險再住院病患分析
define high_risk_readmission_patients AS (
    patients_with_14day_readmission P
    where P.readmission_count > 1
        or P.days_to_readmission <= 7
    return {
        patient_id: P.patient_id,
        discharge_date: P.discharge_date,
        readmission_count: P.readmission_count,
        days_to_readmission: P.days_to_readmission,
        risk_level: if P.days_to_readmission <= 3 then '極高風險'
                    else if P.days_to_readmission <= 7 then '高風險'
                    else if P.readmission_count > 1 then '多次再住院'
                    else '中度風險'
    }
)

-- 再住院天數分布分析
define readmission_days_distribution AS (
    patients_with_14day_readmission P
    return {
        days_category: if P.days_to_readmission <= 3 then '0-3天'
                      else if P.days_to_readmission <= 7 then '4-7天'
                      else if P.days_to_readmission <= 10 then '8-10天'
                      else '11-14天',
        patient_count: Count(P)
    }
    group by days_category
)

-- ==================== 主要輸出 ====================

/*
 * 主要指標結果
 * 包含季度和年度的14日內再住院率
 */
define "Main Output" AS (
    all_periods_results
)

/*
 * 詳細病患清單
 * 14日內再住院的病患明細
 */
define "Detailed Patient List" AS (
    patients_with_14day_readmission
)

/*
 * 高風險病患清單
 * 需要特別關注的再住院病患
 */
define "High Risk Patients" AS (
    high_risk_readmission_patients
)
