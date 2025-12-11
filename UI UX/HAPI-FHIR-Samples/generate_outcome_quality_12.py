"""
生成12個結果品質指標測試病人數據 (TW20001-TW20012)
指標-17: 急性心肌梗塞死亡率 (6病人)
指標-18: 失智症安寧療護利用率 (6病人)
"""
import json
from datetime import datetime, timedelta
import random

# 使用新的ID範圍避免與現有數據衝突
START_ID = 20001
PATIENT_COUNT = 12

# ICD-10診斷代碼
DIAGNOSIS_CODES = {
    'ami': ['I21.0', 'I21.1', 'I21.2', 'I21.9'],  # 急性心肌梗塞
    'dementia': ['F00', 'F01', 'F02', 'F03', 'G30'],  # 失智症
}

# 安寧療護醫令代碼
HOSPICE_CODES = ['05023C', '05024C', '05025C']

def generate_patient(patient_id, age_range=(60, 90)):
    """生成Patient資源"""
    birth_year = 2025 - random.randint(*age_range)
    return {
        "resourceType": "Patient",
        "id": f"TW{patient_id}",
        "identifier": [{
            "system": "http://www.moi.gov.tw/",
            "value": f"TW{patient_id}"
        }],
        "name": [{"family": "測試", "given": [f"結果{patient_id}"]}],
        "gender": random.choice(["male", "female"]),
        "birthDate": f"{birth_year}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}"
    }

def generate_encounter(patient_id, encounter_num, class_code='IMP', start_date=None, end_date=None):
    """生成Encounter資源"""
    if not start_date:
        start_date = datetime(2024, 10, random.randint(1, 25))  # 🔧 改為2024-Q4
    if not end_date:
        end_date = start_date + timedelta(days=random.randint(5, 14))
    
    encounter_id = f"ENC{patient_id}{encounter_num:02d}"
    
    return {
        "resourceType": "Encounter",
        "id": encounter_id,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": class_code,
            "display": "inpatient encounter" if class_code == "IMP" else "ambulatory"
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "period": {
            "start": start_date.strftime("%Y-%m-%dT08:00:00Z"),
            "end": end_date.strftime("%Y-%m-%dT18:00:00Z")
        }
    }

def generate_condition(patient_id, condition_num, encounter_id, code):
    """生成Condition資源"""
    condition_id = f"COND{patient_id}{condition_num:02d}"
    
    return {
        "resourceType": "Condition",
        "id": condition_id,
        "clinicalStatus": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                "code": "active"
            }]
        },
        "code": {
            "coding": [{
                "system": "http://hl7.org/fhir/sid/icd-10",
                "code": code,
                "display": f"Diagnosis {code}"
            }]
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"}
    }

def generate_observation_death(patient_id, obs_num, encounter_id):
    """生成死亡記錄Observation"""
    obs_id = f"OBS{patient_id}{obs_num:02d}"
    
    return {
        "resourceType": "Observation",
        "id": obs_id,
        "status": "final",
        "code": {
            "coding": [{
                "system": "http://loinc.org",
                "code": "69453-9",
                "display": "Cause of Death"
            }]
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"},
        "effectiveDateTime": "2025-10-20T15:00:00Z",
        "valueCodeableConcept": {
            "coding": [{
                "system": "http://hl7.org/fhir/sid/icd-10",
                "code": "I21.9",
                "display": "Acute myocardial infarction, unspecified"
            }]
        }
    }

def generate_procedure(patient_id, proc_num, encounter_id, code):
    """生成Procedure資源(安寧療護)"""
    proc_id = f"PROC{patient_id}{proc_num:02d}"
    
    return {
        "resourceType": "Procedure",
        "id": proc_id,
        "status": "completed",
        "code": {
            "coding": [{
                "system": "http://www.nhi.gov.tw/",
                "code": code,
                "display": f"Hospice Care {code}"
            }]
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"},
        "performedDateTime": "2025-10-15T10:00:00Z"
    }

def create_bundle():
    """創建完整的Bundle"""
    entries = []
    
    # ========== 指標-17: 急性心肌梗塞死亡率 (6病人: 5存活, 1死亡) ==========
    for i in range(1, 7):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id)
        encounter = generate_encounter(patient_id, 1, 'IMP')
        condition = generate_condition(patient_id, 1, encounter['id'], 
                                       random.choice(DIAGNOSIS_CODES['ami']))
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}},
            {"resource": condition, "request": {"method": "PUT", "url": f"Condition/{condition['id']}"}}
        ])
        
        # 第6個病人死亡
        if i == 6:
            death_obs = generate_observation_death(patient_id, 1, encounter['id'])
            entries.append(
                {"resource": death_obs, "request": {"method": "PUT", "url": f"Observation/{death_obs['id']}"}}
            )
    
    # ========== 指標-18: 失智症安寧療護利用率 (6病人: 4有安寧, 2無) ==========
    for i in range(7, 13):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id, age_range=(70, 95))  # 失智症通常較老
        
        # 主要住院encounter
        encounter1 = generate_encounter(patient_id, 1, 'IMP')
        condition = generate_condition(patient_id, 1, encounter1['id'], 
                                       random.choice(DIAGNOSIS_CODES['dementia']))
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter1, "request": {"method": "PUT", "url": f"Encounter/{encounter1['id']}"}},
            {"resource": condition, "request": {"method": "PUT", "url": f"Condition/{condition['id']}"}}
        ])
        
        # 前4個病人有安寧療護
        if i <= 10:
            # 安寧療護encounter
            hospice_date = datetime(2024, 10, random.randint(15, 28))  # 🔧 改為2024-Q4
            encounter2 = generate_encounter(patient_id, 2, 'AMB', 
                                           hospice_date, 
                                           hospice_date + timedelta(days=1))
            
            # 安寧療護Procedure
            procedure = generate_procedure(patient_id, 1, encounter2['id'], 
                                          random.choice(HOSPICE_CODES))
            
            entries.extend([
                {"resource": encounter2, "request": {"method": "PUT", "url": f"Encounter/{encounter2['id']}"}},
                {"resource": procedure, "request": {"method": "PUT", "url": f"Procedure/{procedure['id']}"}}
            ])
    
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": entries
    }
    
    return bundle

if __name__ == "__main__":
    bundle = create_bundle()
    
    # 儲存到檔案
    output_file = "outcome_quality_12_bundle.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, indent=2, ensure_ascii=False)
    
    # 統計資訊
    resource_counts = {}
    for entry in bundle['entry']:
        resource_type = entry['resource']['resourceType']
        resource_counts[resource_type] = resource_counts.get(resource_type, 0) + 1
    
    print(f"✅ 成功生成Bundle: {output_file}")
    print(f"📊 總資源數: {len(bundle['entry'])}")
    print(f"📋 資源明細:")
    for resource_type, count in sorted(resource_counts.items()):
        print(f"   - {resource_type}: {count}")
    print(f"\n👥 病人ID範圍: TW{START_ID} - TW{START_ID + PATIENT_COUNT - 1}")
    print(f"\n預期指標結果:")
    print(f"   指標-17 (急性心肌梗塞死亡率): 1/6 = 16.67%")
    print(f"   指標-18 (失智症安寧療護利用率): 4/6 = 66.67%")
