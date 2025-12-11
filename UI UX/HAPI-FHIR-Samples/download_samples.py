"""
從 HAPI FHIR 下載傳染病樣本數據
"""

import requests
import json
from datetime import datetime

HAPI_SERVER = "http://hapi.fhir.org/baseR4"

# 5種傳染病的 ICD-10 代碼
DISEASE_CODES = {
    'covid19': ['U07.1', 'U07.2'],
    'influenza': ['J09', 'J10.0', 'J10.1', 'J11.0', 'J11.1'],
    'conjunctivitis': ['H10.0', 'H10.1', 'H10.2', 'H10.3'],
    'enterovirus': ['A87.0', 'B08.4', 'B08.5'],
    'diarrhea': ['A00.0', 'A02.0', 'A04.0', 'A08.0', 'A09']
}

def download_condition_samples(disease_type, codes, count=5):
    """下載 Condition 樣本"""
    print(f"\n下載 {disease_type} 樣本...")
    
    all_resources = []
    patient_ids = set()
    
    for code in codes:
        try:
            # 使用完整系統URL格式查詢
            url = f"{HAPI_SERVER}/Condition?code=http://hl7.org/fhir/sid/icd-10|{code}&_count={count}"
            response = requests.get(url, timeout=30)
            
            if response.status_code == 200:
                bundle = response.json()
                if bundle.get('entry'):
                    print(f"  ✓ {code}: 找到 {len(bundle['entry'])} 筆")
                    for entry in bundle['entry'][:count]:
                        condition = entry['resource']
                        all_resources.append({
                            'resourceType': 'Condition',
                            'resource': condition
                        })
                        
                        # 記錄患者ID
                        if 'subject' in condition and 'reference' in condition['subject']:
                            patient_ref = condition['subject']['reference']
                            patient_id = patient_ref.split('/')[-1]
                            patient_ids.add(patient_id)
                else:
                    print(f"  - {code}: 無資料")
            else:
                print(f"  ✗ {code}: HTTP {response.status_code}")
                
        except Exception as e:
            print(f"  ✗ {code}: {str(e)}")
    
    return all_resources, patient_ids

def download_patient_data(patient_ids):
    """下載患者資料"""
    print(f"\n下載 {len(patient_ids)} 位患者資料...")
    
    patients = []
    for patient_id in list(patient_ids)[:10]:  # 最多10位
        try:
            url = f"{HAPI_SERVER}/Patient/{patient_id}"
            response = requests.get(url, timeout=30)
            
            if response.status_code == 200:
                patient = response.json()
                patients.append({
                    'resourceType': 'Patient',
                    'resource': patient
                })
                print(f"  ✓ Patient/{patient_id}")
        except Exception as e:
            print(f"  ✗ Patient/{patient_id}: {str(e)}")
    
    return patients

def save_samples(disease_type, conditions, patients):
    """保存樣本到文件"""
    
    sample_data = {
        'downloaded_at': datetime.now().isoformat(),
        'disease_type': disease_type,
        'total_conditions': len(conditions),
        'total_patients': len(patients),
        'conditions': conditions,
        'patients': patients
    }
    
    filename = f"{disease_type}_samples.json"
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(sample_data, f, ensure_ascii=False, indent=2)
    
    print(f"✓ 已保存到: {filename}")
    return filename

def main():
    print("=" * 60)
    print("從 HAPI FHIR 下載傳染病樣本數據")
    print("=" * 60)
    
    all_patients = {}
    
    for disease_type, codes in DISEASE_CODES.items():
        conditions, patient_ids = download_condition_samples(disease_type, codes)
        
        if patient_ids:
            patients = download_patient_data(patient_ids)
            
            # 合併患者資料（避免重複）
            for patient_entry in patients:
                patient_id = patient_entry['resource']['id']
                if patient_id not in all_patients:
                    all_patients[patient_id] = patient_entry
            
            # 保存樣本
            if conditions:
                save_samples(disease_type, conditions, patients)
        
        print(f"完成 {disease_type}")
    
    # 保存格式參考摘要
    print("\n生成格式參考摘要...")
    if all_patients:
        sample_patient = list(all_patients.values())[0]['resource']
        
        format_ref = {
            'patient_format': {
                'id': sample_patient.get('id'),
                'identifier': sample_patient.get('identifier', []),
                'name': sample_patient.get('name', []),
                'gender': sample_patient.get('gender'),
                'birthDate': sample_patient.get('birthDate'),
                'address': sample_patient.get('address', [])
            }
        }
        
        with open('format_reference.json', 'w', encoding='utf-8') as f:
            json.dump(format_ref, f, ensure_ascii=False, indent=2)
        
        print("✓ 已保存格式參考: format_reference.json")
    
    print("\n" + "=" * 60)
    print("下載完成！")
    print("=" * 60)

if __name__ == '__main__':
    main()
