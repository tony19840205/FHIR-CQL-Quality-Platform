"""
使用 FHIR Bundle 批次上傳（更快速）
"""

import json
import requests

# FHIR 伺服器設定
FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"

def upload_bundle_batch(bundle_file):
    """使用 transaction Bundle 批次上傳"""
    
    print(f"正在讀取數據檔案: {bundle_file}")
    with open(bundle_file, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    # 將 collection 類型改為 transaction 類型
    bundle['type'] = 'transaction'
    
    # 為每個 entry 添加 request 資訊
    for entry in bundle['entry']:
        resource = entry['resource']
        resource_type = resource['resourceType']
        resource_id = resource.get('id', '')
        
        if resource_id:
            # 使用 PUT 更新現有資源
            entry['request'] = {
                'method': 'PUT',
                'url': f"{resource_type}/{resource_id}"
            }
        else:
            # 使用 POST 創建新資源
            entry['request'] = {
                'method': 'POST',
                'url': resource_type
            }
    
    total_resources = len(bundle['entry'])
    print(f"總共 {total_resources} 筆資源要批次上傳")
    print(f"目標伺服器: {FHIR_SERVER}")
    print("=" * 60)
    
    try:
        # 發送 transaction Bundle
        print("開始批次上傳...")
        response = requests.post(
            FHIR_SERVER,
            json=bundle,
            headers={'Content-Type': 'application/fhir+json'},
            timeout=300  # 5分鐘超時
        )
        
        if response.status_code in [200, 201]:
            print(f"[SUCCESS] 批次上傳成功！")
            result = response.json()
            
            # 統計結果
            success = 0
            failed = 0
            
            if 'entry' in result:
                for entry in result['entry']:
                    status = entry.get('response', {}).get('status', '')
                    if '201' in status or '200' in status:
                        success += 1
                    else:
                        failed += 1
            
            print(f"[SUCCESS] 成功: {success}/{total_resources}")
            print(f"[FAILED] 失敗: {failed}/{total_resources}")
            print(f"成功率: {success/total_resources*100:.1f}%")
            
            return success, failed
        else:
            print(f"[ERROR] 上傳失敗: HTTP {response.status_code}")
            print(f"錯誤訊息: {response.text[:500]}")
            return 0, total_resources
            
    except Exception as e:
        print(f"[ERROR] 上傳過程發生錯誤: {str(e)}")
        return 0, total_resources

if __name__ == '__main__':
    print("=" * 60)
    print("傳染病數據批次上傳工具（使用 FHIR Transaction Bundle）")
    print("=" * 60)
    print()
    
    success, errors = upload_bundle_batch('infectious_disease_bundle.json')
    
    print("\n" + "=" * 60)
    print("上傳作業完成")
    print("=" * 60)
