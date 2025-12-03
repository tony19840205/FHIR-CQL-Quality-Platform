library Indicator_14_Uterine_Fibroid_Surgery_14Day_Readmission_473_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率
// 指標代碼: 473.01
// 製作日期：2025-11-20

/*
 * 指標名稱: 14. 子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率
 * Indicator: Readmission Rate within 14 Days after Uterine Myomectomy Surgery Due to Related Diagnosis
 * 指標代碼: 473.01
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 資料範圍: 
 *   (1) 每季所有屬醫院總額之住院案件
 *   (2) 排除代辦案件
 * 
 * 公式說明:
 * 分子: 分母案件出院14日內因該手術相關診斷再住院次數
 * 分母: 申報子宮肌瘤診斷(排除癌症診斷)且有施行子宮肌瘤摘除或子宮切除手術治療住院人次數
 * 
 * 子宮肌瘤診斷: 住診案件任一主次診斷之ICD-10-CM前3碼為D25
 * 
 * 癌症診斷: 門、住診案件任一主、次診斷前3碼為C00-C96(但排除C944、C946)、D37-D48、
 *           全碼Z51.12、J84.81
 * 
 * 子宮肌瘤摘除術: 住診案件，醫令類別2日醫令代碼97010K、97011A、97012B、97013B、80402C、
 *                 80420C、80415B、97013C、80415C、80425C
 * 
 * 子宮切除術: 住診案件，醫令類別2日醫令代碼97025K、97026A、97027B、97020K、97021A、97022B、
 *             97035K、97036A、97037B、80403B、80404B、80421B、80416B、80412B、97027C、80404C
 * 
 * 相關診斷: 住診案件，任一主、次診斷前3碼N70-N85
 * 
 * 14日內再住院率計算方式:
 * 住診:(再次住院入院日 - 手術當次住院出院日) <= 14 (跨院)
 * 
 * 子宮肌瘤診斷與手術(子宮肌瘤摘除或子宮切除手術)需限定發生在同一清單案件(同案件分類、流水號)
 * 
 * 製表日期: 114/05/13
 * 製表單位: 衛生福利部 中央健康保險署
 */

-- ==================== Codesystem 定義 ====================

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://hl7.org/fhir/sid/icd-10-pcs'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "LOINC": 'http://loinc.org'
codesystem "TW_DRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'
codesystem "DRG_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'
codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'

-- ==================== Code 定義 ====================

-- ICD-10-CM 子宮肌瘤診斷 (D25)
code "Uterine_Leiomyoma_D25": 'D25' from "ICD10CM" display '子宮平滑肌瘤(子宮肌瘤)'
code "Uterine_Leiomyoma_D250": 'D25.0' from "ICD10CM" display '子宮體部之黏膜下平滑肌瘤'
code "Uterine_Leiomyoma_D251": 'D25.1' from "ICD10CM" display '子宮體部之壁內平滑肌瘤'
code "Uterine_Leiomyoma_D252": 'D25.2' from "ICD10CM" display '子宮體部之漿膜下平滑肌瘤'
code "Uterine_Leiomyoma_D259": 'D25.9' from "ICD10CM" display '子宮平滑肌瘤，未明示部位'

-- ICD-10-CM 癌症診斷 (排除項目)
-- C00-C96 (惡性腫瘤，但排除C944、C946)
code "Cancer_Exclusion_C944": 'C94.4' from "ICD10CM" display '急性全骨髓性白血病(排除)'
code "Cancer_Exclusion_C946": 'C94.6' from "ICD10CM" display '骨髓增生性疾病(排除)'

-- D37-D48 (不確定或未知性質之腫瘤)
code "Cancer_Neoplasm_D37": 'D37' from "ICD10CM" display '口腔及消化器官之不確定或未知性質之腫瘤'
code "Cancer_Neoplasm_D48": 'D48' from "ICD10CM" display '其他及未明示部位之不確定或未知性質之腫瘤'

-- Z51.12, J84.81
code "Cancer_Chemo_Z5112": 'Z51.12' from "ICD10CM" display '抗腫瘤化學治療之後續照護'
code "Cancer_Related_J8481": 'J84.81' from "ICD10CM" display '淋巴管平滑肌瘤病'

