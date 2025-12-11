library Indicator_11_4_Cesarean_Section_Rate_First_Time_1075_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 剖腹產率-初次具適應症
// 指標代碼: 1075.01
// 製作日期：2025-11-20

/*
 * 指標名稱: 11-4. 剖腹產率-初次具適應症
 * Indicator: Cesarean Section Rate - First Time with Medical Indication
 * 指標代碼: 1075.01
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 資料範圍: 每季所有醫院總額之生產案件，排除代辦案件
 * 
 * 製表單位: 衛生福利部 中央健康保險署
 * 製表日期: 114/05/13
 * 
 * 公式說明:
 * 分子: 總生產案件數中屬初次非自願剖腹產案件數
 * 分母: 總生產案件數(自然產案件+剖腹產案件)
 * 
 * 初次非自願剖腹產案件定義：
 * (1) 醫令代碼81004C、81028C 或主處置代碼(手術代碼)為10D00Z0、10D00Z1、10D00Z2 之案件
 *     但需排除下列條件(符合1或2任一項):
 *     a.DRG碼為0373B(自行要求剖腹產)
 *     b.主處置代碼(手術代碼)為10D00Z0、10D00Z1、10D00Z2且主次診斷碼為O342(前胎剖腹產生產)
 * 
 * (2) 自然產案件：符合下列任一條件：
 *     a.TW-DRG前三碼為372~375
 *     b.DRG_CODE為0373A、0373C
 *     c.需符合任一自然產醫令代碼：
 *       81017C、81018C、81019C、97004C、97005D、81024C、81025C、81026C、97934C、81034C
 * 
 * (3) 剖腹產案件：符合下列任一條件：
 *     a.TW-DRG前三碼為370、371、513
 *     b.DRG_CODE為0371A、0373B
 *     c.符合任一剖腹產醫令代碼：
 *       81004C、81028C、97009C、81005C、81029C、97014C
 * 
 * 製表日期：114/05/13
 * 製表單位：衛生福利部 中央健康保險署
 * 
 * 備註:
 * 1.資料來源：醫療給付檔案分析系統，指標代碼：1075.01
 * 2.資料範圍：(1)每季所有醫院總額之生產案件。(2)排除代辦案件。
 * 3.公式說明：
 *   分子：總生產案件數中屬初次非自願剖腹產案件數
 *   分母：總生產案件數(自然產案件+剖腹產案件)
 * 4.初次非自願剖腹產案件：醫令代碼81004C、81028C或主處置代碼(手術代碼)為10D00Z0、10D00Z1、10D00Z2之案件。
 *   ※排除下列條件(符合1或2任一項):
 *     (1).DRG碼為0373B(自行要求剖腹產)
 *     (2).主處置代碼(手術代碼)為10D00Z0、10D00Z1、10D00Z2且主次診斷碼為O342(前胎剖腹產生產)
 * 5.自然產案件：符合下列任一條件：(1).TW-DRG前三碼為372~375。(2).DRG_CODE為0373A、0373C。
 *   (3).需符合任一自然產醫令代碼：81017C、81018C、81019C、97004C、97005D、81024C、81025C、81026C、97934C、81034C。
 * 6.剖腹產案件：符合下列任一條件：(1).TW-DRG前三碼為370、371、513。(2).DRG_CODE為0371A、0373B。
 *   (3).符合任一剖腹產醫令代碼：81004C、81028C、97009C、81005C、81029C、97014C。
 * 7.製表日期：114/05/13
 * 8.製表單位：衛生福利部 中央健康保險署
 * 
 * 9.本項指標含符合適應症及自行要求剖腹產案件，各院所收治產婦之複雜度不同，故觀察結果也不同。
 *   本項指標不宜逕予判斷院所生產照護品質。
 * 
 * 臨床意義:
 * - 監測初次剖腹產中具醫療適應症的使用率
 * - 評估醫療指引的遵循度
 * - 促進基於醫療證據的剖腹產決策
 * - 排除自行要求剖腹產和前次剖腹產案件
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料（產婦）
 * - Encounter: 住院生產紀錄
 * - Procedure: 手術處置資料（剖腹產、自然產）
 * - Condition: 診斷資料（主次診斷ICD-10）
 * - Claim: 醫療費用申報（DRG代碼）
 * - Observation: 剖腹產適應症評估
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 1075.01 (指標代碼)

codesystem "TW_DRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'
    -- 台灣診斷關聯群（TW-DRG）代碼系統
    -- 370, 371: 剖腹產
    -- 513: 不具適應症之剖腹產
    -- 372, 373, 374, 375: 自然產DRG

codesystem "DRG_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'
    -- DRG明細代碼系統
    -- 0371A: 剖腹產
    -- 0373A, 0373C: 自然產
    -- 0373B: 自行要求剖腹產（排除項）

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- O80-O84: 分娩相關診斷
    -- O82: 剖腹產分娩
    -- O342: 前胎剖腹產生產（排除項）
    -- O82.0-O82.2: 具適應症之剖腹產

codesystem "ICD10PCS": 'http://hl7.org/fhir/sid/icd-10-pcs'
    -- ICD-10-PCS 處置代碼系統
    -- 10D00Z0: 經腹低段剖腹產取出產物
    -- 10D00Z1: 經腹低段剖腹產取出產物-保留子宮
    -- 10D00Z2: 經腹低段剖腹產取出產物-切除子宮
    -- 10E0XZZ: 陰道分娩

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 剖腹產相關代碼
    -- 11466000: Cesarean section (剖腹產)
    -- 177141003: Elective cesarean section (選擇性剖腹產)
    -- 177152005: Emergency cesarean section (緊急剖腹產)
    -- 62508004: Cesarean hysterectomy (剖腹產子宮切除術)
    -- 40219000: Classical cesarean section (傳統式剖腹產)
    -- 18946005: Lower segment cesarean section (下段剖腹產)
    -- 274130007: Emergency cesarean hysterectomy (緊急剖腹產子宮切除術)
    -- 排除項
    -- 386637004: Cesarean section on request (自行要求剖腹產)
    -- 450483001: Cesarean section without medical indication (無醫療適應症剖腹產)
    -- 3311000175109: Cesarean section following previous cesarean section (前次剖腹產後再次剖腹產)
    -- 剖腹產醫療適應症相關代碼
    -- 237311001: Cephalopelvic disproportion (胎頭骨盆不對稱)
    -- 199246003: Fetal distress (胎兒窘迫)
    -- 289365005: Finding of malposition of fetus (胎位不正)
    -- 271903000: Placenta previa (前置胎盤)
    -- 415105001: Placental abruption (胎盤早期剝離)
    -- 48194001: Pregnancy induced hypertension (妊娠高血壓)
    -- 15938005: Eclampsia (子癇症)
    -- 237238006: Prolonged labor (產程遲滯)
    -- 427139004: Multiple gestation (多胞胎妊娠)
    -- 自然產相關代碼
    -- 302383004: Delivery normal (正常分娩)
    -- 289253008: Spontaneous vaginal delivery (自然陰道分娩)
    -- 236974004: Instrumental delivery (器械輔助分娩)
    -- 177157004: Vaginal delivery (陰道分娩)
    -- 236973005: Normal vaginal delivery (正常陰道分娩)
    -- 289256000: Forceps delivery (產鉗助產)
    -- 61586001: Vacuum extraction delivery (真空吸引助產)
    -- 384729004: Delivery of product of conception (分娩)
    -- 200144004: Obstetric delivery (產科分娩)

codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
    -- Current Procedural Terminology 處置代碼系統
    -- 剖腹產相關代碼
    -- 59510: Cesarean delivery (剖腹產)
    -- 59514: Cesarean delivery with postpartum care (剖腹產含產後照護)
    -- 59515: Cesarean delivery with antepartum and postpartum care (剖腹產含產前產後照護)
    -- 59620: Cesarean delivery after attempted vaginal delivery (嘗試陰道分娩後改剖腹產)
    -- 自然產相關代碼
    -- 59400: Vaginal delivery (陰道分娩)
    -- 59409: Vaginal delivery with episiotomy (陰道分娩含會陰切開)
    -- 59410: Vaginal delivery including postpartum care (陰道分娩含產後照護)
    -- 59612: Vaginal delivery after previous cesarean (前次剖腹產後陰道分娩 VBAC)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode 代碼系統
    -- IMP: 住院 (Inpatient)
    -- OBSENC: Obstetrics encounter (產科就醫)

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
    -- 台灣健保局專用代碼系統
    -- 醫事機構代碼
    -- 醫療服務代碼

codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
    -- 健保處置代碼系統
    -- 自然產醫令代碼
    -- 81017C: 自然產接生
    -- 81018C: 自然產接生(含會陰切開)
    -- 81019C: 自然產接生(含會陰修補)
    -- 81024C: 產鉗助產
    -- 81025C: 真空吸引助產
    -- 81026C: 臀位牽引術
    -- 81034C: 複雜性陰道分娩
    -- 97004C: 自然產接生費
    -- 97005D: 陰道分娩
    -- 97934C: 產科接生處置
    -- 剖腹產醫令代碼（初次非自願）
    -- 81004C: 剖腹產術（初次）
    -- 81028C: 選擇性剖腹產（初次）
    -- 其他剖腹產醫令代碼
    -- 81005C: 剖腹產合併子宮切除
    -- 81029C: 緊急剖腹產
    -- 97009C: 剖腹產手術費
    -- 97014C: 剖腹產處置費

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- I: 住院

codesystem "LOINC": 'http://loinc.org'
    -- Logical Observation Identifiers Names and Codes
    -- 11636-8: Delivery method (分娩方式)
    -- 73761-9: Type of cesarean section (剖腹產類型)
    -- 57074-7: Indication for cesarean section (剖腹產適應症)
    -- 82810-3: Pregnancy intention (懷孕意圖)
    -- 72147-2: Cesarean delivery reason (剖腹產原因)

-- ==================== 代碼定義 ====================

-- ==================== 健保指標代碼 ====================

code "Indicator_1075_01": '1075.01' from "NHI_INDICATOR" display '剖腹產率-初次具適應症'

-- ==================== TW-DRG代碼（自然產）====================

code "Natural_Delivery_DRG_372": '372' from "TW_DRG" display '自然產DRG-372'
code "Natural_Delivery_DRG_373": '373' from "TW_DRG" display '自然產DRG-373'
code "Natural_Delivery_DRG_374": '374' from "TW_DRG" display '自然產DRG-374'
code "Natural_Delivery_DRG_375": '375' from "TW_DRG" display '自然產DRG-375'

-- ==================== TW-DRG代碼（剖腹產）====================

code "Cesarean_DRG_370": '370' from "TW_DRG" display '剖腹產DRG-370'
code "Cesarean_DRG_371": '371' from "TW_DRG" display '剖腹產DRG-371'
code "Cesarean_DRG_513": '513' from "TW_DRG" display '剖腹產DRG-513'

-- ==================== DRG_CODE代碼 ====================

-- 自然產DRG_CODE
code "Natural_Delivery_DRG_0373A": '0373A' from "DRG_CODE" display '自然產-0373A'
code "Natural_Delivery_DRG_0373C": '0373C' from "DRG_CODE" display '自然產-0373C'

-- 剖腹產DRG_CODE
code "Cesarean_DRG_0371A": '0371A' from "DRG_CODE" display '剖腹產-0371A'
code "Cesarean_DRG_0373B": '0373B' from "DRG_CODE" display '自行要求剖腹產-0373B(排除)'

-- ==================== ICD-10-CM診斷代碼 ====================

-- 剖腹產分娩
code "Cesarean_Delivery_O82": 'O82' from "ICD10CM" display '單胎經剖腹產分娩'
code "Cesarean_Delivery_O820": 'O82.0' from "ICD10CM" display '選擇性剖腹產分娩'
code "Cesarean_Delivery_O821": 'O82.1' from "ICD10CM" display '緊急剖腹產分娩'
code "Cesarean_Delivery_O822": 'O82.2' from "ICD10CM" display '剖腹產子宮切除術'

-- 前次剖腹產（排除項）
code "Previous_Cesarean_O342": 'O342' from "ICD10CM" display '前胎剖腹產生產(排除)'

-- 自然產分娩
code "Vaginal_Delivery_O80": 'O80' from "ICD10CM" display '單胎自然產分娩'
code "Vaginal_Delivery_O81": 'O81' from "ICD10CM" display '器械助產分娩'

-- ==================== ICD-10-PCS處置代碼 ====================

-- 剖腹產處置代碼
code "Cesarean_10D00Z0": '10D00Z0' from "ICD10PCS" display '經腹低段剖腹產取出產物'
code "Cesarean_10D00Z1": '10D00Z1' from "ICD10PCS" display '經腹低段剖腹產取出產物-保留子宮'
code "Cesarean_10D00Z2": '10D00Z2' from "ICD10PCS" display '經腹低段剖腹產取出產物-切除子宮'

-- 自然產處置代碼
code "Vaginal_Delivery_10E0XZZ": '10E0XZZ' from "ICD10PCS" display '經陰道分娩'

-- ==================== 健保處置代碼（NHI_PROCEDURE）====================

-- 初次非自願剖腹產醫令代碼
code "NHI_Cesarean_First_81004C": '81004C' from "NHI_PROCEDURE" display '剖腹產術(初次)'
code "NHI_Cesarean_Elective_81028C": '81028C' from "NHI_PROCEDURE" display '選擇性剖腹產(初次)'

-- 其他剖腹產醫令代碼
code "NHI_Cesarean_With_Hysterectomy_81005C": '81005C' from "NHI_PROCEDURE" display '剖腹產合併子宮切除'
code "NHI_Cesarean_Emergency_81029C": '81029C' from "NHI_PROCEDURE" display '緊急剖腹產'
code "NHI_Cesarean_Fee_97009C": '97009C' from "NHI_PROCEDURE" display '剖腹產手術費'
code "NHI_Cesarean_Without_Indication_97014C": '97014C' from "NHI_PROCEDURE" display '剖腹產處置費'

-- 自然產醫令代碼
code "NHI_Natural_Delivery_81017C": '81017C' from "NHI_PROCEDURE" display '自然產接生'
code "NHI_Natural_Delivery_With_Episiotomy_81018C": '81018C' from "NHI_PROCEDURE" display '自然產接生(含會陰切開)'
code "NHI_Natural_Delivery_With_Repair_81019C": '81019C' from "NHI_PROCEDURE" display '自然產接生(含會陰修補)'
code "NHI_Forceps_Delivery_81024C": '81024C' from "NHI_PROCEDURE" display '產鉗助產'
code "NHI_Vacuum_Delivery_81025C": '81025C' from "NHI_PROCEDURE" display '真空吸引助產'
code "NHI_Breech_Delivery_81026C": '81026C' from "NHI_PROCEDURE" display '臀位牽引術'
code "NHI_Complex_Vaginal_Delivery_81034C": '81034C' from "NHI_PROCEDURE" display '複雜性陰道分娩'
code "NHI_Natural_Delivery_Fee_97004C": '97004C' from "NHI_PROCEDURE" display '自然產接生費'
code "NHI_Vaginal_Delivery_97005D": '97005D' from "NHI_PROCEDURE" display '陰道分娩'
code "NHI_Obstetric_Procedure_97934C": '97934C' from "NHI_PROCEDURE" display '產科接生處置'

-- ==================== SNOMED CT代碼 ====================

-- 剖腹產類型
code "SNOMED_Cesarean_Section": '11466000' from "SNOMEDCT" display '剖腹產'
code "SNOMED_Elective_Cesarean": '177141003' from "SNOMEDCT" display '選擇性剖腹產'
code "SNOMED_Emergency_Cesarean": '177152005' from "SNOMEDCT" display '緊急剖腹產'
code "SNOMED_Lower_Segment_Cesarean": '18946005' from "SNOMEDCT" display '下段剖腹產'
code "SNOMED_Classical_Cesarean": '40219000' from "SNOMEDCT" display '傳統式剖腹產'
code "SNOMED_Cesarean_Hysterectomy": '62508004' from "SNOMEDCT" display '剖腹產子宮切除術'

-- 排除項（自行要求、前次剖腹產）
code "SNOMED_Cesarean_On_Request": '386637004' from "SNOMEDCT" display '自行要求剖腹產(排除)'
code "SNOMED_Cesarean_Without_Indication": '450483001' from "SNOMEDCT" display '無醫療適應症剖腹產(排除)'
code "SNOMED_Previous_Cesarean": '3311000175109' from "SNOMEDCT" display '前次剖腹產後再次剖腹產(排除)'

-- 剖腹產適應症
code "SNOMED_Cephalopelvic_Disproportion": '237311001' from "SNOMEDCT" display '胎頭骨盆不對稱'
code "SNOMED_Fetal_Distress": '199246003' from "SNOMEDCT" display '胎兒窘迫'
code "SNOMED_Fetal_Malposition": '289365005' from "SNOMEDCT" display '胎位不正'
code "SNOMED_Placenta_Previa": '271903000' from "SNOMEDCT" display '前置胎盤'
code "SNOMED_Placental_Abruption": '415105001' from "SNOMEDCT" display '胎盤早期剝離'
code "SNOMED_Pregnancy_Hypertension": '48194001' from "SNOMEDCT" display '妊娠高血壓'
code "SNOMED_Eclampsia": '15938005' from "SNOMEDCT" display '子癇症'
code "SNOMED_Prolonged_Labor": '237238006' from "SNOMEDCT" display '產程遲滯'
code "SNOMED_Multiple_Gestation": '427139004' from "SNOMEDCT" display '多胞胎妊娠'

-- 自然產類型
code "SNOMED_Normal_Delivery": '302383004' from "SNOMEDCT" display '正常分娩'
code "SNOMED_Spontaneous_Vaginal_Delivery": '289253008' from "SNOMEDCT" display '自然陰道分娩'
code "SNOMED_Vaginal_Delivery": '177157004' from "SNOMEDCT" display '陰道分娩'
code "SNOMED_Normal_Vaginal_Delivery": '236973005' from "SNOMEDCT" display '正常陰道分娩'
code "SNOMED_Instrumental_Delivery": '236974004' from "SNOMEDCT" display '器械輔助分娩'
code "SNOMED_Forceps_Delivery": '289256000' from "SNOMEDCT" display '產鉗助產'
code "SNOMED_Vacuum_Extraction": '61586001' from "SNOMEDCT" display '真空吸引助產'

-- ==================== CPT代碼 ====================

-- 剖腹產CPT
code "CPT_Cesarean_59510": '59510' from "CPT" display '剖腹產(CPT)'
code "CPT_Cesarean_With_Care_59514": '59514' from "CPT" display '剖腹產含產後照護'
code "CPT_Cesarean_Full_Care_59515": '59515' from "CPT" display '剖腹產含產前產後照護'
code "CPT_Cesarean_After_Vaginal_59620": '59620' from "CPT" display '嘗試陰道分娩後改剖腹產'

-- 自然產CPT
code "CPT_Vaginal_Delivery_59400": '59400' from "CPT" display '陰道分娩(CPT)'
code "CPT_Vaginal_With_Episiotomy_59409": '59409' from "CPT" display '陰道分娩含會陰切開'
code "CPT_Vaginal_With_Care_59410": '59410' from "CPT" display '陰道分娩含產後照護'
code "CPT_VBAC_59612": '59612' from "CPT" display '前次剖腹產後陰道分娩(VBAC)'

-- ==================== ActCode代碼 ====================

code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'
code "ActCode_Obstetrics": 'OBSENC' from "ActCode" display '產科就醫'

-- ==================== LOINC代碼 ====================

code "LOINC_Delivery_Method": '11636-8' from "LOINC" display '分娩方式'
code "LOINC_Cesarean_Type": '73761-9' from "LOINC" display '剖腹產類型'
code "LOINC_Cesarean_Indication": '57074-7' from "LOINC" display '剖腹產適應症'
code "LOINC_Cesarean_Reason": '72147-2' from "LOINC" display '剖腹產原因'

-- ==================== ValueSet定義 ====================

-- 自然產DRG ValueSet (372~375)
valueset "Natural_Delivery_DRG_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/natural-delivery-drg'

-- 剖腹產DRG ValueSet (370, 371, 513)
valueset "Cesarean_Delivery_DRG_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cesarean-delivery-drg'

-- 自然產醫令代碼ValueSet
valueset "Natural_Delivery_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/natural-delivery-procedures'

-- 剖腹產醫令代碼ValueSet
valueset "Cesarean_Delivery_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cesarean-delivery-procedures'

-- 初次非自願剖腹產醫令代碼ValueSet
valueset "First_Time_Cesarean_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/first-time-cesarean-procedures'

-- 剖腹產ICD-10-PCS處置代碼ValueSet (10D00Z0, 10D00Z1, 10D00Z2)
valueset "Cesarean_ICD10PCS_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cesarean-icd10pcs'

-- 剖腹產適應症ValueSet
valueset "Cesarean_Indication_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cesarean-indication'

-- 排除項ValueSet（自行要求剖腹產、前次剖腹產）
valueset "Cesarean_Exclusion_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cesarean-exclusion'

-- ==================== 參數定義 ====================

parameter "Measurement_Period" Interval<DateTime>
    default Interval[@2024-01-01T00:00:00.0, @2024-12-31T23:59:59.999]

-- ==================== Context定義 ====================

context Patient

-- ==================== 主要定義 ====================

/*
 * 定義1: 住院生產案件
 * 住院類型的生產相關案件
 */
