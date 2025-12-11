# GitHub 上製作類似 FHIR 伺服器方案評估

**評估日期**：2025-12-08  
**目標**：在 GitHub 上建立類似 FHIR Server 的解決方案

---

## 🎯 核心問題分析

### 真正的 FHIR Server 需要什麼？

| 功能 | 真實 FHIR Server | GitHub Pages 能做到？ | 替代方案 |
|------|------------------|----------------------|----------|
| **GET 查詢** | ✅ 支援 | ✅ **可以**（靜態 JSON） | - |
| **POST 新增** | ✅ 支援 | ❌ 不行（唯讀） | GitHub Actions |
| **PUT 更新** | ✅ 支援 | ❌ 不行（唯讀） | Git Push |
| **DELETE 刪除** | ✅ 支援 | ❌ 不行（唯讀） | Git Push |
| **搜尋/過濾** | ✅ 動態查詢 | ⚠️ 客戶端實現 | JavaScript |
| **版本控制** | ✅ 支援 | ✅ **天生支援**（Git） | - |
| **歷史紀錄** | ✅ 支援 | ✅ **完整紀錄**（Git） | - |

---

## ✅ 方案 1：GitHub Pages 靜態 FHIR API（推薦）⭐⭐⭐

### 概念
將 GitHub Pages 打造成「唯讀 FHIR Server」

### 能做到的事
```javascript
// ✅ 可以做到
fetch('https://YOUR_USERNAME.github.io/fhir-test-data/data/Patient/TW00001.json')
  .then(r => r.json())
  .then(patient => console.log(patient));

// ✅ 可以做到
fetch('https://YOUR_USERNAME.github.io/fhir-test-data/data/bundles/cgmh/CGMH_test_data_taiwan_100_bundle.json')
  .then(r => r.json())
  .then(bundle => {
    // 客戶端處理資料
    const patients = bundle.entry.filter(e => e.resource.resourceType === 'Patient');
  });

// ✅ 可以做到（客戶端搜尋）
const patients = await searchPatients({ family: '陳' });
```

### 做不到的事
```javascript
// ❌ 做不到（無法寫入）
fetch('https://YOUR_USERNAME.github.io/fhir-test-data/data/Patient', {
  method: 'POST',
  body: JSON.stringify(newPatient)  // 無法新增
});

// ❌ 做不到（無法更新）
fetch('https://YOUR_USERNAME.github.io/fhir-test-data/data/Patient/TW00001', {
  method: 'PUT',
  body: JSON.stringify(updatedPatient)  // 無法更新
});
```

### 架構設計
```
GitHub Repository (fhir-test-data)
├── index.html                          # 首頁
├── api/                                # 模擬 API
│   ├── metadata.json                   # CapabilityStatement
│   ├── Patient/
│   │   ├── index.json                  # 所有病患列表
│   │   ├── TW00001.json                # 個別病患
│   │   ├── TW00002.json
│   │   └── ...
│   ├── Observation/
│   │   ├── index.json
│   │   └── ...
│   └── Encounter/
│       └── ...
└── bundles/                            # Bundle 資料
    ├── cgmh/
    ├── hapi-samples/
    └── dashboard/
```

### 前端整合方式
```javascript
// fhir-client.js - 模擬 FHIR Client
class GitHubFHIRClient {
  constructor(baseUrl) {
    this.baseUrl = baseUrl;
  }
  
  // GET Patient by ID
  async getPatient(id) {
    const response = await fetch(`${this.baseUrl}/api/Patient/${id}.json`);
    return response.json();
  }
  
  // Search Patients
  async searchPatients(params) {
    const index = await fetch(`${this.baseUrl}/api/Patient/index.json`).then(r => r.json());
    
    // 客戶端過濾
    return index.entry.filter(entry => {
      const patient = entry.resource;
      if (params.family && !patient.name[0].family.includes(params.family)) return false;
      if (params.given && !patient.name[0].given[0].includes(params.given)) return false;
      return true;
    });
  }
  
  // GET Bundle
  async getBundle(category, filename) {
    const response = await fetch(`${this.baseUrl}/bundles/${category}/${filename}`);
    return response.json();
  }
}

// 使用方式
const client = new GitHubFHIRClient('https://YOUR_USERNAME.github.io/fhir-test-data');
const patient = await client.getPatient('TW00001');
```

### 優點
- ✅ **零成本**
- ✅ **100% 穩定**（不受外部伺服器影響）
- ✅ **全球 CDN**（快速存取）
- ✅ **版本控制**（Git 完整歷史）
- ✅ **不動程式碼**（前端可選擇性使用）

### 缺點
- ❌ 唯讀（無法新增/修改/刪除）
- ⚠️ 搜尋需客戶端實現
- ⚠️ 不支援複雜 FHIR 查詢語法

### 適用場景
- ✅ **展示 Demo**（最佳選擇）
- ✅ **前端測試**
- ✅ **指標計算**（已有完整資料）
- ✅ **評審展示**
- ❌ 不適合：需要動態新增資料

