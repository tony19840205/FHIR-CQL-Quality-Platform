"""
生成 50 位病人的醫療品質指標資料 (TW00259-TW00308)
指標01: 門診注射劑使用率 2.45%
指標02: 門診抗生素使用率 2.38%
時間範圍: 2024 Q4 (10-12月)
"""

import json
import random
from datetime import datetime, timedelta

# 台灣常見姓氏
surnames = ['陳', '林', '黃', '張', '李', '王', '吳', '劉', '蔡', '楊',
            '許', '鄭', '謝', '郭', '洪', '曾', '邱', '廖', '賴', '周']

# 台灣常見名字
male_given_names = ['建國', '家豪', '志明', '俊傑', '文龍', '冠宇', '承翰', '宗翰', '柏翰', '彥廷']
female_given_names = ['淑芬', '雅婷', '怡君', '佳穎', '婉婷', '欣怡', '筱涵', '詩涵', '鈺婷', '宜蓁']

# 台灣縣市
cities = ['台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市', '基隆市', '新竹市', 
          '嘉義市', '新竹縣', '苗栗縣', '彰化縣', '南投縣', '雲林縣', '嘉義縣', '屏東縣',
          '宜蘭縣', '花蓮縣', '台東縣', '澎湖縣']

# 門診科別
departments = [
    {'code': 'IM', 'name': '內科', 'weight': 40},
    {'code': 'SUR', 'name': '外科', 'weight': 20},
    {'code': 'FM', 'name': '家醫科', 'weight': 30},
    {'code': 'ENT', 'name': '耳鼻喉科', 'weight': 5},
    {'code': 'OPH', 'name': '眼科', 'weight': 5}
]

# ICD-10 診斷代碼
diagnoses = [
    {'code': 'J00', 'display': 'Acute nasopharyngitis (common cold)', 'weight': 15},
    {'code': 'J06.9', 'display': 'Acute upper respiratory infection', 'weight': 15},
    {'code': 'I10', 'display': 'Essential hypertension', 'weight': 20},
    {'code': 'E11.9', 'display': 'Type 2 diabetes mellitus', 'weight': 15},
    {'code': 'J45.9', 'display': 'Asthma', 'weight': 10},
    {'code': 'M79.3', 'display': 'Myalgia', 'weight': 10},
    {'code': 'L03.90', 'display': 'Cellulitis', 'weight': 8},
    {'code': 'K29.7', 'display': 'Gastritis', 'weight': 7}
]

# 注射劑藥物 (ATC分類) - 排除疫苗和特殊藥品
# 根據CQL 3127規範,排除: 化療藥(L01/L02)、疫苗(J07BB)、特殊藥品
injection_medications = [
    {'code': 'A11EA', 'name': 'Vitamin B Complex', 'display': 'B群注射', 'weight': 30},
    {'code': 'M01AB05', 'name': 'Diclofenac', 'display': '非類固醇止痛針', 'weight': 25},
    {'code': 'M01AE01', 'name': 'Ibuprofen injection', 'display': '消炎止痛針', 'weight': 20},
    {'code': 'H02AB04', 'name': 'Methylprednisolone', 'display': '類固醇注射', 'weight': 15},
    {'code': 'N02BE01', 'name': 'Paracetamol injection', 'display': '普拿疼注射劑', 'weight': 10}
]

# 口服抗生素 (ATC: J01)
antibiotic_medications = [
    {'code': 'J01CA04', 'name': 'Amoxicillin', 'display': '安莫西林', 'weight': 48},
    {'code': 'J01DB01', 'name': 'Cefalexin', 'display': '第一代頭孢菌素', 'weight': 32},
    {'code': 'J01AA02', 'name': 'Doxycycline', 'display': '去氧羥四環素', 'weight': 12},
    {'code': 'J01FA10', 'name': 'Azithromycin', 'display': '阿奇黴素', 'weight': 8}
]

