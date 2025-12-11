"""
同院用藥重疊指標測試資料生成器
生成42位病患，涵蓋8個同院用藥重疊指標 (03-3 至 03-10)
日期範圍: 2025 Q4 (2025-10-01 至 2025-12-31)
"""

import json
import random
from datetime import datetime, timedelta
import hashlib

# 設定隨機種子以確保可重現性
random.seed(42)

# FHIR伺服器設定
FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"

# 醫院組織
HOSPITAL_ID = "ORG-TaiwanHospital50"
HOSPITAL_NAME = "台灣50專用醫院"

# 2025 Q4 日期範圍
Q4_START = datetime(2025, 10, 1)
Q4_END = datetime(2025, 12, 31)

# 病患組設定
PATIENT_GROUPS = {
    "diabetes": {
        "count": 6,
        "indicator": "03-3",
        "disease_code": "E11.9",
        "disease_name": "第2型糖尿病",
        "drugs": [
            {"atc": "A10BA02", "name": "Metformin", "code": "AA123451##"},
            {"atc": "A10BB01", "name": "Glibenclamide", "code": "AB234561##"}
        ]
    },
    "psychotic": {
        "count": 5,
        "indicator": "03-4",
        "disease_code": "F20.9",
        "disease_name": "思覺失調症",
        "drugs": [
            {"atc": "N05AH03", "name": "Olanzapine", "code": "NA123451##"},
            {"atc": "N05AX08", "name": "Risperidone", "code": "NB234561##"}
        ]
    },
    "depression": {
        "count": 5,
        "indicator": "03-5",
        "disease_code": "F32.9",
        "disease_name": "憂鬱症",
        "drugs": [
            {"atc": "N06AB03", "name": "Fluoxetine", "code": "NC123451##"},
            {"atc": "N06AB04", "name": "Sertraline", "code": "ND234561##"}
        ]
    },
    "insomnia": {
        "count": 5,
        "indicator": "03-6",
        "disease_code": "G47.00",
        "disease_name": "失眠症",
        "drugs": [
            {"atc": "N05CD02", "name": "Nitrazepam", "code": "NE123451##"},
            {"atc": "N05CF01", "name": "Zopiclone", "code": "NF234561##"}
        ]
    },
    "thrombosis": {
        "count": 6,
        "indicator": "03-7",
        "disease_code": "I25.10",
        "disease_name": "冠狀動脈粥樣硬化性心臟病",
        "drugs": [
            {"atc": "B01AC06", "name": "Aspirin", "code": "BA123451##"},
            {"atc": "B01AF01", "name": "Rivaroxaban", "code": "BB234561##"}
        ]
    },
    "prostate": {
        "count": 5,
        "indicator": "03-8",
        "disease_code": "N40",
        "disease_name": "前列腺增生",
        "drugs": [
            {"atc": "G04CA02", "name": "Tamsulosin", "code": "GA123451##"},
            {"atc": "G04CB01", "name": "Finasteride", "code": "GB234561##"}
        ]
    },
    "hypertension": {
        "count": 5,
        "indicator": "03-9",
        "disease_code": "I10",
        "disease_name": "原發性高血壓",
        "drugs": [
            {"atc": "C07AB02", "name": "Metoprolol", "code": "CA123451##"},
            {"atc": "C09AA02", "name": "Enalapril", "code": "CB234561##"}
        ]
    },
    "hyperlipidemia": {
        "count": 5,
        "indicator": "03-10",
        "disease_code": "E78.5",
        "disease_name": "高血脂症",
        "drugs": [
            {"atc": "C10AA01", "name": "Simvastatin", "code": "CC123451##"},
            {"atc": "C10AB02", "name": "Bezafibrate", "code": "CD234561##"}
        ]
    }
}

# 重疊模式
OVERLAP_PATTERNS = {
    "full": {  # 完全重疊
        "prescription1": {"start_day": 1, "duration": 28},
        "prescription2": {"start_day": 5, "duration": 28},
        "overlap_days": 24
    },
    "partial": {  # 部分重疊
        "prescription1": {"start_day": 1, "duration": 21},
        "prescription2": {"start_day": 15, "duration": 21},
        "overlap_days": 7
    },
    "none": {  # 無重疊
        "prescription1": {"start_day": 1, "duration": 28},
        "prescription2": {"start_day": 29, "duration": 28},
        "overlap_days": 0
    }
}

# 台灣常見姓氏和名字
SURNAMES = ["陳", "林", "黃", "張", "李", "王", "吳", "劉", "蔡", "楊", "許", "鄭", "謝", "洪", "郭"]
GIVEN_NAMES_MALE = ["志明", "建國", "家豪", "俊傑", "偉強", "文華", "明哲", "宗憲", "國輝", "博文"]
GIVEN_NAMES_FEMALE = ["淑芬", "雅婷", "怡君", "佳穎", "美玲", "欣怡", "小芳", "麗華", "淑惠", "靜怡"]

