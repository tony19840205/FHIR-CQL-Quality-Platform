#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
查看現有的 Procedure 資源格式作為參考
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 60)
print("查看現有 Procedure 資源格式")
print("=" * 60)
print()

# 查詢一個現有的 Procedure
response = requests.get(
    f"{fhir_server}/Procedure",
    params={
        'code': '81004C',
        'status': 'completed',
        '_count': 1
    },
    verify=False
)

if response.status_code == 200:
    result = response.json()
    if result.get('entry'):
        proc = result['entry'][0]['resource']
        
        print("現有 Procedure 範例:")
        print(json.dumps(proc, indent=2, ensure_ascii=False))
        print()
        print("=" * 60)
        print("關鍵欄位:")
        print(f"  - id: {proc.get('id')}")
        print(f"  - status: {proc.get('status')}")
        print(f"  - code.coding[0].system: {proc.get('code', {}).get('coding', [{}])[0].get('system')}")
        print(f"  - code.coding[0].code: {proc.get('code', {}).get('coding', [{}])[0].get('code')}")
        print(f"  - subject: {proc.get('subject', {}).get('reference')}")
        print(f"  - encounter: {proc.get('encounter', {}).get('reference')}")
else:
    print(f"查詢失敗: {response.status_code}")

print("=" * 60)
