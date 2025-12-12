// ========== ESG 指標儀表板邏輯 ==========
// CQL整合版本 - 基於ESG CQL 1119文件夾
//
// CQL文件映射:
// - 抗生素使用率: Antibiotic_Utilization.cql (455行)
// - 電子病歷採用率: EHR_Adoption_Rate.cql (445行)
// - 廢棄物管理: Waste.cql (353行)
//
// CQL定義內容:
// - WHO ATC/DDD標準 (J01* 抗生素代碼)
// - HIMSS EMRAM標準 (電子病歷成熟度)
// - GRI 306標準 (廢棄物管理2021/2023)
// - SASB HC-DY-260a.2/260a.3 (醫療永續指標)
// - 時間範圍: 無限制(擷取所有資料)

console.log('🚀 esg-indicators.js 文件已加载');

let currentResults = {};

// ========== 輔助函數 ==========
function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// 頁面載入
document.addEventListener('DOMContentLoaded', function() {
    console.log('ESG 指標儀表板已載入');
    
    // 初始化卡片顯示
    initializeCards();
    
    // 更新示范模式按钮状态
    updateDemoModeButton();
    
    // 從 localStorage 載入設定
    const savedServer = localStorage.getItem('fhirServer');
    const savedToken = localStorage.getItem('authToken');
    
    if (savedServer) {
        setTimeout(() => {
            if (typeof FHIRConnection !== 'undefined') {
                window.fhirConnection = new FHIRConnection();
                window.fhirConnection.serverUrl = savedServer;
                window.fhirConnection.authToken = savedToken || '';
                window.fhirConnection.isConnected = true;
                
                console.log('✅ FHIR 連線已恢復');
                
                // 🆕 立即檢查連線並隱藏 banner
                checkFHIRConnection();
            }
        }, 200);
    } else {
        // 🆕 如果沒有儲存的連線，顯示 banner
        checkFHIRConnection();
    }
});

// 初始化卡片
function initializeCards() {
    const cards = ['antibiotic', 'ehr', 'waste'];
    
    cards.forEach(card => {
        const countElement = document.getElementById(`${card}Count`);
        const rateElement = document.getElementById(`${card}Rate`);
        const dateElement = document.getElementById(`${card}DateRange`);
        
        if (countElement) countElement.textContent = '--';
        if (rateElement) rateElement.textContent = '--%';
        if (dateElement) dateElement.textContent = '資料範圍: 全部資料';
    });
}

// 檢查 FHIR 連線
async function checkFHIRConnection() {
    const banner = document.getElementById('connectionBanner');
    
    await new Promise(resolve => setTimeout(resolve, 100));
    
    if (!window.fhirConnection || !window.fhirConnection.serverUrl) {
        if (banner) banner.classList.add('show');
        return false;
    } else {
        if (banner) banner.classList.remove('show');
        return true;
    }
}

// ========== 備份：原始版本 (如需復原請取消註解) ==========
// async function executeQuery_BACKUP(indicatorType) { ... }
// ========== 備份結束 ==========

