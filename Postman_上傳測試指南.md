# 📋 Postman 上傳測試完整指南

## 🎯 目標
上傳測試資料到台灣衛福部 FHIR Server (`https://thas.mohw.gov.tw/v/r4/fhir`)，然後測試 SAND-BOX 的 EHR Launch。

---

## 📦 Step 1: 準備測試資料

### 建議使用的測試資料（小批次）：
```
test_data_diabetes_2_patients.json          (2 病人，糖尿病)
test_data_eswl_3_patients.json              (3 病人，體外震波)
test_single_cesarean.json                   (1 病人，剖腹產)
```

**總共：6 個病人，快速測試用** ⭐

---

## 🔧 Step 2: Postman 設定

### 2.1 創建新請求

1. **開啟 Postman**
2. **新增請求 (New Request)**
   - 名稱：`Upload FHIR Bundle - Taiwan MOHW`
   - 方法：`POST`
   - URL：`https://thas.mohw.gov.tw/v/r4/fhir`

### 2.2 設定 Headers

```
Content-Type: application/fhir+json
Accept: application/fhir+json
```

### 2.3 設定 Body

1. 選擇 **Body** 標籤
2. 選擇 **raw** 
3. 選擇 **JSON** 格式
4. 複製貼上測試資料內容（見下方）

---

## 📄 Step 3: 測試資料內容

### 選項 A：單一病人測試（最簡單）⭐

打開 `test_single_cesarean.json`，複製全部內容到 Postman Body。

### 選項 B：糖尿病 2 病人

打開 `test_data_diabetes_2_patients.json`，複製全部內容到 Postman Body。

### 選項 C：體外震波 3 病人

打開 `test_data_eswl_3_patients.json`，複製全部內容到 Postman Body。

---

## 🚀 Step 4: 執行上傳

1. **點擊 Send 按鈕**
2. **等待回應**（可能需要 5-30 秒）
3. **檢查回應狀態**：
   - ✅ `200 OK` 或 `201 Created` = 成功
   - ❌ `400 Bad Request` = 資料格式錯誤
   - ❌ `403 Forbidden` = 權限問題
   - ❌ `500 Server Error` = 伺服器錯誤
   - ❌ `Timeout` = 連線逾時

---

## 🔍 Step 5: 驗證上傳成功

上傳成功後，測試查詢：

### 5.1 查詢所有病人

```
GET https://thas.mohw.gov.tw/v/r4/fhir/Patient
```

### 5.2 查詢特定病人

```
GET https://thas.mohw.gov.tw/v/r4/fhir/Patient/[病人ID]
```

### 5.3 查詢 Observation

```
GET https://thas.mohw.gov.tw/v/r4/fhir/Observation?patient=[病人ID]
```

---

## 🎯 Step 6: SAND-BOX Launch 測試

### 6.1 準備 Launch URL

你的 GitHub Pages URL（需要修改）：
```
https://tony19840205.github.io/FHIR-CQL-Quality-Platform/index.html
```

或使用本地測試：
```
http://localhost:8080/index.html
```

### 6.2 在 SAND-BOX 輸入

1. 選擇：**EHR Launch**
2. FHIR Server URL：`https://thas.mohw.gov.tw/v/r4/fhir`
3. Launch URL：輸入你的應用程式 URL
4. 點擊「完成」

---

## ⚠️ 已知問題與解決方案

### 問題 1：CORS 封鎖

**症狀**：
```
Access to fetch at 'https://thas.mohw.gov.tw/v/r4/fhir/metadata' 
has been blocked by CORS policy
```

**解決方案**：
- 使用 Postman（不受 CORS 限制）✅
- 使用 CORS 代理（見 `cors-fix-test.html`）
- 使用本地測試環境

### 問題 2：連線逾時

**症狀**：
```
Failed to load resource: net::ERR_FAILED
```

**解決方案**：
- 確認伺服器狀態（可能在維護）
- 多試幾次（伺服器不穩定）
- 切換到備用伺服器（Firely 或 SMART Health IT）

### 問題 3：資料被清空

**症狀**：查詢不到剛上傳的資料

**原因**：Sand-Box 可能定期清空資料（6 個月一次）

**解決方案**：
- 重新上傳
- 記錄上傳時間
- 使用穩定的測試伺服器

---

## 📊 測試清單

- [ ] Postman 設定完成
- [ ] 上傳 1 個病人成功
- [ ] 查詢病人資料成功
- [ ] SAND-BOX Launch URL 輸入
- [ ] Launch 測試成功
- [ ] Dashboard 顯示資料

---

## 🆘 遇到問題？

### 快速診斷：

1. **Postman 無法連線** → 檢查網路，確認 URL 正確
2. **上傳失敗 (400)** → 檢查 JSON 格式，確認是 FHIR Bundle
3. **上傳失敗 (403/500)** → 伺服器問題，稍後再試
4. **查詢不到資料** → 等待 1-2 分鐘，資料可能需要時間索引
5. **Launch 失敗** → 檢查 URL 是否正確，確認有 CORS 設定

---

## 📞 技術支援資訊

- **FHIR Server**：https://thas.mohw.gov.tw/v/r4/fhir
- **文件**：FHIR R4 Specification (https://hl7.org/fhir/R4/)
- **測試工具**：Postman, curl, Python requests

---

**建議：先用 Postman 上傳 `test_single_cesarean.json` (1 病人) 快速測試！** ⭐
