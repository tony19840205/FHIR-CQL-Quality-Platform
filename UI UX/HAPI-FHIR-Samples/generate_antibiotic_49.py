import json
import random
from datetime import datetime, timedelta

print("💊 開始生成 49 筆抗生素使用數據（TW00201-TW00249）...")

# 台灣姓氏（前20大姓）
SURNAMES = ['陳', '林', '黃', '張', '李', '王', '吳', '劉', '蔡', '楊',
            '許', '鄭', '謝', '郭', '洪', '邱', '曾', '廖', '賴', '徐']

# 台灣常見名字（性別區分）
GIVEN_NAMES_MALE = ['志明', '家豪', '俊傑', '建宏', '冠宇', '柏翰', '承翰', '宗翰', '宇軒', '政廷',
                    '文彬', '文雄', '世豪', '俊宏', '俊宇', '俊廷', '冠廷', '家銘', '志豪', '明哲']
GIVEN_NAMES_FEMALE = ['淑芬', '怡君', '淑惠', '美玲', '雅婷', '怡萱', '詩涵', '雅筑', '欣怡', '佳穎',
                      '淑娟', '美惠', '麗華', '秀英', '雅雯', '怡靜', '宜蓁', '佳蓉', '雅芳', '淑玲']

# 台灣22縣市
TAIWAN_CITIES = [
    '台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市',
    '基隆市', '新竹市', '嘉義市',
    '新竹縣', '苗栗縣', '彰化縣', '南投縣', '雲林縣', '嘉義縣',
    '屏東縣', '宜蘭縣', '花蓮縣', '台東縣', '澎湖縣', '金門縣', '連江縣'
]

# 抗生素配置（WHO AWaRe 分類）
ANTIBIOTICS = {
    'access': {
        'percentage': 0.60,  # 60%
        'medications': [
            {
                'name': 'Amoxicillin',
                'atc': 'J01CA04',
                'ddd': 1000,  # 1000mg
                'unit': 'mg',
                'route': 'PO',
                'frequency': 'TID'
            },
            {
                'name': 'Doxycycline',
                'atc': 'J01AA02',
                'ddd': 100,  # 100mg
                'unit': 'mg',
                'route': 'PO',
                'frequency': 'BID'
            }
        ]
    },
    'watch': {
        'percentage': 0.30,  # 30%
        'medications': [
            {
                'name': 'Ceftriaxone',
                'atc': 'J01DD04',
                'ddd': 2000,  # 2000mg
                'unit': 'mg',
                'route': 'IV',
                'frequency': 'QD'
            },
            {
                'name': 'Ciprofloxacin',
                'atc': 'J01MA02',
                'ddd': 800,  # 800mg
                'unit': 'mg',
                'route': 'PO',
                'frequency': 'BID'
            }
        ]
    },
    'reserve': {
        'percentage': 0.10,  # 10%
        'medications': [
            {
                'name': 'Vancomycin',
                'atc': 'J01XA01',
                'ddd': 2000,  # 2000mg
                'unit': 'mg',
                'route': 'IV',
                'frequency': 'BID'
            },
            {
                'name': 'Meropenem',
                'atc': 'J01DH02',
                'ddd': 3000,  # 3000mg
                'unit': 'mg',
                'route': 'IV',
                'frequency': 'TID'
            }
        ]
    }
}

# 常見感染診斷（ICD-10）
INFECTIONS = [
    {'code': 'J18.9', 'display': 'Pneumonia, unspecified organism'},
    {'code': 'N39.0', 'display': 'Urinary tract infection, site not specified'},
    {'code': 'L03.90', 'display': 'Cellulitis, unspecified'},
    {'code': 'J20.9', 'display': 'Acute bronchitis, unspecified'},
    {'code': 'A41.9', 'display': 'Sepsis, unspecified organism'},
]

def generate_patient(patient_id):
    """生成病人資料"""
    gender = random.choice(['male', 'female'])
    given_name = random.choice(GIVEN_NAMES_MALE if gender == 'male' else GIVEN_NAMES_FEMALE)
    surname = random.choice(SURNAMES)
    full_name = f"{surname}{given_name}"
    
    # 年齡：18-85歲
    age = random.randint(18, 85)
    birth_year = 2025 - age
    birth_date = f"{birth_year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    
    return {
        "resourceType": "Patient",
        "id": patient_id,
        "identifier": [{
            "system": "urn:oid:2.16.886.101.20003.20001",
            "value": patient_id
        }],
        "name": [{
            "text": full_name,
            "family": surname,
            "given": [given_name]
        }],
        "gender": gender,
        "birthDate": birth_date,
        "address": [{
            "city": random.choice(TAIWAN_CITIES),
            "country": "TW"
        }]
    }

