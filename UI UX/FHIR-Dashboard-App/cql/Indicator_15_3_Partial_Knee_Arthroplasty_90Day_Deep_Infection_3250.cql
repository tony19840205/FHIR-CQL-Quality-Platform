library Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 3250
// 條件依據：半人工膝關節置換手術後九十日以內置換物深部感染率
// 製作日期：2025-11-20

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// NHI 半人工膝關節置換術代碼
code "64169B": '64169B' from "NHI_PROCEDURE" display '半人工膝關節置換術'

// NHI 置換物深部感染代碼
code "64053B": '64053B' from "NHI_PROCEDURE" display '西醫院所之住院案件中，以手術醫令行後續醫療置換物感染之手術'
code "64198B": '64198B' from "NHI_PROCEDURE" display '置換物深部感染之手術'
code "64164B": '64164B' from "NHI_PROCEDURE" display '人工膝關節置換術'

// SNOMED 半人工膝關節置換術代碼
code "425272008": '425272008' from "SNOMEDCT" display 'Unicompartmental knee replacement'
code "609590004": '609590004' from "SNOMEDCT" display 'Partial knee replacement'

// 1. 半人工膝關節置換執行案件數 (Denominator)
define "Partial TKA Procedures":
  [Procedure] P
    where (
      exists (P.code.coding C where C in {
        "64169B",
        "425272008", "609590004"
      })
    )
    and P.status ~ 'completed'

// 2. 置換物深部感染案件數 (Numerator)
define "Deep Infection After Partial TKA":
  [Procedure] PI
    where (
      exists (PI.code.coding C where C in {"64053B", "64198B"})
    )
    and PI.status ~ 'completed'
    and exists (
      "Partial TKA Procedures" PTKA
        where PTKA.subject.reference = PI.subject.reference
        // 正確時間邏輯：感染發生在半人工膝關節置換術後 90 天內
        and (PI.performed as FHIR.dateTime).value in Interval[
          (PTKA.performed as FHIR.dateTime).value,
          (PTKA.performed as FHIR.dateTime).value + 90 days
        ]
        // 排除條件：排除執行人工膝關節置換術(64164B)同日申報64198B 或 半人工膝關節置換術(64169B)同日申報64198B
        and not (
          exists (PI.code.coding C where C ~ "64198B")
          and (
            exists (PTKA.code.coding C where C ~ "64164B")
            or exists (PTKA.code.coding C where C ~ "64169B")
          )
          and (PTKA.performed as FHIR.dateTime).value = (PI.performed as FHIR.dateTime).value
        )
    )

// 3. 分母：每季半人工膝關節置換執行案件數
define "Denominator":
  Count("Partial TKA Procedures")

// 4. 分子：每季置換物深部感染案件數
define "Numerator":
  Count("Deep Infection After Partial TKA")

// 5. 指標計算結果
define "Infection Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null
