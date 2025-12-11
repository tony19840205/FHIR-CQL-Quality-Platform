#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
檢查 Procedure 是否正確上傳並關聯
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 60)
print("檢查 Procedure 資源")
print("=" * 60)
print()

# 檢查 Procedure 是否存在
print("1. 查詢 Procedure CS-PROC-001:")
response = requests.get(
    f"{fhir_server}/Procedure/CS-PROC-001",
    verify=False
)
if response.status_code == 200:
    proc = response.json()
    print(f"   ✅ 找到 Procedure: {proc.get('id')}")
    print(f"   - Status: {proc.get('status')}")
    print(f"   - Code: {proc.get('code', {}).get('coding', [{}])[0].get('code')}")
    print(f"   - Subject: {proc.get('subject', {}).get('reference')}")
    print(f"   - Encounter: {proc.get('encounter', {}).get('reference')}")
else:
    print(f"   ❌ 找不到: {response.status_code}")

print()

# 檢查 Encounter 關聯
print("2. 查詢 Encounter CS-ENC-001:")
response = requests.get(
    f"{fhir_server}/Encounter/CS-ENC-001",
    verify=False
)
if response.status_code == 200:
    enc = response.json()
    print(f"   ✅ 找到 Encounter: {enc.get('id')}")
    print(f"   - Class: {enc.get('class', {}).get('code')}")
    print(f"   - Status: {enc.get('status')}")
    print(f"   - Period: {enc.get('period', {}).get('start')} ~ {enc.get('period', {}).get('end')}")
else:
    print(f"   ❌ 找不到: {response.status_code}")

print()

# 嘗試用 encounter 參數查詢 Procedure
print("3. 用 encounter 參數查詢 Procedure:")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={
        'encounter': 'Encounter/CS-ENC-001',
        'status': 'completed'
    },
    verify=False
)
if response.status_code == 200:
    result = response.json()
    count = result.get('total', 0)
    print(f"   查詢結果: {count} 筆")
    if result.get('entry'):
        for entry in result['entry']:
            proc = entry['resource']
            print(f"   - Procedure ID: {proc.get('id')}")
            print(f"     Code: {proc.get('code', {}).get('coding', [{}])[0].get('code')}")
else:
    print(f"   ❌ 查詢失敗: {response.status_code}")

print()
print("=" * 60)
