import requests
from datetime import datetime

# FHIR server URL
base_url = "https://emr-smart.appx.com.tw/v/r4/fhir"

print("\n🔍 檢查結果品質指標 Encounter 日期...")
print("=" * 60)

# 檢查其中一個病人的 Encounter 詳情
patient_id = "TW20001"
response = requests.get(f"{base_url}/Encounter?subject=Patient/{patient_id}")

if response.status_code == 200:
    data = response.json()
    if data.get('entry'):
        for entry in data['entry']:
            encounter = entry['resource']
            enc_id = encounter.get('id')
            period = encounter.get('period', {})
            status = encounter.get('status')
            
            print(f"\nEncounter/{enc_id}:")
            print(f"  Status: {status}")
            print(f"  Period.start: {period.get('start')}")
            print(f"  Period.end: {period.get('end')}")
            
            # 檢查 Patient reference
            subject = encounter.get('subject', {})
            print(f"  Subject: {subject.get('reference')}")
    else:
        print("❌ 無 entry")
else:
    print(f"❌ API 錯誤: {response.status_code}")

print("\n" + "=" * 60)
print("🔍 前端查詢條件 (2025-Q4):")
print("  date: ge2024-10-01")
print("  date: le2024-12-31")
print("  status: finished")
