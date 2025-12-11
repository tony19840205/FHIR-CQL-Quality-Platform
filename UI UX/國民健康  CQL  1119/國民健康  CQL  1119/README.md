# CQL 測試系統使用說明

## 快速開始

1. 設定資料上限（編輯 config.json）
   - max_records_per_resource: 0      無限制（擷取所有資料）
   - max_records_per_resource: 1000   每個資源上限 1000 筆
   - max_records_per_resource: 2000   每個資源上限 2000 筆

2. 執行測試
   .\test.ps1

## 系統配置

### config.json 設定項目

- fhir_servers: FHIR 伺服器列表
  - enabled: true/false (啟用/停用)
  
- filters:
  - time_period_years: 時間範圍（年）
  - max_records_per_resource: 資料上限（0=無限制）
  
- cql_libraries: CQL 函式庫列表

### CQL 函式庫

1. COVID19VaccinationCoverage.cql
   - 包含完整的 SNOMED CT 和 CVX 疫苗代碼
   - SNOMED: 840539006, 840534001, 1119305005, 1119349007
   - CVX: 207-213, 217-219
   
2. HypertensionActiveCases.cql
   - 實施國際標準的高血壓確診邏輯（自動去重）
   - 規則1: 至少2次不同日期診斷
   - 規則2: 1次診斷 + 2次異常血壓
   - 規則3: 長期服用降壓藥
   - 使用 distinct() 完全避免重複計數
   
3. InfluenzaVaccinationCoverage.cql
   - 流感疫苗接種涵蓋率計算

## 重要功能

 動態資料上限設定（可由工程師自行調整）
 支援多個 FHIR 伺服器
 自動分頁處理
 CQL 層級的去重邏輯（符合國際標準）
 完整的疫苗代碼支援（SNOMED + CVX）
 詳細的資料分析報告

## 輸出檔案

- fhir_data_YYYYMMDD_HHMMSS.json: 完整 FHIR 資料
- report_YYYYMMDD_HHMMSS.txt: 文字分析報告

## 注意事項

- 設定為無限制時（0），會擷取伺服器上所有可用資料
- 建議首次測試時設定較小的上限（如 1000）
- 病人去重邏輯已在 CQL 中實施，不在 PowerShell 腳本中處理
- 公開測試伺服器目前無 COVID-19 疫苗資料，建議使用流感疫苗測試

## 版本資訊

- 版本: 1.0.0
- 更新日期: 2025-11-16
- 作者: CQL Team
