/**
 * ============================================
 * 調整醫療品質指標腳本
 * 確保 8 個優先指標落在目標範圍內
 * ============================================
 */

const fs = require('fs');
const path = require('path');

// 指標目標配置
const INDICATOR_TARGETS = {
    // 指標 01: 門診注射劑使用率
    outpatient_injection: {
        target: 5.0,
        min: 3.5,
        max: 7.5,
        description: '門診注射劑使用率 (%)'
    },
    
    // 指標 02: 門診抗生素使用率
    outpatient_antibiotic: {
        target: 18.0,
        min: 15.0,
        max: 22.0,
        description: '門診抗生素使用率 (%)'
    },
    
    // 指標 10: 糖尿病控制不良率
    diabetes_poor_control: {
        target: 20.0,
        min: 16.0,
        max: 25.0,
        hba1c_threshold: 9.0,
        description: '糖尿病控制不良率 (HbA1c > 9%)'
    },
    
    // 指標 03-1: 同醫院降血壓藥重複用藥率
    same_hospital_bp_overlap: {
        target: 6.5,
        min: 4.0,
        max: 9.0,
        description: '同醫院降血壓藥重複用藥率 (%)'
    },
    
    // 指標 03-8: 跨醫院降血壓藥重複用藥率（專利技術）
    cross_hospital_bp_overlap: {
        target: 8.5,
        min: 6.0,
        max: 11.0,
        description: '跨醫院降血壓藥重複用藥率 (%)'
    },
    
    // 指標 11-1: 高血壓控制不良率
    hypertension_poor_control: {
        target: 22.0,
        min: 18.0,
        max: 26.0,
        sbp_threshold: 140,
        dbp_threshold: 90,
        description: '高血壓控制不良率 (SBP >= 140 或 DBP >= 90)'
    },
    
    // 指標 12: 14 日內再住院率
    readmission_14_day: {
        target: 7.0,
        min: 5.0,
        max: 9.0,
        description: '14 日內再住院率 (%)'
    },
    
    // 指標 14: 剖腹產率
    cesarean_section: {
        target: 35.0,
        min: 30.0,
        max: 40.0,
        description: '剖腹產率 (%)'
    }
};

/**
 * 在目標範圍內生成隨機值
 */
function generateValueInRange(min, max, decimalPlaces = 2) {
    const value = min + Math.random() * (max - min);
    return Number(value.toFixed(decimalPlaces));
}

/**
 * 調整 HbA1c 值以符合糖尿病控制不良率目標
 */
function adjustDiabetesControl(bundles) {
    const target = INDICATOR_TARGETS.diabetes_poor_control;
    let diabetesPatients = 0;
    let poorControlTarget = 0;
    let currentPoorControl = 0;
    
    // 第一輪掃描：統計糖尿病患者和目前控制不良數
    bundles.forEach(bundle => {
        if (!bundle.entry) return;
        
        let hasDiabetes = false;
        let hba1cValue = null;
        
        bundle.entry.forEach(entry => {
            const resource = entry.resource;
            
            // 檢查是否有糖尿病診斷
            if (resource.resourceType === 'Condition') {
                const coding = resource.code?.coding?.[0];
                if (coding?.display?.toLowerCase().includes('diabetes')) {
                    hasDiabetes = true;
                }
            }
            
            // 檢查 HbA1c 值
            if (resource.resourceType === 'Observation') {
                const coding = resource.code?.coding?.[0];
                if (coding?.display?.toLowerCase().includes('hba1c') ||
                    coding?.display?.toLowerCase().includes('hemoglobin a1c')) {
                    hba1cValue = resource.valueQuantity?.value;
                    if (hba1cValue > target.hba1c_threshold) {
                        currentPoorControl++;
                    }
                }
            }
        });
        
        if (hasDiabetes) {
            diabetesPatients++;
        }
    });
    
    if (diabetesPatients === 0) return { adjusted: 0, total: 0 };
    
    // 計算需要調整的數量
    const targetRate = generateValueInRange(target.min, target.max, 1) / 100;
    poorControlTarget = Math.round(diabetesPatients * targetRate);
    
    console.log(`  糖尿病患者: ${diabetesPatients}`);
    console.log(`  目標控制不良數: ${poorControlTarget} (${(targetRate * 100).toFixed(1)}%)`);
    console.log(`  目前控制不良數: ${currentPoorControl}`);
    
    // 第二輪：調整 HbA1c 值
    let adjusted = 0;
    const needIncrease = poorControlTarget > currentPoorControl;
    const adjustCount = Math.abs(poorControlTarget - currentPoorControl);
    
    bundles.forEach(bundle => {
        if (adjusted >= adjustCount) return;
        if (!bundle.entry) return;
        
        let hasDiabetes = false;
        let hba1cEntry = null;
        
        // 尋找糖尿病患者的 HbA1c
        bundle.entry.forEach(entry => {
            const resource = entry.resource;
            
            if (resource.resourceType === 'Condition') {
                const coding = resource.code?.coding?.[0];
                if (coding?.display?.toLowerCase().includes('diabetes')) {
                    hasDiabetes = true;
                }
            }
            
            if (resource.resourceType === 'Observation') {
                const coding = resource.code?.coding?.[0];
                if (coding?.display?.toLowerCase().includes('hba1c')) {
                    hba1cEntry = entry;
                }
            }
        });
        
        if (hasDiabetes && hba1cEntry) {
            const currentValue = hba1cEntry.resource.valueQuantity.value;
            
            if (needIncrease && currentValue <= target.hba1c_threshold) {
                // 需要增加控制不良：將 HbA1c 提高到 > 9.0
                hba1cEntry.resource.valueQuantity.value = generateValueInRange(9.1, 11.5, 2);
                adjusted++;
            } else if (!needIncrease && currentValue > target.hba1c_threshold) {
                // 需要減少控制不良：將 HbA1c 降低到 <= 9.0
                hba1cEntry.resource.valueQuantity.value = generateValueInRange(6.5, 9.0, 2);
                adjusted++;
            }
        }
    });
    
    return { adjusted, total: diabetesPatients, target: poorControlTarget };
}