---

## 💡 方案 2：GitHub Actions + JSON Database（半動態）⭐⭐

### 概念
透過 GitHub Actions 實現「偽動態」更新

### 運作方式
```yaml
# .github/workflows/add-patient.yml
name: Add Patient via API
on:
  workflow_dispatch:
    inputs:
      patient_data:
        description: 'Patient JSON data'
        required: true

jobs:
  add-patient:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Add Patient
        run: |
          echo '${{ github.event.inputs.patient_data }}' > api/Patient/new-patient.json
          
      - name: Update Index
        run: |
          node scripts/update-index.js
          
      - name: Commit and Push
        run: |
          git config user.name "GitHub Actions"
          git add .
          git commit -m "Add new patient"
          git push
```

### 前端「POST」實現
```javascript
// 前端呼叫 GitHub Actions
async function addPatient(patientData) {
  // 1. 觸發 GitHub Actions
  const response = await fetch('https://api.github.com/repos/YOUR_USERNAME/fhir-test-data/dispatches', {
    method: 'POST',
    headers: {
      'Authorization': 'token YOUR_GITHUB_TOKEN',
      'Accept': 'application/vnd.github.v3+json'
    },
    body: JSON.stringify({
      event_type: 'add-patient',
      client_payload: {
        patient: patientData
      }
    })
  });
  
  // 2. 等待 GitHub Actions 完成（約 1-2 分鐘）
  await new Promise(resolve => setTimeout(resolve, 120000));
  
  // 3. 重新載入資料
  location.reload();
}
```

### 優點
- ✅ 可以「新增」資料（透過 GitHub Actions）
- ✅ 完整版本控制
- ✅ 仍然免費

### 缺點
- ❌ 延遲高（1-2 分鐘）
- ❌ 複雜度高
- ⚠️ 需要 GitHub Token

### 適用場景
- ⚠️ 需要偶爾新增資料
- ❌ 不適合：即時互動

---

## 🚀 方案 3：GitHub Codespaces + HAPI FHIR（完整動態）⭐

### 概念
在 GitHub Codespaces 運行真正的 HAPI FHIR Server

### 架構
```
GitHub Repository
├── .devcontainer/
│   └── devcontainer.json               # Codespaces 設定
├── docker-compose.yml                  # HAPI FHIR 容器
└── data/                               # 初始資料
    └── bundles/
```

### devcontainer.json
```json
{
  "name": "FHIR Server",
  "dockerComposeFile": "docker-compose.yml",
  "service": "fhir-server",
  "workspaceFolder": "/workspace",
  "forwardPorts": [8080],
  "postCreateCommand": "bash scripts/load-data.sh"
}
```

### docker-compose.yml
```yaml
version: '3'
services:
  fhir-server:
    image: hapiproject/hapi:latest
    ports:
      - "8080:8080"
    environment:
      - hapi.fhir.fhir_version=R4
      - hapi.fhir.server_address=http://localhost:8080/fhir
```

### 使用方式
```bash
# 1. 開啟 GitHub Codespaces
# 2. HAPI FHIR 自動啟動
# 3. 存取 http://localhost:8080/fhir

# 上傳資料
curl -X POST http://localhost:8080/fhir \
  -H "Content-Type: application/fhir+json" \
  -d @bundles/cgmh/CGMH_test_data_taiwan_100_bundle.json
```

### 優點
- ✅ **完整 FHIR Server**（所有功能）
- ✅ 整合開發環境
- ✅ 按使用付費

### 缺點
- ❌ 有成本（每月 60 小時免費，超過需付費）
- ❌ 停止後資料遺失（除非持久化）
- ⚠️ 不適合 24/7 運行

### 適用場景
- ✅ **開發測試**
- ✅ 短期 Demo
- ❌ 不適合：長期運行

---

## ⚡ 方案 4：Cloudflare Workers + KV（邊緣運算）⭐⭐

### 概念
使用 Cloudflare Workers 建立無伺服器 FHIR API

### 架構
```javascript
// worker.js - Cloudflare Worker
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url);
  
  // GET Patient by ID
  if (url.pathname.startsWith('/Patient/')) {
    const id = url.pathname.split('/')[2];
    const patient = await FHIR_KV.get(`Patient:${id}`, 'json');
    return new Response(JSON.stringify(patient), {
      headers: { 'Content-Type': 'application/fhir+json' }
    });
  }
  
  // POST Patient
  if (url.pathname === '/Patient' && request.method === 'POST') {
    const patient = await request.json();
    const id = generateId();
    await FHIR_KV.put(`Patient:${id}`, JSON.stringify(patient));
    return new Response(JSON.stringify({ id }), { status: 201 });
  }
  
  return new Response('Not Found', { status: 404 });
}
```

### 優點
- ✅ 支援讀寫
- ✅ 全球邊緣節點（超快）
- ✅ 免費額度大（每天 10 萬次請求）

