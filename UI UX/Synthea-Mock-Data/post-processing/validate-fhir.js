/**
 * ============================================
 * FHIR 資料驗證腳本
 * 驗證生成的 FHIR R4 資料格式和完整性
 * ============================================
 */

const fs = require('fs');
const path = require('path');

// 驗證統計
const stats = {
    totalFiles: 0,
    totalResources: 0,
    resourceTypes: {},
    errors: [],
    warnings: []
};

// 必要的 FHIR R4 資源類型
const REQUIRED_RESOURCE_TYPES = [
    'Patient',
    'Encounter',
    'Observation',
    'Condition',
    'MedicationRequest'
];

/**
 * 驗證單個資源
 */
function validateResource(resource, fileIndex) {
    const errors = [];
    const warnings = [];
    
    // 檢查基本欄位
    if (!resource.resourceType) {
        errors.push('缺少 resourceType');
    }
    
    if (!resource.id) {
        warnings.push('缺少 id');
    }
    
    // 統計資源類型
    if (resource.resourceType) {
        if (!stats.resourceTypes[resource.resourceType]) {
            stats.resourceTypes[resource.resourceType] = 0;
        }
        stats.resourceTypes[resource.resourceType]++;
    }
    
    // 特定資源類型的驗證
    switch (resource.resourceType) {
        case 'Patient':
            if (!resource.name || resource.name.length === 0) {
                warnings.push('Patient 缺少 name');
            }
            if (!resource.gender) {
                warnings.push('Patient 缺少 gender');
            }
            if (!resource.birthDate) {
                warnings.push('Patient 缺少 birthDate');
            }
            break;
            
        case 'Observation':
            if (!resource.code) {
                errors.push('Observation 缺少 code');
            }
            if (!resource.subject) {
                errors.push('Observation 缺少 subject (Patient reference)');
            }
            if (!resource.valueQuantity && !resource.valueCodeableConcept && !resource.component) {
                warnings.push('Observation 缺少 value');
            }
            break;
            
        case 'Condition':
            if (!resource.code) {
                errors.push('Condition 缺少 code');
            }
            if (!resource.subject) {
                errors.push('Condition 缺少 subject (Patient reference)');
            }
            break;
            
        case 'MedicationRequest':
            if (!resource.medicationCodeableConcept && !resource.medicationReference) {
                errors.push('MedicationRequest 缺少 medication');
            }
            if (!resource.subject) {
                errors.push('MedicationRequest 缺少 subject (Patient reference)');
            }
            break;
            
        case 'Encounter':
            if (!resource.status) {
                errors.push('Encounter 缺少 status');
            }
            if (!resource.class) {
                errors.push('Encounter 缺少 class');
            }
            if (!resource.subject) {
                errors.push('Encounter 缺少 subject (Patient reference)');
            }
            break;
    }
    
    return { errors, warnings };
}

/**
 * 驗證 Bundle
 */
function validateBundle(bundleData, fileName) {
    const bundleErrors = [];
    const bundleWarnings = [];
    
    // 檢查 Bundle 類型
    if (bundleData.resourceType !== 'Bundle') {
        bundleErrors.push(`${fileName}: 不是有效的 Bundle 資源`);
        return { errors: bundleErrors, warnings: bundleWarnings };
    }
    
    if (!bundleData.type) {
        bundleWarnings.push(`${fileName}: Bundle 缺少 type`);
    }
    
    if (!bundleData.entry || bundleData.entry.length === 0) {
        bundleWarnings.push(`${fileName}: Bundle 沒有 entry`);
        return { errors: bundleErrors, warnings: bundleWarnings };
    }
    
    // 驗證每個資源
    bundleData.entry.forEach((entry, index) => {
        if (!entry.resource) {
            bundleWarnings.push(`${fileName}: Entry ${index} 缺少 resource`);
            return;
        }
        
        const { errors, warnings } = validateResource(entry.resource, index);
        
        errors.forEach(err => {
            bundleErrors.push(`${fileName} [Entry ${index}]: ${err}`);
        });
        
        warnings.forEach(warn => {
            bundleWarnings.push(`${fileName} [Entry ${index}]: ${warn}`);
        });
        
        stats.totalResources++;
    });
    
    return { errors: bundleErrors, warnings: bundleWarnings };
}

/**
 * 檢查關鍵指標資料
 */
