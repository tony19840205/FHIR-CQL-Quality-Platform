"""
生成46個手術品質指標測試病人數據 (TW10001-TW10046)
專注於6個簡單指標: 12, 14, 15-1, 15-2, 16, 19
"""
import json
import uuid
from datetime import datetime, timedelta
import random

# 使用新的ID範圍避免與現有250筆encounter衝突
START_ID = 10001
PATIENT_COUNT = 46

# ICD-10 手術相關診斷代碼
DIAGNOSIS_CODES = {
    'clean_surgery': ['Z98.890', 'Z48.815'],  # 清淨手術後狀態
    'uterine_fibroid': ['D25.0', 'D25.1', 'D25.2', 'D25.9'],  # 子宮肌瘤
    'knee_replacement': ['M17.0', 'M17.1', 'M17.9'],  # 膝骨關節炎
    'surgical_wound_infection': ['T81.4', 'T81.40XA', 'T81.41XA'],  # 手術傷口感染
}

# ICD-10-PCS 手術代碼
PROCEDURE_CODES = {
    'clean_surgery': ['0W9F30Z', '0W9F40Z'],  # 清淨手術示例
    'uterine_fibroid_surgery': ['0UTB4ZZ', '0UT90ZZ'],  # 子宮肌瘤切除術
    'knee_arthroplasty_partial': ['0SRC0JZ', '0SRD0JZ'],  # 部分膝關節置換
    'knee_arthroplasty_total': ['0SRC069', '0SRD069'],  # 全膝關節置換
    'inpatient_surgery': ['0DBJ4ZZ', '0FBG4ZZ'],  # 住院手術示例
}

# LOINC codes for observations
LOINC_CODES = {
    'infection_marker': '26464-8',  # WBC
    'surgical_site_assessment': '72170-4',  # Surgical site assessment
}

def generate_patient(patient_id):
    """生成Patient資源"""
    return {
        "resourceType": "Patient",
        "id": f"TW{patient_id}",
        "identifier": [
            {
                "system": "http://www.moi.gov.tw/",
                "value": f"TW{patient_id}"
            }
        ],
        "name": [{"family": "測試", "given": [f"病人{patient_id}"]}],
        "gender": random.choice(["male", "female"]),
        "birthDate": f"{random.randint(1940, 2000)}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}"
    }

def generate_encounter(patient_id, encounter_num, class_code='IMP', start_date=None, end_date=None):
    """生成Encounter資源"""
    if not start_date:
        start_date = datetime(2025, 10, random.randint(1, 20))
    if not end_date:
        end_date = start_date + timedelta(days=random.randint(3, 10))
    
    encounter_id = f"ENC{patient_id}{encounter_num:02d}"
    
    return {
        "resourceType": "Encounter",
        "id": encounter_id,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": class_code,
            "display": "inpatient encounter" if class_code == "IMP" else "emergency"
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "period": {
            "start": start_date.strftime("%Y-%m-%dT08:00:00Z"),
            "end": end_date.strftime("%Y-%m-%dT10:00:00Z")
        }
    }

