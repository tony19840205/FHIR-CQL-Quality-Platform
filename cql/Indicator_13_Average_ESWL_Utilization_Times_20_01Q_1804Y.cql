library Indicator_13_Average_ESWL_Utilization_Times_20_01Q_1804Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 接受體外震波碎石術(ESWL)病人平均利用ESWL之次數
// 指標代碼: 1804
// 製作日期：2025-11-20

/*
 * 指標名稱: 13. 接受體外震波碎石術(ESWL)病人平均利用ESWL之次數
 * Indicator: Average number of ESWL procedures per patient receiving ESWL
 * 指標代碼暫以: 20.01 (季), 1804年 - 根據檔名說明
 * 檔名: 13_接受體外震波碎石術(ESWL)病人平均利用ESWL之次數(20.01季 1804年).cql
 *
 * 說明:
 * - 分子: 在觀察期內發生之 ESWL (體外震波碎石術) 總次數
 * - 分母: 在觀察期內接受至少一次 ESWL 之個別病人數 (unique patients)
 * - 指標值: 平均每位接受 ESWL 病人之 ESWL 次數 = 分子 / 分母
 *
 * 注意: 本CQL以常用的國際代碼作為初始代碼集 (SNOMED CT, CPT, ICD10-PCS 等)。
 * 若您有完整的在地代碼（NHI_PROCEDURE、國內ICD/手術代碼等），請提供，我會立即替換或補齊。
 */

-- ==================== Codesystem 定義 ====================

codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ICD10PCS": 'http://hl7.org/fhir/sid/icd-10-pcs'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
codesystem "LOINC": 'http://loinc.org'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "DRG_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'
codesystem "TW_DRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'
codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'

-- ==================== Code 定義 (示例) ====================
-- 註: 下列代碼為常見或國際代碼，請於需要時提供在地完整清單以便更新

-- SNOMED CT
code "SNOMED_ESWL" : '80146002' from "SNOMEDCT" display 'Extracorporeal shockwave lithotripsy (ESWL)'

-- CPT
code "CPT_ESWL_50590" : '50590' from "CPT" display 'Lithotripsy, extracorporeal shock wave; pyelolithotomy; fragmentation of renal calculi'

-- ICD-10-PCS (示例，需確認)
code "ICD10PCS_ESWL_0TF" : '0TF00ZZ' from "ICD10PCS" display 'Extracorporeal lithotripsy, kidney (approximate)'

-- NHI 處置代碼 (需要在地代碼清單，以下為示例 placeholder)
code "NHI_ESWL_XXXX" : 'XXXX' from "NHI_PROCEDURE" display 'ESWL (placeholder - replace with actual NHI code)'

-- LOINC (若有觀察值相關)
code "LOINC_ESWL_INDICATION" : '57074-7' from "LOINC" display 'Indication for lithotripsy (example)'

-- ==================== ValueSet 定義 ====================
valueset "ESWL_Procedures_ValueSet": 'urn:oid:1.2.840.10008.2.16.4' -- (placeholder URI; replace with authoritative valueset URI if available)

-- ==================== 參數 ====================
parameter "Measurement_Period" Interval<DateTime>
    default Interval[@2024-01-01T00:00:00.0, @2024-12-31T23:59:59.999]

context Patient

-- ==================== 定義: ESWL Procedures ====================

-- 取得觀察期內的 Procedure 資源，符合 ESWL 相關代碼
define "ESWL_Procedures":
    [Procedure] P
        where P.status = 'completed'
            and exists (P.code.coding C where 
                (
                    C.system = 'http://snomed.info/sct' and C.code in { '80146002' }
                ) or (
                    C.system = 'http://www.ama-assn.org/go/cpt' and C.code in { '50590' }
                ) or (
                    C.system = 'http://hl7.org/fhir/sid/icd-10-pcs' and C.code in { '0TF00ZZ' }
                ) or (
                    C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure' and C.code in { 'XXXX' }
                )
            )
            and P.performed during "Measurement_Period"

-- 若需要限制在住院或門診，可額外篩選 Encounter/class

-- ==================== 定義: 每位病人的 ESWL 次數 ====================
-- 針對每位 Patient 計算在觀察期內之 ESWL Procedure 次數

define "Patient_ESWL_Counts":
    {
        PatientId: id Patient,
        ESWLCount: Count(
            [Procedure] P
                where P.subject.reference = 'Patient/' + id Patient
                    and exists (P.code.coding C where 
                        (
                            C.system = 'http://snomed.info/sct' and C.code in { '80146002' }
                        ) or (
                            C.system = 'http://www.ama-assn.org/go/cpt' and C.code in { '50590' }
                        ) or (
                            C.system = 'http://hl7.org/fhir/sid/icd-10-pcs' and C.code in { '0TF00ZZ' }
                        ) or (
                            C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure' and C.code in { 'XXXX' }
                        )
                    )
                    and P.performed during "Measurement_Period"
        )
    }

-- ==================== 定義: 接受至少一次 ESWL 之病人名單 ====================

define "Patients_With_ESWL":
    distinct (
        [Patient] PAT
            where exists (
                [Procedure] P
                    where P.subject.reference = 'Patient/' + id PAT
                        and exists (P.code.coding C where 
                            (
                                C.system = 'http://snomed.info/sct' and C.code in { '80146002' }
                            ) or (
                                C.system = 'http://www.ama-assn.org/go/cpt' and C.code in { '50590' }
                            ) or (
                                C.system = 'http://hl7.org/fhir/sid/icd-10-pcs' and C.code in { '0TF00ZZ' }
                            ) or (
                                C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure' and C.code in { 'XXXX' }
                            )
                        )
                        and P.performed during "Measurement_Period"
            )
    )

-- ==================== 定義: 總 ESWL 次數 (分子) ====================

define "Total_ESWL_Procedures":
    Count(
        [Procedure] P
            where exists (P.code.coding C where 
                (
                    C.system = 'http://snomed.info/sct' and C.code in { '80146002' }
                ) or (
                    C.system = 'http://www.ama-assn.org/go/cpt' and C.code in { '50590' }
                ) or (
                    C.system = 'http://hl7.org/fhir/sid/icd-10-pcs' and C.code in { '0TF00ZZ' }
                ) or (
                    C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure' and C.code in { 'XXXX' }
                )
            )
            and P.performed during "Measurement_Period"
    )

-- ==================== 定義: 接受 ESWL 之病人數 (分母) ====================

define "Number_of_Patients_With_ESWL":
    Count("Patients_With_ESWL")

-- ==================== 定義: 平均每位病人之 ESWL 次數 (指標) ====================

define "Average_ESWL_Per_Patient":
    if "Number_of_Patients_With_ESWL" > 0
    then ("Total_ESWL_Procedures" / "Number_of_Patients_With_ESWL")
    else null

-- ==================== 輸出結果物件 ====================

define "Indicator_13_Result":
    {
        IndicatorName: '接受體外震波碎石術(ESWL)病人平均利用ESWL之次數',
        IndicatorCode: '13',
        MeasurementPeriod: "Measurement_Period",
        TotalESWLProcedures: "Total_ESWL_Procedures",
        PatientsWithESWL: "Number_of_Patients_With_ESWL",
        AveragePerPatient: "Average_ESWL_Per_Patient"
    }

-- End of file
