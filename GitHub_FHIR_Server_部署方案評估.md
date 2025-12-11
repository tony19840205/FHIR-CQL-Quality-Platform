# GitHub FHIR Server 部署方案評估

**評估日期**：2025-12-08  
**目的**：應對外部 FHIR 伺服器不穩定問題，建立可靠的測試環境

---

## 📊 現況問題分析

### 外部伺服器狀況

| 伺服器 | URL | 狀態 | 問題 |
|--------|-----|------|------|
| Taiwan MOHW | https://thas.mohw.gov.tw/v/r4/fhir | ⚠️ 不穩定 | 查詢超時（30s+） |
| HAPI FHIR | https://hapi.fhir.org/baseR4 | ❌ 失效 | 404 Not Found |
| SMART Health IT | https://r4.smarthealthit.org | ✅ 正常 | 公開測試，資料可能被清除 |
| Firely Server | https://server.fire.ly/r4 | ✅ 正常 | 公開測試，資料可能被清除 |

### 主要風險
1. **資料穩定性**：公開伺服器可能定期清空資料
2. **服務可用性**：外部伺服器可能維護或故障
3. **查詢效能**：Taiwan MOHW 查詢經常超時
4. **資料安全**：測試資料在公開伺服器上無法控制

---

## 🎯 GitHub 部署方案

### 方案 A：GitHub Pages + JSON Server（輕量級）⭐ 推薦快速啟動

**架構**：Static JSON API on GitHub Pages

**優點**：
- ✅ 完全免費
- ✅ 5 分鐘內快速部署
- ✅ 自動 HTTPS
- ✅ 全球 CDN 加速
- ✅ 100% 控制資料

**限點**：
- ❌ 唯讀（無法 POST/PUT/DELETE）
- ❌ 不支援完整 FHIR REST API
- ⚠️ 檔案大小限制（100MB）

**適用場景**：
- 前端展示
- CQL 查詢測試
- 指標計算驗證
- **最適合目前需求** ✅

**實作方式**：
```
1. 建立 GitHub Repository: fhir-test-data
2. 上傳所有 JSON Bundle 檔案
3. 啟用 GitHub Pages
4. 前端直接 fetch JSON 檔案
```

**成本**：$0  
**維護**：幾乎為零  
**部署時間**：5-10 分鐘

---

### 方案 B：GitHub Actions + HAPI FHIR（Docker）

**架構**：Self-hosted HAPI FHIR Server with GitHub Actions

**優點**：
- ✅ 完整 FHIR R4 API
- ✅ 支援 CRUD 操作
- ✅ CQL Engine 支援
- ✅ 可自動重新部署

**限點**：
- ❌ 需要外部主機（Azure/AWS/GCP）
- ❌ 有運行成本（每月 $5-20）
- ⚠️ 需要維護和監控
- ⚠️ 部署較複雜

**適用場景**：
- 完整 FHIR 功能測試
- 持續整合測試
- 生產環境準備

**實作方式**：
```
1. 建立 Azure/AWS 帳號
2. Docker 容器部署 HAPI FHIR
3. GitHub Actions 自動化部署
4. 定期備份資料
```

**成本**：$5-20/月  
**維護**：中等  
**部署時間**：1-2 小時

---

### 方案 C：GitHub Codespaces + HAPI FHIR（開發環境）

**架構**：GitHub Codespaces 運行 HAPI FHIR

**優點**：
- ✅ 快速啟動（10 分鐘）
- ✅ 完整 FHIR API
- ✅ 開發環境整合
- ✅ 按使用計費

**限點**：
- ❌ 有使用時數限制（每月 60 小時免費）
- ❌ 停止後資料可能遺失
- ⚠️ 不適合長期運行

**適用場景**：
- 開發測試
- 短期驗證
- 學習研究

**成本**：$0-10/月（視使用量）  
**維護**：低  
**部署時間**：10-15 分鐘

---

### 方案 D：混合方案（推薦）⭐⭐⭐

**架構**：GitHub Pages（主） + SMART Health IT（備）

**策略**：
1. **主要**：GitHub Pages 託管靜態 JSON（100% 可靠）
2. **備用**：SMART Health IT（需要完整 API 時）
3. **本地**：HAPI FHIR Docker（開發測試用）

**優點**：
- ✅ 最大可靠性
- ✅ 零成本
- ✅ 快速部署
- ✅ 靈活切換

**實作**：
```javascript
// 前端自動切換
const FHIR_ENDPOINTS = {
  primary: 'https://YOUR_USERNAME.github.io/fhir-test-data',
  fallback: 'https://r4.smarthealthit.org',
  local: 'http://localhost:8080/fhir'
};

async function fetchFHIR(endpoint) {
  try {
    return await fetch(`${FHIR_ENDPOINTS.primary}${endpoint}.json`);
  } catch (error) {
    return await fetch(`${FHIR_ENDPOINTS.fallback}${endpoint}`);
  }
}
```