def generate_procedure(patient_id, procedure_num, encounter_id, code, code_system="http://hl7.org/fhir/sid/icd-10-pcs"):
    """生成Procedure資源"""
    procedure_id = f"PROC{patient_id}{procedure_num:02d}"
    
    return {
        "resourceType": "Procedure",
        "id": procedure_id,
        "status": "completed",
        "code": {
            "coding": [{
                "system": code_system,
                "code": code,
                "display": f"Surgical Procedure {code}"
            }]
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"},
        "performedDateTime": "2025-10-15T10:00:00Z"
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

def generate_medication_request(patient_id, med_num, encounter_id, medication_name, days):
    """生成MedicationRequest資源 (抗生素)"""
    med_id = f"MED{patient_id}{med_num:02d}"
    
    return {
        "resourceType": "MedicationRequest",
        "id": med_id,
        "status": "completed",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [{
                "system": "http://www.whocc.no/atc",
                "code": "J01",
                "display": medication_name
            }]
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"},
        "authoredOn": "2025-10-15T10:00:00Z",
        "dosageInstruction": [{
            "timing": {
                "repeat": {
                    "frequency": 1,
                    "period": 1,
                    "periodUnit": "d",
                    "boundsDuration": {
                        "value": days,
                        "unit": "days",
                        "system": "http://unitsofmeasure.org",
                        "code": "d"
                    }
                }
            }
        }]
    }

def generate_observation(patient_id, obs_num, encounter_id, loinc_code, value):
    """生成Observation資源"""
    obs_id = f"OBS{patient_id}{obs_num:02d}"
    
    return {
        "resourceType": "Observation",
        "id": obs_id,
        "status": "final",
        "code": {
            "coding": [{
                "system": "http://loinc.org",
                "code": loinc_code
            }]
        },
        "subject": {"reference": f"Patient/TW{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"},
        "effectiveDateTime": "2025-10-16T10:00:00Z",
        "valueString": value
    }

def create_bundle():
    """創建完整的Bundle"""
    entries = []
    
    # 指標12: 清淨手術抗生素超過3天使用率 (10病人: 4超過3天, 6正常)
    for i in range(1, 11):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id)
        encounter = generate_encounter(patient_id, 1, 'IMP')
        procedure = generate_procedure(patient_id, 1, encounter['id'], 
                                       random.choice(PROCEDURE_CODES['clean_surgery']))
        condition = generate_condition(patient_id, 1, encounter['id'], 
                                       random.choice(DIAGNOSIS_CODES['clean_surgery']))
        
        # 4個病人抗生素超過3天
        antibiotic_days = 5 if i <= 4 else 2
        medication = generate_medication_request(patient_id, 1, encounter['id'], 
                                                 "Antibiotic", antibiotic_days)
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}},
            {"resource": procedure, "request": {"method": "PUT", "url": f"Procedure/{procedure['id']}"}},
            {"resource": condition, "request": {"method": "PUT", "url": f"Condition/{condition['id']}"}},
            {"resource": medication, "request": {"method": "PUT", "url": f"MedicationRequest/{medication['id']}"}}
        ])
    
    # 指標14: 子宮肌瘤手術14天再入院率 (8病人: 2再入院, 6正常)
    for i in range(11, 19):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id)
        patient['gender'] = 'female'  # 子宮手術限女性
        
        # 第一次入院 (手術)
        first_admission = datetime(2025, 10, random.randint(1, 10))
        encounter1 = generate_encounter(patient_id, 1, 'IMP', first_admission, 
                                        first_admission + timedelta(days=3))
        procedure = generate_procedure(patient_id, 1, encounter1['id'], 
                                       random.choice(PROCEDURE_CODES['uterine_fibroid_surgery']))
        condition = generate_condition(patient_id, 1, encounter1['id'], 
                                       random.choice(DIAGNOSIS_CODES['uterine_fibroid']))
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter1, "request": {"method": "PUT", "url": f"Encounter/{encounter1['id']}"}},
            {"resource": procedure, "request": {"method": "PUT", "url": f"Procedure/{procedure['id']}"}},
            {"resource": condition, "request": {"method": "PUT", "url": f"Condition/{condition['id']}"}}
        ])
        
        # 2個病人14天內再入院
        if i <= 12:
            readmission_date = first_admission + timedelta(days=random.randint(5, 13))
            encounter2 = generate_encounter(patient_id, 2, 'IMP', readmission_date, 
                                           readmission_date + timedelta(days=2))
            entries.append(
                {"resource": encounter2, "request": {"method": "PUT", "url": f"Encounter/{encounter2['id']}"}}
            )
    
    # 指標15-1: 部分膝關節置換90天深部感染率 (6病人: 1感染, 5正常)
    for i in range(19, 25):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id)
        encounter = generate_encounter(patient_id, 1, 'IMP')
        procedure = generate_procedure(patient_id, 1, encounter['id'], 
                                       random.choice(PROCEDURE_CODES['knee_arthroplasty_partial']))
        condition = generate_condition(patient_id, 1, encounter['id'], 
                                       random.choice(DIAGNOSIS_CODES['knee_replacement']))
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}},
            {"resource": procedure, "request": {"method": "PUT", "url": f"Procedure/{procedure['id']}"}},
            {"resource": condition, "request": {"method": "PUT", "url": f"Condition/{condition['id']}"}}
        ])
        
        # 1個病人90天內深部感染
        if i == 19:
            infection_condition = generate_condition(patient_id, 2, encounter['id'], 'T84.54XA')
            entries.append(
                {"resource": infection_condition, "request": {"method": "PUT", "url": f"Condition/{infection_condition['id']}"}}
            )
    
    # 指標15-2: 全膝關節置換90天深部感染率 (6病人: 1感染, 5正常)
    for i in range(25, 31):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id)
        encounter = generate_encounter(patient_id, 1, 'IMP')
        procedure = generate_procedure(patient_id, 1, encounter['id'], 
                                       random.choice(PROCEDURE_CODES['knee_arthroplasty_total']))
        condition = generate_condition(patient_id, 1, encounter['id'], 
                                       random.choice(DIAGNOSIS_CODES['knee_replacement']))
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}},
            {"resource": procedure, "request": {"method": "PUT", "url": f"Procedure/{procedure['id']}"}},
            {"resource": condition, "request": {"method": "PUT", "url": f"Condition/{condition['id']}"}}
        ])
        
        # 1個病人90天內深部感染
        if i == 25:
            infection_condition = generate_condition(patient_id, 2, encounter['id'], 'T84.54XA')
            entries.append(
                {"resource": infection_condition, "request": {"method": "PUT", "url": f"Condition/{infection_condition['id']}"}}
            )
    
    # 指標16: 住院手術傷口感染率 (8病人: 2感染, 6正常)
    for i in range(31, 39):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id)
        encounter = generate_encounter(patient_id, 1, 'IMP')
        procedure = generate_procedure(patient_id, 1, encounter['id'], 
                                       random.choice(PROCEDURE_CODES['inpatient_surgery']))
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}},
            {"resource": procedure, "request": {"method": "PUT", "url": f"Procedure/{procedure['id']}"}}
        ])
        
        # 2個病人傷口感染
        if i <= 32:
            infection_condition = generate_condition(patient_id, 1, encounter['id'], 
                                                     random.choice(DIAGNOSIS_CODES['surgical_wound_infection']))
            observation = generate_observation(patient_id, 1, encounter['id'], 
                                               LOINC_CODES['surgical_site_assessment'], 
                                               "Wound infection present")
            entries.extend([
                {"resource": infection_condition, "request": {"method": "PUT", "url": f"Condition/{infection_condition['id']}"}},
                {"resource": observation, "request": {"method": "PUT", "url": f"Observation/{observation['id']}"}}
            ])
    
    # 指標19: 清淨手術傷口感染率 (8病人: 1感染, 7正常)
    for i in range(39, 47):
        patient_id = START_ID + i - 1
        patient = generate_patient(patient_id)
        encounter = generate_encounter(patient_id, 1, 'IMP')
        procedure = generate_procedure(patient_id, 1, encounter['id'], 
                                       random.choice(PROCEDURE_CODES['clean_surgery']))
        condition = generate_condition(patient_id, 1, encounter['id'], 
                                       random.choice(DIAGNOSIS_CODES['clean_surgery']))
        
        entries.extend([
            {"resource": patient, "request": {"method": "PUT", "url": f"Patient/TW{patient_id}"}},
            {"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}},
            {"resource": procedure, "request": {"method": "PUT", "url": f"Procedure/{procedure['id']}"}},
            {"resource": condition, "request": {"method": "PUT", "url": f"Condition/{condition['id']}"}}
        ])
        
        # 1個病人傷口感染
        if i == 39:
            infection_condition = generate_condition(patient_id, 2, encounter['id'], 
                                                     random.choice(DIAGNOSIS_CODES['surgical_wound_infection']))
            observation = generate_observation(patient_id, 1, encounter['id'], 
                                               LOINC_CODES['surgical_site_assessment'], 
                                               "Wound infection present")
            entries.extend([
                {"resource": infection_condition, "request": {"method": "PUT", "url": f"Condition/{infection_condition['id']}"}},
                {"resource": observation, "request": {"method": "PUT", "url": f"Observation/{observation['id']}"}}
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
    output_file = "surgical_quality_46_bundle.json"
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
    print(f"   指標-12 (清淨手術抗生素超3天): 4/10 = 40%")
    print(f"   指標-14 (子宮肌瘤14天再入院): 2/8 = 25%")
    print(f"   指標-15-1 (部分膝置換感染): 1/6 = 16.67%")
    print(f"   指標-15-2 (全膝置換感染): 1/6 = 16.67%")
    print(f"   指標-16 (住院手術傷口感染): 2/8 = 25%")
    print(f"   指標-19 (清淨手術傷口感染): 1/8 = 12.5%")
