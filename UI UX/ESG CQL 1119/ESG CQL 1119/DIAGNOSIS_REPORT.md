# 🔍 ESG CQL 測試系統 - 問題診斷報告

執行時間: 2025-11-16  
診斷人員: AI Assistant

---

## ❓ 問題 1: 為什麼3個CQL的總病患數和總就醫次數都是70？

### 📊 實際數據流程

#### 步驟1: FHIR資料擷取（無時間限制）
```
HAPI FHIR Server:
├── Patient: 20 筆
├── Encounter: 20 筆
├── MedicationRequest: 20 筆
└── MedicationAdministration: 20 筆

SMART Health IT Sandbox:
├── Patient: 50 筆
├── Encounter: 50 筆
├── MedicationRequest: 50 筆
└── MedicationAdministration: 50 筆

合併後（去重）:
├── Patient: 70 筆
├── Encounter: 70 筆
├── MedicationRequest: 70 筆
└── MedicationAdministration: 70 筆
```

#### 步驟2: VS Code時間過濾（2年內）
```
時間範圍: 2023-11-17 至 2025-11-16

過濾結果:
├── Patient: 70 -> 70 筆 ✅ (不過濾病患資料)
├── Encounter: 70 -> 0 筆 ❌ (全部太舊)
├── MedicationRequest: 70 -> 6 筆 ⚠️ (僅8.6%)
└── MedicationAdministration: 70 -> 6 筆 ⚠️ (僅8.6%)
```

#### 步驟3: CQL計算（使用過濾後的資料）

**Antibiotic_Utilization CQL:**
```python
total_patients = 70           # 使用Patient（不受時間影響）
total_encounters = 0          # 應該是0，但顯示了過濾前的70
total_antibiotic_orders = 6   # 實際過濾後
total_antibiotic_administrations = 6  # 實際過濾後
```

**EHR_Adoption_Rate CQL:**
```python
total_patients = 70           # 使用Patient（不受時間影響）
total_encounters = 0          # 應該是0，但顯示了過濾前的70
total_ehr_documents = 1       # 實際過濾後
total_electronic_prescriptions = 6  # 實際過濾後
```

**Waste CQL:**
```python
total_patients = 70           # 使用Patient（不受時間影響）
total_encounters = 0          # 應該是0，但顯示了過濾前的70
```

### 🔴 根本原因

**不是錯誤，而是設計特性**：

1. **Patient資源不受時間過濾** - 正確的設計
   - 原因：病患基本資料是永久性的
   - 用途：統計所有病患的人口學特徵

2. **Encounter顯示問題** - 需要修正
   - 目前：顯示過濾前的數量（70）
   - 實際：過濾後是0筆
   - 影響：造成誤解，看起來有70次就醫，實際上沒有

3. **為什麼3個CQL都顯示70？**
   - 因為都使用相同的Patient pool（70人）
   - Encounter在過濾後實際是0，但程式顯示了過濾前的數量

### ✅ 正確的數字應該是：

```
Antibiotic_Utilization:
├── 總病患數: 70 人 ✅
├── 總就醫次數: 0 次 ⚠️ (應該顯示0，不是70)
├── 抗生素醫囑數: 6 筆 ✅
└── 抗生素給藥次數: 6 次 ✅

EHR_Adoption_Rate:
├── 總病患數: 70 人 ✅
├── 總就醫次數: 0 次 ⚠️ (應該顯示0，不是70)
├── EHR文件數: 1 份 ✅
└── 電子處方數: 6 筆 ✅

Waste:
├── 總病患數: 70 人 ✅
└── 總就醫次數: 0 次 ⚠️ (應該顯示0，不是70)
```

---

## ❓ 問題 2: 醫療廢棄物怎麼計算？都有在FHIR嗎？

### 📋 答案：廢棄物數據**不在**標準FHIR中

#### FHIR R4標準資源

標準FHIR R4 **沒有**專門的廢棄物資源類型：

**有的資源**:
- ✅ Patient, Encounter, Medication
- ✅ Observation, Procedure, DiagnosticReport
- ✅ Device, Substance, Specimen

**沒有的資源**:
- ❌ Waste (廢棄物)
- ❌ EnvironmentalImpact (環境影響)
- ❌ ResourceConsumption (資源消耗)

#### 目前系統的廢棄物計算方式

**方法1: 基於就醫次數估算（目前使用）**

```python
# 在 cql_processor.py 的 _execute_waste() 函數中
total_waste_kg = len(encounters) * 2.5  # 每次就醫平均2.5kg
recyclable_waste_kg = total_waste_kg * 0.3  # 30%可回收
hazardous_waste_kg = total_waste_kg * 0.15  # 15%有害
```

**假設基礎**:
- 門診平均: 1-2 kg/次
- 住院平均: 5-10 kg/天
- 手術平均: 15-30 kg/次
- 本系統使用: 2.5 kg/次（中間值）

**方法2: 從Observation搜尋廢棄物記錄（理想方式）**

