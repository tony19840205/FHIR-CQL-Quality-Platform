"""
驗證結果品質指標的查詢邏輯是否正確
模擬前端 JS 的過濾邏輯
"""
import requests

base_url = "https://emr-smart.appx.com.tw/v/r4/fhir"

print("\n" + "="*70)
print("🔍 驗證指標-17: 急性心肌梗塞死亡率")
print("="*70)

# 步驟1: 取得結果品質病人ID範圍
outcome_patient_ids = [f"TW{20000+i:05d}" for i in range(1, 13)]
ami_patient_ids = outcome_patient_ids[:6]  # TW20001-TW20006
print(f"\n✅ AMI病人ID範圍: {ami_patient_ids[0]} - {ami_patient_ids[-1]}")

# 步驟2: 查詢這些病人的 Encounters (2024-Q4)
print("\n🔍 查詢 2024-Q4 的 Encounters...")
response = requests.get(f"{base_url}/Encounter", params={
    'status': 'finished',
    'date': ['ge2024-10-01', 'le2024-12-31'],
    '_count': 500
})

if response.status_code != 200:
    print(f"❌ API錯誤: {response.status_code}")
    exit(1)

data = response.json()
all_encounters = data.get('entry', [])
print(f"✅ 查詢到 {len(all_encounters)} 筆 Encounters")

# 步驟3: 記憶體過濾出AMI病人的encounters
filtered_encounters = []
for entry in all_encounters:
    patient_ref = entry['resource'].get('subject', {}).get('reference', '')
    patient_id = patient_ref.split('/')[-1] if '/' in patient_ref else ''
    if patient_id in ami_patient_ids:
        filtered_encounters.append(entry)

print(f"✅ 過濾後: {len(filtered_encounters)} 筆 AMI病人的 Encounters")

# 步驟4: 檢查每個encounter的診斷和死亡記錄
ami_patients_set = set()
ami_deaths_set = set()

ami_icd_codes = ['I21.0', 'I21.1', 'I21.2', 'I21.9', 'I21', 'I22']

for entry in filtered_encounters:
    encounter = entry['resource']
    encounter_id = encounter['id']
    patient_ref = encounter.get('subject', {}).get('reference', '')
    patient_id = patient_ref.split('/')[-1] if '/' in patient_ref else ''
    
    # 檢查 Condition (AMI 診斷)
    cond_response = requests.get(f"{base_url}/Condition", params={
        'encounter': f"Encounter/{encounter_id}",
        '_count': 10
    })
    
    has_ami = False
    if cond_response.status_code == 200:
        conditions = cond_response.json().get('entry', [])
        for cond_entry in conditions:
            condition = cond_entry['resource']
            codings = condition.get('code', {}).get('coding', [])
            for coding in codings:
                code = coding.get('code', '')
                if any(code.startswith(ami_code) for ami_code in ami_icd_codes):
                    has_ami = True
                    print(f"  ✅ {patient_id} - Encounter/{encounter_id}: 診斷 {code}")
                    break
            if has_ami:
                break
    
    if has_ami:
        ami_patients_set.add(patient_id)
        
        # 檢查死亡記錄 (Observation)
        obs_response = requests.get(f"{base_url}/Observation", params={
            'encounter': f"Encounter/{encounter_id}",
            'code': 'death',
            '_count': 10
        })
        
        if obs_response.status_code == 200:
            observations = obs_response.json().get('entry', [])
            for obs_entry in observations:
                observation = obs_entry['resource']
                value = observation.get('valueString', '')
                if value == 'deceased':
                    ami_deaths_set.add(patient_id)
                    print(f"  💀 {patient_id} - 死亡記錄")

print(f"\n📊 指標-17 計算結果:")
print(f"  分母 (AMI病人數): {len(ami_patients_set)}")
print(f"  分子 (死亡人數): {len(ami_deaths_set)}")
if len(ami_patients_set) > 0:
    rate = (len(ami_deaths_set) / len(ami_patients_set)) * 100
    print(f"  比率: {rate:.2f}%")
    print(f"  預期: 16.67% (1/6)")
else:
    print(f"  比率: 0.00%")

print("\n" + "="*70)
print("🔍 驗證指標-18: 失智症安寧療護利用率")
print("="*70)

dementia_patient_ids = outcome_patient_ids[6:]  # TW20007-TW20012
print(f"\n✅ 失智症病人ID範圍: {dementia_patient_ids[0]} - {dementia_patient_ids[-1]}")

# 過濾出失智症病人的encounters
filtered_encounters = []
for entry in all_encounters:
    patient_ref = entry['resource'].get('subject', {}).get('reference', '')
    patient_id = patient_ref.split('/')[-1] if '/' in patient_ref else ''
    if patient_id in dementia_patient_ids:
        filtered_encounters.append(entry)

print(f"✅ 過濾後: {len(filtered_encounters)} 筆失智症病人的 Encounters")

# 檢查失智症診斷和安寧療護
dementia_patients_set = set()
hospice_patients_set = set()

dementia_icd_codes = ['F00', 'F01', 'F02', 'F03', 'G30']
hospice_codes = ['05023C', '05024C', '05025C']

for entry in filtered_encounters:
    encounter = entry['resource']
    encounter_id = encounter['id']
    patient_ref = encounter.get('subject', {}).get('reference', '')
    patient_id = patient_ref.split('/')[-1] if '/' in patient_ref else ''
    
    # 檢查 Condition (失智症診斷)
    cond_response = requests.get(f"{base_url}/Condition", params={
        'encounter': f"Encounter/{encounter_id}",
        '_count': 10
    })
    
    has_dementia = False
    if cond_response.status_code == 200:
        conditions = cond_response.json().get('entry', [])
        for cond_entry in conditions:
            condition = cond_entry['resource']
            codings = condition.get('code', {}).get('coding', [])
            for coding in codings:
                code = coding.get('code', '')
                if any(code.startswith(dem_code) for dem_code in dementia_icd_codes):
                    has_dementia = True
                    print(f"  ✅ {patient_id} - Encounter/{encounter_id}: 診斷 {code}")
                    break
            if has_dementia:
                break
    
    if has_dementia:
        dementia_patients_set.add(patient_id)
        
        # 檢查安寧療護 Procedure
        proc_response = requests.get(f"{base_url}/Procedure", params={
            'encounter': f"Encounter/{encounter_id}",
            '_count': 10
        })
        
        if proc_response.status_code == 200:
            procedures = proc_response.json().get('entry', [])
            for proc_entry in procedures:
                procedure = proc_entry['resource']
                codings = procedure.get('code', {}).get('coding', [])
                for coding in codings:
                    code = coding.get('code', '')
                    if code in hospice_codes:
                        hospice_patients_set.add(patient_id)
                        print(f"  🏥 {patient_id} - 安寧療護代碼 {code}")

print(f"\n📊 指標-18 計算結果:")
print(f"  分母 (失智症病人數): {len(dementia_patients_set)}")
print(f"  分子 (接受安寧療護人數): {len(hospice_patients_set)}")
if len(dementia_patients_set) > 0:
    rate = (len(hospice_patients_set) / len(dementia_patients_set)) * 100
    print(f"  比率: {rate:.2f}%")
    print(f"  預期: 66.67% (4/6)")
else:
    print(f"  比率: 0.00%")

print("\n" + "="*70)
print("✅ CQL邏輯驗證完成")
print("="*70)
