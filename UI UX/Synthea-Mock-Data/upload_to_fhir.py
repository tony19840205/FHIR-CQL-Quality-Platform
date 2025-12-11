"""
上傳傳染病數據到 FHIR 伺服器
"""

import json
import requests
from datetime import datetime

# FHIR 伺服器設定
FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"

def upload_bundle(bundle_file):
    """上傳 Bundle 到 FHIR 伺服器"""
    
    print(f"正在讀取數據檔案: {bundle_file}")
    with open(bundle_file, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    total_resources = len(bundle['entry'])
    print(f"總共 {total_resources} 筆資源要上傳")
    print(f"目標伺服器: {FHIR_SERVER}")
    print("-" * 60)
    
    # 統計
    success_count = 0
    error_count = 0
    errors = []
    
    # 逐一上傳資源
    for i, entry in enumerate(bundle['entry'], 1):
        resource = entry['resource']
        resource_type = resource['resourceType']
        resource_id = resource.get('id', 'unknown')
        
        try:
            # 使用 PUT 方法上傳（如果資源有 ID）
            if 'id' in resource:
                url = f"{FHIR_SERVER}/{resource_type}/{resource_id}"
                response = requests.put(url, json=resource, headers={'Content-Type': 'application/fhir+json'})
            else:
                # 使用 POST 方法建立新資源
                url = f"{FHIR_SERVER}/{resource_type}"
                response = requests.post(url, json=resource, headers={'Content-Type': 'application/fhir+json'})
            
            if response.status_code in [200, 201]:
                success_count += 1
                if i % 100 == 0:
                    print(f"[OK] 已上傳 {i}/{total_resources} ({success_count} 成功, {error_count} 失敗)")
            else:
                error_count += 1
                error_msg = f"{resource_type}/{resource_id}: HTTP {response.status_code}"
                errors.append(error_msg)
                if error_count <= 5:  # 只顯示前5個錯誤
                    print(f"[ERROR] {error_msg}")
                    
        except Exception as e:
            error_count += 1
            error_msg = f"{resource_type}/{resource_id}: {str(e)}"
            errors.append(error_msg)
            if error_count <= 5:
                print(f"[ERROR] {error_msg}")
    
    # 最終結果
    print("-" * 60)
    print(f"\n上傳完成！")
    print(f"[SUCCESS] 成功: {success_count}/{total_resources}")
    print(f"[FAILED] 失敗: {error_count}/{total_resources}")
    print(f"成功率: {success_count/total_resources*100:.1f}%")
    
    # 保存錯誤日誌
    if errors:
        error_log = {
            'upload_time': datetime.now().isoformat(),
            'total': total_resources,
            'success': success_count,
            'errors': error_count,
            'error_details': errors
        }
        with open('upload_errors.json', 'w', encoding='utf-8') as f:
            json.dump(error_log, f, ensure_ascii=False, indent=2)
        print(f"\n錯誤詳情已保存到: upload_errors.json")
    
    return success_count, error_count

if __name__ == '__main__':
    print("=" * 60)
    print("傳染病數據上傳工具")
    print("=" * 60)
    print()
    
    # 上傳數據
    success, errors = upload_bundle('infectious_disease_bundle.json')
    
    print("\n" + "=" * 60)
    print("上傳作業完成")
    print("=" * 60)
