"""
測試連線到台灣衛福部 FHIR SAND-BOX
"""
import requests
import json

FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

print("="*70)
print("測試連線到台灣衛福部 FHIR SAND-BOX")
print("="*70)
print(f"伺服器: {FHIR_SERVER}")
print()

# 測試連線
try:
    print("測試 1: 檢查伺服器 metadata...")
    response = requests.get(f"{FHIR_SERVER}/metadata", timeout=10)
    print(f"✅ HTTP {response.status_code}")
    
    if response.status_code == 200:
        metadata = response.json()
        print(f"✅ FHIR 版本: {metadata.get('fhirVersion', 'N/A')}")
        print(f"✅ 伺服器類型: {metadata.get('software', {}).get('name', 'N/A')}")
    print()
    
except Exception as e:
    print(f"❌ 連線失敗: {e}")
    print()

# 測試查詢 Patient
try:
    print("測試 2: 查詢 Patient 資源...")
    response = requests.get(f"{FHIR_SERVER}/Patient?_count=1", timeout=10)
    print(f"✅ HTTP {response.status_code}")
    
    if response.status_code == 200:
        bundle = response.json()
        total = bundle.get('total', 0)
        print(f"✅ 目前 Patient 總數: {total}")
    print()
    
except Exception as e:
    print(f"❌ 查詢失敗: {e}")
    print()

print("="*70)
print("測試完成")
print("="*70)