function checkIndicatorData() {
    console.log('\n檢查關鍵指標資料:');
    console.log('----------------------------------------');
    
    const checks = {
        patients: stats.resourceTypes['Patient'] || 0,
        conditions: stats.resourceTypes['Condition'] || 0,
        observations: stats.resourceTypes['Observation'] || 0,
        medications: stats.resourceTypes['MedicationRequest'] || 0,
        encounters: stats.resourceTypes['Encounter'] || 0
    };
    
    console.log(`✓ Patient 資源: ${checks.patients}`);
    console.log(`✓ Condition 資源: ${checks.conditions} (診斷)`);
    console.log(`✓ Observation 資源: ${checks.observations} (檢驗檢查)`);
    console.log(`✓ MedicationRequest 資源: ${checks.medications} (用藥)`);
    console.log(`✓ Encounter 資源: ${checks.encounters} (就醫紀錄)`);
    
    // 檢查是否滿足最小要求
    const warnings = [];
    
    if (checks.patients < 100) {
        warnings.push('病人數量少於 100，建議至少生成 1000 位病人');
    }
    
    if (checks.observations < checks.patients * 5) {
        warnings.push('Observation 資源可能不足，每位病人平均應有多筆檢驗資料');
    }
    
    if (checks.medications < checks.patients * 2) {
        warnings.push('MedicationRequest 資源可能不足，用藥指標可能無法正確計算');
    }
    
    if (warnings.length > 0) {
        console.log('\n注意事項:');
        warnings.forEach(w => console.log(`  ⚠ ${w}`));
    }
}

/**
 * 主驗證函數
 */
async function validateFHIR() {
    console.log('========================================');
    console.log('  FHIR 資料驗證');
    console.log('========================================\n');
    
    const inputDir = '../generated-fhir-data/fhir-processed';
    
    if (!fs.existsSync(inputDir)) {
        console.error(`✗ 錯誤: 找不到目錄 ${inputDir}`);
        console.error('  請先執行 add-realistic-noise.js');
        process.exit(1);
    }
    
    // 讀取所有檔案
    const files = fs.readdirSync(inputDir)
        .filter(file => file.endsWith('.json'));
    
    console.log(`開始驗證 ${files.length} 個檔案...\n`);
    
    // 驗證每個檔案
    for (const file of files) {
        const filePath = path.join(inputDir, file);
        
        try {
            const bundleData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
            const { errors, warnings } = validateBundle(bundleData, file);
            
            stats.totalFiles++;
            stats.errors.push(...errors);
            stats.warnings.push(...warnings);
            
            // 進度顯示
            if (stats.totalFiles % 100 === 0) {
                console.log(`已驗證 ${stats.totalFiles} 個檔案...`);
            }
            
        } catch (error) {
            stats.errors.push(`${file}: 無法解析 JSON - ${error.message}`);
        }
    }
    
    // 輸出結果
    console.log('\n========================================');
    console.log('  驗證結果');
    console.log('========================================');
    console.log(`總檔案數: ${stats.totalFiles}`);
    console.log(`總資源數: ${stats.totalResources}`);
    console.log(`錯誤數: ${stats.errors.length}`);
    console.log(`警告數: ${stats.warnings.length}`);
    
    // 顯示資源類型統計
    console.log('\n資源類型統計:');
    console.log('----------------------------------------');
    Object.keys(stats.resourceTypes)
        .sort((a, b) => stats.resourceTypes[b] - stats.resourceTypes[a])
        .forEach(type => {
            console.log(`  ${type}: ${stats.resourceTypes[type]}`);
        });
    
    // 檢查必要資源類型
    console.log('\n必要資源檢查:');
    console.log('----------------------------------------');
    REQUIRED_RESOURCE_TYPES.forEach(type => {
        const count = stats.resourceTypes[type] || 0;
        if (count > 0) {
            console.log(`✓ ${type}: ${count}`);
        } else {
            console.log(`✗ ${type}: 缺少`);
            stats.errors.push(`缺少必要資源類型: ${type}`);
        }
    });
    
    // 檢查指標資料
    checkIndicatorData();
    
    // 顯示錯誤（如果有）
    if (stats.errors.length > 0) {
        console.log('\n錯誤列表:');
        console.log('========================================');
        stats.errors.slice(0, 20).forEach(err => {
            console.log(`✗ ${err}`);
        });
        if (stats.errors.length > 20) {
            console.log(`\n... 還有 ${stats.errors.length - 20} 個錯誤未顯示`);
        }
    }
    
    // 顯示警告（前 10 個）
    if (stats.warnings.length > 0) {
        console.log('\n警告列表 (前 10 個):');
        console.log('========================================');
        stats.warnings.slice(0, 10).forEach(warn => {
            console.log(`⚠ ${warn}`);
        });
        if (stats.warnings.length > 10) {
            console.log(`\n... 還有 ${stats.warnings.length - 10} 個警告未顯示`);
        }
    }
    
    // 總結
    console.log('\n========================================');
    if (stats.errors.length === 0) {
        console.log('✓ 驗證通過！資料格式正確');
        console.log('\n下一步:');
        console.log('  1. 在瀏覽器開啟 ../upload-scripts/preview-data.html 預覽資料');
        console.log('  2. 確認無誤後執行 .\\upload-to-fhir.ps1 -TestMode 上傳測試');
    } else {
        console.log('✗ 發現錯誤，請檢查並修正');
        process.exit(1);
    }
    console.log('========================================\n');
}

// 執行驗證
validateFHIR().catch(error => {
    console.error('✗ 驗證失敗:', error);
    process.exit(1);
});
