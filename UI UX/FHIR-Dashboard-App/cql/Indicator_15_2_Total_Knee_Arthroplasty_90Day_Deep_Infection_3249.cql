library Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 3249
// 條件依據：全人工膝關節置換手術後九十日以內置換物深部感染率
// 製作日期：2025-11-20

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// NHI 全人工膝關節置換術代碼
code "64164B": '64164B' from "NHI_PROCEDURE" display '人工膝關節置換術'
code "97805K": '97805K' from "NHI_PROCEDURE" display '全人工膝關節置換術-雙側'
code "97806A": '97806A' from "NHI_PROCEDURE" display '全人工膝關節置換術-單側'
code "97807B": '97807B' from "NHI_PROCEDURE" display '全人工膝關節置換術-複雜'
code "64169B": '64169B' from "NHI_PROCEDURE" display '全人工膝關節置換術'

// NHI 置換物深部感染代碼
code "64053B": '64053B' from "NHI_PROCEDURE" display '西醫院所之住院案件中，以手術醫令行後續醫療置換物感染之手術'
code "64198B": '64198B' from "NHI_PROCEDURE" display '置換物深部感染之手術'

// SNOMED TKA 代碼
code "609588000": '609588000' from "SNOMEDCT" display 'Total knee replacement'
code "179344006": '179344006' from "SNOMEDCT" display 'Primary total knee replacement'
code "265157000": '265157000' from "SNOMEDCT" display 'Total knee arthroplasty'

// 1. 全人工膝關節置換執行案件數 (Denominator)
define "TKA Procedures":
  [Procedure] P
    where (
      exists (P.code.coding C where C in {
        "64164B", "97805K", "97806A", "97807B", "64169B",
        "609588000", "179344006", "265157000"
      })
    )
    and P.status ~ 'completed'

// 2. 置換物深部感染案件數 (Numerator)
define "Deep Infection After TKA":
  [Procedure] PI
    where (
      exists (PI.code.coding C where C in {"64053B", "64198B"})
    )
    and PI.status ~ 'completed'
    and exists (
      "TKA Procedures" TKA
        where TKA.subject.reference = PI.subject.reference
        // 正確時間邏輯：感染發生在 TKA 手術後 90 天內
        and (PI.performed as FHIR.dateTime).value in Interval[
          (TKA.performed as FHIR.dateTime).value,
          (TKA.performed as FHIR.dateTime).value + 90 days
        ]
        // 排除條件：排除執行人工膝關節置換術(64164B)同日申報64198B 或 全人工膝關節置換術(64169B)同日申報64198B
        and not (
          exists (PI.code.coding C where C ~ "64198B")
          and (
            exists (TKA.code.coding C where C ~ "64164B")
            or exists (TKA.code.coding C where C ~ "64169B")
          )
          and (TKA.performed as FHIR.dateTime).value = (PI.performed as FHIR.dateTime).value
        )
    )

// 3. 分母：每季全人工膝關節置換執行案件數
define "Denominator":
  Count("TKA Procedures")

// 4. 分子：每季置換物深部感染案件數
define "Numerator":
  Count("Deep Infection After TKA")

// 5. 指標計算結果
define "Infection Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null