define "Inpatient_Delivery_Encounters":
    [Encounter: type in "ActCode_Obstetrics"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Inpatient"
            and E.period ends during "Measurement_Period"
            and not exists (
                E.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/proxy-case'
                        and Ex.valueBoolean = true
            )

/*
 * 定義2: 自然產案件（符合任一條件）
 * (1) TW-DRG前三碼為372~375
 * (2) DRG_CODE為0373A、0373C
 * (3) 需符合任一自然產醫令代碼
 */
define "Natural_Delivery_Cases":
    "Inpatient_Delivery_Encounters" E
        where exists (
            [Claim] C
                where C.encounter.reference = 'Encounter/' + E.id
                    and (
                        // 條件1: TW-DRG前三碼為372~375
                        exists (
                            C.diagnosis D
                                where D.type.coding.exists(c: c.code = 'drg')
                                    and (
                                        D.diagnosisCodeableConcept.coding.exists(c: c.system = "TW_DRG" and c.code in {'372', '373', '374', '375'})
                                    )
                        )
                        // 條件2: DRG_CODE為0373A、0373C
                        or exists (
                            C.diagnosis D
                                where D.type.coding.exists(c: c.code = 'drg')
                                    and D.diagnosisCodeableConcept.coding.exists(c: c.system = "DRG_CODE" and c.code in {'0373A', '0373C'})
                        )
                    )
        )
        // 條件3: 需符合任一自然產醫令代碼
        and exists (
            [Procedure] P
                where P.encounter.reference = 'Encounter/' + E.id
                    and P.status = 'completed'
                    and P.code.coding.exists(c: 
                        c.system = "NHI_PROCEDURE" 
                        and c.code in {'81017C', '81018C', '81019C', '97004C', '97005D', '81024C', '81025C', '81026C', '97934C', '81034C'}
                    )
        )

/*
 * 定義3: 剖腹產案件（符合任一條件）
 * (1) TW-DRG前三碼為370、371、513
 * (2) DRG_CODE為0371A、0373B
 * (3) 符合任一剖腹產醫令代碼
 */
define "Cesarean_Delivery_Cases":
    "Inpatient_Delivery_Encounters" E
        where exists (
            [Claim] C
                where C.encounter.reference = 'Encounter/' + E.id
                    and (
                        // 條件1: TW-DRG前三碼為370、371、513
                        exists (
                            C.diagnosis D
                                where D.type.coding.exists(c: c.code = 'drg')
                                    and D.diagnosisCodeableConcept.coding.exists(c: c.system = "TW_DRG" and c.code in {'370', '371', '513'})
                        )
                        // 條件2: DRG_CODE為0371A、0373B
                        or exists (
                            C.diagnosis D
                                where D.type.coding.exists(c: c.code = 'drg')
                                    and D.diagnosisCodeableConcept.coding.exists(c: c.system = "DRG_CODE" and c.code in {'0371A', '0373B'})
                        )
                    )
        )
        // 條件3: 符合任一剖腹產醫令代碼
        and exists (
            [Procedure] P
                where P.encounter.reference = 'Encounter/' + E.id
                    and P.status = 'completed'
                    and P.code.coding.exists(c: 
                        c.system = "NHI_PROCEDURE" 
                        and c.code in {'81004C', '81028C', '97009C', '81005C', '81029C', '97014C'}
                    )
        )

/*
 * 定義4: 初次非自願剖腹產案件
 * 醫令代碼81004C、81028C 或主處置代碼(手術代碼)為10D00Z0、10D00Z1、10D00Z2
 * 但需排除:
 * (1) DRG碼為0373B(自行要求剖腹產)
 * (2) 主處置代碼為10D00Z0、10D00Z1、10D00Z2且主次診斷碼為O342(前胎剖腹產生產)
 */
define "First_Time_Non_Voluntary_Cesarean_Cases":
    "Cesarean_Delivery_Cases" E
        where (
            // 符合初次非自願剖腹產醫令代碼或處置代碼
            exists (
                [Procedure] P
                    where P.encounter.reference = 'Encounter/' + E.id
                        and P.status = 'completed'
                        and (
                            // 醫令代碼81004C、81028C
                            P.code.coding.exists(c: 
                                c.system = "NHI_PROCEDURE" 
                                and c.code in {'81004C', '81028C'}
                            )
                            // 或主處置代碼10D00Z0、10D00Z1、10D00Z2
                            or P.code.coding.exists(c: 
                                c.system = "ICD10PCS" 
                                and c.code in {'10D00Z0', '10D00Z1', '10D00Z2'}
                            )
                        )
            )
        )
        // 排除條件1: DRG碼為0373B(自行要求剖腹產)
        and not exists (
            [Claim] C
                where C.encounter.reference = 'Encounter/' + E.id
                    and exists (
                        C.diagnosis D
                            where D.type.coding.exists(c: c.code = 'drg')
                                and D.diagnosisCodeableConcept.coding.exists(c: 
                                    c.system = "DRG_CODE" 
                                    and c.code = '0373B'
                                )
                    )
        )
        // 排除條件2: 主處置代碼為10D00Z0、10D00Z1、10D00Z2且主次診斷碼為O342
        and not (
            exists (
                [Procedure] P
                    where P.encounter.reference = 'Encounter/' + E.id
                        and P.status = 'completed'
                        and P.code.coding.exists(c: 
                            c.system = "ICD10PCS" 
                            and c.code in {'10D00Z0', '10D00Z1', '10D00Z2'}
                        )
            )
            and exists (
                [Condition] C
                    where C.encounter.reference = 'Encounter/' + E.id
                        and C.code.coding.exists(c: 
                            c.system = "ICD10CM" 
                            and c.code = 'O342'
                        )
                        and C.category.exists(cat: 
                            cat.coding.exists(c: c.code in {'principal-diagnosis', 'secondary-diagnosis'})
                        )
            )
        )

/*
 * 定義5: 總生產案件數（分母）
 * 自然產案件 + 剖腹產案件
 */
define "Total_Delivery_Cases":
    "Natural_Delivery_Cases" union "Cesarean_Delivery_Cases"

/*
 * 定義6: 初次非自願剖腹產案件數（分子）
 */
define "Numerator":
    Count("First_Time_Non_Voluntary_Cesarean_Cases")

/*
 * 定義7: 總生產案件數（分母）
 */
define "Denominator":
    Count("Total_Delivery_Cases")

/*
 * 定義8: 剖腹產率-初次具適應症
 */
define "First_Time_Cesarean_Rate":
    if "Denominator" > 0 
    then ("Numerator" / "Denominator") * 100
    else null

/*
 * 定義9: 指標結果
 */
define "Indicator_Result":
    {
        IndicatorCode: '1075.01',
        IndicatorName: '剖腹產率-初次具適應症',
        Numerator: "Numerator",
        Denominator: "Denominator",
        Rate: "First_Time_Cesarean_Rate",
        Unit: '%',
        MeasurementPeriod: "Measurement_Period",
        CalculationDate: Now()
    }