### 缺點
- ⚠️ 需要學習 Cloudflare Workers
- ⚠️ KV 儲存有限制
- ❌ 不是標準 FHIR Server

### 適用場景
- ✅ 高流量展示
- ✅ 需要寫入功能
- ⚠️ 中等複雜度

---

## 📊 方案比較總表

| 方案 | 成本 | 部署時間 | FHIR 完整度 | 讀取 | 寫入 | 適用場景 | 推薦度 |
|------|------|----------|-------------|------|------|----------|--------|
| **方案 1: GitHub Pages** | $0 | 30分鐘 | 60% | ✅ | ❌ | 展示、測試 | ⭐⭐⭐ |
| 方案 2: GitHub Actions | $0 | 2小時 | 70% | ✅ | ⏱️ | 偶爾更新 | ⭐⭐ |
| 方案 3: Codespaces | $0-20/月 | 15分鐘 | 100% | ✅ | ✅ | 開發測試 | ⭐ |
| 方案 4: Cloudflare | $0-5/月 | 1小時 | 80% | ✅ | ✅ | 高流量 | ⭐⭐ |

---

## 🎯 針對你的需求推薦

### 你的使用情境分析

根據你的檔案內容：
- ✅ 已有完整測試資料（645 人）
- ✅ 主要用於指標計算和展示
- ✅ 資料已製作完成，不常更新
- ⚠️ 外部伺服器不穩定

### 最佳方案：**方案 1（GitHub Pages 靜態 API）** ⭐⭐⭐

**理由**：
1. ✅ **完全符合需求**：你的資料已經準備好，只需要穩定讀取
2. ✅ **零成本零維護**
3. ✅ **30 分鐘完成**
4. ✅ **100% 可靠**
5. ✅ **不動程式碼**（前端加個選項即可）

**實施方式**：
```
1. 建立 GitHub Repository (5分鐘)
2. 上傳 33 個 JSON 檔案 (10分鐘)
3. 建立索引和 API 結構 (10分鐘)
4. 啟用 GitHub Pages (5分鐘)
5. 前端整合（在下拉選單加一個選項）(5分鐘)
```

---

## 🔧 具體實作建議

### 階段 1：基礎 API 結構（今天完成）

```
fhir-test-data/
├── index.html                          # 首頁
├── api/
│   ├── metadata.json                   # FHIR CapabilityStatement
│   ├── Patient/
│   │   └── index.json                  # 所有 645 位病患
│   ├── Observation/
│   │   └── index.json
│   └── Bundle/
│       └── index.json                  # 33 個 Bundle 清單
└── data/
    ├── cgmh/                           # 直接放 JSON 檔案
    ├── hapi-samples/
    ├── dashboard/
    └── root/
```

### 階段 2：前端整合（5 分鐘）

在你的 FHIR-Dashboard-App 中：

```javascript
// 在伺服器下拉選單新增
const servers = [
  {
    name: "台灣衛福部 FHIR Server (官方測試環境) ⭐",
    url: "https://thas.mohw.gov.tw/v/r4/fhir"
  },
  {
    name: "HAPI FHIR R4 (國際測試伺服器)",
    url: "https://hapi.fhir.org/baseR4"
  },
  {
    name: "SMART Health IT R4",
    url: "https://r4.smarthealthit.org"
  },
  // ========== 新增這個 ==========
  {
    name: "GitHub 靜態資料 (本地備援) 🔒",
    url: "https://YOUR_USERNAME.github.io/fhir-test-data/data",
    type: "static",
    description: "完整 645 位病患測試資料，100% 可用"
  },
  // ==============================
  {
    name: "自訂伺服器...",
    url: "custom"
  }
];
```

---

## ✅ 結論

### 可以製作「類似」伺服器嗎？

**答案：可以！但有限制**

| 功能 | 真實 FHIR Server | GitHub Pages 方案 |
|------|------------------|-------------------|
| 讀取資料 | ✅ | ✅ **完全支援** |
| 搜尋查詢 | ✅ 伺服器端 | ✅ 客戶端實現 |
| 新增資料 | ✅ | ❌ 不支援（但你不需要） |
| 更新資料 | ✅ | ❌ 不支援（但你不需要） |
| 指標計算 | ✅ | ✅ **完全支援** |
| 展示 Demo | ✅ | ✅ **更好**（不怕被清空） |
| 穩定性 | ⚠️ | ✅ **100%** |

### 對你來說：

**GitHub Pages = 90% 的 FHIR Server 功能 + 0% 成本 + 100% 穩定性**

**足夠嗎？** ✅ **絕對足夠！**

---

## 🚀 下一步行動

**建議立即實施方案 1**：

1. ✅ 建立 GitHub Repository（5 分鐘）
2. ✅ 上傳資料檔案（10 分鐘）
3. ✅ 建立 API 結構（10 分鐘）
4. ✅ 啟用 GitHub Pages（5 分鐘）
5. ✅ 前端整合（5 分鐘）

**總計：35 分鐘**

**需要我現在開始建立嗎？** 🎯
