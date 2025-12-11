/**
 * ============================================
 * 添加真實數據變異腳本
 * 為 Synthea 生成的資料添加 ±10% 隨機變異和小數位數
 * ============================================
 */

const fs = require('fs');
const path = require('path');

// 設定參數
const CONFIG = {
    inputDir: '../generated-fhir-data/fhir',
    outputDir: '../generated-fhir-data/fhir-processed',
    variationPercentage: 10, // ±10% 變異
    decimalPlaces: {
        percentage: 2,    // 百分比類數據保留 2 位小數
        measurement: 1,   // 測量值類數據保留 1 位小數
        count: 0          // 計數類數據保留整數
    }
};

// 需要添加變異的觀察值類型
const OBSERVATION_TYPES = {
    // 生命徵象
    'blood-pressure': { variation: 8, decimals: 1 },
    'heart-rate': { variation: 10, decimals: 0 },
    'respiratory-rate': { variation: 12, decimals: 0 },
    'body-temperature': { variation: 2, decimals: 1 },
    'body-weight': { variation: 5, decimals: 1 },
    'body-height': { variation: 1, decimals: 1 },
    'bmi': { variation: 5, decimals: 1 },
    
    // 實驗室檢查
    'glucose': { variation: 15, decimals: 1 },
    'hba1c': { variation: 8, decimals: 2 },
    'cholesterol': { variation: 10, decimals: 1 },
    'triglyceride': { variation: 12, decimals: 1 },
    'hdl': { variation: 10, decimals: 1 },
    'ldl': { variation: 10, decimals: 1 },
    'creatinine': { variation: 8, decimals: 2 },
    'egfr': { variation: 10, decimals: 1 },
    'alt': { variation: 15, decimals: 0 },
    'ast': { variation: 15, decimals: 0 }
};

/**
 * 為數值添加隨機變異
 */
function addVariation(value, variationPercent, decimalPlaces) {
    if (typeof value !== 'number' || isNaN(value)) {
        return value;
    }
    
    // 計算變異範圍
    const variation = value * (variationPercent / 100);
    const randomVariation = (Math.random() * 2 - 1) * variation;
    const newValue = value + randomVariation;
    
    // 確保非負值
    const finalValue = Math.max(0, newValue);
    
    // 四捨五入到指定小數位數
    return Number(finalValue.toFixed(decimalPlaces));
}

/**
 * 處理 Observation 資源
 */
function processObservation(observation) {
    if (!observation.valueQuantity || !observation.valueQuantity.value) {
        return observation;
    }
    
    // 判斷觀察類型
    let observationType = 'default';
    let config = { variation: 10, decimals: 1 };
    
    if (observation.code && observation.code.coding) {
        const coding = observation.code.coding[0];
        const display = coding.display ? coding.display.toLowerCase() : '';
        
        // 根據 display 判斷類型
        for (const [type, typeConfig] of Object.entries(OBSERVATION_TYPES)) {
            if (display.includes(type) || display.includes(type.replace('-', ' '))) {
                config = typeConfig;
                observationType = type;
                break;
            }
        }
    }
    
    // 添加變異
    const originalValue = observation.valueQuantity.value;
    observation.valueQuantity.value = addVariation(
        originalValue,
        config.variation,
        config.decimals
    );
    
    // 添加擴展記錄原始值（用於驗證）
    if (!observation.extension) {
        observation.extension = [];
    }
    observation.extension.push({
        url: 'http://synthea-mock-data/original-value',
        valueDecimal: originalValue
    });
    
    return observation;
}

/**
 * 處理 MedicationRequest 資源
 */