def generate_patient_id(index):
    """生成病患ID"""
    return f"TW{362 + index:05d}"

def generate_name(gender):
    """生成隨機姓名"""
    surname = random.choice(SURNAMES)
    given_names = GIVEN_NAMES_MALE if gender == "male" else GIVEN_NAMES_FEMALE
    given_name = random.choice(given_names)
    return f"{surname}{given_name}"

def generate_birth_date(group_name):
    """根據疾病類型生成合理的出生日期"""
    if group_name == "prostate":
        # 前列腺疾病：50-80歲男性
        age = random.randint(50, 80)
    elif group_name in ["psychotic", "depression"]:
        # 精神疾病：25-65歲
        age = random.randint(25, 65)
    elif group_name == "insomnia":
        # 失眠：30-70歲
        age = random.randint(30, 70)
    else:
        # 慢性病：40-75歲
        age = random.randint(40, 75)
    
    birth_year = 2025 - age
    birth_month = random.randint(1, 12)
    birth_day = random.randint(1, 28)
    return f"{birth_year}-{birth_month:02d}-{birth_day:02d}"

def generate_patient(patient_id, group_name):
    """生成Patient資源"""
    # 前列腺疾病只有男性
    gender = "male" if group_name == "prostate" else random.choice(["male", "female"])
    
    return {
        "resourceType": "Patient",
        "id": patient_id,
        "identifier": [{
            "system": "http://www.nhi.gov.tw/patient",
            "value": patient_id
        }],
        "name": [{
            "text": generate_name(gender),
            "family": generate_name(gender)[0],
            "given": [generate_name(gender)[1:]]
        }],
        "gender": gender,
        "birthDate": generate_birth_date(group_name)
    }

def generate_encounter(encounter_id, patient_id, visit_date):
    """生成Encounter資源 (門診)"""
    visit_datetime = datetime.combine(visit_date, datetime.min.time().replace(hour=random.randint(9, 16)))
    
    return {
        "resourceType": "Encounter",
        "id": encounter_id,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "AMB",
            "display": "ambulatory"
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "serviceProvider": {
            "reference": f"Organization/{HOSPITAL_ID}",
            "display": HOSPITAL_NAME
        },
        "period": {
            "start": visit_datetime.strftime("%Y-%m-%dT%H:%M:%S+08:00"),
            "end": (visit_datetime + timedelta(minutes=30)).strftime("%Y-%m-%dT%H:%M:%S+08:00")
        }
    }

def generate_condition(condition_id, patient_id, encounter_id, disease_code, disease_name):
    """生成Condition資源"""
    return {
        "resourceType": "Condition",
        "id": condition_id,
        "clinicalStatus": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                "code": "active"
            }]
        },
        "verificationStatus": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                "code": "confirmed"
            }]
        },
        "code": {
            "coding": [{
                "system": "http://hl7.org/fhir/sid/icd-10",
                "code": disease_code,
                "display": disease_name
            }]
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        }
    }

def generate_medication_request(med_id, patient_id, encounter_id, drug, start_date, duration_days):
    """生成MedicationRequest資源"""
    end_date = start_date + timedelta(days=duration_days - 1)
    
    # 確保醫令代碼第8碼為'1'(口服)
    drug_code = drug["code"].replace("##", f"1{random.randint(10, 99)}")
    
    return {
        "resourceType": "MedicationRequest",
        "id": med_id,
        "status": "completed",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [{
                "system": "http://www.whocc.no/atc",
                "code": drug["atc"],
                "display": drug["name"]
            }, {
                "system": "http://www.nhi.gov.tw/medication",
                "code": drug_code,
                "display": drug["name"]
            }]
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "authoredOn": start_date.strftime("%Y-%m-%dT09:00:00+08:00"),
        "requester": {
            "reference": f"Organization/{HOSPITAL_ID}",
            "display": HOSPITAL_NAME
        },
        "dosageInstruction": [{
            "timing": {
                "repeat": {
                    "boundsDuration": {
                        "value": duration_days,
                        "unit": "days",
                        "system": "http://unitsofmeasure.org",
                        "code": "d"
                    }
                }
            },
            "doseAndRate": [{
                "doseQuantity": {
                    "value": 1,
                    "unit": "tablet",
                    "system": "http://unitsofmeasure.org",
                    "code": "TAB"
                }
            }]
        }],
        "dispenseRequest": {
            "validityPeriod": {
                "start": start_date.strftime("%Y-%m-%d"),
                "end": end_date.strftime("%Y-%m-%d")
            },
            "quantity": {
                "value": duration_days,
                "unit": "tablet"
            }
        }
    }