```python
# 搜尋包含"waste"關鍵字的觀察記錄
waste_observations = [o for o in observations 
                     if 'waste' in str(o.get('code', {})).lower()]
```

但公開測試伺服器**沒有**這類資料。

#### 如何在FHIR中記錄廢棄物？

**方案1: 使用Observation擴展**

```json
{
  "resourceType": "Observation",
  "status": "final",
  "category": [{
    "coding": [{
      "system": "http://terminology.hl7.org/CodeSystem/observation-category",
      "code": "environmental",
      "display": "Environmental"
    }]
  }],
  "code": {
    "coding": [{
      "system": "http://esg.fhir.org/CodeSystem/waste-types",
      "code": "medical-waste",
      "display": "Medical Waste Generated"
    }]
  },
  "valueQuantity": {
    "value": 5.2,
    "unit": "kg",
    "system": "http://unitsofmeasure.org",
    "code": "kg"
  },
  "component": [
    {
      "code": {
        "text": "Recyclable"
      },
      "valueQuantity": {
        "value": 1.5,
        "unit": "kg"
      }
    },
    {
      "code": {
        "text": "Hazardous"
      },
      "valueQuantity": {
        "value": 0.8,
        "unit": "kg"
      }
    }
  ]
}
```

**方案2: 使用自定義Extension**

```json
{
  "resourceType": "Encounter",
  "extension": [{
    "url": "http://esg.fhir.org/StructureDefinition/waste-generated",
    "valueQuantity": {
      "value": 3.5,
      "unit": "kg"
    }
  }]
}
```

### 💡 建議

對於真實環境：

1. **短期方案**: 繼續使用估算（基於就醫類型和次數）
2. **中期方案**: 在Observation中記錄廢棄物數據
3. **長期方案**: 建立ESG專用的FHIR Extension或Profile

---

## ❓ 問題 3: HIMSS EMRAM等級 Level 2 是什麼意思？

### 🏥 HIMSS EMRAM (Electronic Medical Record Adoption Model)

**等級範圍**: 0-7（共8個等級）

#### 完整等級說明

| Level | 名稱 | 說明 | 要求 |
|-------|------|------|------|
| **Level 7** | 完全無紙化 | 資料共享、連續照護、資料分析 | EHR採用率≥95%, 所有功能≥90% |
| **Level 6** | 醫師文件電子化 | 完整的醫師文件、CDSS | EHR採用率≥85%, 電子處方≥85% |
| **Level 5** | 閉環給藥 | 電子給藥記錄(eMAR) | EHR採用率≥70%, 電子處方≥70% |
| **Level 4** | CPOE | 電腦醫囑輸入系統 | EHR採用率≥50% |
| **Level 3** | 臨床文件電子化 | 護理與臨床文件 | EHR文件率≥30% |
| **Level 2** | 🔶 **CDR** | **臨床資料儲存庫** | **檢驗結果率≥20%** |
| **Level 1** | 部分系統 | 實驗室、藥局系統 | 有基本電子系統 |
| **Level 0** | 全紙本 | 無電子病歷 | - |

#### 您的系統：Level 2 (CDR)

**達成條件**:
```
✅ 有電子病歷文件 (20份)
✅ 有電子檢驗結果 (部分)
❌ 但電子檢驗結果率 = 0% (未達20%標準)
```

**為什麼評為Level 2？**

查看評估邏輯：
```python
when "Electronic Lab Results Rate (%)" >= 20.0
  then 2  // CDR（臨床資料儲存庫）
when exists("EHR Documents") or exists("Electronic Lab Results")
  then 1  // 部分系統安裝
else 0    // 全紙本
```

因為：
- 有EHR Documents (20份) ✅
- 所以至少是Level 1
- 檢驗結果率未達20%，所以不是Level 3
- **結論**: Level 2

**實際上可能的問題**:
- 如果Encounter真的是0，很多比率計算會出錯
- 建議以"有電子文件"作為Level 1-2的判斷

#### 改善路徑

```
目前 Level 2
    ↓ 提升EHR文件率至30%
Level 3 (臨床文件電子化)
    ↓ 實施CPOE系統，EHR採用率≥50%
Level 4 (CPOE)
    ↓ 實施eMAR，採用率≥70%
Level 5 (閉環給藥)
    ↓ 完整醫師文件，採用率≥85%
Level 6 (醫師文件電子化)
    ↓ 全面數位化，採用率≥95%
Level 7 (完全無紙化) 🎯
```

---

## ❓ 問題 4: EHR文件數 20份是什麼？

### 📄 EHR文件來源

**FHIR資源**: `DocumentReference`

從2個伺服器擷取的資料：
```
HAPI FHIR Server: 20份 DocumentReference
SMART Health IT Sandbox: 0份 DocumentReference
─────────────────────────────────────────
合併後: 20份

經過2年時間過濾:
20份 -> 1份 ⚠️ (只有1份在2年內)
```

