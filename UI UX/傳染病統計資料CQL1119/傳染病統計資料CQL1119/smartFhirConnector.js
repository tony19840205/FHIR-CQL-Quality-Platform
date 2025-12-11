const axios = require('axios');
const fs = require('fs');
const path = require('path');

/**
 * SMART FHIR 連線管理器
 * 用於連接到外部 SMART 伺服器並檢索 FHIR 資源
 */
class SmartFhirConnector {
  constructor(config) {
    this.servers = config.smartServers.filter(s => s.enabled);
    this.filterCriteria = config.filterCriteria;
    this.results = [];
  }

  /**
   * 從所有已啟用的 SMART 伺服器檢索資料
   */
  async fetchDataFromAllServers() {
    console.log(`\n🔗 連接到 ${this.servers.length} 個 SMART FHIR 伺服器...\n`);
    
    const allData = [];
    
    for (const server of this.servers) {
      try {
        console.log(`📡 正在連接: ${server.name} (${server.fhirBaseUrl})`);
        const serverData = await this.fetchFromServer(server);
        allData.push({
          server: server.name,
          url: server.fhirBaseUrl,
          data: serverData,
          success: true
        });
        console.log(`✅ 成功從 ${server.name} 獲取資料\n`);
      } catch (error) {
        console.error(`❌ 從 ${server.name} 獲取資料失敗: ${error.message}\n`);
        allData.push({
          server: server.name,
          url: server.fhirBaseUrl,
          error: error.message,
          success: false
        });
      }
    }
    
    return allData;
  }

  /**
   * 從單一伺服器檢索所有相關的 FHIR 資源
   */
  async fetchFromServer(server) {
    const baseUrl = server.fhirBaseUrl;
    
    // 計算2年前的日期
    const twoYearsAgo = new Date();
    twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - this.filterCriteria.timeRangeYears);
    const dateFilter = twoYearsAgo.toISOString().split('T')[0];
    
    const resources = {
      patients: [],
      conditions: [],
      observations: [],
      encounters: []
    };

    try {
      // 檢索所有患者 (無數量限制)
      console.log(`  ↳ 檢索 Patient 資源 (無限制)...`);
      resources.patients = await this.fetchAllPages(baseUrl, 'Patient', {});

      // 檢索診斷條件 (2年內，無數量限制)
      console.log(`  ↳ 檢索 Condition 資源 (${dateFilter} 之後，無限制)...`);
      resources.conditions = await this.fetchAllPages(baseUrl, 'Condition', {
        'recorded-date': `ge${dateFilter}`
      });

      // 檢索實驗室檢驗 (2年內，無數量限制)
      console.log(`  ↳ 檢索 Observation 資源 (${dateFilter} 之後，無限制)...`);
      resources.observations = await this.fetchAllPages(baseUrl, 'Observation', {
        'date': `ge${dateFilter}`,
        'category': 'laboratory'
      });

      // 檢索就醫記錄 (2年內，無數量限制)
      console.log(`  ↳ 檢索 Encounter 資源 (${dateFilter} 之後，無限制)...`);
      resources.encounters = await this.fetchAllPages(baseUrl, 'Encounter', {
        'date': `ge${dateFilter}`
      });

      console.log(`  📊 總計: ${resources.patients.length} 患者, ${resources.conditions.length} 診斷, ${resources.observations.length} 檢驗, ${resources.encounters.length} 就醫記錄`);

    } catch (error) {
      console.error(`  ❌ 資源檢索錯誤: ${error.message}`);
      throw error;
    }

    return resources;
  }

  /**
   * 通用 FHIR 資源檢索方法
   */
  async fetchResource(baseUrl, resourceType, params = {}) {
    try {
      const url = `${baseUrl}/${resourceType}`;
      const response = await axios.get(url, {
        params: params,
        headers: {
          'Accept': 'application/fhir+json'
        },
        timeout: 30000
      });
      
      return response.data;
    } catch (error) {
      if (error.response) {
        throw new Error(`HTTP ${error.response.status}: ${error.response.statusText}`);
      } else if (error.request) {
        throw new Error('無法連接到伺服器');
      } else {
        throw new Error(error.message);
      }
    }
  }

  /**
   * 自動翻頁獲取所有資源（無數量限制）
   */
  async fetchAllPages(baseUrl, resourceType, params = {}) {
    const allEntries = [];
    let nextUrl = null;
    let pageCount = 0;
    const maxPages = 100; // 安全限制：最多100頁，避免無限迴圈
    
    try {
      // 第一次請求
      params._count = 1000; // 每頁1000筆，減少請求次數
      const firstResponse = await this.fetchResource(baseUrl, resourceType, params);
      
      if (firstResponse.entry) {
        allEntries.push(...firstResponse.entry);
        pageCount++;
      }
      
      // 檢查是否有下一頁
      if (firstResponse.link) {
        const nextLink = firstResponse.link.find(link => link.relation === 'next');
        if (nextLink) {
          nextUrl = nextLink.url;
        }
      }
      
      // 自動翻頁獲取所有資料
      while (nextUrl && pageCount < maxPages) {
        const response = await axios.get(nextUrl, {
          headers: { 'Accept': 'application/fhir+json' },
          timeout: 30000
        });
        
        if (response.data.entry) {
          allEntries.push(...response.data.entry);
          pageCount++;
          process.stdout.write(`\r  ↳ 已獲取 ${pageCount} 頁，共 ${allEntries.length} 筆資料...`);
        }
        
        // 尋找下一頁
        nextUrl = null;
        if (response.data.link) {
          const nextLink = response.data.link.find(link => link.relation === 'next');
          if (nextLink) {
            nextUrl = nextLink.url;
          }
        }
      }
      
      if (pageCount > 1) {
        console.log(''); // 換行
      }
      
      return allEntries;
      
    } catch (error) {
      console.error(`\n  ⚠️  翻頁時發生錯誤: ${error.message}`);
      return allEntries; // 返回已獲取的資料
    }
  }

  /**
   * 從 FHIR Bundle 中提取資源
   */
  extractResources(bundle) {
    if (!bundle || !bundle.entry) {
      return [];
    }
    return bundle.entry.map(entry => entry.resource);
  }

  /**
   * 依據患者 ID 取得患者資訊
   */
  async getPatientById(baseUrl, patientId) {
    try {
      const response = await axios.get(`${baseUrl}/Patient/${patientId}`, {
        headers: { 'Accept': 'application/fhir+json' },
        timeout: 10000
      });
      return response.data;
    } catch (error) {
      console.error(`無法取得患者 ${patientId}: ${error.message}`);
      return null;
    }
  }
}

module.exports = SmartFhirConnector;
