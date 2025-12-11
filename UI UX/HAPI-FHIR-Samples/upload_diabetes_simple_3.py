"""
上傳3個簡單的糖尿病患者到FHIR server
"""

import requests
import json

FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"

# 讀取bundle
with open('diabetes_simple_3.json', 'r', encoding='utf-8') as f:
    bundle = json.load(f)

print(f"📤 上傳 {len(bundle['entry'])} 個資源到FHIR server...")

# 上傳
response = requests.post(FHIR_SERVER, json=bundle, headers={
    'Content-Type': 'application/fhir+json'
})

print(f"\n{'='*50}")
if response.status_code == 200:
    print("✅ 上傳成功!")
    print(f"狀態碼: {response.status_code}")
    result = response.json()
    print(f"已處理 {len(result.get('entry', []))} 個資源")
else:
    print(f"❌ 上傳失敗")
    print(f"狀態碼: {response.status_code}")
    print(f"錯誤: {response.text[:500]}")
print(f"{'='*50}")
