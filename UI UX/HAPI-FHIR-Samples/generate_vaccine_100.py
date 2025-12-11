import json
import random
from datetime import datetime, timedelta

print("🏥 開始生成 100 筆台灣疫苗接種數據（TW00101-TW00200）...")

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

# 疫苗類型配置（CVX代碼）
VACCINES = {
    'flu': {
        'count': 79,  # 79%
        'cvx_codes': [
            {'code': '141', 'display': 'Influenza, seasonal, injectable'},
            {'code': '185', 'display': 'Influenza, seasonal, injectable, quadrivalent'}
        ],
        'doses': 1,  # 流感一年打1劑
        'text': 'Influenza vaccine'
    },
    'covid': {
        'count': 21,  # 21%
        'cvx_codes': [
            {'code': '208', 'display': 'COVID-19, mRNA, LNP-S, PF, 30 mcg/0.3 mL dose (Pfizer)'},
            {'code': '207', 'display': 'COVID-19, mRNA, LNP-S, PF, 100 mcg/0.5 mL dose (Moderna)'}
        ],
        'doses_range': [1, 3],  # COVID-19: 1-3劑
        'text': 'COVID-19 vaccine'
    }
}

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

def generate_immunization(patient_id, vaccine_type, dose_number, total_doses):
    """生成疫苗接種記錄"""
    vaccine_config = VACCINES[vaccine_type]
    
    # 隨機選擇疫苗品牌
    cvx = random.choice(vaccine_config['cvx_codes'])
    
    # 接種日期（2024-2025流感季 / COVID持續接種）
    if vaccine_type == 'flu':
        # 流感季：2024年10月 - 2025年1月
        base_date = datetime(2024, 10, 1)
        days_offset = random.randint(0, 120)
    else:
        # COVID：2024年全年
        base_date = datetime(2024, 1, 1)
        days_offset = random.randint(0, 365) + (dose_number - 1) * 90  # 每劑間隔3個月
    
    occurrence_date = (base_date + timedelta(days=days_offset)).strftime('%Y-%m-%d')
    
    # 疫苗ID格式：TW00101-flu-1 或 TW00101-covid-2
    immunization_id = f"{patient_id}-{vaccine_type}-{dose_number}"
    
    return {
        "resourceType": "Immunization",
        "id": immunization_id,
        "status": "completed",
        "vaccineCode": {
            "coding": [{
                "system": "http://hl7.org/fhir/sid/cvx",
                "code": cvx['code'],
                "display": cvx['display']
            }],
            "text": vaccine_config['text']
        },
        "patient": {
            "reference": f"Patient/{patient_id}"
        },
        "occurrenceDateTime": occurrence_date,
        "primarySource": True,
        "lotNumber": f"LOT{random.randint(100000, 999999)}",
        "expirationDate": "2026-12-31",
        "site": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActSite",
                "code": "LA",
                "display": "left arm"
            }]
        },
        "route": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/v3-RouteOfAdministration",
                "code": "IM",
                "display": "Injection, intramuscular"
            }]
        },
        "doseQuantity": {
            "value": 0.5,
            "unit": "mL",
            "system": "http://unitsofmeasure.org",
            "code": "mL"
        },
        "protocolApplied": [{
            "doseNumberPositiveInt": dose_number,
            "seriesDosesPositiveInt": total_doses
        }]
    }

def generate_all_data():
    """生成全部數據"""
    entries = []
    stats = {
        'patients': 0,
        'flu_immunizations': 0,
        'covid_immunizations': 0
    }
    
    # 分配疫苗類型
    patient_ids = [f"TW{str(i).zfill(5)}" for i in range(101, 201)]
    random.shuffle(patient_ids)
    
    flu_patients = patient_ids[:79]
    covid_patients = patient_ids[79:]
    
    print(f"分配：流感疫苗 {len(flu_patients)} 人，COVID-19疫苗 {len(covid_patients)} 人")
    
    # 生成流感疫苗數據
    for patient_id in flu_patients:
        # 病人資料
        patient = generate_patient(patient_id)
        entries.append({
            "resource": patient,
            "request": {
                "method": "PUT",
                "url": f"Patient/{patient_id}"
            }
        })
        stats['patients'] += 1
        
        # 流感疫苗（1劑）
        immunization = generate_immunization(patient_id, 'flu', 1, 1)
        entries.append({
            "resource": immunization,
            "request": {
                "method": "PUT",
                "url": f"Immunization/{immunization['id']}"
            }
        })
        stats['flu_immunizations'] += 1
        
        if (stats['patients']) % 20 == 0:
            print(f"已生成 {stats['patients']}/100 筆病人資料...")
    
    # 生成COVID-19疫苗數據
    for patient_id in covid_patients:
        # 病人資料
        patient = generate_patient(patient_id)
        entries.append({
            "resource": patient,
            "request": {
                "method": "PUT",
                "url": f"Patient/{patient_id}"
            }
        })
        stats['patients'] += 1
        
        # COVID-19疫苗（1-3劑）
        num_doses = random.randint(1, 3)
        for dose in range(1, num_doses + 1):
            immunization = generate_immunization(patient_id, 'covid', dose, num_doses)
            entries.append({
                "resource": immunization,
                "request": {
                    "method": "PUT",
                    "url": f"Immunization/{immunization['id']}"
                }
            })
            stats['covid_immunizations'] += 1
        
        if (stats['patients']) % 20 == 0:
            print(f"已生成 {stats['patients']}/100 筆病人資料...")
    
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
output_file = 'vaccine_100_bundle.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

file_size = len(json.dumps(bundle, ensure_ascii=False)) / 1024

print(f"\n✅ 生成完成！")
print(f"病人總數: {stats['patients']}")
print(f"流感疫苗: {stats['flu_immunizations']} 筆")
print(f"COVID-19疫苗: {stats['covid_immunizations']} 筆")
print(f"總資源數: {len(entries)}")
print(f"\n已保存到文件: {output_file}")
print(f"文件大小: {file_size:.2f} KB")

# 保存統計
stats_file = 'vaccine_100_stats.json'
with open(stats_file, 'w', encoding='utf-8') as f:
    json.dump(stats, f, ensure_ascii=False, indent=2)
print(f"已保存統計資訊到: {stats_file}")