-- ICD-10-CM 相關診斷 (N70-N85: 女性生殖器官炎症性疾病)
code "Related_Diagnosis_N70": 'N70' from "ICD10CM" display '輸卵管炎及卵巢炎'
code "Related_Diagnosis_N71": 'N71' from "ICD10CM" display '子宮之炎症性疾病，子宮頸除外'
code "Related_Diagnosis_N72": 'N72' from "ICD10CM" display '子宮頸之炎症性疾病'
code "Related_Diagnosis_N73": 'N73' from "ICD10CM" display '其他女性骨盆腔炎症性疾病'
code "Related_Diagnosis_N74": 'N74' from "ICD10CM" display '他處歸類的疾病引起之女性骨盆腔炎症性疾患'
code "Related_Diagnosis_N75": 'N75' from "ICD10CM" display '巴氏腺之疾病'
code "Related_Diagnosis_N76": 'N76' from "ICD10CM" display '陰道及外陰之其他炎症'
code "Related_Diagnosis_N77": 'N77' from "ICD10CM" display '他處歸類的疾病引起之外陰陰道潰瘍及炎症'
code "Related_Diagnosis_N80": 'N80' from "ICD10CM" display '子宮內膜異位'
code "Related_Diagnosis_N81": 'N81' from "ICD10CM" display '女性生殖器官脫垂'
code "Related_Diagnosis_N82": 'N82' from "ICD10CM" display '涉及女性生殖道之瘻管'
code "Related_Diagnosis_N83": 'N83' from "ICD10CM" display '卵巢、輸卵管及寬韌帶之非炎症性疾患'
code "Related_Diagnosis_N84": 'N84' from "ICD10CM" display '女性生殖道之息肉'
code "Related_Diagnosis_N85": 'N85' from "ICD10CM" display '子宮之其他非炎症性疾患，子宮頸除外'

-- 健保處置代碼 - 子宮肌瘤摘除術
code "NHI_Myomectomy_97010K": '97010K' from "NHI_PROCEDURE" display '子宮肌瘤摘除術-腹腔鏡'
code "NHI_Myomectomy_97011A": '97011A' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_97012B": '97012B' from "NHI_PROCEDURE" display '子宮肌瘤摘除術(含腹腔鏡)'
code "NHI_Myomectomy_97013B": '97013B' from "NHI_PROCEDURE" display '腹腔鏡子宮肌瘤摘除術'
code "NHI_Myomectomy_80402C": '80402C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_80420C": '80420C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術(腹腔鏡)'
code "NHI_Myomectomy_80415B": '80415B' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_97013C": '97013C' from "NHI_PROCEDURE" display '腹腔鏡子宮肌瘤摘除術'
code "NHI_Myomectomy_80415C": '80415C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_80425C": '80425C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術(腹腔鏡)'

-- 健保處置代碼 - 子宮切除術
code "NHI_Hysterectomy_97025K": '97025K' from "NHI_PROCEDURE" display '子宮切除術-腹腔鏡'
code "NHI_Hysterectomy_97026A": '97026A' from "NHI_PROCEDURE" display '子宮切除術'
code "NHI_Hysterectomy_97027B": '97027B' from "NHI_PROCEDURE" display '子宮切除術(含腹腔鏡)'
code "NHI_Hysterectomy_97020K": '97020K' from "NHI_PROCEDURE" display '全子宮切除術-腹腔鏡'
code "NHI_Hysterectomy_97021A": '97021A' from "NHI_PROCEDURE" display '全子宮切除術'
code "NHI_Hysterectomy_97022B": '97022B' from "NHI_PROCEDURE" display '全子宮切除術(含腹腔鏡)'
code "NHI_Hysterectomy_97035K": '97035K' from "NHI_PROCEDURE" display '次全子宮切除術-腹腔鏡'
code "NHI_Hysterectomy_97036A": '97036A' from "NHI_PROCEDURE" display '次全子宮切除術'
code "NHI_Hysterectomy_97037B": '97037B' from "NHI_PROCEDURE" display '次全子宮切除術(含腹腔鏡)'
code "NHI_Hysterectomy_80403B": '80403B' from "NHI_PROCEDURE" display '子宮切除術'
code "NHI_Hysterectomy_80404B": '80404B' from "NHI_PROCEDURE" display '子宮切除術(腹腔鏡)'
code "NHI_Hysterectomy_80421B": '80421B' from "NHI_PROCEDURE" display '全子宮切除術'
code "NHI_Hysterectomy_80416B": '80416B' from "NHI_PROCEDURE" display '子宮切除術'
code "NHI_Hysterectomy_80412B": '80412B' from "NHI_PROCEDURE" display '次全子宮切除術'
code "NHI_Hysterectomy_97027C": '97027C' from "NHI_PROCEDURE" display '子宮切除術(腹腔鏡)'
code "NHI_Hysterectomy_80404C": '80404C' from "NHI_PROCEDURE" display '子宮切除術(腹腔鏡)'