def weighted_random_choice(items):
    """加權隨機選擇"""
    total_weight = sum(item['weight'] for item in items)
    random_value = random.uniform(0, total_weight)
    current_weight = 0
    for item in items:
        current_weight += item['weight']
        if random_value <= current_weight:
            return item
    return items[-1]

def generate_patient(patient_id):
    """生成病人資料"""
    gender = random.choice(['male', 'female'])
    surname = random.choice(surnames)
    given_name = random.choice(male_given_names if gender == 'male' else female_given_names)
    
    # 年齡分布: 18-35(20%), 36-50(30%), 51-65(30%), 66+(20%)
    age_group = random.choices([1, 2, 3, 4], weights=[20, 30, 30, 20])[0]
    if age_group == 1:
        birth_year = random.randint(1989, 2006)
    elif age_group == 2:
        birth_year = random.randint(1974, 1988)
    elif age_group == 3:
        birth_year = random.randint(1959, 1973)
    else:
        birth_year = random.randint(1930, 1958)
    
    return {
        "resourceType": "Patient",
        "id": patient_id,
        "identifier": [{
            "system": "http://hospital.example.org/patients",
            "value": patient_id
        }],
        "name": [{
            "family": surname,
            "given": [given_name],
            "text": f"{surname}{given_name}"
        }],
        "gender": gender,
        "birthDate": f"{birth_year}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}",
        "address": [{
            "city": random.choice(cities),
            "country": "TW"
        }]
    }

def generate_encounter(patient_id, encounter_id, visit_date, department):
    """生成門診就診記錄"""
    return {
        "resourceType": "Encounter",
        "id": encounter_id,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "AMB",
            "display": "ambulatory"
        },
        "type": [{
            "coding": [{
                "system": "http://hospital.example.org/department",
                "code": department['code'],
                "display": department['name']
            }],
            "text": department['name']
        }],
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "period": {
            "start": visit_date.isoformat(),
            "end": (visit_date + timedelta(hours=1)).isoformat()
        }
    }

def generate_condition(patient_id, encounter_id, condition_id, diagnosis):
    """生成診斷記錄"""
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
                "code": diagnosis['code'],
                "display": diagnosis['display']
            }],
            "text": diagnosis['display']
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        }
    }

def generate_medication_request(patient_id, encounter_id, med_request_id, medication, medication_type):
    """生成藥物處方"""
    # 根據藥物類型生成10碼健保代碼
    # 注射劑: 第8碼(索引7)='2', 口服: 第8碼='1'
    if medication_type == 'injection':
        # 注射劑健保代碼範例: BC123452AA (第8碼index 7是'2')
        base_hash = hash(medication['code']) % 100000
        nhi_code = f"BC{base_hash:05d}2AA"
    else:
        # 口服藥健保代碼範例: AC123451AA (第8碼index 7是'1')
        base_hash = hash(medication['code']) % 100000
        nhi_code = f"AC{base_hash:05d}1AA"
    
    return {
        "resourceType": "MedicationRequest",
        "id": med_request_id,
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
                    "code": medication['code'],
                    "display": medication['display']
                }
            ],
            "text": medication['name']
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "authoredOn": datetime.now().isoformat(),
        "dosageInstruction": [{
            "text": "注射給藥" if medication_type == 'injection' else "口服,每日3次",
            "route": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "385219001" if medication_type == 'injection' else "26643006",
                    "display": "Injection" if medication_type == 'injection' else "Oral"
                }]
            }
        }]
    }

