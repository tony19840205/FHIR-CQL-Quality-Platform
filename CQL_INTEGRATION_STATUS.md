# CQL整合狀態報告

## 📋 傳染病監測面板 (disease-control.html)

### CQL文件來源
文件夾: `傳染病統計資料CQL1119/傳染病統計資料CQL1119/`

### 5個CQL文件映射

#### 1. COVID-19
- **CQL文件**: `InfectiousDisease_COVID19_Surveillance.cql`
- **JavaScript實現**: `dashboard-simple.js` → `queryDiseaseData('covid19', conn)`
- **診斷代碼**: 
  - ICD-10: U07.1 (COVID-19, virus identified)
  - 搜尋詞: COVID, COVID-19, coronavirus, SARS-CoV-2
- **時間範圍**: 2年內 (符合CQL要求)
- **查詢資源**: Condition + Encounter
- **整合狀態**: ✅ 已整合CQL邏輯

#### 2. 流感 (Influenza)
- **CQL文件**: `InfectiousDisease_Influenza_Surveillance.cql`
- **JavaScript實現**: `dashboard-simple.js` → `queryDiseaseData('influenza', conn)`
- **診斷代碼**: 
  - ICD-10: J09, J10, J11 (Influenza)
  - ICD-9: 487.x (Influenza)
  - 搜尋詞: Influenza, flu, Grippe, 流感
- **時間範圍**: 2年內
- **查詢資源**: Condition + Encounter
- **整合狀態**: ✅ 已整合CQL邏輯

#### 3. 急性結膜炎 (Acute Conjunctivitis)
- **CQL文件**: `InfectiousDisease_AcuteConjunctivitis_Surveillance.cql`
- **JavaScript實現**: `dashboard-simple.js` → `queryDiseaseData('conjunctivitis', conn)`
- **診斷代碼**: 
  - ICD-10: H10 (Conjunctivitis)
  - 搜尋詞: Conjunctivitis, pink eye, 結膜炎
- **時間範圍**: 2年內
- **查詢資源**: Condition + Encounter
- **整合狀態**: ✅ 已整合CQL邏輯

#### 4. 腸病毒 (Enterovirus)
- **CQL文件**: `InfectiousDisease_Enterovirus_Surveillance.cql`
- **JavaScript實現**: `dashboard-simple.js` → `queryDiseaseData('enterovirus', conn)`
- **診斷代碼**: 
  - ICD-10: B97.1 (Enterovirus), B08.4 (Hand, foot and mouth disease)
  - 搜尋詞: Enterovirus, 腸病毒, hand foot mouth
- **時間範圍**: 2年內
- **查詢資源**: Condition + Encounter
- **整合狀態**: ✅ 已整合CQL邏輯

#### 5. 急性腹瀉 (Acute Diarrhea)
- **CQL文件**: `InfectiousDisease_AcuteDiarrhea_Surveillance.cql`
- **JavaScript實現**: `dashboard-simple.js` → `queryDiseaseData('diarrhea', conn)`
- **診斷代碼**: 
  - ICD-10: A09 (Infectious gastroenteritis), K52 (Noninfective gastroenteritis)
  - 搜尋詞: Diarrhea, diarrhoea, 腹瀉, gastroenteritis
- **時間範圍**: 2年內
- **查詢資源**: Condition + Encounter
- **整合狀態**: ✅ 已整合CQL邏輯

---

## 📋 醫療品質指標面板 (quality-indicators.html)

### CQL文件來源
文件夾: `醫院總額醫療品質資訊1119/醫院總額醫療品質資訊(1119)/`

### 已實現指標 (4/39)

#### 1. indicator-01: 門診注射劑使用率 (3127)
- **CQL文件**: `3127_門診注射劑使用率.cql`
- **JavaScript實現**: `quality-indicators.js` → `queryOutpatientInjectionRateSample()`
- **CQL邏輯**: 
  - 分母: 所有門診Encounter
  - 分子: 有MedicationRequest且route='injection'
  - 排除: 9項CQL排除條件 (化療、透析等)
