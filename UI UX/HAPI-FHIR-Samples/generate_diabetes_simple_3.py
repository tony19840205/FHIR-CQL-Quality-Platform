"""
生成3個簡單的糖尿病患者用於測試indicator-07
- 糖尿病診斷（E11.9）
- 糖尿病用藥（ATC A10）
- HbA1c檢驗（LOINC 4548-4）
"""

import json
from datetime import datetime, timedelta

# 病患ID範圍: TW00400-TW00402
START_ID = 400

def generate_bundle():
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": []
    }
    
    for i in range(3):
        patient_id = START_ID + i
        patient_id_str = f"TW{patient_id:05d}"
        
        # 1. Patient
        patient = {
            "resourceType": "Patient",
            "id": patient_id_str,
            "identifier": [{
                "system": "https://www.nhi.gov.tw/",
                "value": patient_id_str
            }],
            "name": [{
                "text": f"糖尿病測試患者{patient_id}",
                "family": f"Test{patient_id}"
            }],
            "gender": "male",
            "birthDate": "1970-01-01"
        }
        bundle['entry'].append({
            "resource": patient,
            "request": {"method": "PUT", "url": f"Patient/{patient_id_str}"}
        })
        
        # 2. Encounter (門診)
        enc_id = f"{patient_id_str}-dm-test"
        encounter = {
            "resourceType": "Encounter",
            "id": enc_id,
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "門診"
            },
            "subject": {"reference": f"Patient/{patient_id_str}"},
            "period": {
                "start": "2025-11-15T10:00:00",
                "end": "2025-11-15T11:00:00"
            }
        }
        bundle['entry'].append({
            "resource": encounter,
            "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}
        })
        
        # 3. Condition (糖尿病 E11.9)
        cond_id = f"{patient_id_str}-dm-diag"
        condition = {
            "resourceType": "Condition",
            "id": cond_id,
            "clinicalStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                    "code": "active"
                }]
            },
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10",
                    "code": "E11.9",
                    "display": "Type 2 diabetes mellitus without complications"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id_str}"},
            "encounter": {"reference": f"Encounter/{enc_id}"}
        }
        bundle['entry'].append({
            "resource": condition,
            "request": {"method": "PUT", "url": f"Condition/{cond_id}"}
        })
        
        # 4. MedicationRequest (Metformin, ATC A10BA02)
        med_id = f"{patient_id_str}-metformin"
        medication = {
            "resourceType": "MedicationRequest",
            "id": med_id,
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [
                    {
                        "system": "https://www.nhi.gov.tw/medication",
                        "code": "AC456781AA",
                        "display": "Metformin"
                    },
                    {
                        "system": "http://www.whocc.no/atc",
                        "code": "A10BA02",
                        "display": "Metformin"
                    }
                ]
            },
            "subject": {"reference": f"Patient/{patient_id_str}"},
            "encounter": {"reference": f"Encounter/{enc_id}"},
            "authoredOn": "2025-11-15T10:30:00"
        }
        bundle['entry'].append({
            "resource": medication,
            "request": {"method": "PUT", "url": f"MedicationRequest/{med_id}"}
        })
        
        # 5. Observation (HbA1c, LOINC 4548-4)
        obs_id = f"{patient_id_str}-hba1c"
        observation = {
            "resourceType": "Observation",
            "id": obs_id,
            "status": "final",
            "category": [{
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                    "code": "laboratory"
                }]
            }],
            "code": {
                "coding": [{
                    "system": "http://loinc.org",
                    "code": "4548-4",
                    "display": "Hemoglobin A1c/Hemoglobin.total in Blood"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id_str}"},
            "effectiveDateTime": "2025-11-15T09:00:00",
            "valueQuantity": {
                "value": 7.5,
                "unit": "%",
                "system": "http://unitsofmeasure.org",
                "code": "%"
            }
        }
        bundle['entry'].append({
            "resource": observation,
            "request": {"method": "PUT", "url": f"Observation/{obs_id}"}
        })
    
    return bundle

# 生成並儲存
bundle = generate_bundle()

with open('diabetes_simple_3.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print("✅ 生成完成！")
print(f"📊 資源統計:")
print(f"  - Patient: 3")
print(f"  - Encounter: 3")
print(f"  - Condition: 3 (E11.9)")
print(f"  - MedicationRequest: 3 (ATC A10BA02)")
print(f"  - Observation: 3 (LOINC 4548-4, HbA1c)")
print(f"  - 總計: 15 個資源")
print(f"\n預期結果: indicator-07 = 100% (3/3)")
