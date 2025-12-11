"""
上傳結果品質指標測試數據到FHIR伺服器
"""
import json
import requests

FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"
BUNDLE_FILE = "outcome_quality_12_bundle.json"

def upload_bundle():
    """上傳Bundle到FHIR伺服器"""
    print(f"📂 讀取Bundle檔案: {BUNDLE_FILE}")
    
    with open(BUNDLE_FILE, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    total_entries = len(bundle['entry'])
    print(f"📦 Bundle包含 {total_entries} 個資源")
    
    # 使用transaction方式上傳
    print(f"\n🚀 開始上傳到: {FHIR_SERVER}")
    
    try:
        response = requests.post(
            FHIR_SERVER,
            json=bundle,
            headers={"Content-Type": "application/fhir+json"},
            timeout=120
        )
        
        print(f"\n📊 上傳結果:")
        print(f"   HTTP Status: {response.status_code}")
        
        if response.status_code in [200, 201]:
            result = response.json()
            
            if result.get('resourceType') == 'Bundle':
                success_count = sum(1 for entry in result.get('entry', []) 
                                   if entry.get('response', {}).get('status', '').startswith('2'))
                print(f"   ✅ 成功上傳: {success_count}/{total_entries} 個資源")
                
                # 統計各類資源
                resource_stats = {}
                for entry in bundle['entry']:
                    resource_type = entry['resource']['resourceType']
                    resource_stats[resource_type] = resource_stats.get(resource_type, 0) + 1
                
                print(f"\n📋 上傳資源明細:")
                for resource_type, count in sorted(resource_stats.items()):
                    print(f"   - {resource_type}: {count}")
                    
                print(f"\n🎯 預期查詢結果:")
                print(f"   指標-17 (急性心肌梗塞死亡率): 16.67%")
                print(f"   指標-18 (失智症安寧療護利用率): 66.67%")
            else:
                print(f"   ⚠️  回應格式異常")
                print(f"   Response: {response.text[:500]}")
        else:
            print(f"   ❌ 上傳失敗")
            print(f"   Response: {response.text[:500]}")
            
    except requests.exceptions.Timeout:
        print(f"   ❌ 請求逾時 (超過120秒)")
    except Exception as e:
        print(f"   ❌ 上傳錯誤: {str(e)}")

if __name__ == "__main__":
    upload_bundle()