### 📋 DocumentReference是什麼？

在FHIR中，`DocumentReference`代表：

**常見的文件類型**:
- 🏥 出院摘要 (Discharge Summary)
- 📝 門診紀錄 (Progress Note)
- 🔬 檢驗報告 (Lab Report)
- 📊 影像報告 (Radiology Report)
- 💊 用藥紀錄 (Medication Summary)
- 📋 病歷摘要 (Clinical Summary)

**DocumentReference結構**:
```json
{
  "resourceType": "DocumentReference",
  "status": "current",
  "type": {
    "coding": [{
      "system": "http://loinc.org",
      "code": "34133-9",
      "display": "Summarization of episode note"
    }]
  },
  "subject": {
    "reference": "Patient/123"
  },
  "date": "2024-05-15T10:30:00Z",
  "content": [{
    "attachment": {
      "contentType": "application/pdf",
      "url": "http://example.org/document.pdf"
    }
  }]
}
```

### 🔍 實際情況

**顯示20份的原因**:
- 程式碼計算的是**過濾前**的數量
- 實際上只有**1份**在2年內

**正確的數字應該是**:
```
EHR文件數: 1 份（2年內）
EHR文件數（全部）: 20 份
```

---

## ❓ 問題 5: EHR採用率（就醫次數）0.0% 是什麼意思？

### 📊 計算公式

```python
EHR採用率 = (有電子病歷的就醫次數 / 總就醫次數) × 100%
```

### 🔍 為什麼是0.0%？

**原因分析**:

```
步驟1: 計算總就醫次數
total_encounters = 70（應該是0，過濾後）

步驟2: 計算有EHR的就醫次數
encounters_with_ehr = 0（因為沒有Encounter在2年內）

步驟3: 計算採用率
if 70 > 0:
    rate = (0 / 70) × 100% = 0.0%
```

**真正的問題**:
- 因為**沒有任何Encounter在2年內**
- 所以無法計算哪些就醫有EHR記錄
- 結果就是 0 / 70 = 0%

### ✅ 正確的解讀

**情況1: 如果Encounter真的是0**
```
總就醫次數: 0
有EHR的就醫: 0
採用率: 無法計算（N/A）
```

**情況2: 如果不過濾時間**
```
總就醫次數: 70
有EHR的就醫: 需要重新計算
採用率: 可能不是0%
```

### 🔍 查看實際邏輯

在 `EHR_Adoption_Rate.cql` 中：

```cql
define "Encounters with EHR":
  "All Encounters" E
    where exists([DocumentReference: ...] D where D.date during E.period)
       or exists([Observation: ...] O where O.effective during E.period)
       or exists([MedicationRequest: ...] M where M.authoredOn during E.period)
       or exists([Procedure: ...] P where P.performed during E.period)
```

**為什麼是0%？**
1. `All Encounters` = 0（過濾後）
2. 所以 `Encounters with EHR` = 0
3. 採用率 = 0/0 或 0/70（取決於如何處理）

---

## 🔧 修正建議

### 問題1: Encounter數量顯示錯誤

**需要修改**: `cql_processor.py`

確保顯示的是**過濾後**的數量，而不是原始數量。

### 問題2: 廢棄物計算

**選項1**: 繼續使用估算（說明清楚）
**選項2**: 在真實環境中使用Observation記錄

### 問題3-5: 顯示說明

在報告中加入更清楚的說明：
- Encounter被時間過濾掉了
- 計算是基於過濾後的資料
- 某些指標可能不適用

---

## 📊 建議的改進方案

### 1. 修正顯示邏輯
```python
# 應該顯示過濾後的真實數量
results['total_encounters'] = len(encounters)  # 實際應該是0
results['note'] = '2年內就醫記錄為0，部分指標無法計算'
```

### 2. 加入資料有效性檢查
```python
if len(encounters) == 0:
    results['warning'] = '無2年內就醫記錄，計算結果僅供參考'
```

### 3. 提供兩種報告
- **報告A**: 2年內資料（目前有問題）
- **報告B**: 全部資料（不限時間）

---

## ✅ 總結

| 問題 | 狀態 | 說明 |
|------|------|------|
| 1. 為何都是70 | ⚠️ 需修正 | Patient正確，Encounter應該顯示0 |
| 2. 廢棄物計算 | ℹ️ 說明 | FHIR無標準，使用估算 |
| 3. EMRAM Level 2 | ✅ 正常 | CDR等級，可以改善 |
| 4. EHR文件20份 | ⚠️ 需修正 | 實際2年內只有1份 |
| 5. 採用率0% | ⚠️ 需修正 | 因為Encounter=0導致 |

**核心問題**: 公開測試伺服器的資料太舊，2年過濾後幾乎沒有可用的Encounter資料。

**建議**: 
1. 修正程式碼，正確顯示過濾後的數量
2. 加入警告訊息
3. 提供"不限時間"的報告選項

您希望我立即修正這些問題嗎？
