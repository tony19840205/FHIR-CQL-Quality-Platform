#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
診斷 FHIR 資源上傳錯誤
"""

import json
import requests

FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

def diagnose_resource(bundle_file, resource_index=1):
    """診斷特定資源的上傳錯誤"""
    
    # 讀取 Bundle
    with open(bundle_file, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    # 取得資源
    resource = bundle['entry'][resource_index]['resource']
    resource_type = resource['resourceType']
    resource_id = resource['id']
    
    print(f"\n{'='*60}")
    print(f"診斷資源: {resource_type}/{resource_id}")
    print(f"{'='*60}\n")
    
    # 顯示資源內容
    print("資源內容:")
    print(json.dumps(resource, indent=2, ensure_ascii=False)[:500])
    print("...\n")
    
    # 嘗試上傳
    url = f"{FHIR_SERVER}/{resource_type}/{resource_id}"
    headers = {
        'Content-Type': 'application/fhir+json',
        'Accept': 'application/fhir+json'
    }
    
    try:
        response = requests.put(url, json=resource, headers=headers)
        
        if response.status_code == 200 or response.status_code == 201:
            print(f"✅ 成功上傳")
        else:
            print(f"❌ 上傳失敗: HTTP {response.status_code}")
            print(f"\n錯誤詳情:")
            print(f"Status: {response.status_code}")
            print(f"Reason: {response.reason}")
            
            # 嘗試解析錯誤訊息
            try:
                error_json = response.json()
                print(f"\n錯誤JSON:")
                print(json.dumps(error_json, indent=2, ensure_ascii=False))
                
                # 提取 OperationOutcome
                if error_json.get('resourceType') == 'OperationOutcome':
                    print(f"\n具體錯誤:")
                    for issue in error_json.get('issue', []):
                        severity = issue.get('severity', 'unknown')
                        code = issue.get('code', 'unknown')
                        diagnostics = issue.get('diagnostics', '')
                        location = issue.get('location', [])
                        
                        print(f"  - [{severity}] {code}")
                        print(f"    位置: {', '.join(location) if location else 'N/A'}")
                        print(f"    說明: {diagnostics}")
                        
            except:
                print(f"\n錯誤文本:")
                print(response.text[:1000])
    
    except Exception as e:
        print(f"❌ 請求失敗: {str(e)}")

# 診斷三個不同類型的失敗資源
print("\n" + "="*60)
print("開始診斷失敗資源")
print("="*60)

# 1. 診斷 outpatient_quality 中的 Encounter
print("\n\n1️⃣ 診斷 Encounter 資源")
diagnose_resource("CGMH_test_data_outpatient_quality_53_bundle.json", 1)

# 2. 診斷 outpatient_quality 中的 Condition
print("\n\n2️⃣ 診斷 Condition 資源")
diagnose_resource("CGMH_test_data_outpatient_quality_53_bundle.json", 2)

# 3. 診斷 outpatient_quality 中的 MedicationRequest
print("\n\n3️⃣ 診斷 MedicationRequest 資源")
try:
    diagnose_resource("CGMH_test_data_outpatient_quality_53_bundle.json", 3)
except:
    print("找不到 MedicationRequest，嘗試其他索引...")
    diagnose_resource("CGMH_test_data_outpatient_quality_53_bundle.json", 5)

print("\n\n" + "="*60)
print("診斷完成")
print("="*60)
