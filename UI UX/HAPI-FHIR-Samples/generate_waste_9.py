"""
生成 9 位住院病人的廢棄物管理資料 (TW00250-TW00258)
全部為住院病人,分布於三個病房:內科、外科、加護病房
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
          '宜蘭縣', '花蓮縣', '台東縣', '澎湖縣', '金門縣', '連江縣']

# 病房類型及其廢棄物產生率 (公斤/床日)
ward_types = [
    {'type': 'Internal Medicine', 'name': '內科病房', 'general': 1.5, 'infectious': 0.8, 'recyclable': 0.2, 'days_range': (4, 5)},
    {'type': 'Surgery', 'name': '外科病房', 'general': 2.0, 'infectious': 1.5, 'recyclable': 0.3, 'days_range': (5, 7)},
    {'type': 'ICU', 'name': '加護病房', 'general': 2.5, 'infectious': 2.0, 'recyclable': 0.3, 'days_range': (3, 4)}
]

def generate_patient(patient_id, ward_type_info):
    """生成病人資料"""
    gender = random.choice(['male', 'female'])
    surname = random.choice(surnames)
    given_name = random.choice(male_given_names if gender == 'male' else female_given_names)
    
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
        "birthDate": f"{random.randint(1950, 2010)}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}",
        "address": [{
            "city": random.choice(cities),
            "country": "TW"
        }]
    }

def generate_encounter(patient_id, ward_type_info, encounter_days):
    """生成住院紀錄"""
    # 隨機選擇過去 30 天內的入院日期
    admission_date = datetime.now() - timedelta(days=random.randint(5, 30))
    discharge_date = admission_date + timedelta(days=encounter_days)
    
    return {
        "resourceType": "Encounter",
        "id": f"{patient_id}-enc",
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "IMP",
            "display": "inpatient encounter"
        },
        "type": [{
            "coding": [{
                "system": "http://hospital.example.org/ward-types",
                "code": ward_type_info['type'],
                "display": ward_type_info['name']
            }],
            "text": ward_type_info['name']
        }],
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "period": {
            "start": admission_date.strftime("%Y-%m-%dT08:00:00+08:00"),
            "end": discharge_date.strftime("%Y-%m-%dT10:00:00+08:00")
        },
        "hospitalization": {
            "admitSource": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/admit-source",
                    "code": "emd",
                    "display": "From accident/emergency department"
                }]
            }
        }
    }

def generate_waste_observation(patient_id, waste_type, quantity, observation_date, encounter_days):
    """生成廢棄物觀察紀錄"""
    waste_types = {
        'general': {'code': 'general-waste', 'display': 'General Waste', 'text': '一般廢棄物'},
        'infectious': {'code': 'infectious-waste', 'display': 'Infectious Waste', 'text': '感染性廢棄物'},
        'recyclable': {'code': 'recyclable-waste', 'display': 'Recyclable Waste', 'text': '可回收廢棄物'}
    }
    
    waste_info = waste_types[waste_type]
    obs_id = f"{patient_id}-waste-{waste_type}"
    
    return {
        "resourceType": "Observation",
        "id": obs_id,
        "status": "final",
        "category": [{
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "environmental",
                "display": "Environmental"
            }]
        }],
        "code": {
            "coding": [{
                "system": "http://hospital.example.org/waste-types",
                "code": waste_info['code'],
                "display": waste_info['display']
            }],
            "text": waste_info['text']
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{patient_id}-enc"
        },
        "effectiveDateTime": observation_date.strftime("%Y-%m-%dT12:00:00+08:00"),
        "issued": observation_date.strftime("%Y-%m-%dT12:00:00+08:00"),
        "valueQuantity": {
            "value": round(quantity, 2),
            "unit": "kg",
            "system": "http://unitsofmeasure.org",
            "code": "kg"
        },
        "note": [{
            "text": f"住院 {encounter_days} 天產生的{waste_info['text']}總量"
        }]
    }

def generate_bundle():
    """生成包含 9 位病人的 FHIR Bundle"""
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": []
    }
    
    patient_number = 250  # 起始編號 TW00250
    total_general = 0
    total_infectious = 0
    total_recyclable = 0
    
    # 每種病房類型各 3 位病人
    for ward_type_info in ward_types:
        for i in range(3):
            patient_id = f"TW{patient_number:05d}"
            
            # 隨機住院天數
            days_min, days_max = ward_type_info['days_range']
            encounter_days = random.randint(days_min, days_max)
            
            # 計算廢棄物產生量
            general_waste = ward_type_info['general'] * encounter_days
            infectious_waste = ward_type_info['infectious'] * encounter_days
            recyclable_waste = ward_type_info['recyclable'] * encounter_days
            
            total_general += general_waste
            total_infectious += infectious_waste
            total_recyclable += recyclable_waste
            
            # 觀察日期設在住院結束前一天
            observation_date = datetime.now() - timedelta(days=random.randint(1, 10))
            
            # 生成 Patient 資源
            patient = generate_patient(patient_id, ward_type_info)
            bundle["entry"].append({
                "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Patient/{patient_id}",
                "resource": patient,
                "request": {
                    "method": "PUT",
                    "url": f"Patient/{patient_id}"
                }
            })
            
            # 生成 Encounter 資源
            encounter = generate_encounter(patient_id, ward_type_info, encounter_days)
            bundle["entry"].append({
                "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Encounter/{patient_id}-enc",
                "resource": encounter,
                "request": {
                    "method": "PUT",
                    "url": f"Encounter/{patient_id}-enc"
                }
            })
            
            # 生成 3 個 Observation 資源 (一般、感染性、可回收)
            for waste_type, quantity in [('general', general_waste), 
                                         ('infectious', infectious_waste), 
                                         ('recyclable', recyclable_waste)]:
                observation = generate_waste_observation(patient_id, waste_type, quantity, 
                                                        observation_date, encounter_days)
                bundle["entry"].append({
                    "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/Observation/{patient_id}-waste-{waste_type}",
                    "resource": observation,
                    "request": {
                        "method": "PUT",
                        "url": f"Observation/{patient_id}-waste-{waste_type}"
                    }
                })
            
            print(f"生成 {patient_id}: {ward_type_info['name']} - {encounter_days}天 - "
                  f"一般{general_waste:.1f}kg, 感染{infectious_waste:.1f}kg, 可回收{recyclable_waste:.1f}kg")
            
            patient_number += 1
    
    total_waste = total_general + total_infectious + total_recyclable
    recycling_rate = (total_recyclable / total_waste * 100) if total_waste > 0 else 0
    
    print(f"\n總廢棄物統計:")
    print(f"  一般廢棄物: {total_general:.2f} kg ({total_general/total_waste*100:.1f}%)")
    print(f"  感染性廢棄物: {total_infectious:.2f} kg ({total_infectious/total_waste*100:.1f}%)")
    print(f"  可回收廢棄物: {total_recyclable:.2f} kg ({total_recyclable/total_waste*100:.1f}%)")
    print(f"  總計: {total_waste:.2f} kg")
    print(f"  回收率: {recycling_rate:.2f}%")
    print(f"\n總資源數: {len(bundle['entry'])} (9 Patient + 9 Encounter + 27 Observation)")
    
    return bundle

if __name__ == "__main__":
    print("開始生成 9 位住院病人的廢棄物管理資料...\n")
    bundle = generate_bundle()
    
    output_file = "waste_9_bundle.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)
    
    print(f"\n已成功生成 {output_file}")