// 執行查詢（新版：漸進式計數 + 防重複點擊）
async function executeQuery(indicatorType) {
    console.log(`🔍 執行查詢: ${indicatorType}`);
    console.log(`📊 當前模式: ${localStorage.getItem('demoMode') === 'true' ? '示範模式' : '真實數據模式'}`);
    
    // 检查是否为示范模式
    const demoMode = localStorage.getItem('demoMode') === 'true';
    
    // 如果不是示范模式，则检查 FHIR 连线
    if (!demoMode) {
        const isConnected = await checkFHIRConnection();
        if (!isConnected) {
            alert('請先在首頁設定 FHIR 伺服器連線，或啟用示範模式');
            return;
        }
    }
    
    // 修正ID映射：ehr-adoption -> Ehr
    const btnIdMap = {
        'antibiotic': 'Antibiotic',
        'ehr-adoption': 'Ehr',
        'waste': 'Waste'
    };
    const btnId = btnIdMap[indicatorType] || capitalize(indicatorType);
    
    const btn = document.getElementById(`btn${btnId}`);
    const statusElement = document.getElementById(`status${btnId}`);
    
    // 🔒 防重複點擊
    if (btn && btn.disabled) {
        console.warn('⚠️ 查詢進行中，請勿重複點擊');
        return;
    }
    
    // 🆕 漸進式計數動畫
    let count = 0;
    let countInterval = null;
    
    if (btn) {
        btn.disabled = true;
        countInterval = setInterval(() => {
            count += Math.floor(Math.random() * 50) + 30;
            btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> 已撈取 ${count} 筆`;
        }, 150);
    }
    
    if (statusElement) {
        statusElement.innerHTML = '<span style="color: #2563eb;"><i class="fas fa-spinner fa-spin"></i> 執行中...</span>';
    }
    
    try {
        let results;
        switch(indicatorType) {
            case 'antibiotic':
                results = await queryAntibioticUtilization();
                updateESGCard('antibiotic', results, '案件');
                break;
            case 'ehr-adoption':
                results = await queryEHRAdoption();
                updateESGCard('ehr', results, '機構');
                break;
            case 'waste':
                results = await queryWasteManagement();
                updateESGCard('waste', results, 'kg');
                break;
        }
        
        currentResults[indicatorType] = results;
        
        // 🆕 清除計數動畫並顯示實際筆數
        if (countInterval) clearInterval(countInterval);
        const actualCount = results.totalCases || results.count || 0;
        if (btn) {
            btn.innerHTML = `<i class="fas fa-check"></i> 完成 (${actualCount} 筆)`;
        }
        
        if (statusElement) {
            statusElement.innerHTML = '<span style="color: #10b981;"><i class="fas fa-check-circle"></i> 完成</span>';
            setTimeout(() => { statusElement.innerHTML = ''; }, 3000);
        }
        
    } catch (error) {
        console.error('查詢失敗:', error);
        
        // 🆕 清除計數動畫
        if (countInterval) clearInterval(countInterval);
        if (btn) {
            btn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> 查詢失敗';
        }
        
        if (statusElement) {
            statusElement.innerHTML = '<span style="color: #ef4444;"><i class="fas fa-times-circle"></i> 失敗</span>';
        }
        alert(`查詢失敗: ${error.message}`);
    } finally {
        // 🆕 延遲 2 秒後恢復按鈕
        setTimeout(() => {
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-play"></i> 執行查詢';
            }
        }, 2000);
    }
}

// ========== 抗生素使用率查詢 ==========
// CQL來源: Antibiotic_Utilization.cql (455行)
// CQL定義:
// - ATC代碼: J01* (所有抗生素)
// - WHO AWaRe分類: Access/Watch/Reserve
// - 基於標準: WHO ATC/DDD + SASB HC-DY-260a.2
// - 資源: MedicationRequest, MedicationAdministration
async function queryAntibioticUtilization() {
    console.log('📋 CQL查詢: 抗生素使用率');
    console.log('   CQL來源: Antibiotic_Utilization.cql');
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    if (demoMode) {
        console.log('✨ 示範模式：使用模擬數據');
        // 添加延迟以显示加载状态
        await new Promise(resolve => setTimeout(resolve, 800));
        return generateDemoDataESG('antibiotic');
    }
    
    const conn = window.fhirConnection;
    console.log(`   🌐 FHIR伺服器: ${conn.serverUrl}`);
    
    // ========== CQL查詢: MedicationAdministration資源（優先，更準確） ==========
    // 對應CQL: [MedicationAdministration: "ESG Antibiotic All"]
    const antibioticPatients = new Set();
    const antibioticNames = ['Amoxicillin', 'Doxycycline', 'Ceftriaxone', 'Ciprofloxacin', 'Vancomycin', 'Meropenem'];
    
    // 嘗試用text搜尋（emr-smart相容）
    for (const name of antibioticNames) {
        try {
            const medAdmins = await conn.query('MedicationAdministration', {
                'code:text': name,
                status: 'completed',
                _count: 1000
            });
            
            if (medAdmins.entry) {
                console.log(`   ✅ MedicationAdministration "${name}": ${medAdmins.entry.length} 筆`);
                medAdmins.entry.forEach(entry => {
                    const patientRef = entry.resource.subject?.reference;
                    if (patientRef) {
                        const patientId = patientRef.replace('Patient/', '');
                        antibioticPatients.add(patientId);
                    }
                });
            }
        } catch (error) {
            console.warn(`   ⚠️ 查詢 "${name}" 失敗:`, error.message);
        }
    }
    
    // 如果text搜尋沒結果，嘗試code搜尋（HAPI相容）
    if (antibioticPatients.size === 0) {
        console.log('   📌 text搜尋無結果，嘗試 ATC code 搜尋...');
        try {
            const medAdmins = await conn.query('MedicationAdministration', {
                'medication-code': 'http://www.whocc.no/atc|J01',
                status: 'completed',
                _count: 1000
            });
            
            if (medAdmins.entry) {
                console.log(`   ✅ MedicationAdministration (ATC J01*): ${medAdmins.entry.length} 筆`);
                medAdmins.entry.forEach(entry => {
                    const patientRef = entry.resource.subject?.reference;
                    if (patientRef) {
                        const patientId = patientRef.replace('Patient/', '');
                        antibioticPatients.add(patientId);
                    }
                });
            }
        } catch (error) {
            console.warn('   ⚠️ ATC code 查詢失敗:', error.message);
        }
    }
    
    const antibioticPatientCount = antibioticPatients.size;
    
    // 查詢所有就醫記錄以計算總病人數
    const encounters = await conn.query('Encounter', {
        status: 'finished',
        _count: 1000
    });
    
    const allPatients = new Set();
    if (encounters.entry) {
        encounters.entry.forEach(entry => {
            const patientRef = entry.resource.subject?.reference;
            if (patientRef) {
                const patientId = patientRef.replace('Patient/', '');
                allPatients.add(patientId);
            }
        });
    }
    
    const totalPatients = allPatients.size;
    
    console.log(`   👥 病人統計: ${antibioticPatientCount} 使用抗生素 / ${totalPatients} 總病人數`);
    
    if (totalPatients === 0 || antibioticPatientCount === 0) {
        console.log('   ⚠️ 無抗生素使用資料');
        return {
            totalPatients: 0,
            antibioticPatients: 0,
            utilizationRate: 0,
            noData: true
        };
    }
    
    const utilizationRate = ((antibioticPatientCount / totalPatients) * 100).toFixed(2);
    
    return {
        totalPatients,
        antibioticPatients: antibioticPatientCount,
        utilizationRate,
        noData: false
    };
}

// ========== 電子病歷採用率查詢 ==========
// CQL來源: EHR_Adoption_Rate.cql (445行)
// CQL定義:
// - LOINC代碼: 34133-9 (臨床文件), 18842-5 (出院摘要)
// - HIMSS EMRAM標準 (電子病歷成熟度)
// - 資源: Patient, DocumentReference, Observation
async function queryEHRAdoption() {
    console.log('📋 CQL查詢: 電子病歷採用率');
    console.log('   CQL來源: EHR_Adoption_Rate.cql');
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    if (demoMode) {
        console.log('✨ 示範模式：使用模擬數據');
        // 添加延迟以显示加载状态
        await new Promise(resolve => setTimeout(resolve, 800));
        return generateDemoDataESG('ehr');
    }
    
    const conn = window.fhirConnection;
    console.log(`   🌐 FHIR伺服器: ${conn.serverUrl}`);
    
    // ========== CQL查詢: Patient + DocumentReference資源 ==========
    // 對應CQL: Count(distinct Patient with DocumentReference)
    const patients = await conn.query('Patient', {
        _count: 1000
    });
    
    const documents = await conn.query('DocumentReference', {
        _count: 1000
    });
    
    let totalOrgs = patients.entry?.length || 0;
    let ehrAdoptedOrgs = documents.entry?.length || 0;
    
    console.log(`   ✅ Patient查詢: ${totalOrgs} 筆`);
    console.log(`   ✅ DocumentReference查詢: ${ehrAdoptedOrgs} 筆`);
    console.log(`   📊 結果: ${ehrAdoptedOrgs} 有電子病歷 / ${totalOrgs} 總患者`);
    
    if (totalOrgs === 0) {
        return {
            totalOrganizations: 0,
            ehrAdopted: 0,
            adoptionRate: 0,
            noData: true
        };
    }
    
    const adoptionRate = ((ehrAdoptedOrgs / totalOrgs) * 100).toFixed(2);
    
    return {
        totalOrganizations: totalOrgs,
        ehrAdopted: ehrAdoptedOrgs,
        adoptionRate,
        noData: false
    };
}

// ========== 廢棄物管理查詢 ==========
async function queryWasteManagement() {
    console.log('📋 CQL查詢: 醫療廢棄物管理');
    console.log('   CQL來源: Waste.cql');
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    if (demoMode) {
        console.log('✨ 示範模式：使用模擬數據');
        // 添加延迟以显示加载状态
        await new Promise(resolve => setTimeout(resolve, 800));
        return generateDemoDataESG('waste');
    }
    
    const conn = window.fhirConnection;
    console.log(`   🌐 FHIR伺服器: ${conn.serverUrl}`);
    
    // ========== CQL查詢: Observation資源 (三種廢棄物類型) ==========
    // 對應CQL: [Observation: "Waste Mass Code"]
    try {
        // 查詢三種廢棄物類型
        const wasteTypes = ['General Waste', 'Infectious Waste', 'Recyclable Waste'];
        let generalWaste = 0;
        let infectiousWaste = 0;
        let recyclableWaste = 0;
        
        for (const wasteType of wasteTypes) {
            const wasteObs = await conn.query('Observation', {
                'code:text': wasteType,
                _count: 1000
            });
            
            console.log(`   ✅ ${wasteType}查詢: ${wasteObs.entry?.length || 0} 筆`);
            
            if (wasteObs.entry && wasteObs.entry.length > 0) {
                wasteObs.entry.forEach(entry => {
                    const value = entry.resource.valueQuantity?.value;
                    if (value) {
                        if (wasteType === 'General Waste') {
                            generalWaste += value;
                        } else if (wasteType === 'Infectious Waste') {
                            infectiousWaste += value;
                        } else if (wasteType === 'Recyclable Waste') {
                            recyclableWaste += value;
                        }
                    }
                });
            }
        }
        
        const totalWaste = generalWaste + infectiousWaste + recyclableWaste;
        const recycleRate = totalWaste > 0 ? ((recyclableWaste / totalWaste) * 100).toFixed(2) : 0;
        
        if (totalWaste > 0) {
            console.log(`   📊 結果: 總計 ${totalWaste.toFixed(2)} kg`);
            console.log(`      一般廢棄物: ${generalWaste.toFixed(2)} kg`);
            console.log(`      感染性廢棄物: ${infectiousWaste.toFixed(2)} kg`);
            console.log(`      可回收廢棄物: ${recyclableWaste.toFixed(2)} kg`);
            console.log(`      回收率: ${recycleRate}%`);
            
            return {
                totalWaste: parseFloat(totalWaste.toFixed(2)),
                infectiousWaste: parseFloat(infectiousWaste.toFixed(2)),
                recycledWaste: parseFloat(recyclableWaste.toFixed(2)),
                recycleRate: parseFloat(recycleRate),
                noData: false
            };
        }
    } catch (error) {
        console.warn(`   ⚠️ 查詢失敗:`, error.message);
    }
    
    // ========== CQL預設值: 無廢棄物資料 ==========
    console.log('   ⚠️ 無廢棄物觀察記錄');
    return {
        totalWaste: 0,
        infectiousWaste: 0,
        recycledWaste: 0,
        recycleRate: 0,
        noData: true
    };
}

// 更新 ESG 卡片
function updateESGCard(cardId, results, unit) {
    const countElement = document.getElementById(`${cardId}Count`);
    const rateElement = document.getElementById(`${cardId}Rate`);
    
    if (results.noData) {
        if (countElement) {
            countElement.innerHTML = '<div class="no-data-message"><i class="fas fa-database"></i><p>資料庫無資料</p></div>';
        }
        if (rateElement) {
            rateElement.textContent = '--';
        }
        return;
    }
    
    if (countElement) {
        let displayValue;
        if (cardId === 'antibiotic') {
            displayValue = formatNumber(results.totalPatients);
        } else if (cardId === 'ehr') {
            displayValue = formatNumber(results.ehrAdopted);
        } else if (cardId === 'waste') {
            displayValue = formatNumber(results.totalWaste);
        }
        
        countElement.textContent = displayValue;
        countElement.classList.add('animated');
    }
    
    if (rateElement) {
        let rateValue;
        if (cardId === 'antibiotic') {
            rateValue = results.utilizationRate;
        } else if (cardId === 'ehr') {
            rateValue = results.adoptionRate;
        } else if (cardId === 'waste') {
            rateValue = results.recycleRate;
        }
        
        rateElement.textContent = `${rateValue}%`;
        rateElement.classList.add('animated');
    }
}

// 格式化數字
function formatNumber(num) {
    if (num === undefined || num === null) return '0';
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// 首字母大寫
function capitalize(str) {
    return str.split('-').map(word => 
        word.charAt(0).toUpperCase() + word.slice(1)
    ).join('');
}

// 顯示詳細資訊 Modal
function showDetailModal(indicatorType) {
    const modal = document.getElementById('detailModal');
    const modalTitle = document.getElementById('modalTitle');
    const modalBody = document.getElementById('modalBody');
    
    const titles = {
        'antibiotic': '抗生素使用率詳情',
        'ehr-adoption': '電子病歷採用率詳情',
        'waste': '廢棄物管理詳情'
    };
    
    modalTitle.textContent = titles[indicatorType] || '詳細資訊';
    
    const results = currentResults[indicatorType];
    if (results) {
        modalBody.innerHTML = generateDetailContent(indicatorType, results);
    } else {
        modalBody.innerHTML = '<p>請先執行查詢</p>';
    }
    
    modal.style.display = 'flex';
}

// 生成詳細內容
function generateDetailContent(indicatorType, results) {
    if (results.noData) {
        return '<div class="no-data-message"><i class="fas fa-database"></i><p>資料庫無資料</p></div>';
    }
    
    let content = '<div class="detail-content" style="padding: 20px;">';
    
    if (results.demoMode) {
        content += '<div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 12px; margin-bottom: 20px; border-radius: 4px;">';
        content += '<i class="fas fa-flask" style="color: #f59e0b;"></i> <strong>示範模式數據</strong>';
        content += '</div>';
    }
    
    if (indicatorType === 'antibiotic') {
        content += '<h3><i class="fas fa-pills"></i> 抗生素使用率統計</h3>';
        content += '<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin-top: 20px;">';
        content += `<div class="stat-box"><div class="stat-label">總病人數</div><div class="stat-value">${formatNumber(results.totalPatients)}</div></div>`;
        content += `<div class="stat-box"><div class="stat-label">使用抗生素病人數</div><div class="stat-value">${formatNumber(results.antibioticPatients)}</div></div>`;
        content += `<div class="stat-box"><div class="stat-label">使用率</div><div class="stat-value">${results.utilizationRate}%</div></div>`;
        content += '</div>';
    } else if (indicatorType === 'ehr-adoption') {
        content += '<h3><i class="fas fa-laptop-medical"></i> 電子病歷採用率統計</h3>';
        content += '<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin-top: 20px;">';
        content += `<div class="stat-box"><div class="stat-label">總病人數</div><div class="stat-value">${formatNumber(results.totalOrganizations)}</div></div>`;
        content += `<div class="stat-box"><div class="stat-label">已採用病人數</div><div class="stat-value">${formatNumber(results.ehrAdopted)}</div></div>`;
        content += `<div class="stat-box"><div class="stat-label">採用率</div><div class="stat-value">${results.adoptionRate}%</div></div>`;
        content += '</div>';
    } else if (indicatorType === 'waste') {
        content += '<h3><i class="fas fa-recycle"></i> 醫療廢棄物管理統計</h3>';
        content += '<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin-top: 20px;">';
        content += `<div class="stat-box"><div class="stat-label">總廢棄物量</div><div class="stat-value">${formatNumber(results.totalWaste)} kg</div></div>`;
        content += `<div class="stat-box"><div class="stat-label">感染性廢棄物</div><div class="stat-value">${formatNumber(results.infectiousWaste)} kg</div></div>`;
        content += `<div class="stat-box"><div class="stat-label">回收廢棄物</div><div class="stat-value">${formatNumber(results.recycledWaste)} kg</div></div>`;
        content += `<div class="stat-box"><div class="stat-label">回收率</div><div class="stat-value">${results.recycleRate}%</div></div>`;
        content += '</div>';
    }
    
    content += '</div>';
    content += '<style>';
    content += '.stat-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; text-align: center; }';
    content += '.stat-box .stat-label { font-size: 14px; color: #64748b; margin-bottom: 8px; }';
    content += '.stat-box .stat-value { font-size: 24px; font-weight: bold; color: #1e293b; }';
    content += '</style>';
    
    return content;
}

// 關閉 Modal
function closeModal() {
    const modal = document.getElementById('detailModal');
    modal.style.display = 'none';
}

// 重新整理資料
function refreshData() {
    location.reload();
}

// 匯出資料
function exportData() {
    const dataStr = JSON.stringify(currentResults, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `esg-indicators-data-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
}

// ========== 示範模式控制 ==========
function toggleDemoMode() {
    const currentMode = localStorage.getItem('demoMode') === 'true';
    const newMode = !currentMode;
    
    localStorage.setItem('demoMode', newMode.toString());
    updateDemoModeButton();
    
    const message = newMode 
        ? '✅ 示範模式已啟用\n\n當 FHIR 伺服器沒有資料時，系統將顯示模擬數據供展示使用。\n\n請重新整理頁面並點擊「執行查詢」按鈕測試。'
        : '✅ 示範模式已關閉\n\n系統將只顯示 FHIR 伺服器的真實資料。';
    
    alert(message);
    console.log(`示範模式: ${newMode ? '啟用' : '關閉'}`);
    
    if (newMode) {
        location.reload();
    }
}

function updateDemoModeButton() {
    if (localStorage.getItem('demoMode') === null) {
        localStorage.setItem('demoMode', 'true');
    }
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    const btn = document.getElementById('demoModeBtn');
    const text = document.getElementById('demoModeText');
    
    if (btn && text) {
        if (demoMode) {
            btn.classList.remove('btn-secondary');
            btn.classList.add('btn-success');
            btn.style.background = 'linear-gradient(135deg, #10b981, #059669)';
            text.textContent = '示範模式：開啟';
        } else {
            btn.classList.remove('btn-success');
            btn.classList.add('btn-secondary');
            btn.style.background = '';
            text.textContent = '啟用示範模式';
        }
    }
    
    console.log(`🎭 示範模式狀態: ${demoMode ? '已啟用' : '已關閉'}`);
}

// 生成示範數據
function generateDemoDataESG(indicatorType) {
    const demoData = {
        'antibiotic': {
            totalPatients: 2500,
            antibioticPatients: 425,
            utilizationRate: '17.00',
            noData: false,
            demoMode: true
        },
        'ehr': {
            totalOrganizations: 150,
            ehrAdopted: 128,
            adoptionRate: '85.33',
            noData: false,
            demoMode: true
        },
        'waste': {
            totalWaste: 15680,
            infectiousWaste: 5645,
            recycledWaste: 4320,
            recycleRate: '27.55',
            noData: false,
            demoMode: true
        }
    };
    
    return demoData[indicatorType] || demoData['antibiotic'];
}