---

## 🚀 推薦實施計畫

### 階段 1：立即部署（今天完成）

**選擇方案 A + D**：GitHub Pages 靜態 JSON

#### 步驟 1：建立 Repository
```powershell
cd "c:\Users\tony1\Desktop\UI UX-20251122(0013)"

# 建立新的 FHIR 資料 repository
git init fhir-test-data
cd fhir-test-data

# 建立資料夾結構
mkdir patients, bundles, metadata

# 複製所有 JSON 檔案
Copy-Item "..\UI UX\HAPI-FHIR-Samples\*.json" -Destination "bundles\"
Copy-Item "..\UI UX\FHIR-Dashboard-App\*_Patients.json" -Destination "bundles\"
Copy-Item "..\test_data_*.json" -Destination "bundles\"
```

#### 步驟 2：建立索引檔案
```javascript
// index.json - 所有資料的索引
{
  "resourceType": "Bundle",
  "type": "collection",
  "entry": [
    {
      "fullUrl": "https://YOUR_USERNAME.github.io/fhir-test-data/bundles/CGMH_test_data_taiwan_100_bundle.json",
      "resource": {
        "resourceType": "Bundle",
        "id": "cgmh-taiwan-100",
        "meta": {
          "lastUpdated": "2025-12-08T00:00:00Z"
        }
      }
    }
    // ... 其他 32 個檔案
  ],
  "total": 33,
  "meta": {
    "patients": 645,
    "resources": 3500
  }
}
```

#### 步驟 3：啟用 GitHub Pages
```powershell
# Push to GitHub
git add .
git commit -m "Initial FHIR test data"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/fhir-test-data.git
git push -u origin main

# GitHub 網頁操作：
# Settings → Pages → Source: main branch → Save
```

#### 步驟 4：前端整合
```javascript
// 修改 FHIR-Dashboard-App 的 API endpoint
const GITHUB_FHIR = 'https://YOUR_USERNAME.github.io/fhir-test-data';

async function loadPatients() {
  const response = await fetch(`${GITHUB_FHIR}/index.json`);
  const index = await response.json();
  
  // 載入所有 bundles
  for (const entry of index.entry) {
    const bundle = await fetch(entry.fullUrl);
    processBundle(await bundle.json());
  }
}
```

**完成時間**：30 分鐘  
**立即好處**：
- ✅ 所有資料 100% 可存取
- ✅ 不再依賴外部伺服器
- ✅ 查詢速度大幅提升（CDN）
- ✅ 可隨時更新資料

---

### 階段 2：功能增強（本週完成）

#### 2.1 建立 Patient 索引
```json
// patients/index.json
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 645,
  "entry": [
    {
      "resource": {
        "resourceType": "Patient",
        "id": "TW00001",
        "name": [{"text": "病患 1"}],
        "bundleUrl": "bundles/CGMH_test_data_taiwan_100_bundle.json"
      }
    }
    // ... 所有 645 位病患
  ]
}
```

#### 2.2 建立指標快取
```json
// indicators/cache.json
{
  "indicators": {
    "03-1": {
      "name": "同院降血壓藥重疊",
      "numerator": 4,
      "denominator": 93,
      "rate": 0.043,
      "lastUpdated": "2025-12-08"
    }
    // ... 所有 29 個指標
  }
}
```

#### 2.3 自動化腳本
```powershell
# generate_index.ps1 - 自動產生索引檔案
$bundles = Get-ChildItem "bundles\*.json"
$patients = @()
$totalResources = 0

foreach ($bundle in $bundles) {
  $data = Get-Content $bundle.FullName | ConvertFrom-Json
  foreach ($entry in $data.entry) {
    if ($entry.resource.resourceType -eq "Patient") {
      $patients += $entry.resource
    }
  }
  $totalResources += $data.entry.Count
}

$index = @{
  resourceType = "Bundle"
  type = "collection"
  total = $patients.Count
  totalResources = $totalResources
  entry = $patients
}

$index | ConvertTo-Json -Depth 10 | Out-File "patients/index.json" -Encoding UTF8
```

---

### 階段 3：進階功能（未來規劃）

#### 3.1 GitHub Actions 自動化
```yaml
# .github/workflows/update-fhir-data.yml
name: Update FHIR Data
on:
  push:
    paths:
      - 'bundles/**'
jobs:
  update-index:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Generate Index
        run: |
          node scripts/generate-index.js
      - name: Commit Changes
        run: |
          git config user.name "GitHub Actions"
          git add .
          git commit -m "Auto-update index"
          git push
```