function processMedicationRequest(medicationRequest) {
    // 為藥物劑量添加小變異
    if (medicationRequest.dosageInstruction) {
        medicationRequest.dosageInstruction.forEach(dosage => {
            if (dosage.doseAndRate) {
                dosage.doseAndRate.forEach(dar => {
                    if (dar.doseQuantity && dar.doseQuantity.value) {
                        const originalValue = dar.doseQuantity.value;
                        dar.doseQuantity.value = addVariation(
                            originalValue,
                            5, // 劑量變異較小
                            2  // 保留 2 位小數
                        );
                    }
                });
            }
        });
    }
    
    return medicationRequest;
}

/**
 * 處理單個 FHIR Bundle 檔案
 */
function processBundle(bundleData) {
    if (!bundleData.entry) {
        return bundleData;
    }
    
    let processedCount = {
        observations: 0,
        medications: 0,
        others: 0
    };
    
    bundleData.entry.forEach(entry => {
        if (!entry.resource) return;
        
        const resourceType = entry.resource.resourceType;
        
        switch (resourceType) {
            case 'Observation':
                entry.resource = processObservation(entry.resource);
                processedCount.observations++;
                break;
                
            case 'MedicationRequest':
                entry.resource = processMedicationRequest(entry.resource);
                processedCount.medications++;
                break;
                
            default:
                processedCount.others++;
        }
    });
    
    return { bundle: bundleData, counts: processedCount };
}

/**
 * 處理所有檔案
 */
async function processAllFiles() {
    console.log('========================================');
    console.log('  添加真實數據變異');
    console.log('========================================\n');
    
    // 確認輸入目錄存在
    if (!fs.existsSync(CONFIG.inputDir)) {
        console.error(`✗ 錯誤: 找不到輸入目錄 ${CONFIG.inputDir}`);
        console.error('  請先執行 run-synthea.ps1 生成資料');
        process.exit(1);
    }
    
    // 建立輸出目錄
    if (!fs.existsSync(CONFIG.outputDir)) {
        fs.mkdirSync(CONFIG.outputDir, { recursive: true });
    }
    
    // 讀取所有 JSON 檔案
    const files = fs.readdirSync(CONFIG.inputDir)
        .filter(file => file.endsWith('.json'));
    
    console.log(`找到 ${files.length} 個 FHIR 檔案\n`);
    
    let totalCounts = {
        files: 0,
        observations: 0,
        medications: 0,
        others: 0
    };
    
    // 處理每個檔案
    for (const file of files) {
        const inputPath = path.join(CONFIG.inputDir, file);
        const outputPath = path.join(CONFIG.outputDir, file);
        
        try {
            // 讀取 Bundle
            const bundleData = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
            
            // 處理 Bundle
            const { bundle: processedBundle, counts } = processBundle(bundleData);
            
            // 寫入處理後的檔案
            fs.writeFileSync(
                outputPath,
                JSON.stringify(processedBundle, null, 2),
                'utf8'
            );
            
            // 累計統計
            totalCounts.files++;
            totalCounts.observations += counts.observations;
            totalCounts.medications += counts.medications;
            totalCounts.others += counts.others;
            
            // 進度顯示
            if (totalCounts.files % 100 === 0) {
                console.log(`已處理 ${totalCounts.files} 個檔案...`);
            }
            
        } catch (error) {
            console.error(`✗ 處理檔案失敗: ${file}`);
            console.error(`  錯誤: ${error.message}`);
        }
    }
    
    console.log('\n========================================');
    console.log('  處理完成');
    console.log('========================================');
    console.log(`✓ 總檔案數: ${totalCounts.files}`);
    console.log(`  - Observation 資源: ${totalCounts.observations}`);
    console.log(`  - MedicationRequest 資源: ${totalCounts.medications}`);
    console.log(`  - 其他資源: ${totalCounts.others}`);
    console.log(`\n輸出位置: ${path.resolve(CONFIG.outputDir)}\n`);
    
    console.log('下一步:');
    console.log('  node adjust-indicators.js');
    console.log('');
}

// 執行主程式
processAllFiles().catch(error => {
    console.error('✗ 執行失敗:', error);
    process.exit(1);
});
