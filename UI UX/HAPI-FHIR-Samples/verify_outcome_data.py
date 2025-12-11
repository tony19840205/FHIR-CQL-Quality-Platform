import requests

# FHIR server URL
base_url = "https://emr-smart.appx.com.tw/v/r4/fhir"

print("\n🔍 檢查結果品質指標病人資料...")
print("=" * 60)

# 檢查 TW20001-TW20012 病人
for i in range(1, 13):
    patient_id = f"TW{20000 + i:05d}"
    
    try:
        # 檢查 Patient
        response = requests.get(f"{base_url}/Patient/{patient_id}")
        patient_exists = response.status_code == 200
        
        # 檢查該病人的 Encounter
        enc_response = requests.get(f"{base_url}/Encounter?subject=Patient/{patient_id}")
        encounter_count = 0
        if enc_response.status_code == 200:
            data = enc_response.json()
            encounter_count = len(data.get('entry', []))
        
        status = "✅" if patient_exists else "❌"
        print(f"{status} {patient_id}: Patient={patient_exists}, Encounters={encounter_count}")
        
    except Exception as e:
        print(f"❌ {patient_id}: Error - {e}")

print("\n" + "=" * 60)
print("✅ 驗證完成")