#### 3.2 搜尋 API（GitHub Pages 限制下的變通）
```javascript
// search-api.js - 客戶端搜尋
class FHIRSearch {
  async search(resourceType, params) {
    // 載入相關 bundle
    const index = await fetch(`${GITHUB_FHIR}/index.json`).then(r => r.json());
    
    // 客戶端過濾
    const results = index.entry.filter(entry => {
      // 實作搜尋邏輯
      return matchParams(entry.resource, params);
    });
    
    return results;
  }
}
```

---

## 💰 成本比較

| 方案 | 初始成本 | 月成本 | 年成本 | 維護成本 |
|------|----------|--------|--------|----------|
| **方案 A（GitHub Pages）** | $0 | $0 | $0 | 極低 ⭐ |
| 方案 B（Azure App Service） | $0 | $10-20 | $120-240 | 中 |
| 方案 C（Codespaces） | $0 | $0-10 | $0-120 | 低 |
| **方案 D（混合）** | $0 | $0 | $0 | 低 ⭐⭐⭐ |
| 外部伺服器（現況） | $0 | $0 | $0 | 高（不可靠）❌ |

---

## 📋 實施檢查清單

### 立即執行（今天）
- [ ] 建立 `fhir-test-data` GitHub Repository
- [ ] 上傳所有 33 個 JSON bundle 檔案
- [ ] 建立 `index.json` 索引
- [ ] 啟用 GitHub Pages
- [ ] 測試 JSON 可存取性
- [ ] 更新前端 API endpoint

### 本週完成
- [ ] 建立 Patient 索引 (`patients/index.json`)
- [ ] 建立指標快取 (`indicators/cache.json`)
- [ ] 撰寫索引產生腳本 (`generate_index.ps1`)
- [ ] 整合前端查詢功能
- [ ] 效能測試和優化

### 進階功能（選用）
- [ ] GitHub Actions 自動化
- [ ] 版本控制策略
- [ ] 備份機制
- [ ] 客戶端搜尋 API
- [ ] 監控和分析

---

## 🎯 預期成果

### 立即效益
1. **100% 可用性**：不再受外部伺服器影響
2. **快速查詢**：GitHub CDN 全球加速
3. **完全控制**：資料隨時更新，不會被清除
4. **零成本**：完全免費方案

### 長期效益
1. **可擴展性**：輕鬆增加更多測試資料
2. **版本管理**：Git 追蹤所有變更
3. **協作便利**：團隊成員可共同維護
4. **展示友善**：可公開分享給評審

---

## 📝 技術規格

### Repository 結構
```
fhir-test-data/
├── README.md                    # 說明文件
├── index.json                   # 主索引
├── bundles/                     # 所有 Bundle 檔案
│   ├── CGMH_test_data_taiwan_100_bundle.json
│   ├── CGMH_test_data_vaccine_100_bundle.json
│   └── ... (33 個檔案)
├── patients/                    # Patient 索引
│   └── index.json
├── indicators/                  # 指標快取
│   ├── cache.json
│   └── details/
│       ├── 03-1.json
│       └── ... (29 個指標)
├── metadata/                    # FHIR Metadata
│   └── CapabilityStatement.json
└── scripts/                     # 工具腳本
    ├── generate_index.ps1
    └── validate_data.ps1
```

### API Endpoints（靜態）
```
https://YOUR_USERNAME.github.io/fhir-test-data/
├── /index.json                  # 主索引
├── /bundles/*.json              # 所有 Bundles
├── /patients/index.json         # 病患清單
├── /indicators/cache.json       # 指標快取
└── /metadata/CapabilityStatement.json
```

---

## 🚨 重要提醒

### GitHub Pages 限制
1. **檔案大小**：單檔不超過 100MB（目前檔案都很小，無問題）
2. **Repository 大小**：建議不超過 1GB（目前約 10-20MB）
3. **唯讀**：無法透過 API 新增/修改資料（可透過 Git 更新）
4. **頻寬**：每月 100GB（足夠使用）

### 資料更新流程
```powershell
# 本地更新資料
cd fhir-test-data
# 修改 JSON 檔案
git add .
git commit -m "Update patient data"
git push

# GitHub Pages 自動更新（5 分鐘內）
```

---

## ✅ 結論與建議

### 最佳方案：**方案 D（混合）**

**立即實施**：
1. ✅ 建立 GitHub Pages（方案 A）
2. ✅ 保留 SMART Health IT 作為備援
3. ✅ 前端智慧切換 endpoint

**理由**：
- 零成本
- 最高可靠性
- 快速部署（30 分鐘）
- 完全符合目前需求

**下一步**：
執行階段 1 的 4 個步驟，今天內完成部署！

---

**需要我立即開始建立 GitHub Repository 和相關檔案嗎？** 🚀