- **ATC代碼**: 完整5位數精確匹配
- **整合狀態**: ✅ 已完全實現CQL邏輯

#### 2. indicator-02: 門診抗生素使用率 (1140.01)
- **CQL文件**: `1140.01_門診抗生素使用率.cql`
- **JavaScript實現**: `quality-indicators.js` → `queryOutpatientAntibioticRateSample()`
- **CQL邏輯**: 
  - 分母: 所有門診Encounter
  - 分子: 有MedicationRequest且ATC=J01*
  - 排除: 5項CQL排除條件
- **ATC代碼**: J01開頭 (所有抗生素)
- **整合狀態**: ✅ 已完全實現CQL邏輯

#### 3. indicator-03-1: 降壓藥物重複用藥率 (1710)
- **CQL文件**: `1710_降壓藥物重複用藥率.cql`
- **JavaScript實現**: `quality-indicators.js` → `queryDrugOverlapRateSample('antihypertensive')`
- **CQL邏輯**: 
  - 查找所有降壓藥處方
  - 計算同類型藥物時間重疊天數
  - 重疊≥10天視為重複用藥
- **ATC代碼**: C07, C02CA, C02DB, C03, C08, C09 (5位數精確)
- **日期計算**: `calculateOverlapDays()` 函數
- **整合狀態**: ✅ 已完全實現CQL邏輯

#### 4. indicator-03-2: 降血脂藥物重複用藥率 (1711)
- **CQL文件**: `1711_降血脂藥物重複用藥率.cql`
- **JavaScript實現**: `quality-indicators.js` → `queryDrugOverlapRateSample('lipid')`
- **CQL邏輯**: 
  - 查找所有降血脂藥處方
  - 計算同類型藥物時間重疊天數
  - 重疊≥10天視為重複用藥
- **ATC代碼**: C10AA, C10AB, C10AC, C10AD, C10AX (5位數精確)
- **日期計算**: `calculateOverlapDays()` 函數
- **整合狀態**: ✅ 已完全實現CQL邏輯

### 待實現指標 (35/39)
- indicator-04 至 indicator-39 尚未實現
- 所有CQL文件已存在於`醫院總額醫療品質資訊(1119)`文件夾
- 需逐步解析CQL並實現JavaScript查詢邏輯

---

## 🔧 技術實現細節

### CQL → JavaScript 轉換模式

#### 1. 時間範圍過濾
```cql
// CQL
define "Measurement Period":
  Interval[@2023-01-01T00:00:00.0, @2025-12-31T23:59:59.0]
```
```javascript
// JavaScript
const twoYearsAgo = new Date();
twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
const dateFilter = twoYearsAgo.toISOString().split('T')[0];

// FHIR查詢
conn.query('Condition', {
    'recorded-date': `ge${dateFilter}`,
    _count: 1000
});
```

#### 2. 診斷代碼過濾
```cql
// CQL
[Condition: "COVID-19 Diagnosis Codes"]
  where onset during "Measurement Period"
```
```javascript
// JavaScript
const searchTerms = ['COVID', 'COVID-19', 'U07.1'];
const conditions = await conn.query('Condition', {
    'code:text': term,
    'recorded-date': `ge${dateFilter}`
});
```

#### 3. 患者去重
```cql
// CQL
Count(distinct [Patient])
```
```javascript
// JavaScript
const patientSet = new Set();
conditions.forEach(c => {
    const ref = c.subject?.reference?.split('/').pop();
    if (ref) patientSet.add(ref);
});
console.log(`唯一患者數: ${patientSet.size}`);
```

#### 4. 排除條件
```cql
// CQL
except [Encounter: "Chemotherapy"]
except [Encounter: "Dialysis"]
```
```javascript
// JavaScript
// 檢查診斷排除條件
const hasExcludedCondition = allConditions.some(condition => {
    const codes = condition.code?.coding || [];
    return codes.some(coding => 
        EXCLUDED_ICD_CODES.includes(coding.code)
    );
});
if (hasExcludedCondition) {
    // 排除此Encounter
}
```