def generate_encounter(patient_id, is_inpatient):
    """生成就醫記錄"""
    encounter_id = f"{patient_id}-encounter"
    
    # 住院或門診
    if is_inpatient:
        encounter_class = random.choice(['IMP', 'ACUTE'])
        # 住院日數：3-14天
        los = random.randint(3, 14)
        end_date = datetime(2025, random.randint(1, 11), random.randint(1, 28))
        start_date = end_date - timedelta(days=los)
    else:
        encounter_class = random.choice(['AMB', 'EMER'])
        # 門診當天
        start_date = datetime(2025, random.randint(1, 11), random.randint(1, 28))
        end_date = start_date + timedelta(hours=2)
    
    # 隨機感染診斷
    diagnosis = random.choice(INFECTIONS)
    
    return {
        "resourceType": "Encounter",
        "id": encounter_id,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": encounter_class
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "period": {
            "start": start_date.strftime('%Y-%m-%dT%H:%M:%S+08:00'),
            "end": end_date.strftime('%Y-%m-%dT%H:%M:%S+08:00')
        },
        "reasonCode": [{
            "coding": [{
                "system": "http://hl7.org/fhir/sid/icd-10",
                "code": diagnosis['code'],
                "display": diagnosis['display']
            }],
            "text": diagnosis['display']
        }]
    }, start_date, end_date

def select_antibiotic():
    """根據 WHO AWaRe 分類選擇抗生素"""
    rand = random.random()
    
    if rand < 0.60:  # 60% Access
        category = 'access'
    elif rand < 0.90:  # 30% Watch
        category = 'watch'
    else:  # 10% Reserve
        category = 'reserve'
    
    medication = random.choice(ANTIBIOTICS[category]['medications'])
    return medication, category

def generate_medication_request(patient_id, encounter_id, medication, authored_date):
    """生成抗生素醫囑"""
    request_id = f"{patient_id}-med-request"
    
    return {
        "resourceType": "MedicationRequest",
        "id": request_id,
        "status": "completed",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [{
                "system": "http://www.whocc.no/atc",
                "code": medication['atc'],
                "display": medication['name']
            }],
            "text": medication['name']
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "authoredOn": authored_date.strftime('%Y-%m-%dT%H:%M:%S+08:00'),
        "dosageInstruction": [{
            "timing": {
                "code": {
                    "coding": [{
                        "code": medication['frequency']
                    }]
                }
            },
            "route": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/v3-RouteOfAdministration",
                    "code": medication['route']
                }]
            },
            "doseAndRate": [{
                "doseQuantity": {
                    "value": medication['ddd'] / (3 if medication['frequency'] == 'TID' else 2 if medication['frequency'] == 'BID' else 1),
                    "unit": medication['unit'],
                    "system": "http://unitsofmeasure.org",
                    "code": medication['unit']
                }
            }]
        }]
    }

def generate_medication_administration(patient_id, medication, admin_date, dose_number):
    """生成抗生素給藥記錄"""
    admin_id = f"{patient_id}-med-admin-{dose_number}"
    
    dose_per_admin = medication['ddd'] / (3 if medication['frequency'] == 'TID' else 2 if medication['frequency'] == 'BID' else 1)
    
    return {
        "resourceType": "MedicationAdministration",
        "id": admin_id,
        "status": "completed",
        "medicationCodeableConcept": {
            "coding": [{
                "system": "http://www.whocc.no/atc",
                "code": medication['atc'],
                "display": medication['name']
            }],
            "text": medication['name']
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "effectiveDateTime": admin_date.strftime('%Y-%m-%dT%H:%M:%S+08:00'),
        "dosage": {
            "route": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/v3-RouteOfAdministration",
                    "code": medication['route']
                }]
            },
            "dose": {
                "value": dose_per_admin,
                "unit": medication['unit'],
                "system": "http://unitsofmeasure.org",
                "code": medication['unit']
            }
        }
    }

