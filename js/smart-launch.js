// ========== SMART on FHIR Launch 處理 ==========

console.log('🚀 SMART on FHIR Launch Handler 已載入');

// 檢查是否有 launch 參數（EHR Launch）
const urlParams = new URLSearchParams(window.location.search);
const launchToken = urlParams.get('launch');
const iss = urlParams.get('iss');

console.log('📋 URL 參數:', {
    launch: launchToken ? '✓ 已接收' : '✗ 未提供',
    iss: iss || '未提供'
});

// 如果有 launch 參數，啟動 SMART Launch 流程
if (launchToken && iss) {
    console.log('🔐 檢測到 SMART Launch 參數，開始授權流程...');
    handleSmartLaunch(launchToken, iss);
}

async function handleSmartLaunch(launch, issUrl) {
    try {
        console.log(`📡 正在從 ${issUrl} 取得授權伺服器資訊...`);
        
        // 取得 FHIR Server 的 metadata
        const metadataResponse = await fetch(`${issUrl}/metadata`);
        if (!metadataResponse.ok) {
            throw new Error(`無法取得 FHIR Server metadata: ${metadataResponse.status}`);
        }
        
        const metadata = await metadataResponse.json();
        console.log('✓ 已取得 FHIR Server metadata');
        
        // 從 metadata 中取得 OAuth 端點
        const security = metadata.rest?.[0]?.security;
        const oauthExtension = security?.extension?.find(
            ext => ext.url === 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'
        );
        
        if (!oauthExtension) {
            console.warn('⚠️ FHIR Server 未提供 OAuth 端點，使用備用方案');
            // 備用方案：直接儲存 FHIR Server URL
            localStorage.setItem('fhirServer', issUrl);
            localStorage.setItem('launchToken', launch);
            console.log('✓ 已儲存 FHIR Server 和 Launch Token');
            return;
        }
        
        const authorizeUrl = oauthExtension.extension.find(ext => ext.url === 'authorize')?.valueUri;
        const tokenUrl = oauthExtension.extension.find(ext => ext.url === 'token')?.valueUri;
        
        console.log('✓ OAuth 端點:', {
            authorize: authorizeUrl,
            token: tokenUrl
        });
        
        if (!authorizeUrl) {
            throw new Error('FHIR Server 未提供授權端點');
        }
        
        // 準備 OAuth 授權請求
        const redirectUri = 'https://tony19840205.github.io/FHIR-CQL-Quality-Platform/launch.html';
        const clientId = 'fhir-cql-platform'; // 可能需要根據實際情況調整
        const scope = 'launch openid fhirUser patient/*.read';
        
        // 生成 state 參數（用於防止 CSRF 攻擊並傳遞資訊）
        const state = btoa(JSON.stringify({
            iss: issUrl,
            tokenUrl: tokenUrl,
            timestamp: Date.now()
        }));
        
        // 構建授權 URL
        const authUrl = new URL(authorizeUrl);
        authUrl.searchParams.append('response_type', 'code');
        authUrl.searchParams.append('client_id', clientId);
        authUrl.searchParams.append('redirect_uri', redirectUri);
        authUrl.searchParams.append('launch', launch);
        authUrl.searchParams.append('scope', scope);
        authUrl.searchParams.append('state', state);
        authUrl.searchParams.append('aud', issUrl);
        
        console.log('🔄 正在重定向到授權頁面...');
        console.log('授權 URL:', authUrl.toString());
        
        // 重定向到授權頁面
        window.location.href = authUrl.toString();
        
    } catch (error) {
        console.error('❌ SMART Launch 處理失敗:', error);
        alert(`SMART Launch 失敗: ${error.message}\n\n將使用標準模式載入應用程式`);
        
        // 失敗時儲存 ISS 並繼續
        if (issUrl) {
            localStorage.setItem('fhirServer', issUrl);
        }
    }
}

// 檢查是否從 OAuth 回調返回
if (window.location.pathname.includes('launch.html')) {
    console.log('📍 當前在 OAuth 回調頁面');
}

// 提供全域函數供其他腳本使用
window.smartLaunch = {
    isLaunched: !!(launchToken && iss),
    launchToken: launchToken,
    iss: iss
};

console.log('✓ SMART Launch Handler 初始化完成');
