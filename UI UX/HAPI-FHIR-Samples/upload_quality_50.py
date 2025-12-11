"""
上傳 50 位病人的醫療品質指標資料到 emr-smart FHIR 伺服器
"""

import json
import requests

def upload_bundle(bundle_file):
    """上傳 Bundle 到 FHIR 伺服器"""
    url = "https://emr-smart.appx.com.tw/v/r4/fhir"
    
    with open(bundle_file, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    print(f"準備上傳 {len(bundle['entry'])} 個資源到 {url}")
    print(f"\n資源類型:")
    resource_types = {}
    for entry in bundle['entry']:
        rt = entry['resource']['resourceType']
        resource_types[rt] = resource_types.get(rt, 0) + 1
    for rt, count in resource_types.items():
        print(f"  {rt}: {count}")
    
    print("\n開始上傳...")
    response = requests.post(url, json=bundle, headers={'Content-Type': 'application/fhir+json'})
    
    if response.status_code in [200, 201]:
        print(f"上傳成功! 狀態碼: {response.status_code}")
        result = response.json()
        if 'entry' in result:
            print(f"伺服器回應: 已處理 {len(result['entry'])} 個資源")
            
            errors = []
            for entry in result.get('entry', []):
                if 'response' in entry and entry['response'].get('status', '').startswith(('4', '5')):
                    errors.append(entry['response'])
            
            if errors:
                print(f"\n警告: 發現 {len(errors)} 個錯誤:")
                for i, error in enumerate(errors[:5], 1):
                    print(f"  {i}. {error.get('status')}: {error.get('outcome', {}).get('issue', [{}])[0].get('diagnostics', 'Unknown error')}")
            else:
                print("所有資源均成功上傳")
        return True
    else:
        print(f"上傳失敗! 狀態碼: {response.status_code}")
        print(f"錯誤訊息: {response.text[:500]}")
        return False

if __name__ == "__main__":
    bundle_file = "quality_50_bundle.json"
    success = upload_bundle(bundle_file)
    
    if success:
        print("\n醫療品質指標資料上傳完成!")
        print("病人編號: TW00259 - TW00308")
        print("資源總數: 496 (50 Patient + 173 Encounter + 173 Condition + 100 Medication)")
        print("時間範圍: 2025 Q4 (10-12月)")
    else:
        print("\n上傳失敗,請檢查網路連線和伺服器狀態")
