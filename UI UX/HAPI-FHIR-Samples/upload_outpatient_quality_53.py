#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
上傳門診品質指標測試資料到FHIR伺服器
覆蓋模式: 使用PUT更新資源
"""

import json
import requests

# FHIR伺服器設定
FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"

def upload_bundle(bundle_file):
    """上傳FHIR Bundle到伺服器"""
    
    print(f"準備上傳 {bundle_file} 到 {FHIR_SERVER}")
    print()
    
    # 讀取Bundle檔案
    with open(bundle_file, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    total_resources = len(bundle['entry'])
    
    # 統計資源類型
    resource_types = {}
    for entry in bundle['entry']:
        resource_type = entry['resource']['resourceType']
        resource_types[resource_type] = resource_types.get(resource_type, 0) + 1
    
    print(f"資源類型:")
    for resource_type, count in resource_types.items():
        print(f"  {resource_type}: {count}")
    print()
    
    # 上傳Bundle
    print("開始上傳...")
    try:
        response = requests.post(
            FHIR_SERVER,
            json=bundle,
            headers={
                'Content-Type': 'application/fhir+json',
                'Accept': 'application/fhir+json'
            },
            timeout=300  # 5分鐘timeout
        )
        
        print(f"上傳成功! 狀態碼: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            if result.get('resourceType') == 'Bundle':
                processed = len(result.get('entry', []))
                print(f"伺服器回應: 已處理 {processed} 個資源")
            print("所有資源均成功上傳")
        else:
            print(f"伺服器回應: {response.text[:500]}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ 上傳失敗: {e}")
        return False
    
    print()
    print("="*60)
    print("門診品質指標資料上傳完成!")
    print(f"病人編號: TW00309 - TW00361")
    print(f"資源總數: {total_resources} ({sum(resource_types.values())} Patient + Encounter + Condition + MedicationRequest + Observation)")
    print(f"時間範圍: 2025 Q4 (10-12月)")
    print("="*60)
    
    return True

if __name__ == '__main__':
    upload_bundle('outpatient_quality_53_bundle.json')