def generate_medication_administration(patient_id, encounter_id, med_admin_id, medication, medication_type):
    """生成藥物給藥記錄"""
    # 生成與MedicationRequest相同的健保代碼
    if medication_type == 'injection':
        base_hash = hash(medication['code']) % 100000
        nhi_code = f"BC{base_hash:05d}2AA"
    else:
        base_hash = hash(medication['code']) % 100000
        nhi_code = f"AC{base_hash:05d}1AA"
    
    return {
        "resourceType": "MedicationAdministration",
        "id": med_admin_id,
        "status": "completed",
        "medicationCodeableConcept": {
            "coding": [
                {
                    "system": "https://www.nhi.gov.tw/medication",
                    "code": nhi_code,
                    "display": medication['display']
                },
                {
                    "system": "http://www.whocc.no/atc",
                    "code": medication['code'],
                    "display": medication['display']
                }
            ],
            "text": medication['name']
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "context": {
            "reference": f"Encounter/{encounter_id}"
        },
        "effectiveDateTime": datetime.now().isoformat(),
        "dosage": {
            "route": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "385219001" if medication_type == 'injection' else "26643006",
                    "display": "Injection" if medication_type == 'injection' else "Oral"
                }]
            },
            "dose": {
                "value": 1,
                "unit": "dose",
                "system": "http://unitsofmeasure.org",
                "code": "{dose}"
            }
        }
    }