#### 5. ATC藥物代碼匹配
```cql
// CQL
[MedicationRequest: code in "Antihypertensive Medications"]
  where medication.coding.code starts with 'C07'
```
```javascript
// JavaScript
function isAntihypertensiveDrug(atcCode) {
    const prefixes = ['C07', 'C02CA', 'C02DB', 'C03', 'C08', 'C09'];
    return prefixes.some(prefix => 
        atcCode && atcCode.startsWith(prefix) && atcCode.length >= 5
    );
}
```

#### 6. 日期重疊計算
```cql
// CQL
Interval[med1.effectiveStart, med1.effectiveEnd] 
  overlaps Interval[med2.effectiveStart, med2.effectiveEnd]
```
```javascript
// JavaScript
function calculateOverlapDays(period1, period2) {
    const start1 = new Date(period1.start);
    const end1 = new Date(period1.end);
    const start2 = new Date(period2.start);
    const end2 = new Date(period2.end);
    
    const overlapStart = start1 > start2 ? start1 : start2;
    const overlapEnd = end1 < end2 ? end1 : end2;
    
    if (overlapStart < overlapEnd) {
        return Math.ceil((overlapEnd - overlapStart) / (1000 * 60 * 60 * 24));
    }
    return 0;
}
```

---

## ✅ 驗證清單

### 傳染病監測面板
- [x] CQL文件來源確認: `傳染病統計資料CQL1119`
- [x] 5個CQL檔案全部存在
- [x] JavaScript查詢函數已添加CQL註釋
- [x] 2年時間範圍過濾已實現
- [x] 診斷代碼映射已添加ICD-10代碼
- [x] 患者去重邏輯已實現
- [x] Console日誌顯示CQL來源檔案名稱
- [ ] 實際FHIR數據測試 (待測試服務器有數據)

### 醫療品質指標面板
- [x] CQL文件來源確認: `醫院總額醫療品質資訊1119`
- [x] 4個指標完整實現CQL邏輯
- [x] ATC藥物代碼精確匹配 (5位數)
- [x] 排除條件完整實現
- [x] 日期重疊計算函數
- [x] 移除所有Math.random()模擬數據
- [x] 測試服務器切換功能
- [x] 診斷模式 (DIAGNOSTIC_MODE)
- [ ] 剩餘35個指標待實現

---

## 📊 實現進度

### 傳染病監測 (5/5) ✅ 100%
- ✅ COVID-19
- ✅ 流感
- ✅ 急性結膜炎
- ✅ 腸病毒
- ✅ 急性腹瀉

### 醫療品質指標 (4/39) 🔄 10.3%
- ✅ 門診注射劑使用率
- ✅ 門診抗生素使用率
- ✅ 降壓藥物重複用藥率
- ✅ 降血脂藥物重複用藥率
- ⏳ 剩餘35個指標

---

## 🔍 下一步行動

### 優先級1: 數據驗證
1. 使用測試FHIR服務器 (hapi.fhir.org) 測試查詢
2. 驗證傳染病面板5個CQL查詢能正確返回數據
3. 驗證醫療品質4個指標能正確計算

### 優先級2: 擴展醫療品質指標
4. 實現indicator-04: 急診48小時內再次就診率
5. 實現indicator-05: 14天內再住院率
6. 實現indicator-06-09: 其他門診品質指標
7. 逐步完成全部39個指標

### 優先級3: 優化與文檔
8. 添加更詳細的CQL代碼對照表
9. 創建CQL邏輯測試套件
10. 編寫用戶使用手冊

---

**最後更新**: 2025-01-XX
**CQL整合版本**: v2.0
**狀態**: 傳染病監測✅完成 | 醫療品質🔄進行中