-- SNOMED CT - 子宮肌瘤
code "SNOMED_Uterine_Leiomyoma": '95315005' from "SNOMEDCT" display 'Leiomyoma of uterus'
code "SNOMED_Fibroid_Uterus": '78000009' from "SNOMEDCT" display 'Fibroid uterus'

-- SNOMED CT - 子宮肌瘤摘除術
code "SNOMED_Myomectomy": '176697007' from "SNOMEDCT" display 'Myomectomy'
code "SNOMED_Laparoscopic_Myomectomy": '69712005' from "SNOMEDCT" display 'Laparoscopic myomectomy'

-- SNOMED CT - 子宮切除術
code "SNOMED_Hysterectomy": '236886002' from "SNOMEDCT" display 'Hysterectomy'
code "SNOMED_Total_Hysterectomy": '116140006' from "SNOMEDCT" display 'Total hysterectomy'
code "SNOMED_Subtotal_Hysterectomy": '387643005' from "SNOMEDCT" display 'Subtotal hysterectomy'
code "SNOMED_Laparoscopic_Hysterectomy": '446446002' from "SNOMEDCT" display 'Laparoscopic hysterectomy'

-- CPT - 子宮肌瘤摘除術
code "CPT_Myomectomy_58140": '58140' from "CPT" display 'Myomectomy, excision of fibroid tumor(s) of uterus'
code "CPT_Myomectomy_58145": '58145' from "CPT" display 'Myomectomy, excision of fibroid tumor(s), with total weight > 250 grams'
code "CPT_Myomectomy_58146": '58146' from "CPT" display 'Myomectomy, excision of fibroid tumor(s), with total weight > 250 grams, with removal of tube(s) and/or ovary(s)'

-- CPT - 子宮切除術
code "CPT_Hysterectomy_58150": '58150' from "CPT" display 'Total abdominal hysterectomy'
code "CPT_Hysterectomy_58180": '58180' from "CPT" display 'Supracervical abdominal hysterectomy'
code "CPT_Hysterectomy_58260": '58260' from "CPT" display 'Vaginal hysterectomy'
code "CPT_Hysterectomy_58550": '58550' from "CPT" display 'Laparoscopy, surgical, with vaginal hysterectomy'
code "CPT_Hysterectomy_58570": '58570' from "CPT" display 'Laparoscopy, surgical, with total hysterectomy'

-- ActCode
code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'

-- ==================== ValueSet 定義 ====================

valueset "Uterine_Leiomyoma_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/uterine-leiomyoma-diagnosis'
valueset "Cancer_Exclusion_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-exclusion'
valueset "Myomectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/myomectomy-procedures'
valueset "Hysterectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hysterectomy-procedures'
valueset "Related_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/gynecologic-related-diagnosis'

-- ==================== 參數 ====================

parameter "Measurement_Period" Interval<DateTime>
    default Interval[@2024-01-01T00:00:00.0, @2024-12-31T23:59:59.999]

-- ==================== Context 定義 ====================

context Patient

-- ==================== 主要定義 ====================

/*
 * 定義1: 住院案件（排除代辦案件）
 */
