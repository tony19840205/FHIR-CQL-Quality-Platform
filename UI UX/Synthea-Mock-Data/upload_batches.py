"""
分批上傳 FHIR Bundle（每批 500 筆）
"""

import json
import requests
from datetime import datetime

# FHIR 伺服器設定
FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"
BATCH_SIZE = 500  # 每批上傳數量

def upload_in_batches(bundle_file):
    """分批上傳 Bundle"""
    
    print(f"正在讀取數據檔案: {bundle_file}")
    with open(bundle_file, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    all_entries = bundle['entry']
    total_resources = len(all_entries)
    total_batches = (total_resources + BATCH_SIZE - 1) // BATCH_SIZE
    
    print(f"總共 {total_resources} 筆資源")
    print(f"分成 {total_batches} 批上傳（每批 {BATCH_SIZE} 筆）")
    print(f"目標伺服器: {FHIR_SERVER}")
    print("=" * 60)
    
    total_success = 0
    total_failed = 0
    
    # 分批處理
    for batch_num in range(total_batches):
        start_idx = batch_num * BATCH_SIZE
        end_idx = min((batch_num + 1) * BATCH_SIZE, total_resources)
        batch_entries = all_entries[start_idx:end_idx]
        
        print(f"\n[批次 {batch_num + 1}/{total_batches}] 上傳 {start_idx + 1}-{end_idx} 筆...")
        
        # 建立 transaction Bundle
        batch_bundle = {
            'resourceType': 'Bundle',
            'type': 'transaction',
            'entry': []
        }
        
        # 準備 request
        for entry in batch_entries:
            resource = entry['resource']
            resource_type = resource['resourceType']
            resource_id = resource.get('id', '')
            
            new_entry = {
                'resource': resource
            }
            
            if resource_id:
                new_entry['request'] = {
                    'method': 'PUT',
                    'url': f"{resource_type}/{resource_id}"
                }
            else:
                new_entry['request'] = {
                    'method': 'POST',
                    'url': resource_type
                }
            
            batch_bundle['entry'].append(new_entry)
        
        try:
            response = requests.post(
                FHIR_SERVER,
                json=batch_bundle,
                headers={'Content-Type': 'application/fhir+json'},
                timeout=120
            )
            
            if response.status_code in [200, 201]:
                result = response.json()
                batch_success = 0
                batch_failed = 0
                
                if 'entry' in result:
                    for entry in result['entry']:
                        status = entry.get('response', {}).get('status', '')
                        if '201' in status or '200' in status:
                            batch_success += 1
                        else:
                            batch_failed += 1
                
                total_success += batch_success
                total_failed += batch_failed
                print(f"[OK] 批次完成: 成功 {batch_success}, 失敗 {batch_failed}")
            else:
                print(f"[ERROR] 批次失敗: HTTP {response.status_code}")
                print(f"錯誤: {response.text[:200]}")
                total_failed += len(batch_entries)
                
        except Exception as e:
            print(f"[ERROR] 批次錯誤: {str(e)}")
            total_failed += len(batch_entries)
    
    # 最終結果
    print("\n" + "=" * 60)
    print("上傳完成！")
    print(f"[SUCCESS] 成功: {total_success}/{total_resources}")
    print(f"[FAILED] 失敗: {total_failed}/{total_resources}")
    if total_resources > 0:
        print(f"成功率: {total_success/total_resources*100:.1f}%")
    print("=" * 60)
    
    return total_success, total_failed

if __name__ == '__main__':
    print("=" * 60)
    print("傳染病數據分批上傳工具")
    print("=" * 60)
    print()
    
    upload_in_batches('infectious_disease_bundle.json')
