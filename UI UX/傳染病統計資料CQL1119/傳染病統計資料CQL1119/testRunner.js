const fs = require('fs');
const path = require('path');
const SmartFhirConnector = require('./smartFhirConnector');
const DataFilterAndDisplay = require('./dataFilterDisplay');
const SampleDataGenerator = require('./sampleDataGenerator');

/**
 * 傳染病監測系統 - 主程式
 * 整合 CQL 查詢、SMART FHIR 連線、資料過濾與顯示
 */
class SurveillanceTestRunner {
  constructor(useSampleData = false) {
    this.config = this.loadConfig();
    this.connector = new SmartFhirConnector(this.config);
    this.display = new DataFilterAndDisplay(this.config);
    this.results = [];
    this.useSampleData = useSampleData;
    if (useSampleData) {
      this.sampleGenerator = new SampleDataGenerator();
    }
  }

  /**
   * 載入設定檔
   */
  loadConfig() {
    const configPath = path.join(__dirname, 'config.json');
    const configData = fs.readFileSync(configPath, 'utf8');
    return JSON.parse(configData);
  }

  /**
   * 執行所有測試
   */
  async runAllTests() {
    console.log('\n' + '█'.repeat(80));
    console.log('🦠 傳染病統計監測系統 - 測試開始');
    console.log('█'.repeat(80));
    console.log(`\n⚙️  設定參數:`);
    console.log(`  📅 時間範圍: 過去 ${this.config.filterCriteria.timeRangeYears} 年`);
    console.log(`  🔗 SMART 伺服器數量: ${this.config.smartServers.filter(s => s.enabled).length}`);
    console.log(`  📊 CQL 函式庫數量: ${this.config.cqlLibraries.filter(l => l.enabled).length}`);
    console.log(`  🚫 排除患者個資: ${this.config.filterCriteria.excludePatientIdentifiers ? '是' : '否'}`);
    console.log(`  🧪 使用範例資料: ${this.useSampleData ? '是' : '否'}`);

    // 步驟 1: 從 SMART 伺服器獲取資料（或使用範例資料）
    let serverDataArray;
    if (this.useSampleData) {
      console.log('\n📦 使用範例資料進行測試...\n');
      const sampleData = this.sampleGenerator.getSampleData();
      serverDataArray = [
        {
          server: 'Sample Data Server',
          url: 'local',
          data: sampleData,
          success: true
        }
      ];
    } else {
      serverDataArray = await this.connector.fetchDataFromAllServers();
    }

    // 步驟 2: 對每個 CQL 函式庫進行測試
    const enabledLibraries = this.config.cqlLibraries.filter(lib => lib.enabled);
    
    for (const library of enabledLibraries) {
      console.log(`\n${'▓'.repeat(80)}`);
      console.log(`📚 測試 CQL 函式庫: ${library.name} (${library.description})`);
      console.log(`📄 檔案: ${library.file}`);
      console.log('▓'.repeat(80));

      // 驗證 CQL 檔案是否存在
      const cqlPath = path.join(__dirname, library.file);
      if (!fs.existsSync(cqlPath)) {
        console.error(`❌ CQL 檔案不存在: ${library.file}`);
        continue;
      }

      // 讀取 CQL 內容
      const cqlContent = fs.readFileSync(cqlPath, 'utf8');
      console.log(`✅ CQL 檔案載入成功 (${cqlContent.length} 字元)`);

      // 步驟 3: 處理並顯示資料
      const results = this.display.processData(serverDataArray, library.name);
      this.display.displayResults(results);

      // 儲存結果
      this.results.push({
        library: library.name,
        file: library.file,
        results: results
      });

      // 輸出到檔案
      if (this.config.outputFormat.json) {
        this.saveResultsToJson(library.name, results);
      }

      if (this.config.outputFormat.csv) {
        this.saveResultsToCsv(library.name, results);
      }
    }

    // 顯示總結
    this.displaySummary();
  }

  /**
   * 儲存結果為 JSON
   */
  saveResultsToJson(libraryName, results) {
    const outputDir = this.config.outputFormat.outputDirectory || './results';
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const filename = `${libraryName}_${timestamp}.json`;
    const filepath = path.join(outputDir, filename);

    fs.writeFileSync(filepath, JSON.stringify(results, null, 2), 'utf8');
    console.log(`💾 JSON 結果已儲存: ${filepath}`);
  }

  /**
   * 儲存結果為 CSV
   */
  saveResultsToCsv(libraryName, results) {
    const outputDir = this.config.outputFormat.outputDirectory || './results';
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const filename = `${libraryName}_${timestamp}.csv`;
    const filepath = path.join(outputDir, filename);

    // 建立 CSV 內容
    let csv = '類別,項目,數量,百分比\n';

    // 年齡分佈
    for (const [ageGroup, count] of Object.entries(results.ageDistribution)) {
      const percentage = ((count / results.totalCount) * 100).toFixed(1);
      csv += `年齡分佈,${ageGroup},${count},${percentage}%\n`;
    }

    // 性別分佈
    const genderLabels = { male: '男性', female: '女性', other: '其他', unknown: '未知' };
    for (const [gender, count] of Object.entries(results.genderDistribution)) {
      if (count > 0) {
        const percentage = ((count / results.totalCount) * 100).toFixed(1);
        csv += `性別分佈,${genderLabels[gender]},${count},${percentage}%\n`;
      }
    }

    // 就醫類型分佈
    for (const [type, count] of Object.entries(results.encounterTypeDistribution)) {
      if (count > 0) {
        const percentage = ((count / results.totalCount) * 100).toFixed(1);
        csv += `就醫類型,${type},${count},${percentage}%\n`;
      }
    }

    // 病毒類型分佈
    for (const [virus, count] of Object.entries(results.virusTypeDistribution)) {
      const percentage = ((count / results.totalCount) * 100).toFixed(1);
      csv += `病毒類型,${virus},${count},${percentage}%\n`;
    }

    fs.writeFileSync(filepath, csv, 'utf8');
    console.log(`💾 CSV 結果已儲存: ${filepath}`);
  }

  /**
   * 顯示測試總結
   */
  displaySummary() {
    console.log('\n' + '█'.repeat(80));
    console.log('📊 測試總結');
    console.log('█'.repeat(80));

    console.log(`\n✅ 已完成測試的 CQL 函式庫:`);
    for (const result of this.results) {
      console.log(`  📚 ${result.library}: ${result.results.totalCount} 筆資料`);
    }

    const totalRecords = this.results.reduce((sum, r) => sum + r.results.totalCount, 0);
    console.log(`\n📊 總計處理記錄: ${totalRecords} 筆`);

    console.log('\n🎉 所有測試完成！');
    console.log('█'.repeat(80) + '\n');
  }
}

/**
 * 主程式進入點
 */
async function main() {
  try {
    // 檢查命令列參數
    const useSampleData = process.argv.includes('--sample') || process.argv.includes('-s');
    
    if (useSampleData) {
      console.log('\n💡 提示: 使用範例資料模式 (--sample)');
    }
    
    const runner = new SurveillanceTestRunner(useSampleData);
    await runner.runAllTests();
    process.exit(0);
  } catch (error) {
    console.error('\n❌ 執行錯誤:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// 如果直接執行此檔案
if (require.main === module) {
  main();
}

module.exports = SurveillanceTestRunner;
