#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
上傳住院品質指標測試資料到FHIR Server
使用PUT方法覆蓋上傳
"""

import json
import requests

FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"
BUNDLE_FILE = "inpatient_quality_46_bundle.json"

def main():
    print("=" * 60)
    print("上傳住院品質指標測試資料到FHIR Server")
    print("=" * 60)
    print(f"FHIR Server: {FHIR_SERVER}")
    print(f"Bundle檔案: {BUNDLE_FILE}")
    
    # 讀取bundle
    with open(BUNDLE_FILE, 'r', encoding='utf-8') as f:
        bundle = json.load(f)
    
    resource_count = len(bundle["entry"])
    print(f"待上傳資源數: {resource_count}")
    
    # 上傳bundle
    print("\n開始上傳...")
    response = requests.post(
        FHIR_SERVER,
        json=bundle,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"狀態碼: {response.status_code}")
    
    if response.status_code == 200:
        print("✅ 上傳成功!")
        result = response.json()
        if result.get("entry"):
            success_count = sum(1 for e in result["entry"] if e.get("response", {}).get("status", "").startswith("2"))
            print(f"成功處理: {success_count}/{resource_count} 個資源")
    else:
        print("❌ 上傳失敗!")
        print(f"錯誤訊息: {response.text[:500]}")
    
    print("=" * 60)

if __name__ == '__main__':
    main()