def generate_bundle():
    """生成完整 Bundle"""
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": []
    }
    
    patient_number = 259  # 起始編號 TW00259
    
    # 追蹤統計
    total_encounters = 0
    injection_encounters = 0
    antibiotic_encounters = 0
    
    # 2025 Q4 日期範圍
    q4_start = datetime(2025, 10, 1)
    q4_end = datetime(2025, 12, 1)  # 現在是 2025/12/1
    
    # 50位病人
    for i in range(50):
        patient_id = f"TW{patient_number:05d}"
        
        # 生成 Patient 資源
        patient = generate_patient(patient_id)
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Patient/{patient_id}",
            "resource": patient,
            "request": {
                "method": "PUT",
                "url": f"Patient/{patient_id}"
            }
        })
        
        # 每位病人 2-3 次門診就診
        num_visits = random.randint(2, 3)
        
        for visit_num in range(num_visits):
            # 隨機Q4日期
            days_offset = random.randint(0, (q4_end - q4_start).days)
            visit_date = q4_start + timedelta(days=days_offset)
            
            encounter_id = f"{patient_id}-enc-{visit_num + 1}"
            department = weighted_random_choice(departments)
            diagnosis = weighted_random_choice(diagnoses)
            
            # 生成 Encounter
            encounter = generate_encounter(patient_id, encounter_id, visit_date, department)
            bundle["entry"].append({
                "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Encounter/{encounter_id}",
                "resource": encounter,
                "request": {
                    "method": "PUT",
                    "url": f"Encounter/{encounter_id}"
                }
            })
            
            # 生成 Condition
            condition_id = f"{encounter_id}-cond"
            condition = generate_condition(patient_id, encounter_id, condition_id, diagnosis)
            bundle["entry"].append({
                "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Condition/{condition_id}",
                "resource": condition,
                "request": {
                    "method": "PUT",
                    "url": f"Condition/{condition_id}"
                }
            })
            
            total_encounters += 1
        
        patient_number += 1
    
    # 生成 25 個注射劑案例 (分散在不同病人)
    injection_patients = random.sample(range(259, 309), 25)
    for idx, patient_num in enumerate(injection_patients):
        patient_id = f"TW{patient_num:05d}"
        encounter_id = f"{patient_id}-enc-inj"
        
        # 隨機Q4日期
        days_offset = random.randint(0, (q4_end - q4_start).days)
        visit_date = q4_start + timedelta(days=days_offset)
        
        department = weighted_random_choice(departments)
        diagnosis = weighted_random_choice(diagnoses)
        medication = weighted_random_choice(injection_medications)
        
        # Encounter
        encounter = generate_encounter(patient_id, encounter_id, visit_date, department)
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Encounter/{encounter_id}",
            "resource": encounter,
            "request": {
                "method": "PUT",
                "url": f"Encounter/{encounter_id}"
            }
        })
        
        # Condition
        condition_id = f"{encounter_id}-cond"
        condition = generate_condition(patient_id, encounter_id, condition_id, diagnosis)
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Condition/{condition_id}",
            "resource": condition,
            "request": {
                "method": "PUT",
                "url": f"Condition/{condition_id}"
            }
        })
        
        # MedicationRequest
        med_request_id = f"{encounter_id}-med-req"
        med_request = generate_medication_request(patient_id, encounter_id, med_request_id, medication, 'injection')
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/MedicationRequest/{med_request_id}",
            "resource": med_request,
            "request": {
                "method": "PUT",
                "url": f"MedicationRequest/{med_request_id}"
            }
        })
        
        # MedicationAdministration
        med_admin_id = f"{encounter_id}-med-adm"
        med_admin = generate_medication_administration(patient_id, encounter_id, med_admin_id, medication, 'injection')
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/MedicationAdministration/{med_admin_id}",
            "resource": med_admin,
            "request": {
                "method": "PUT",
                "url": f"MedicationAdministration/{med_admin_id}"
            }
        })
        
        injection_encounters += 1
        total_encounters += 1
    
    # 生成 25 個抗生素案例 (分散在不同病人)
    antibiotic_patients = random.sample(range(259, 309), 25)
    for idx, patient_num in enumerate(antibiotic_patients):
        patient_id = f"TW{patient_num:05d}"
        encounter_id = f"{patient_id}-enc-abx"
        
        # 隨機Q4日期
        days_offset = random.randint(0, (q4_end - q4_start).days)
        visit_date = q4_start + timedelta(days=days_offset)
        
        department = weighted_random_choice(departments)
        diagnosis = weighted_random_choice(diagnoses)
        medication = weighted_random_choice(antibiotic_medications)
        
        # Encounter
        encounter = generate_encounter(patient_id, encounter_id, visit_date, department)
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Encounter/{encounter_id}",
            "resource": encounter,
            "request": {
                "method": "PUT",
                "url": f"Encounter/{encounter_id}"
            }
        })
        
        # Condition
        condition_id = f"{encounter_id}-cond"
        condition = generate_condition(patient_id, encounter_id, condition_id, diagnosis)
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Condition/{condition_id}",
            "resource": condition,
            "request": {
                "method": "PUT",
                "url": f"Condition/{condition_id}"
            }
        })
        
        # MedicationRequest
        med_request_id = f"{encounter_id}-med-req"
        med_request = generate_medication_request(patient_id, encounter_id, med_request_id, medication, 'antibiotic')
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/MedicationRequest/{med_request_id}",
            "resource": med_request,
            "request": {
                "method": "PUT",
                "url": f"MedicationRequest/{med_request_id}"
            }
        })
        
        # MedicationAdministration
        med_admin_id = f"{encounter_id}-med-adm"
        med_admin = generate_medication_administration(patient_id, encounter_id, med_admin_id, medication, 'antibiotic')
        bundle["entry"].append({
            "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/MedicationAdministration/{med_admin_id}",
            "resource": med_admin,
            "request": {
                "method": "PUT",
                "url": f"MedicationAdministration/{med_admin_id}"
            }
        })
        
        antibiotic_encounters += 1
        total_encounters += 1
    
    injection_rate = (injection_encounters / total_encounters * 100) if total_encounters > 0 else 0
    antibiotic_rate = (antibiotic_encounters / total_encounters * 100) if total_encounters > 0 else 0
    
    print(f"\n醫療品質指標統計 (2025 Q4):")
    print(f"  總門診就診: {total_encounters} 次")
    print(f"  注射劑使用: {injection_encounters} 次 ({injection_rate:.2f}%)")
    print(f"  抗生素使用: {antibiotic_encounters} 次 ({antibiotic_rate:.2f}%)")
    print(f"\n總資源數: {len(bundle['entry'])} 個")
    
    return bundle

if __name__ == "__main__":
    print("開始生成 50 位病人的醫療品質指標資料...\n")
    bundle = generate_bundle()
    
    output_file = "quality_50_bundle.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)
    
    print(f"\n已成功生成 {output_file}")
    print("病人編號: TW00259 - TW00308")