define "Inpatient_Encounters":
    [Encounter: type in "ActCode_Inpatient"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Inpatient"
            and E.period ends during "Measurement_Period"
            and not exists (
                E.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/proxy-case'
                        and Ex.valueBoolean = true
            )

/*
 * 定義2: 子宮肌瘤診斷（D25）
 * 住診案件任一主次診斷之ICD-10-CM前3碼為D25
 */
define "Has_Uterine_Leiomyoma_Diagnosis":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        Cod.code = 'D25'
                        or Cod.code starts with 'D25.'
                    )
        )
        and C.category.exists(cat: cat.coding.exists(c: c.code in {'principal-diagnosis', 'secondary-diagnosis', 'encounter-diagnosis'}))

/*
 * 定義3: 癌症診斷（排除項目）
 * C00-C96(但排除C944、C946)、D37-D48、Z51.12、J84.81
 */
define "Has_Cancer_Diagnosis":
    exists (
        [Condition] C
            where exists (
                C.code.coding Cod
                    where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                        and (
                            // C00-C96 (但排除C94.4和C94.6)
                            (
                                (Cod.code >= 'C00' and Cod.code < 'C97')
                                and Cod.code != 'C94.4'
                                and Cod.code != 'C94.6'
                            )
                            // D37-D48
                            or (Cod.code >= 'D37' and Cod.code < 'D49')
                            // Z51.12
                            or Cod.code = 'Z51.12'
                            // J84.81
                            or Cod.code = 'J84.81'
                        )
            )
            and C.category.exists(cat: cat.coding.exists(c: c.code in {'principal-diagnosis', 'secondary-diagnosis', 'encounter-diagnosis'}))
    )

/*
 * 定義4: 子宮肌瘤摘除術
 * 醫令類別2日醫令代碼: 97010K、97011A、97012B、97013B、80402C、80420C、80415B、97013C、80415C、80425C
 */
define "Has_Myomectomy_Procedure":
    exists (
        [Procedure] P
            where P.status = 'completed'
                and exists (
                    P.code.coding Cod
                        where (
                            Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                            and Cod.code in {
                                '97010K', '97011A', '97012B', '97013B', '80402C',
                                '80420C', '80415B', '97013C', '80415C', '80425C'
                            }
                        )
                        or (
                            Cod.system = 'http://snomed.info/sct'
                            and Cod.code in {'176697007', '69712005'}
                        )
                        or (
                            Cod.system = 'http://www.ama-assn.org/go/cpt'
                            and Cod.code in {'58140', '58145', '58146'}
                        )
                )
    )

/*
 * 定義5: 子宮切除術
 * 醫令類別2日醫令代碼: 97025K、97026A、97027B、97020K、97021A、97022B、97035K、97036A、97037B、
 *                     80403B、80404B、80421B、80416B、80412B、97027C、80404C
 */
define "Has_Hysterectomy_Procedure":
    exists (
        [Procedure] P
            where P.status = 'completed'
                and exists (
                    P.code.coding Cod
                        where (
                            Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                            and Cod.code in {
                                '97025K', '97026A', '97027B', '97020K', '97021A', '97022B',
                                '97035K', '97036A', '97037B', '80403B', '80404B', '80421B',
                                '80416B', '80412B', '97027C', '80404C'
                            }
                        )
                        or (
                            Cod.system = 'http://snomed.info/sct'
                            and Cod.code in {'236886002', '116140006', '387643005', '446446002'}
                        )
                        or (
                            Cod.system = 'http://www.ama-assn.org/go/cpt'
                            and Cod.code in {'58150', '58180', '58260', '58550', '58570'}
                        )
                )
    )

/*
 * 定義6: 分母案件
 * 申報子宮肌瘤診斷(排除癌症診斷)且有施行子宮肌瘤摘除或子宮切除手術治療住院人次數
 */