def generate_group_data(group_name, group_config, start_patient_index):
    """生成一組病患的所有資料"""
    resources = []
    patient_count = group_config["count"]
    
    # 分配重疊模式：2個完全重疊 + 2個部分重疊 + 1個無重疊
    patterns = (["full"] * 2 + ["partial"] * 2 + ["none"] * 1) * (patient_count // 5 + 1)
    patterns = patterns[:patient_count]
    random.shuffle(patterns)
    
    for i in range(patient_count):
        patient_idx = start_patient_index + i
        patient_id = generate_patient_id(patient_idx)
        pattern = OVERLAP_PATTERNS[patterns[i]]
        
        # 生成Patient
        patient = generate_patient(patient_id, group_name)
        resources.append(patient)
        
        # 生成兩次門診和處方
        for visit_num in range(1, 3):
            encounter_id = f"ENC-{patient_id}-{visit_num}"
            condition_id = f"COND-{patient_id}-{visit_num}"
            
            # 計算就診日期
            prescription_key = f"prescription{visit_num}"
            start_offset = pattern[prescription_key]["start_day"]
            duration = pattern[prescription_key]["duration"]
            visit_date = Q4_START + timedelta(days=start_offset - 1)
            
            # 生成Encounter
            encounter = generate_encounter(encounter_id, patient_id, visit_date)
            resources.append(encounter)
            
            # 生成Condition (只在第一次就診時生成)
            if visit_num == 1:
                condition = generate_condition(
                    condition_id, patient_id, encounter_id,
                    group_config["disease_code"],
                    group_config["disease_name"]
                )
                resources.append(condition)
            
            # 生成MedicationRequest (選擇不同的藥物)
            drug = group_config["drugs"][visit_num - 1]
            med_id = f"MED-{patient_id}-{visit_num}"
            medication = generate_medication_request(
                med_id, patient_id, encounter_id,
                drug, visit_date, duration
            )
            resources.append(medication)
    
    return resources, patient_count

def main():
    """主函數"""
    print("=" * 80)
    print("同院用藥重疊指標測試資料生成器")
    print("=" * 80)
    print(f"目標: 生成42位病患的完整FHIR資料")
    print(f"涵蓋指標: 03-3 至 03-10 (8個同院用藥重疊指標)")
    print(f"日期範圍: {Q4_START.strftime('%Y-%m-%d')} 至 {Q4_END.strftime('%Y-%m-%d')}")
    print("=" * 80)
    print()
    
    all_resources = []
    patient_index = 0
    
    for group_name, group_config in PATIENT_GROUPS.items():
        print(f"生成 {group_name} 組資料...")
        print(f"  指標: {group_config['indicator']}")
        print(f"  疾病: {group_config['disease_name']} ({group_config['disease_code']})")
        print(f"  病患數: {group_config['count']}")
        
        resources, count = generate_group_data(group_name, group_config, patient_index)
        all_resources.extend(resources)
        patient_index += count
        
        print(f"  ✓ 生成 {len(resources)} 個資源")
        print()
    
    # 建立Bundle
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": []
    }
    
    for resource in all_resources:
        bundle["entry"].append({
            "fullUrl": f"{FHIR_SERVER}/{resource['resourceType']}/{resource['id']}",
            "resource": resource,
            "request": {
                "method": "PUT",
                "url": f"{resource['resourceType']}/{resource['id']}"
            }
        })
    
    # 儲存到檔案
    output_file = "same_hospital_overlap_42_bundle.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)
    
    # 統計資訊
    resource_counts = {}
    for resource in all_resources:
        resource_type = resource["resourceType"]
        resource_counts[resource_type] = resource_counts.get(resource_type, 0) + 1
    
    print("=" * 80)
    print("資料生成完成!")
    print("=" * 80)
    print(f"總病患數: 42")
    print(f"總資源數: {len(all_resources)}")
    print()
    print("資源統計:")
    for resource_type, count in sorted(resource_counts.items()):
        print(f"  - {resource_type}: {count}")
    print()
    print(f"Bundle檔案: {output_file}")
    print("=" * 80)
    print()
    
    # 計算預期重疊率
    print("預期結果:")
    print("-" * 80)
    total_overlap = 0
    total_days = 0
    
    for group_name, group_config in PATIENT_GROUPS.items():
        count = group_config["count"]
        # 2個完全重疊(24天) + 2個部分重疊(7天) + 1個無重疊(0天)
        group_overlap = (24 * 2 + 7 * 2 + 0 * 1) * (count // 5)
        if count % 5 >= 2:
            group_overlap += 24 * 2
        if count % 5 >= 4:
            group_overlap += 7 * 2
        
        # 每人2個處方，各28天或21天 (簡化計算用平均25天)
        group_days = count * 2 * 25
        group_rate = (group_overlap / group_days * 100) if group_days > 0 else 0
        
        total_overlap += group_overlap
        total_days += group_days
        
        print(f"{group_config['indicator']} ({group_config['disease_name']}): ")
        print(f"  重疊天數: {group_overlap}, 總給藥天數: {group_days}, 預期率: {group_rate:.2f}%")
    
    overall_rate = (total_overlap / total_days * 100) if total_days > 0 else 0
    print("-" * 80)
    print(f"整體平均預期重疊率: {overall_rate:.2f}%")
    print("=" * 80)

if __name__ == "__main__":
    main()
