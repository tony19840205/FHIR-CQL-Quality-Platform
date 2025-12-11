/**
 * ESG CQL - Waste（廢棄物）
 * 基於 GRI 306: Waste 2021/2023 標準
 * FHIR R4 對應：Observation / Procedure / Encounter
 * 擷取時間：無限大
 * 生成日期：2025-11-14
 */

library Waste version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ========== 代碼系統定義 ==========

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "UCUM": 'http://unitsofmeasure.org'

// ========== LOINC 代碼 ==========

code "Waste Mass Code": '80353-5' from "LOINC" display 'Waste mass'

// ========== SNOMED CT 代碼 ==========

code "Waste Management Code": '706877002' from "SNOMED" display 'Waste management'
code "Incineration Code": '76938001' from "SNOMED" display 'Incineration'
code "Recycling Code": '257641006' from "SNOMED" display 'Recycling'
code "Landfill Code": '257656000' from "SNOMED" display 'Landfill'
code "Hazardous Waste Code": '710252007' from "SNOMED" display 'Hazardous waste'
code "Non-hazardous Waste Code": '710253002' from "SNOMED" display 'Non-hazardous waste'

// ========== ValueSet 定義 ==========

// GRI-Waste-Type（廢棄物類型）
valueset "Hazardous Waste ValueSet": 'http://esg.fhir.org/ValueSet/hazardous-waste'
valueset "Non-hazardous Waste ValueSet": 'http://esg.fhir.org/ValueSet/non-hazardous-waste'

// GRI-Waste-Disposal（處理方式）
valueset "Incineration ValueSet": 'http://esg.fhir.org/ValueSet/waste-incineration'
valueset "Recycling ValueSet": 'http://esg.fhir.org/ValueSet/waste-recycling'
valueset "Landfill ValueSet": 'http://esg.fhir.org/ValueSet/waste-landfill'
valueset "Reuse ValueSet": 'http://esg.fhir.org/ValueSet/waste-reuse'
valueset "Other Disposal ValueSet": 'http://esg.fhir.org/ValueSet/waste-other-disposal'

// ========== 參數定義 ==========

parameter MeasurementPeriod default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]

// ========== 上下文 ==========

context Patient

// ========== 基礎資料擷取 ==========

/**
 * 1. 所有廢棄物觀察記錄（Observation）
 */
define "All Waste Observations":
  [Observation: "Waste Mass Code"] O
    where O.status in {'final', 'amended', 'corrected'}
      and O.effective during MeasurementPeriod
      and O.value is not null

/**
 * 2. 有害廢棄物記錄
 */
define "Hazardous Waste Observations":
  [Observation] O
    where O.status in {'final', 'amended', 'corrected'}
      and O.effective during MeasurementPeriod
      and O.code in "Hazardous Waste ValueSet"
      and O.value is not null

/**
 * 3. 非有害廢棄物記錄
 */
define "Non-hazardous Waste Observations":
  [Observation] O
    where O.status in {'final', 'amended', 'corrected'}
      and O.effective during MeasurementPeriod
      and O.code in "Non-hazardous Waste ValueSet"
      and O.value is not null

/**
 * 4. 廢棄物處理程序（Procedure）
 */
define "Waste Disposal Procedures":
  [Procedure] P
    where P.status = 'completed'
      and P.performed during MeasurementPeriod

/**
 * 5. 住院記錄（Encounter）- 用於計算 Bed-Day
 */
define "Inpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and E.class.code = 'IMP'
      and E.period.start during MeasurementPeriod

// ========== GRI 306-3：廢棄物產生量計算 ==========

/**
 * GRI 306-3-a：總廢棄物產生量（公斤）
 * 公式：Total Waste = Hazardous Waste + Non-hazardous Waste
 */
define "Total Waste Generated (kg)":
  if exists("All Waste Observations") then
    Sum(
      "All Waste Observations" O
        return (O.value as FHIR.Quantity).value.value
    )
  else
    null

/**
 * 有害廢棄物總量（公斤）
 */
define "Hazardous Waste Total (kg)":
  if exists("Hazardous Waste Observations") then
    Sum(
      "Hazardous Waste Observations" O
        return (O.value as FHIR.Quantity).value.value
    )
  else
    null

/**
 * 非有害廢棄物總量（公斤）
 */
define "Non-hazardous Waste Total (kg)":
  if exists("Non-hazardous Waste Observations") then
    Sum(
      "Non-hazardous Waste Observations" O
        return (O.value as FHIR.Quantity).value.value
    )
  else
    null

// ========== GRI 306-4：廢棄物處理方式計算 ==========

/**
 * 回收處理量（公斤）
 */
define "Recycled Waste (kg)":
  if exists([Procedure] P where P.code in "Recycling ValueSet") then
    Sum(
      [Procedure] P
        where P.status = 'completed'
          and P.code in "Recycling ValueSet"
          and P.performed during MeasurementPeriod
        return 
          if P.outcome.text is not null then
            ToDecimal(P.outcome.text.value)
          else
            0.0
    )
  else
    null

/**
 * 再利用量（公斤）
 */
define "Reused Waste (kg)":
  if exists([Procedure] P where P.code in "Reuse ValueSet") then
    Sum(
      [Procedure] P
        where P.status = 'completed'
          and P.code in "Reuse ValueSet"
          and P.performed during MeasurementPeriod
        return 
          if P.outcome.text is not null then
            ToDecimal(P.outcome.text.value)
          else
            0.0
    )
  else
    null

/**
 * 焚化處理量（公斤）
 */