/**
 * 調整血壓值以符合高血壓控制不良率目標
 */
function adjustHypertensionControl(bundles) {
    const target = INDICATOR_TARGETS.hypertension_poor_control;
    let hypertensionPatients = 0;
    let poorControlTarget = 0;
    let adjusted = 0;
    
    // 統計高血壓患者
    bundles.forEach(bundle => {
        if (!bundle.entry) return;
        
        let hasHypertension = false;
        bundle.entry.forEach(entry => {
            if (entry.resource.resourceType === 'Condition') {
                const coding = entry.resource.code?.coding?.[0];
                if (coding?.display?.toLowerCase().includes('hypertension')) {
                    hasHypertension = true;
                }
            }
        });
        
        if (hasHypertension) {
            hypertensionPatients++;
        }
    });
    
    if (hypertensionPatients === 0) return { adjusted: 0, total: 0 };
    
    const targetRate = generateValueInRange(target.min, target.max, 1) / 100;
    poorControlTarget = Math.round(hypertensionPatients * targetRate);
    
    console.log(`  高血壓患者: ${hypertensionPatients}`);
    console.log(`  目標控制不良數: ${poorControlTarget} (${(targetRate * 100).toFixed(1)}%)`);
    
    // 調整血壓值
    let processedCount = 0;
    bundles.forEach(bundle => {
        if (processedCount >= poorControlTarget) return;
        if (!bundle.entry) return;
        
        let hasHypertension = false;
        let bpEntry = null;
        
        bundle.entry.forEach(entry => {
            const resource = entry.resource;
            
            if (resource.resourceType === 'Condition') {
                const coding = resource.code?.coding?.[0];
                if (coding?.display?.toLowerCase().includes('hypertension')) {
                    hasHypertension = true;
                }
            }
            
            if (resource.resourceType === 'Observation') {
                const coding = resource.code?.coding?.[0];
                if (coding?.display?.toLowerCase().includes('blood pressure')) {
                    bpEntry = entry;
                }
            }
        });
        
        if (hasHypertension && bpEntry && processedCount < poorControlTarget) {
            // 設定為控制不良（SBP >= 140 或 DBP >= 90）
            if (bpEntry.resource.component) {
                bpEntry.resource.component.forEach(comp => {
                    const coding = comp.code?.coding?.[0];
                    if (coding?.display?.toLowerCase().includes('systolic')) {
                        comp.valueQuantity.value = generateValueInRange(145, 165, 1);
                    } else if (coding?.display?.toLowerCase().includes('diastolic')) {
                        comp.valueQuantity.value = generateValueInRange(92, 105, 1);
                    }
                });
            }
            processedCount++;
            adjusted++;
        }
    });
    
    return { adjusted, total: hypertensionPatients, target: poorControlTarget };
}

/**
 * 主處理函數
 */
async function adjustIndicators() {
    console.log('========================================');
    console.log('  調整醫療品質指標');
    console.log('========================================\n');
    
    const inputDir = '../generated-fhir-data/fhir-processed';
    
    if (!fs.existsSync(inputDir)) {
        console.error(`✗ 錯誤: 找不到輸入目錄 ${inputDir}`);
        console.error('  請先執行 add-realistic-noise.js');
        process.exit(1);
    }
    
    // 讀取所有 Bundle 檔案
    const files = fs.readdirSync(inputDir).filter(f => f.endsWith('.json'));
    console.log(`載入 ${files.length} 個 FHIR Bundle 檔案\n`);
    
    const bundles = [];
    for (const file of files) {
        const filePath = path.join(inputDir, file);
        const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        bundles.push({ file, data });
    }
    
    // 調整各項指標
    console.log('調整指標 10: 糖尿病控制不良率');
    const diabetesResult = adjustDiabetesControl(bundles.map(b => b.data));
    console.log(`  ✓ 已調整 ${diabetesResult.adjusted} 筆資料\n`);
    
    console.log('調整指標 11-1: 高血壓控制不良率');
    const hypertensionResult = adjustHypertensionControl(bundles.map(b => b.data));
    console.log(`  ✓ 已調整 ${hypertensionResult.adjusted} 筆資料\n`);
    
    // 寫回檔案
    console.log('寫入調整後的檔案...');
    let savedCount = 0;
    for (const bundle of bundles) {
        const outputPath = path.join(inputDir, bundle.file);
        fs.writeFileSync(
            outputPath,
            JSON.stringify(bundle.data, null, 2),
            'utf8'
        );
        savedCount++;
        
        if (savedCount % 100 === 0) {
            console.log(`  已儲存 ${savedCount} 個檔案...`);
        }
    }
    
    console.log('\n========================================');
    console.log('  調整完成');
    console.log('========================================');
    console.log(`✓ 總共處理 ${files.length} 個檔案`);
    console.log(`  - 糖尿病指標調整: ${diabetesResult.adjusted} 筆`);
    console.log(`  - 高血壓指標調整: ${hypertensionResult.adjusted} 筆`);
    console.log('\n下一步:');
    console.log('  node validate-fhir.js');
    console.log('');
}

// 執行
adjustIndicators().catch(error => {
    console.error('✗ 執行失敗:', error);
    process.exit(1);
});
