#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
住院品質指標測試資料生成器 (2025 Q4)
生成46個病人，支援5個住院品質指標：
- Indicator-09: 14天內非計畫再入院率 (1077.01Q/1809Y)
- Indicator-10: 出院後3天內急診率 (108.01)
- Indicator-11-1: 整體剖腹產率 (1136.01)
- Indicator-11-3: 有適應症剖腹產率 (1138.01)
- Indicator-11-4: 初產婦剖腹產率 (1075.01)
"""

import json
import random
from datetime import datetime, timedelta
import hashlib

# 2025 Q4 日期範圍
START_DATE = datetime(2025, 10, 1)
END_DATE = datetime(2025, 12, 31)

# 病人ID範圍：TW00362-TW00407 (46人)
PATIENT_START_ID = 362
PATIENT_COUNT = 46

def random_date(start, end):
    """生成隨機日期"""
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + timedelta(days=random_days)

def random_datetime(start, end):
    """生成隨機日期時間"""
    date = random_date(start, end)
    hour = random.randint(8, 20)
    minute = random.randint(0, 59)
    return date.replace(hour=hour, minute=minute, second=0, microsecond=0)

def generate_patient(patient_id, gender='male', birth_year=1970):
    """生成病人資料"""
    return {
        "resource": {
            "resourceType": "Patient",
            "id": f"TW{patient_id:05d}",
            "identifier": [{
                "system": "http://www.moi.gov.tw/",
                "value": f"TW{patient_id:05d}"
            }],
            "active": True,
            "name": [{
                "use": "official",
                "text": f"測試病患{patient_id:05d}"
            }],
            "gender": gender,
            "birthDate": f"{birth_year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/TW{patient_id:05d}"
        }
    }

def generate_encounter(enc_id, patient_id, enc_class='IMP', start_dt=None, end_dt=None, status='finished'):
    """生成就診記錄
    enc_class: 'IMP'=住院, 'EMER'=急診, 'AMB'=門診
    """
    if start_dt is None:
        start_dt = random_datetime(START_DATE, END_DATE - timedelta(days=7))
    if end_dt is None:
        # 住院平均5-7天，急診4-8小時
        if enc_class == 'IMP':
            end_dt = start_dt + timedelta(days=random.randint(5, 7))
        elif enc_class == 'EMER':
            end_dt = start_dt + timedelta(hours=random.randint(4, 8))
        else:
            end_dt = start_dt + timedelta(hours=1)
    
    return {
        "resource": {
            "resourceType": "Encounter",
            "id": f"ENC{enc_id:05d}",
            "status": status,
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": enc_class,
                "display": "住院" if enc_class == 'IMP' else ("急診" if enc_class == 'EMER' else "門診")
            },
            "subject": {
                "reference": f"Patient/TW{patient_id:05d}"
            },
            "period": {
                "start": start_dt.isoformat(),
                "end": end_dt.isoformat()
            },
            "serviceProvider": {
                "reference": "Organization/HOSP001",
                "display": "測試醫院"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/ENC{enc_id:05d}"
        }
    }

def generate_condition(cond_id, patient_id, enc_id, icd10_code, display_text):
    """生成診斷記錄"""
    return {
        "resource": {
            "resourceType": "Condition",
            "id": f"COND{cond_id:05d}",
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
                    "code": icd10_code,
                    "display": display_text
                }]
            },
            "subject": {
                "reference": f"Patient/TW{patient_id:05d}"
            },
            "encounter": {
                "reference": f"Encounter/ENC{enc_id:05d}"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Condition/COND{cond_id:05d}"
        }
    }

def generate_procedure(proc_id, patient_id, enc_id, code, display_text, performed_dt):
    """生成手術/處置記錄"""
    return {
        "resource": {
            "resourceType": "Procedure",
            "id": f"PROC{proc_id:05d}",
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-pcs",
                    "code": code,
                    "display": display_text
                }]
            },
            "subject": {
                "reference": f"Patient/TW{patient_id:05d}"
            },
            "encounter": {
                "reference": f"Encounter/ENC{enc_id:05d}"
            },
            "performedDateTime": performed_dt.isoformat()
        },
        "request": {
            "method": "PUT",
            "url": f"Procedure/PROC{proc_id:05d}"
        }
    }

def generate_observation_gravida(obs_id, patient_id, enc_id, gravida=1, para=0):
    """生成產次記錄 (gravida=懷孕次數, para=生產次數)"""
    return {
        "resource": {
            "resourceType": "Observation",
            "id": f"OBS{obs_id:05d}",
            "status": "final",
            "code": {
                "coding": [{
                    "system": "http://loinc.org",
                    "code": "11996-6",
                    "display": "Gravida"
                }]
            },
            "subject": {
                "reference": f"Patient/TW{patient_id:05d}"
            },
            "encounter": {
                "reference": f"Encounter/ENC{enc_id:05d}"
            },
            "valueInteger": gravida,
            "component": [{
                "code": {
                    "coding": [{
                        "system": "http://loinc.org",
                        "code": "11977-6",
                        "display": "Para"
                    }]
                },
                "valueInteger": para
            }]
        },
        "request": {
            "method": "PUT",
            "url": f"Observation/OBS{obs_id:05d}"
        }
    }

def main():
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": []
    }
    
    patient_id = PATIENT_START_ID
    enc_id = 5000 + PATIENT_START_ID
    cond_id = 8000 + PATIENT_START_ID
    proc_id = 9000 + PATIENT_START_ID
    obs_id = 10000 + PATIENT_START_ID
    
    print("=" * 60)
    print("住院品質指標測試資料生成 (2025 Q4)")
    print("=" * 60)
    
    # ==================== 組1: 正常住院患者 (10人) ====================
    print("\n組1: 正常住院患者 (10人) - 單次住院")
    for i in range(10):
        # Patient
        bundle["entry"].append(generate_patient(patient_id, gender=random.choice(['male', 'female']), birth_year=random.randint(1950, 2000)))
        
        # Encounter (住院)
        start_dt = random_datetime(START_DATE, END_DATE - timedelta(days=10))
        end_dt = start_dt + timedelta(days=random.randint(5, 7))
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'IMP', start_dt, end_dt))
        
        # Condition (一般內科疾病)
        diseases = [
            ('J18.9', '肺炎'),
            ('I10', '高血壓'),
            ('E11.9', '第二型糖尿病'),
            ('K29.7', '胃炎'),
            ('N18.9', '慢性腎臟病')
        ]
        disease = random.choice(diseases)
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, disease[0], disease[1]))
        
        patient_id += 1
        enc_id += 1
        cond_id += 1
    
    print(f"  生成: {10}個Patient, {10}個Encounter, {10}個Condition")
    
    # ==================== 組2: 14天內再入院患者 (5人) ====================
    print("\n組2: 14天內非計畫再入院患者 (5人)")
    readmission_count = 0
    for i in range(5):
        # Patient
        bundle["entry"].append(generate_patient(patient_id, gender=random.choice(['male', 'female']), birth_year=random.randint(1950, 1990)))
        
        # 第1次住院
        start_dt1 = random_datetime(START_DATE, END_DATE - timedelta(days=20))
        end_dt1 = start_dt1 + timedelta(days=random.randint(5, 7))
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'IMP', start_dt1, end_dt1))
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, 'I21.9', '急性心肌梗塞'))
        
        enc_id += 1
        cond_id += 1
        
        # 第2次住院 (14天內再入院)
        days_between = random.randint(3, 13)  # 3-13天內再入院
        start_dt2 = end_dt1 + timedelta(days=days_between)
        end_dt2 = start_dt2 + timedelta(days=random.randint(4, 6))
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'IMP', start_dt2, end_dt2))
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, 'I50.9', '心臟衰竭'))
        
        readmission_count += 1
        patient_id += 1
        enc_id += 1
        cond_id += 1
    
    print(f"  生成: {5}個Patient, {10}個Encounter (每人2次), {10}個Condition")
    print(f"  預期再入院率: {readmission_count}/15 = {readmission_count/15*100:.2f}%")
    
    # ==================== 組3: 出院後3天內急診患者 (3人) ====================
    print("\n組3: 出院後3天內急診患者 (3人)")
    ed_within_3days = 0
    for i in range(3):
        # Patient
        bundle["entry"].append(generate_patient(patient_id, gender=random.choice(['male', 'female']), birth_year=random.randint(1960, 2000)))
        
        # 住院
        start_dt = random_datetime(START_DATE, END_DATE - timedelta(days=15))
        end_dt = start_dt + timedelta(days=random.randint(5, 7))
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'IMP', start_dt, end_dt))
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, 'J18.9', '肺炎'))
        
        enc_id += 1
        cond_id += 1
        
        # 出院後1-3天內急診
        days_after = random.randint(1, 3)
        ed_start = end_dt + timedelta(days=days_after, hours=random.randint(2, 20))
        ed_end = ed_start + timedelta(hours=random.randint(4, 8))
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'EMER', ed_start, ed_end))
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, 'R50.9', '發燒'))
        
        ed_within_3days += 1
        patient_id += 1
        enc_id += 1
        cond_id += 1
    
    print(f"  生成: {3}個Patient, {6}個Encounter (每人1住院+1急診), {6}個Condition")
    print(f"  預期急診率: {ed_within_3days}/3 = {ed_within_3days/3*100:.2f}%")
    
    # ==================== 組4: 自然產產婦 (10人) ====================
    print("\n組4: 自然產產婦 (10人)")
    vaginal_delivery = 0
    for i in range(10):
        # Patient (女性)
        birth_year = random.randint(1990, 2005)  # 20-35歲
        bundle["entry"].append(generate_patient(patient_id, gender='female', birth_year=birth_year))
        
        # Encounter (住院)
        start_dt = random_datetime(START_DATE, END_DATE - timedelta(days=5))
        end_dt = start_dt + timedelta(days=random.randint(2, 3))  # 自然產住院2-3天
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'IMP', start_dt, end_dt))
        
        # Condition (自然分娩)
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, 'O80', '自然單胎分娩'))
        
        vaginal_delivery += 1
        patient_id += 1
        enc_id += 1
        cond_id += 1
    
    print(f"  生成: {10}個Patient, {10}個Encounter, {10}個Condition")
    
    # ==================== 組5: 剖腹產產婦-有適應症 (6人) ====================
    print("\n組5: 剖腹產產婦-有適應症 (6人)")
    cesarean_with_indication = 0
    first_time_cesarean = 0
    
    # 剖腹產適應症
    indications = [
        ('O32.1', '臀位'),
        ('O32.2', '橫位'),
        ('O44.0', '前置胎盤'),
        ('O33.9', '骨盆狹窄'),
        ('O36.3', '胎兒窘迫'),
        ('O64.9', '難產')
    ]
    
    for i in range(6):
        # Patient (女性)
        birth_year = random.randint(1988, 2003)
        bundle["entry"].append(generate_patient(patient_id, gender='female', birth_year=birth_year))
        
        # Encounter (住院)
        start_dt = random_datetime(START_DATE, END_DATE - timedelta(days=7))
        end_dt = start_dt + timedelta(days=random.randint(4, 5))  # 剖腹產住院4-5天
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'IMP', start_dt, end_dt))
        
        # Condition (剖腹產適應症)
        indication = random.choice(indications)
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, indication[0], indication[1]))
        cond_id += 1
        
        # Condition (剖腹產後狀態)
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, 'O82', '剖腹產分娩'))
        
        # Procedure (剖腹產手術)
        surgery_dt = start_dt + timedelta(hours=random.randint(2, 6))
        bundle["entry"].append(generate_procedure(proc_id, patient_id, enc_id, '10D00Z0', '低位剖腹產', surgery_dt))
        
        # Observation (產次記錄) - 60%為初產婦
        is_first_time = (i < 4)  # 前4人為初產婦
        gravida = 1 if is_first_time else random.randint(2, 3)
        para = 0 if is_first_time else gravida - 1
        bundle["entry"].append(generate_observation_gravida(obs_id, patient_id, enc_id, gravida, para))
        
        if is_first_time:
            first_time_cesarean += 1
        
        cesarean_with_indication += 1
        patient_id += 1
        enc_id += 1
        cond_id += 1
        proc_id += 1
        obs_id += 1
    
    print(f"  生成: {6}個Patient, {6}個Encounter, {12}個Condition, {6}個Procedure, {6}個Observation")
    print(f"  其中初產婦: {first_time_cesarean}人")
    
    # ==================== 組6: 正常出院患者 (12人) ====================
    print("\n組6: 正常出院患者-3天內無急診 (12人)")
    for i in range(12):
        # Patient
        bundle["entry"].append(generate_patient(patient_id, gender=random.choice(['male', 'female']), birth_year=random.randint(1960, 2000)))
        
        # Encounter (住院)
        start_dt = random_datetime(START_DATE, END_DATE - timedelta(days=10))
        end_dt = start_dt + timedelta(days=random.randint(5, 7))
        bundle["entry"].append(generate_encounter(enc_id, patient_id, 'IMP', start_dt, end_dt))
        
        # Condition
        diseases = [
            ('K80.2', '膽結石'),
            ('M17.9', '膝關節炎'),
            ('L03.9', '蜂窩性組織炎'),
            ('K35.8', '急性闌尾炎'),
            ('N20.0', '腎結石')
        ]
        disease = random.choice(diseases)
        bundle["entry"].append(generate_condition(cond_id, patient_id, enc_id, disease[0], disease[1]))
        
        patient_id += 1
        enc_id += 1
        cond_id += 1
    
    print(f"  生成: {12}個Patient, {12}個Encounter, {12}個Condition")
    
    # ==================== 統計 ====================
    total_patients = PATIENT_COUNT
    total_resources = len(bundle["entry"])
    
    print("\n" + "=" * 60)
    print("生成統計")
    print("=" * 60)
    print(f"總病人數: {total_patients}")
    print(f"總資源數: {total_resources}")
    print(f"  - Patient: {total_patients}")
    print(f"  - Encounter: {sum(1 for e in bundle['entry'] if e['resource']['resourceType'] == 'Encounter')}")
    print(f"  - Condition: {sum(1 for e in bundle['entry'] if e['resource']['resourceType'] == 'Condition')}")
    print(f"  - Procedure: {sum(1 for e in bundle['entry'] if e['resource']['resourceType'] == 'Procedure')}")
    print(f"  - Observation: {sum(1 for e in bundle['entry'] if e['resource']['resourceType'] == 'Observation')}")
    
    print("\n預期指標結果:")
    
    # Indicator-09: 14天內非計畫再入院率
    total_discharges_09 = 10 + 5 + 3 + 12  # 所有第一次住院出院數
    readmissions_09 = 5
    rate_09 = (readmissions_09 / total_discharges_09 * 100) if total_discharges_09 > 0 else 0
    print(f"  Indicator-09 (14天內再入院率): {readmissions_09}/{total_discharges_09} = {rate_09:.2f}%")
    
    # Indicator-10: 出院後3天內急診率
    total_discharges_10 = 10 + 3 + 12  # 非產科住院出院數
    ed_within_3days_10 = 3
    rate_10 = (ed_within_3days_10 / total_discharges_10 * 100) if total_discharges_10 > 0 else 0
    print(f"  Indicator-10 (出院後3天內急診率): {ed_within_3days_10}/{total_discharges_10} = {rate_10:.2f}%")
    
    # Indicator-11-1: 整體剖腹產率
    total_deliveries = 10 + 6
    cesarean_deliveries = 6
    rate_11_1 = (cesarean_deliveries / total_deliveries * 100) if total_deliveries > 0 else 0
    print(f"  Indicator-11-1 (整體剖腹產率): {cesarean_deliveries}/{total_deliveries} = {rate_11_1:.2f}%")
    
    # Indicator-11-3: 有適應症剖腹產率
    cesarean_with_ind = 6
    total_cesarean = 6
    rate_11_3 = (cesarean_with_ind / total_cesarean * 100) if total_cesarean > 0 else 0
    print(f"  Indicator-11-3 (有適應症剖腹產率): {cesarean_with_ind}/{total_cesarean} = {rate_11_3:.2f}%")
    
    # Indicator-11-4: 初產婦剖腹產率
    first_time_cesarean_total = 4
    rate_11_4 = (first_time_cesarean_total / total_cesarean * 100) if total_cesarean > 0 else 0
    print(f"  Indicator-11-4 (初產婦剖腹產率): {first_time_cesarean_total}/{total_cesarean} = {rate_11_4:.2f}%")
    
    # 保存檔案
    output_file = 'inpatient_quality_46_bundle.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Bundle已保存至: {output_file}")
    print("=" * 60)

if __name__ == '__main__':
    main()