define "Incinerated Waste (kg)":
  if exists([Procedure] P where P.code in "Incineration ValueSet") then
    Sum(
      [Procedure] P
        where P.status = 'completed'
          and P.code in "Incineration ValueSet"
          and P.performed during MeasurementPeriod
        return 
          if P.outcome.text is not null then
            ToDecimal(P.outcome.text.value)
          else
            0.0
    )
  else
    null

/**
 * 掩埋處理量（公斤）
 */
define "Landfilled Waste (kg)":
  if exists([Procedure] P where P.code in "Landfill ValueSet") then
    Sum(
      [Procedure] P
        where P.status = 'completed'
          and P.code in "Landfill ValueSet"
          and P.performed during MeasurementPeriod
        return 
          if P.outcome.text is not null then
            ToDecimal(P.outcome.text.value)
          else
            0.0
    )
  else
    null

/**
 * 其他處理方式（公斤）
 */
define "Other Disposal Waste (kg)":
  if exists([Procedure] P where P.code in "Other Disposal ValueSet") then
    Sum(
      [Procedure] P
        where P.status = 'completed'
          and P.code in "Other Disposal ValueSet"
          and P.performed during MeasurementPeriod
        return 
          if P.outcome.text is not null then
            ToDecimal(P.outcome.text.value)
          else
            0.0
    )
  else
    null

// ========== 效率指標計算 ==========

/**
 * 總住院日數（Bed-Days）
 */
define "Total Bed Days":
  if exists("Inpatient Encounters") then
    Sum(
      "Inpatient Encounters" E
        return 
          days between start of E.period and end of E.period
    )
  else
    null

/**
 * 每床日廢棄物產生量（公斤/床日）
 * 公式：Total Waste / Total Bed Days
 */
define "Waste per Bed-Day (kg/bed-day)":
  if "Total Waste Generated (kg)" is not null and "Total Bed Days" is not null and "Total Bed Days" > 0 then
    "Total Waste Generated (kg)" / "Total Bed Days"
  else
    null

/**
 * 回收率（%）
 * 公式：Recycled Waste / Total Waste × 100
 */
define "Recycling Rate (%)":
  if "Recycled Waste (kg)" is not null and "Total Waste Generated (kg)" is not null and "Total Waste Generated (kg)" > 0 then
    ("Recycled Waste (kg)" / "Total Waste Generated (kg)") * 100
  else
    null

/**
 * 再利用率（%）
 */
define "Reuse Rate (%)":
  if "Reused Waste (kg)" is not null and "Total Waste Generated (kg)" is not null and "Total Waste Generated (kg)" > 0 then
    ("Reused Waste (kg)" / "Total Waste Generated (kg)") * 100
  else
    null

/**
 * 有害廢棄物佔比（%）
 */
define "Hazardous Waste Percentage (%)":
  if "Hazardous Waste Total (kg)" is not null and "Total Waste Generated (kg)" is not null and "Total Waste Generated (kg)" > 0 then
    ("Hazardous Waste Total (kg)" / "Total Waste Generated (kg)") * 100
  else
    null

// ========== 最終報告輸出 ==========

/**
 * ESG 廢棄物管理綜合報告
 */
define "ESG Waste Management Report":
  if "Total Waste Generated (kg)" is null then
    '【FHIR 無資料記載】'
  else
    {
      reporting_period: MeasurementPeriod,
      
      // GRI 306-3：廢棄物產生量
      total_waste_kg: Coalesce("Total Waste Generated (kg)", 0.0),
      hazardous_waste_kg: Coalesce("Hazardous Waste Total (kg)", 0.0),
      non_hazardous_waste_kg: Coalesce("Non-hazardous Waste Total (kg)", 0.0),
      
      // GRI 306-4：廢棄物處理方式
      recycled_kg: Coalesce("Recycled Waste (kg)", 0.0),
      reused_kg: Coalesce("Reused Waste (kg)", 0.0),
      incinerated_kg: Coalesce("Incinerated Waste (kg)", 0.0),
      landfilled_kg: Coalesce("Landfilled Waste (kg)", 0.0),
      other_disposal_kg: Coalesce("Other Disposal Waste (kg)", 0.0),
      
      // 效率指標
      total_bed_days: Coalesce("Total Bed Days", 0),
      waste_per_bed_day_kg: "Waste per Bed-Day (kg/bed-day)",
      recycling_rate_percent: "Recycling Rate (%)",
      reuse_rate_percent: "Reuse Rate (%)",
      hazardous_waste_percent: "Hazardous Waste Percentage (%)",
      
      // 資料狀態
      data_status: 
        if "Total Waste Generated (kg)" is null then 'FHIR 無資料記載'
        else if "Total Waste Generated (kg)" = 0.0 then '無廢棄物記錄'
        else '資料完整',
      
      // 標準引用
      standards: {
        gri: 'GRI 306: Waste 2021/2023',
        fhir: 'HL7 FHIR R4',
        units: 'UCUM (International Units)',
        terminology: 'SNOMED CT / LOINC'
      }
    }

/**
 * 資料完整性檢查
 */
define "Data Completeness Check":
  {
    has_waste_data: exists("All Waste Observations"),
    has_disposal_data: exists("Waste Disposal Procedures"),
    has_encounter_data: exists("Inpatient Encounters"),
    
    message: 
      if not exists("All Waste Observations") then 'FHIR 無資料記載 - 缺少廢棄物觀察記錄'
      else if not exists("Waste Disposal Procedures") then '警告 - 缺少廢棄物處理程序記錄'
      else if not exists("Inpatient Encounters") then '警告 - 缺少住院記錄，無法計算每床日廢棄物量'
      else '資料完整'
  }
