"""
測試前端過濾邏輯
"""
import requests

# 模擬前端getSurgicalQualityPatientIds()
surgical_patient_ids = [f'TW{i}' for i in range(10001, 10047)]
print(f"手術病人ID範圍: {surgical_patient_ids[0]} - {surgical_patient_ids[-1]}")
print(f"總共 {len(surgical_patient_ids)} 個ID")

# 查詢所有Q4住院encounter
url = "https://emr-smart.appx.com.tw/v/r4/fhir/Encounter"
params = {
    'class': 'IMP',
    'status': 'finished',
    'date': ['ge2025-10-01', 'le2025-12-31'],
    '_count': 500
}

print(f"\n查詢URL: {url}")
print(f"參數: {params}")

r = requests.get(url, params=params)
print(f"\nHTTP Status: {r.status_code}")

if r.status_code == 200:
    data = r.json()
    total_entries = len(data.get('entry', []))
    print(f"查詢到 {total_entries} 筆Encounter")
    
    # 模擬前端過濾邏輯
    filtered_encounters = []
    for entry in data.get('entry', []):
        patient_ref = entry['resource'].get('subject', {}).get('reference', '')
        patient_id = patient_ref.split('/')[-1] if '/' in patient_ref else ''
        
        if patient_id in surgical_patient_ids:
            filtered_encounters.append(entry)
            print(f"  ✓ 匹配: {patient_id} (Encounter: {entry['resource']['id']})")
    
    print(f"\n過濾結果: {len(filtered_encounters)} 筆手術品質病人的Encounter")
    
    if len(filtered_encounters) == 0:
        print("\n❌ 沒有找到任何匹配的Encounter!")
        print("可能原因:")
        print("1. Patient ID格式不匹配")
        print("2. 日期範圍不匹配")
        print("3. 數據未正確上傳")
        
        # 檢查前5筆encounter的Patient ID
        print("\n前5筆Encounter的Patient ID:")
        for i, entry in enumerate(data.get('entry', [])[:5]):
            patient_ref = entry['resource'].get('subject', {}).get('reference', '')
            print(f"  {i+1}. {patient_ref}")
else:
    print(f"查詢失敗: {r.text[:200]}")