def generate_all_data():
    """生成全部數據"""
    entries = []
    stats = {
        'patients': 0,
        'encounters': 0,
        'medication_requests': 0,
        'medication_administrations': 0,
        'inpatient': 0,
        'outpatient': 0,
        'access': 0,
        'watch': 0,
        'reserve': 0,
        'total_bed_days': 0
    }
    
    # 分配住院/門診
    patient_ids = [f"TW{str(i).zfill(5)}" for i in range(201, 250)]
    random.shuffle(patient_ids)
    
    inpatient_ids = patient_ids[:20]  # 20人住院（40%）
    outpatient_ids = patient_ids[20:]  # 29人門診（60%）
    
    print(f"分配：住院 {len(inpatient_ids)} 人，門診 {len(outpatient_ids)} 人")
    
    # 生成住院病人數據
    for patient_id in inpatient_ids:
        # 病人資料
        patient = generate_patient(patient_id)
        entries.append({
            "resource": patient,
            "request": {"method": "PUT", "url": f"Patient/{patient_id}"}
        })
        stats['patients'] += 1
        stats['inpatient'] += 1
        
        # 就醫記錄
        encounter, start_date, end_date = generate_encounter(patient_id, True)
        entries.append({
            "resource": encounter,
            "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}
        })
        stats['encounters'] += 1
        
        # 計算住院日數
        los = (end_date - start_date).days
        stats['total_bed_days'] += los
        
        # 選擇抗生素
        medication, category = select_antibiotic()
        stats[category] += 1
        
        # 醫囑
        med_request = generate_medication_request(patient_id, encounter['id'], medication, start_date)
        entries.append({
            "resource": med_request,
            "request": {"method": "PUT", "url": f"MedicationRequest/{med_request['id']}"}
        })
        stats['medication_requests'] += 1
        
        # 給藥記錄（住院病人：2-3次）
        num_doses = random.randint(2, 3)
        for dose_num in range(1, num_doses + 1):
            admin_date = start_date + timedelta(days=dose_num - 1)
            med_admin = generate_medication_administration(patient_id, medication, admin_date, dose_num)
            entries.append({
                "resource": med_admin,
                "request": {"method": "PUT", "url": f"MedicationAdministration/{med_admin['id']}"}
            })
            stats['medication_administrations'] += 1
        
        if stats['patients'] % 10 == 0:
            print(f"已生成 {stats['patients']}/49 筆病人資料...")
    
    # 生成門診病人數據
    for patient_id in outpatient_ids:
        # 病人資料
        patient = generate_patient(patient_id)
        entries.append({
            "resource": patient,
            "request": {"method": "PUT", "url": f"Patient/{patient_id}"}
        })
        stats['patients'] += 1
        stats['outpatient'] += 1
        
        # 就醫記錄
        encounter, start_date, end_date = generate_encounter(patient_id, False)
        entries.append({
            "resource": encounter,
            "request": {"method": "PUT", "url": f"Encounter/{encounter['id']}"}
        })
        stats['encounters'] += 1
        
        # 選擇抗生素
        medication, category = select_antibiotic()
        stats[category] += 1
        
        # 醫囑
        med_request = generate_medication_request(patient_id, encounter['id'], medication, start_date)
        entries.append({
            "resource": med_request,
            "request": {"method": "PUT", "url": f"MedicationRequest/{med_request['id']}"}
        })
        stats['medication_requests'] += 1
        
        # 給藥記錄（門診病人：1-2次）
        num_doses = random.randint(1, 2)
        for dose_num in range(1, num_doses + 1):
            admin_date = start_date
            med_admin = generate_medication_administration(patient_id, medication, admin_date, dose_num)
            entries.append({
                "resource": med_admin,
                "request": {"method": "PUT", "url": f"MedicationAdministration/{med_admin['id']}"}
            })
            stats['medication_administrations'] += 1
        
        if stats['patients'] % 10 == 0:
            print(f"已生成 {stats['patients']}/49 筆病人資料...")
    
    return entries, stats

# 執行生成
entries, stats = generate_all_data()

# 建立 Bundle
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": entries
}

# 保存檔案
output_file = 'antibiotic_49_bundle.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

file_size = len(json.dumps(bundle, ensure_ascii=False)) / 1024

print(f"\n✅ 生成完成！")
print(f"病人總數: {stats['patients']}")
print(f"  - 住院: {stats['inpatient']} 人")
print(f"  - 門診: {stats['outpatient']} 人")
print(f"就醫記錄: {stats['encounters']} 筆")
print(f"抗生素醫囑: {stats['medication_requests']} 筆")
print(f"給藥記錄: {stats['medication_administrations']} 筆")
print(f"總住院日數: {stats['total_bed_days']} 天")
print(f"\nWHO AWaRe 分布:")
print(f"  - Access: {stats['access']} 人 ({stats['access']/49*100:.1f}%)")
print(f"  - Watch: {stats['watch']} 人 ({stats['watch']/49*100:.1f}%)")
print(f"  - Reserve: {stats['reserve']} 人 ({stats['reserve']/49*100:.1f}%)")
print(f"總資源數: {len(entries)}")
print(f"\n已保存到文件: {output_file}")
print(f"文件大小: {file_size:.2f} KB")

# 保存統計
stats_file = 'antibiotic_49_stats.json'
with open(stats_file, 'w', encoding='utf-8') as f:
    json.dump(stats, f, ensure_ascii=False, indent=2)
print(f"已保存統計資訊到: {stats_file}")