define "Denominator_Cases":
    "Inpatient_Encounters" E
        where exists (
            [Condition] C
                where C.encounter.reference = 'Encounter/' + E.id
                    and exists (
                        C.code.coding Cod
                            where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                                and (
                                    Cod.code = 'D25'
                                    or Cod.code starts with 'D25.'
                                )
                    )
        )
        // 排除癌症診斷
        and not exists (
            [Condition] C
                where C.encounter.reference = 'Encounter/' + E.id
                    and exists (
                        C.code.coding Cod
                            where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                                and (
                                    (
                                        (Cod.code >= 'C00' and Cod.code < 'C97')
                                        and Cod.code != 'C94.4'
                                        and Cod.code != 'C94.6'
                                    )
                                    or (Cod.code >= 'D37' and Cod.code < 'D49')
                                    or Cod.code = 'Z51.12'
                                    or Cod.code = 'J84.81'
                                )
                    )
        )
        // 有子宮肌瘤摘除術或子宮切除術
        and (
            exists (
                [Procedure] P
                    where P.encounter.reference = 'Encounter/' + E.id
                        and P.status = 'completed'
                        and exists (
                            P.code.coding Cod
                                where (
                                    Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                                    and Cod.code in {
                                        '97010K', '97011A', '97012B', '97013B', '80402C',
                                        '80420C', '80415B', '97013C', '80415C', '80425C'
                                    }
                                )
                                or (
                                    Cod.system = 'http://snomed.info/sct'
                                    and Cod.code in {'176697007', '69712005'}
                                )
                        )
            )
            or exists (
                [Procedure] P
                    where P.encounter.reference = 'Encounter/' + E.id
                        and P.status = 'completed'
                        and exists (
                            P.code.coding Cod
                                where (
                                    Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                                    and Cod.code in {
                                        '97025K', '97026A', '97027B', '97020K', '97021A', '97022B',
                                        '97035K', '97036A', '97037B', '80403B', '80404B', '80421B',
                                        '80416B', '80412B', '97027C', '80404C'
                                    }
                                )
                                or (
                                    Cod.system = 'http://snomed.info/sct'
                                    and Cod.code in {'236886002', '116140006', '387643005', '446446002'}
                                )
                        )
            )
        )

/*
 * 定義7: 14日內再住院（因相關診斷N70-N85）
 * 相關診斷: 住診案件，任一主、次診斷前3碼N70-N85
 */
define "Readmission_Within_14_Days":
    "Denominator_Cases" IndexEncounter
        where exists (
            "Inpatient_Encounters" ReadmitEncounter
                where ReadmitEncounter.subject.reference = IndexEncounter.subject.reference
                    // 再次住院入院日期在原住院出院後14日內
                    and ReadmitEncounter.period.start in Interval[
                        IndexEncounter.period.end,
                        IndexEncounter.period.end + 14 days
                    ]
                    // 且再住院案件包含相關診斷 N70-N85
                    and exists (
                        [Condition] C
                            where C.encounter.reference = 'Encounter/' + ReadmitEncounter.id
                                and exists (
                                    C.code.coding Cod
                                        where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                                            and (
                                                (Cod.code >= 'N70' and Cod.code < 'N86')
                                                or Cod.code starts with 'N70.'
                                                or Cod.code starts with 'N71.'
                                                or Cod.code starts with 'N72.'
                                                or Cod.code starts with 'N73.'
                                                or Cod.code starts with 'N74.'
                                                or Cod.code starts with 'N75.'
                                                or Cod.code starts with 'N76.'
                                                or Cod.code starts with 'N77.'
                                                or Cod.code starts with 'N80.'
                                                or Cod.code starts with 'N81.'
                                                or Cod.code starts with 'N82.'
                                                or Cod.code starts with 'N83.'
                                                or Cod.code starts with 'N84.'
                                                or Cod.code starts with 'N85.'
                                            )
                                )
                                and C.category.exists(cat: cat.coding.exists(c: c.code in {'principal-diagnosis', 'secondary-diagnosis', 'encounter-diagnosis'}))
                    )
        )

/*
 * 定義8: 分子（14日內再住院人次）
 */
define "Numerator":
    Count("Readmission_Within_14_Days")

/*
 * 定義9: 分母（符合條件的手術案件數）
 */
define "Denominator":
    Count("Denominator_Cases")

/*
 * 定義10: 再住院率
 */
define "Readmission_Rate":
    if "Denominator" > 0
    then ("Numerator" / "Denominator") * 100
    else null

/*
 * 定義11: 指標結果
 */
define "Indicator_14_Result":
    {
        IndicatorCode: '473.01',
        IndicatorName: '子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率',
        Numerator: "Numerator",
        Denominator: "Denominator",
        Rate: "Readmission_Rate",
        Unit: '%',
        MeasurementPeriod: "Measurement_Period",
        CalculationDate: Now()
    }

-- End of file
