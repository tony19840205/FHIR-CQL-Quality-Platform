#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
門診品質指標測試資料生成器 (53位病患)
涵蓋指標: 04-慢性處方箋, 05-多重用藥, 06-小兒氣喘急診, 07-糖尿病HbA1c, 08-同日再就診
病患編號: TW00309-TW00361
時間範圍: 2025 Q4 (10-12月)
"""

import json
import random
from datetime import datetime, timedelta

# ========== 配置參數 ==========
START_PATIENT_ID = 309
TOTAL_PATIENTS = 53
QUARTER_START = datetime(2025, 10, 1)
QUARTER_END = datetime(2025, 12, 31)

# ========== 病患分組策略 ==========
# 1. 慢性病患者 (20人): TW00309-TW00328
# 2. 糖尿病患者 (15人): TW00329-TW00343
# 3. 兒童氣喘患者 (10人): TW00344-TW00353
# 4. 多重用藥患者 (5人): TW00354-TW00358
# 5. 一般門診患者 (3人): TW00359-TW00361

# ========== 藥品資料庫 ==========
# 慢性病用藥 (至少28天)
chronic_medications = [
    {'code': 'C09AA01', 'name': 'Captopril', 'display': '降血壓藥(ACEI)'},
    {'code': 'C10AA01', 'name': 'Simvastatin', 'display': '降血脂藥(Statin)'},
    {'code': 'A10BA02', 'name': 'Metformin', 'display': '降血糖藥(雙胍類)'},
    {'code': 'N06AB06', 'name': 'Sertraline', 'display': '抗憂鬱藥(SSRI)'},
    {'code': 'N05CF02', 'name': 'Zolpidem', 'display': '安眠藥'},
]

# 糖尿病用藥 (ATC A10*)
diabetes_medications = [
    {'code': 'A10BA02', 'name': 'Metformin', 'display': '雙胍類降血糖藥'},
    {'code': 'A10BB01', 'name': 'Glibenclamide', 'display': '磺醯尿素類'},
    {'code': 'A10BH01', 'name': 'Sitagliptin', 'display': 'DPP-4抑制劑'},
    {'code': 'A10AB01', 'name': 'Insulin (human)', 'display': '胰島素'},
]

# 一般常用藥品 (用於多重用藥)
common_medications = [
    {'code': 'N02BE01', 'name': 'Paracetamol', 'display': '止痛退燒藥'},
    {'code': 'M01AE01', 'name': 'Ibuprofen', 'display': '消炎止痛藥'},
    {'code': 'A02BC01', 'name': 'Omeprazole', 'display': '胃藥(PPI)'},
    {'code': 'R06AX13', 'name': 'Loratadine', 'display': '抗組織胺'},
    {'code': 'J01CA04', 'name': 'Amoxicillin', 'display': '抗生素'},
    {'code': 'C03CA01', 'name': 'Furosemide', 'display': '利尿劑'},
    {'code': 'C07AB02', 'name': 'Metoprolol', 'display': '乙型阻斷劑'},
    {'code': 'A11CC01', 'name': 'Vitamin D', 'display': '維生素D'},
    {'code': 'B01AC06', 'name': 'Aspirin', 'display': '阿斯匹靈'},
    {'code': 'N02AA01', 'name': 'Morphine', 'display': '嗎啡'},
    {'code': 'R03AC02', 'name': 'Salbutamol', 'display': '氣管擴張劑'},
    {'code': 'A12AA04', 'name': 'Calcium', 'display': '鈣片'},
]

# 氣喘用藥
asthma_medications = [
    {'code': 'R03AC02', 'name': 'Salbutamol', 'display': '短效氣管擴張劑'},
    {'code': 'R03BA01', 'name': 'Beclometasone', 'display': '吸入型類固醇'},
]

# ========== 輔助函數 ==========
def random_date(start, end):
    """生成隨機日期"""
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + timedelta(days=random_days)

def generate_patient(patient_id, age, gender='male'):
    """生成病患資源"""
    birth_date = datetime.now() - timedelta(days=age*365)
    return {
        "resourceType": "Patient",
        "id": f"TW{patient_id:05d}",
        "identifier": [{
            "system": "https://www.nhi.gov.tw/",
            "value": f"TW{patient_id:05d}"
        }],
        "name": [{
            "text": f"測試病患{patient_id:05d}",
            "family": f"Patient{patient_id:05d}"
        }],
        "gender": gender,
        "birthDate": birth_date.strftime('%Y-%m-%d')
    }

def generate_encounter(patient_id, enc_id, enc_type='AMB', date=None):
    """生成就診記錄"""
    if date is None:
        date = random_date(QUARTER_START, QUARTER_END)
    
    return {
        "resourceType": "Encounter",
        "id": enc_id,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": enc_type,
            "display": "急診" if enc_type == 'EMER' else "門診"
        },
        "subject": {
            "reference": f"Patient/TW{patient_id:05d}"
        },
        "period": {
            "start": date.isoformat(),
            "end": (date + timedelta(hours=1)).isoformat()
        },
        "serviceProvider": {
            "reference": "Organization/hospital-001"
        }
    }

def generate_condition(patient_id, cond_id, encounter_id, icd10_code, display):
    """生成診斷記錄"""
    return {
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
                "code": icd10_code,
                "display": display
            }]
        },
        "subject": {
            "reference": f"Patient/TW{patient_id:05d}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "recordedDate": datetime.now().isoformat()
    }

def generate_medication_request(patient_id, encounter_id, med_req_id, medication, days_supply=7, is_chronic=False):
    """生成藥物處方"""
    # 生成10碼健保代碼
    atc_code = medication['code']
    base_hash = hash(atc_code) % 100000
    nhi_code = f"AC{base_hash:05d}1AA"  # 口服藥
    
    # 慢性處方: 28-90天, 一般處方: 3-14天
    if is_chronic:
        days_supply = random.randint(28, 90)
    
    return {
        "resourceType": "MedicationRequest",
        "id": med_req_id,
        "status": "completed",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [
                {
                    "system": "https://www.nhi.gov.tw/medication",
                    "code": nhi_code,
                    "display": medication['display']
                },
                {
                    "system": "http://www.whocc.no/atc",
                    "code": atc_code,
                    "display": medication['display']
                }
            ],
            "text": medication['name']
        },
        "subject": {
            "reference": f"Patient/TW{patient_id:05d}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "authoredOn": datetime.now().isoformat(),
        "dosageInstruction": [{
            "text": f"口服,每日3次,共{days_supply}天",
            "timing": {
                "repeat": {
                    "boundsDuration": {
                        "value": days_supply,
                        "unit": "day",
                        "system": "http://unitsofmeasure.org",
                        "code": "d"
                    }
                }
            },
            "route": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "26643006",
                    "display": "Oral"
                }]
            }
        }],
        "dispenseRequest": {
            "expectedSupplyDuration": {
                "value": days_supply,
                "unit": "day",
                "system": "http://unitsofmeasure.org",
                "code": "d"
            }
        }
    }

def generate_observation_hba1c(patient_id, obs_id, encounter_id, value):
    """生成HbA1c檢驗結果"""
    return {
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
            }],
            "text": "HbA1c"
        },
        "subject": {
            "reference": f"Patient/TW{patient_id:05d}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "effectiveDateTime": random_date(QUARTER_START, QUARTER_END).isoformat(),
        "valueQuantity": {
            "value": value,
            "unit": "%",
            "system": "http://unitsofmeasure.org",
            "code": "%"
        }
    }

# ========== 主要生成邏輯 ==========
def generate_all_data():
    """生成所有測試資料"""
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": []
    }
    
    resource_counts = {
        'Patient': 0,
        'Encounter': 0,
        'Condition': 0,
        'MedicationRequest': 0,
        'Observation': 0
    }
    
    # 統計指標相關數據
    stats = {
        'chronic_prescriptions': 0,
        'total_prescriptions': 0,
        'poly_pharmacy_encounters': 0,
        'asthma_patients': 0,
        'asthma_ed_patients': 0,
        'diabetes_patients': 0,
        'diabetes_with_hba1c': 0,
        'same_day_revisits': 0
    }
    
    # ========== 1. 慢性病患者 (20人): TW00309-TW00328 ==========
    print("\n生成慢性病患者資料...")
    for i in range(20):
        patient_id = START_PATIENT_ID + i
        age = random.randint(50, 80)
        
        # Patient
        patient = generate_patient(patient_id, age)
        bundle['entry'].append({"resource": patient, "request": {"method": "PUT", "url": f"Patient/{patient['id']}"}})
        resource_counts['Patient'] += 1
        
        # 2-3次門診
        num_visits = random.randint(2, 3)
        for v in range(num_visits):
            enc_id = f"TW{patient_id:05d}-chronic-enc-{v+1}"
            encounter = generate_encounter(patient_id, enc_id, 'AMB')
            bundle['entry'].append({"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}})
            resource_counts['Encounter'] += 1
            
            # 診斷: 高血壓或糖尿病
            cond_id = f"TW{patient_id:05d}-chronic-cond-{v+1}"
            icd_code = random.choice(['I10', 'E11.9'])
            condition = generate_condition(patient_id, cond_id, enc_id, icd_code, '慢性病')
            bundle['entry'].append({"resource": condition, "request": {"method": "PUT", "url": f"Condition/{cond_id}"}})
            resource_counts['Condition'] += 1
            
            # 慢性處方 (28-90天)
            num_meds = random.randint(2, 4)
            for m in range(num_meds):
                med_req_id = f"TW{patient_id:05d}-chronic-med-{v+1}-{m+1}"
                medication = random.choice(chronic_medications)
                med_request = generate_medication_request(patient_id, enc_id, med_req_id, medication, is_chronic=True)
                bundle['entry'].append({"resource": med_request, "request": {"method": "PUT", "url": f"MedicationRequest/{med_req_id}"}})
                resource_counts['MedicationRequest'] += 1
                stats['chronic_prescriptions'] += 1
                stats['total_prescriptions'] += 1
    
    # ========== 2. 糖尿病患者 (15人): TW00329-TW00343 ==========
    print("生成糖尿病患者資料...")
    for i in range(15):
        patient_id = START_PATIENT_ID + 20 + i
        age = random.randint(45, 75)
        
        patient = generate_patient(patient_id, age)
        bundle['entry'].append({"resource": patient, "request": {"method": "PUT", "url": f"Patient/{patient['id']}"}})
        resource_counts['Patient'] += 1
        stats['diabetes_patients'] += 1
        
        # 2次門診
        for v in range(2):
            enc_id = f"TW{patient_id:05d}-dm-enc-{v+1}"
            encounter = generate_encounter(patient_id, enc_id, 'AMB')
            bundle['entry'].append({"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}})
            resource_counts['Encounter'] += 1
            
            # 糖尿病診斷 (E10-E11)
            cond_id = f"TW{patient_id:05d}-dm-cond-{v+1}"
            icd_code = random.choice(['E10.9', 'E11.9'])
            condition = generate_condition(patient_id, cond_id, enc_id, icd_code, '糖尿病')
            bundle['entry'].append({"resource": condition, "request": {"method": "PUT", "url": f"Condition/{cond_id}"}})
            resource_counts['Condition'] += 1
            
            # 糖尿病用藥 (ATC A10*)
            num_meds = random.randint(2, 3)
            for m in range(num_meds):
                med_req_id = f"TW{patient_id:05d}-dm-med-{v+1}-{m+1}"
                medication = random.choice(diabetes_medications)
                med_request = generate_medication_request(patient_id, enc_id, med_req_id, medication, days_supply=random.randint(7, 30))
                bundle['entry'].append({"resource": med_request, "request": {"method": "PUT", "url": f"MedicationRequest/{med_req_id}"}})
                resource_counts['MedicationRequest'] += 1
                stats['total_prescriptions'] += 1
        
        # 約70%的病患有HbA1c檢驗
        if random.random() < 0.7:
            obs_id = f"TW{patient_id:05d}-hba1c-obs"
            hba1c_value = round(random.uniform(6.5, 9.5), 1)
            observation = generate_observation_hba1c(patient_id, obs_id, f"TW{patient_id:05d}-dm-enc-1", hba1c_value)
            bundle['entry'].append({"resource": observation, "request": {"method": "PUT", "url": f"Observation/{obs_id}"}})
            resource_counts['Observation'] += 1
            stats['diabetes_with_hba1c'] += 1
    
    # ========== 3. 兒童氣喘患者 (10人): TW00344-TW00353 ==========
    print("生成兒童氣喘患者資料...")
    for i in range(10):
        patient_id = START_PATIENT_ID + 35 + i
        age = random.randint(5, 15)  # 兒童
        
        patient = generate_patient(patient_id, age)
        bundle['entry'].append({"resource": patient, "request": {"method": "PUT", "url": f"Patient/{patient['id']}"}})
        resource_counts['Patient'] += 1
        stats['asthma_patients'] += 1
        
        # 門診
        enc_id = f"TW{patient_id:05d}-asthma-enc"
        encounter = generate_encounter(patient_id, enc_id, 'AMB')
        bundle['entry'].append({"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}})
        resource_counts['Encounter'] += 1
        
        # 氣喘診斷 (J45*)
        cond_id = f"TW{patient_id:05d}-asthma-cond"
        icd_code = random.choice(['J45.0', 'J45.1', 'J45.9'])
        condition = generate_condition(patient_id, cond_id, enc_id, icd_code, '氣喘')
        bundle['entry'].append({"resource": condition, "request": {"method": "PUT", "url": f"Condition/{cond_id}"}})
        resource_counts['Condition'] += 1
        
        # 氣喘用藥
        for m, medication in enumerate(asthma_medications):
            med_req_id = f"TW{patient_id:05d}-asthma-med-{m+1}"
            med_request = generate_medication_request(patient_id, enc_id, med_req_id, medication, days_supply=14)
            bundle['entry'].append({"resource": med_request, "request": {"method": "PUT", "url": f"MedicationRequest/{med_req_id}"}})
            resource_counts['MedicationRequest'] += 1
            stats['total_prescriptions'] += 1
        
        # 30%的病患有急診記錄
        if random.random() < 0.3:
            ed_enc_id = f"TW{patient_id:05d}-asthma-ed"
            ed_encounter = generate_encounter(patient_id, ed_enc_id, 'EMER')
            bundle['entry'].append({"resource": ed_encounter, "request": {"method": "PUT", "url": f"Encounter/{ed_enc_id}"}})
            resource_counts['Encounter'] += 1
            
            # 急診診斷
            ed_cond_id = f"TW{patient_id:05d}-asthma-ed-cond"
            ed_condition = generate_condition(patient_id, ed_cond_id, ed_enc_id, 'J45.9', '氣喘急性發作')
            bundle['entry'].append({"resource": ed_condition, "request": {"method": "PUT", "url": f"Condition/{ed_cond_id}"}})
            resource_counts['Condition'] += 1
            stats['asthma_ed_patients'] += 1
    
    # ========== 4. 多重用藥患者 (5人): TW00354-TW00358 ==========
    print("生成多重用藥患者資料...")
    for i in range(5):
        patient_id = START_PATIENT_ID + 45 + i
        age = random.randint(65, 85)
        
        patient = generate_patient(patient_id, age)
        bundle['entry'].append({"resource": patient, "request": {"method": "PUT", "url": f"Patient/{patient['id']}"}})
        resource_counts['Patient'] += 1
        
        # 1次門診，開立10-12種藥品
        enc_id = f"TW{patient_id:05d}-poly-enc"
        encounter = generate_encounter(patient_id, enc_id, 'AMB')
        bundle['entry'].append({"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}})
        resource_counts['Encounter'] += 1
        stats['poly_pharmacy_encounters'] += 1
        
        # 多重慢性病診斷
        for c, icd in enumerate(['I10', 'E11.9', 'M19.9']):
            cond_id = f"TW{patient_id:05d}-poly-cond-{c+1}"
            condition = generate_condition(patient_id, cond_id, enc_id, icd, '多重慢性病')
            bundle['entry'].append({"resource": condition, "request": {"method": "PUT", "url": f"Condition/{cond_id}"}})
            resource_counts['Condition'] += 1
        
        # 10-12種不同藥品
        num_meds = random.randint(10, 12)
        selected_meds = random.sample(common_medications, min(num_meds, len(common_medications)))
        for m, medication in enumerate(selected_meds):
            med_req_id = f"TW{patient_id:05d}-poly-med-{m+1}"
            med_request = generate_medication_request(patient_id, enc_id, med_req_id, medication, days_supply=random.randint(7, 30))
            bundle['entry'].append({"resource": med_request, "request": {"method": "PUT", "url": f"MedicationRequest/{med_req_id}"}})
            resource_counts['MedicationRequest'] += 1
            stats['total_prescriptions'] += 1
    
    # ========== 5. 一般門診患者 + 同日再就診 (3人): TW00359-TW00361 ==========
    print("生成一般門診患者資料 (含同日再就診)...")
    for i in range(3):
        patient_id = START_PATIENT_ID + 50 + i
        age = random.randint(30, 60)
        
        patient = generate_patient(patient_id, age)
        bundle['entry'].append({"resource": patient, "request": {"method": "PUT", "url": f"Patient/{patient['id']}"}})
        resource_counts['Patient'] += 1
        
        # 同一天就診2次 (模擬同日再就診)
        same_date = random_date(QUARTER_START, QUARTER_END)
        for v in range(2):
            enc_id = f"TW{patient_id:05d}-revisit-enc-{v+1}"
            encounter = generate_encounter(patient_id, enc_id, 'AMB', date=same_date + timedelta(hours=v*3))
            bundle['entry'].append({"resource": encounter, "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}})
            resource_counts['Encounter'] += 1
            
            # 相同診斷 (模擬同日同疾病)
            cond_id = f"TW{patient_id:05d}-revisit-cond-{v+1}"
            condition = generate_condition(patient_id, cond_id, enc_id, 'J06.9', '上呼吸道感染')
            bundle['entry'].append({"resource": condition, "request": {"method": "PUT", "url": f"Condition/{cond_id}"}})
            resource_counts['Condition'] += 1
            
            # 一般用藥
            med_req_id = f"TW{patient_id:05d}-revisit-med-{v+1}"
            medication = random.choice(common_medications[:5])
            med_request = generate_medication_request(patient_id, enc_id, med_req_id, medication, days_supply=7)
            bundle['entry'].append({"resource": med_request, "request": {"method": "PUT", "url": f"MedicationRequest/{med_req_id}"}})
            resource_counts['MedicationRequest'] += 1
            stats['total_prescriptions'] += 1
        
        stats['same_day_revisits'] += 1
    
    # ========== 輸出統計 ==========
    print("\n" + "="*60)
    print("門診品質指標測試資料生成完成 (2025 Q4)")
    print("="*60)
    print(f"\n資源統計:")
    for resource_type, count in resource_counts.items():
        print(f"  {resource_type}: {count} 個")
    print(f"\n總資源數: {sum(resource_counts.values())} 個")
    
    print(f"\n指標預期結果:")
    chronic_rate = (stats['chronic_prescriptions'] / stats['total_prescriptions'] * 100) if stats['total_prescriptions'] > 0 else 0
    print(f"  04-慢性處方箋使用率: {stats['chronic_prescriptions']}/{stats['total_prescriptions']} = {chronic_rate:.2f}%")
    
    poly_rate = (stats['poly_pharmacy_encounters'] / resource_counts['Encounter'] * 100) if resource_counts['Encounter'] > 0 else 0
    print(f"  05-多重用藥率(≥10種): {stats['poly_pharmacy_encounters']}/{resource_counts['Encounter']} = {poly_rate:.2f}%")
    
    asthma_rate = (stats['asthma_ed_patients'] / stats['asthma_patients'] * 100) if stats['asthma_patients'] > 0 else 0
    print(f"  06-小兒氣喘急診率: {stats['asthma_ed_patients']}/{stats['asthma_patients']} = {asthma_rate:.2f}%")
    
    hba1c_rate = (stats['diabetes_with_hba1c'] / stats['diabetes_patients'] * 100) if stats['diabetes_patients'] > 0 else 0
    print(f"  07-糖尿病HbA1c檢驗率: {stats['diabetes_with_hba1c']}/{stats['diabetes_patients']} = {hba1c_rate:.2f}%")
    
    revisit_rate = (stats['same_day_revisits'] / resource_counts['Encounter'] * 100) if resource_counts['Encounter'] > 0 else 0
    print(f"  08-同日再就診率: {stats['same_day_revisits']*2}/{resource_counts['Encounter']} = {revisit_rate:.2f}%")
    
    print(f"\n病人編號: TW00309 - TW00361")
    print(f"資源總數: {sum(resource_counts.values())} 個")
    print(f"時間範圍: 2025 Q4 (10-12月)")
    
    return bundle

# ========== 執行生成 ==========
if __name__ == '__main__':
    print("開始生成 53 位病人的門診品質指標測試資料...")
    bundle = generate_all_data()
    
    # 寫入JSON檔案
    output_file = 'outpatient_quality_53_bundle.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ 已成功生成 {output_file}")
