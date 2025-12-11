"""
傳染病監測數據生成器
生成 800-1000 筆符合 FHIR R4 標準的病人資料，專注於傳染病監測
"""

import json
import random
from datetime import datetime, timedelta
from typing import List, Dict

# 台灣常見姓氏和名字
SURNAMES = ['陳', '林', '黃', '張', '李', '王', '吳', '劉', '蔡', '楊', '許', '鄭', '謝', '郭', '洪']
GIVEN_NAMES_MALE = ['志明', '建宏', '家豪', '俊傑', '冠廷', '宗翰', '柏翰', '承翰', '彥廷', '宇軒']
GIVEN_NAMES_FEMALE = ['淑芬', '雅婷', '怡君', '佳穎', '詩涵', '宜庭', '怡婷', '欣怡', '筱涵', '雅筠']

# 台灣縣市
CITIES = ['台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市', '基隆市', '新竹市', '嘉義市', '宜蘭縣', '新竹縣', '苗栗縣', '彰化縣', '南投縣', '雲林縣', '嘉義縣', '屏東縣', '花蓮縣', '台東縣', '澎湖縣']

# 傳染病相關 ICD-10 診斷碼
DISEASE_CODES = {
    'covid19': {
        'codes': ['U07.1', 'U07.2'],
        'display': ['COVID-19', 'COVID-19 (suspected)'],
        'severity': ['mild', 'moderate', 'severe', 'critical'],
        'weight': [0.65, 0.25, 0.08, 0.02]  # 65% 輕症, 25% 中症, 8% 重症, 2% 危重
    },
    'influenza': {
        'codes': ['J09', 'J10.0', 'J10.1', 'J10.8', 'J11.0', 'J11.1'],
        'display': ['流感', '流感引起的肺炎', '流感伴其他呼吸系統表現', '流感伴其他表現', '非特定型流感伴肺炎', '非特定型流感伴其他呼吸系統表現'],
        'severity': ['mild', 'moderate', 'severe'],
        'weight': [0.70, 0.25, 0.05]
    },
    'conjunctivitis': {
        'codes': ['H10.0', 'H10.1', 'H10.2', 'H10.3', 'H10.9'],
        'display': ['黏液膿性結膜炎', '急性結膜炎', '其他急性結膜炎', '急性結膜炎(未特定)', '結膜炎(未特定)'],
        'severity': ['mild', 'moderate'],
        'weight': [0.85, 0.15]
    },
    'enterovirus': {
        'codes': ['A87.0', 'B08.4', 'B08.5', 'B34.1'],
        'display': ['腸病毒腦膜炎', '手足口病', '咽結膜熱', '腸病毒感染'],
        'severity': ['mild', 'moderate', 'severe'],
        'weight': [0.75, 0.20, 0.05]
    },
    'diarrhea': {
        'codes': ['A00.0', 'A00.9', 'A01.0', 'A02.0', 'A03.0', 'A04.0', 'A04.7', 'A08.0', 'A08.1', 'A08.2', 'A09'],
        'display': ['霍亂', '霍亂(未特定)', '傷寒', '沙門氏菌腸炎', '志賀桿菌病', '腸道致病性大腸桿菌感染', '困難梭菌腸炎', '輪狀病毒腸炎', '諾羅病毒腸炎', '腺病毒腸炎', '急性腸胃炎'],
        'severity': ['mild', 'moderate', 'severe'],
        'weight': [0.70, 0.25, 0.05]
    }
}

# COVID-19 疫苗 CVX 代碼
COVID_VACCINES = [
    {'code': '207', 'display': 'Moderna COVID-19 vaccine'},
    {'code': '208', 'display': 'Pfizer-BioNTech COVID-19 vaccine'},
    {'code': '210', 'display': 'AstraZeneca COVID-19 vaccine'},
    {'code': '212', 'display': 'Janssen COVID-19 vaccine'},
    {'code': '213', 'display': 'SARS-COV-2 (COVID-19) vaccine, UNSPECIFIED'},
    {'code': '217', 'display': 'Novavax COVID-19 vaccine'},
    {'code': '218', 'display': 'Pfizer-BioNTech COVID-19 vaccine (Comirnaty)'},
    {'code': '219', 'display': 'Moderna COVID-19 vaccine (Spikevax)'},
    {'code': '221', 'display': 'Pfizer-BioNTech COVID-19 vaccine for 5-11 years'},
    {'code': '228', 'display': 'Pfizer-BioNTech COVID-19 vaccine for 6 months-4 years'},
    {'code': '229', 'display': 'Moderna COVID-19 vaccine for 6 months-5 years'},
    {'code': '300', 'display': 'Medigen COVID-19 vaccine'}  # 台灣高端疫苗
]

# 流感疫苗 CVX 代碼
INFLUENZA_VACCINES = [
    {'code': '141', 'display': 'Influenza vaccine, seasonal'},
    {'code': '150', 'display': 'Influenza vaccine, injectable, quadrivalent'},
    {'code': '161', 'display': 'Influenza vaccine, injectable, trivalent'},
    {'code': '185', 'display': 'Influenza vaccine, seasonal, quadrivalent'}
]

class InfectiousDiseaseDataGenerator:
    def __init__(self, num_patients: int = 900):
        self.num_patients = num_patients
        self.patients = []
        self.conditions = []
        self.encounters = []
        self.observations = []
        self.immunizations = []
        self.start_date = datetime.now() - timedelta(days=365)
        self.end_date = datetime.now()
        
    def generate_patient_id(self, index: int) -> str:
        """生成病人 ID"""
        return f"patient-infectious-{index:04d}"
    
    def generate_encounter_id(self, patient_id: str, index: int) -> str:
        """生成就診 ID"""
        return f"{patient_id}-encounter-{index:03d}"
    
    def generate_condition_id(self, patient_id: str, index: int) -> str:
        """生成診斷 ID"""
        return f"{patient_id}-condition-{index:03d}"
    
    def generate_observation_id(self, patient_id: str, index: int) -> str:
        """生成觀察 ID"""
        return f"{patient_id}-observation-{index:03d}"
    
    def generate_immunization_id(self, patient_id: str, index: int) -> str:
        """生成疫苗接種 ID"""
        return f"{patient_id}-immunization-{index:03d}"
    
    def random_date(self, start: datetime, end: datetime) -> str:
        """生成隨機日期"""
        delta = end - start
        random_days = random.randint(0, delta.days)
        random_date = start + timedelta(days=random_days)
        return random_date.strftime('%Y-%m-%d')
    
    def generate_patient(self, index: int) -> Dict:
        """生成單一病人資源"""
        patient_id = self.generate_patient_id(index)
        gender = random.choice(['male', 'female'])
        surname = random.choice(SURNAMES)
        given_name = random.choice(GIVEN_NAMES_MALE if gender == 'male' else GIVEN_NAMES_FEMALE)
        
        # 年齡分布：模擬各年齡層
        age_group = random.choices(
            [0, 10, 20, 30, 40, 50, 60, 70, 80],
            weights=[0.10, 0.12, 0.15, 0.18, 0.18, 0.12, 0.10, 0.03, 0.02]
        )[0]
        birth_year = datetime.now().year - age_group - random.randint(0, 9)
        birth_date = f"{birth_year}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}"
        
        city = random.choice(CITIES)
        
        patient = {
            "resourceType": "Patient",
            "id": patient_id,
            "identifier": [{
                "system": "urn:oid:2.16.886.101.20003.20001",
                "value": f"ID{random.randint(100000000, 999999999)}"
            }],
            "name": [{
                "family": surname,
                "given": [given_name],
                "text": f"{surname}{given_name}"
            }],
            "gender": gender,
            "birthDate": birth_date,
            "address": [{
                "city": city,
                "country": "TW"
            }]
        }
        
        return patient
    
    def generate_encounter(self, patient_id: str, encounter_index: int, date: str, disease_type: str) -> Dict:
        """生成就診資源"""
        encounter_id = self.generate_encounter_id(patient_id, encounter_index)
        
        # 根據疾病類型決定就診類別
        if disease_type in ['covid19', 'enterovirus'] and random.random() < 0.15:
            encounter_class = 'IMP'  # 住院
            encounter_type = 'inpatient'
        else:
            encounter_class = 'AMB'  # 門診
            encounter_type = 'outpatient'
        
        encounter = {
            "resourceType": "Encounter",
            "id": encounter_id,
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": encounter_class,
                "display": "Ambulatory" if encounter_class == 'AMB' else "Inpatient"
            },
            "type": [{
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "185345009" if encounter_class == 'AMB' else "32485007",
                    "display": "Encounter for problem" if encounter_class == 'AMB' else "Hospital admission"
                }]
            }],
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "period": {
                "start": f"{date}T08:00:00Z",
                "end": f"{date}T10:00:00Z" if encounter_class == 'AMB' else None
            }
        }
        
        if encounter_class == 'IMP':
            # 住院天數
            days = random.randint(3, 14)
            end_date = (datetime.strptime(date, '%Y-%m-%d') + timedelta(days=days)).strftime('%Y-%m-%d')
            encounter['period']['end'] = f"{end_date}T10:00:00Z"
        
        return encounter
    
    def generate_condition(self, patient_id: str, condition_index: int, encounter_id: str, date: str, disease_type: str) -> Dict:
        """生成診斷資源"""
        condition_id = self.generate_condition_id(patient_id, condition_index)
        
        disease_info = DISEASE_CODES[disease_type]
        code_index = random.randint(0, len(disease_info['codes']) - 1)
        icd_code = disease_info['codes'][code_index]
        display = disease_info['display'][code_index]
        
        severity = random.choices(disease_info['severity'], weights=disease_info['weight'])[0]
        
        condition = {
            "resourceType": "Condition",
            "id": condition_id,
            "clinicalStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                    "code": "active" if random.random() < 0.3 else "resolved",
                    "display": "Active" if random.random() < 0.3 else "Resolved"
                }]
            },
            "verificationStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                    "code": "confirmed",
                    "display": "Confirmed"
                }]
            },
            "category": [{
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-category",
                    "code": "encounter-diagnosis",
                    "display": "Encounter Diagnosis"
                }]
            }],
            "severity": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "255604002" if severity == 'mild' else ("6736007" if severity == 'moderate' else "24484000"),
                    "display": severity.capitalize()
                }]
            },
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10",
                    "code": icd_code,
                    "display": display
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{encounter_id}"
            },
            "onsetDateTime": date,
            "recordedDate": date
        }
        
        return condition
    
    def generate_observation(self, patient_id: str, obs_index: int, encounter_id: str, date: str, disease_type: str) -> Dict:
        """生成觀察資源（症狀、檢驗結果）"""
        observation_id = self.generate_observation_id(patient_id, obs_index)
        
        # 根據疾病類型生成不同觀察項目
        observations_data = {
            'covid19': [
                {'code': '8310-5', 'display': 'Body temperature', 'value': round(random.uniform(37.5, 39.5), 1), 'unit': 'Cel'},
                {'code': '59408-5', 'display': 'Oxygen saturation', 'value': random.randint(90, 98), 'unit': '%'},
                {'code': '94500-6', 'display': 'SARS-CoV-2 RNA', 'value': random.choice(['Positive', 'Negative'])}
            ],
            'influenza': [
                {'code': '8310-5', 'display': 'Body temperature', 'value': round(random.uniform(38.0, 40.0), 1), 'unit': 'Cel'},
                {'code': '94558-4', 'display': 'Influenza A RNA', 'value': random.choice(['Positive', 'Negative'])},
                {'code': '94559-2', 'display': 'Influenza B RNA', 'value': random.choice(['Positive', 'Negative'])}
            ],
            'conjunctivitis': [
                {'code': '8310-5', 'display': 'Body temperature', 'value': round(random.uniform(36.5, 37.5), 1), 'unit': 'Cel'}
            ],
            'enterovirus': [
                {'code': '8310-5', 'display': 'Body temperature', 'value': round(random.uniform(38.0, 39.5), 1), 'unit': 'Cel'},
                {'code': '94316-7', 'display': 'Enterovirus RNA', 'value': random.choice(['Positive', 'Negative'])}
            ],
            'diarrhea': [
                {'code': '8310-5', 'display': 'Body temperature', 'value': round(random.uniform(37.0, 39.0), 1), 'unit': 'Cel'},
                {'code': '625-4', 'display': 'Bacteria identified in Stool', 'value': random.choice(['No growth', 'Salmonella', 'E.coli', 'Shigella'])}
            ]
        }
        
        obs_data = random.choice(observations_data.get(disease_type, observations_data['covid19']))
        
        observation = {
            "resourceType": "Observation",
            "id": observation_id,
            "status": "final",
            "category": [{
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                    "code": "laboratory" if 'RNA' in obs_data['display'] or 'Bacteria' in obs_data['display'] else "vital-signs",
                    "display": "Laboratory" if 'RNA' in obs_data['display'] or 'Bacteria' in obs_data['display'] else "Vital Signs"
                }]
            }],
            "code": {
                "coding": [{
                    "system": "http://loinc.org",
                    "code": obs_data['code'],
                    "display": obs_data['display']
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{encounter_id}"
            },
            "effectiveDateTime": date
        }
        
        # 數值或文字結果
        if isinstance(obs_data['value'], str):
            observation["valueString"] = obs_data['value']
        else:
            observation["valueQuantity"] = {
                "value": obs_data['value'],
                "unit": obs_data.get('unit', ''),
                "system": "http://unitsofmeasure.org",
                "code": obs_data.get('unit', '')
            }
        
        return observation
    
    def generate_immunization(self, patient_id: str, imm_index: int, date: str, vaccine_type: str) -> Dict:
        """生成疫苗接種資源"""
        immunization_id = self.generate_immunization_id(patient_id, imm_index)
        
        if vaccine_type == 'covid19':
            vaccine = random.choice(COVID_VACCINES)
        else:
            vaccine = random.choice(INFLUENZA_VACCINES)
        
        immunization = {
            "resourceType": "Immunization",
            "id": immunization_id,
            "status": "completed",
            "vaccineCode": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/cvx",
                    "code": vaccine['code'],
                    "display": vaccine['display']
                }]
            },
            "patient": {
                "reference": f"Patient/{patient_id}"
            },
            "occurrenceDateTime": date,
            "recorded": date,
            "primarySource": True,
            "lotNumber": f"LOT{random.randint(100000, 999999)}",
            "expirationDate": (datetime.strptime(date, '%Y-%m-%d') + timedelta(days=365)).strftime('%Y-%m-%d'),
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
            }
        }
        
        # 劑量資訊
        if vaccine_type == 'covid19':
            dose_number = random.randint(1, 4)
            immunization["protocolApplied"] = [{
                "doseNumberPositiveInt": dose_number,
                "seriesDosesPositiveInt": 3 if dose_number <= 3 else 4
            }]
        else:
            immunization["protocolApplied"] = [{
                "doseNumberPositiveInt": 1,
                "seriesDosesPositiveInt": 1
            }]
        
        return immunization
    
    def generate_all_data(self):
        """生成所有數據"""
        print(f"開始生成 {self.num_patients} 筆傳染病監測數據...")
        
        for i in range(self.num_patients):
            # 生成病人
            patient = self.generate_patient(i)
            patient_id = patient['id']
            self.patients.append(patient)
            
            # 決定病人感染的疾病類型（可能多種）
            num_diseases = random.choices([1, 2, 3], weights=[0.70, 0.25, 0.05])[0]
            disease_types = random.sample(list(DISEASE_CODES.keys()), num_diseases)
            
            encounter_counter = 0
            condition_counter = 0
            observation_counter = 0
            immunization_counter = 0
            
            # 為每種疾病生成就診記錄
            for disease_type in disease_types:
                # 每種疾病可能有多次就診
                num_encounters = random.choices([1, 2, 3], weights=[0.60, 0.30, 0.10])[0]
                
                for _ in range(num_encounters):
                    # 生成就診日期
                    encounter_date = self.random_date(self.start_date, self.end_date)
                    
                    # 生成就診
                    encounter = self.generate_encounter(patient_id, encounter_counter, encounter_date, disease_type)
                    self.encounters.append(encounter)
                    encounter_id = encounter['id']
                    encounter_counter += 1
                    
                    # 生成診斷
                    condition = self.generate_condition(patient_id, condition_counter, encounter_id, encounter_date, disease_type)
                    self.conditions.append(condition)
                    condition_counter += 1
                    
                    # 生成觀察（症狀、檢驗）
                    num_observations = random.randint(2, 4)
                    for _ in range(num_observations):
                        observation = self.generate_observation(patient_id, observation_counter, encounter_id, encounter_date, disease_type)
                        self.observations.append(observation)
                        observation_counter += 1
            
            # 生成疫苗接種記錄（約70%的人有COVID-19疫苗，50%有流感疫苗）
            if random.random() < 0.70:
                # COVID-19 疫苗（1-4劑）
                num_doses = random.choices([1, 2, 3, 4], weights=[0.10, 0.30, 0.40, 0.20])[0]
                for dose in range(num_doses):
                    vacc_date = self.random_date(self.start_date - timedelta(days=365), self.end_date)
                    immunization = self.generate_immunization(patient_id, immunization_counter, vacc_date, 'covid19')
                    self.immunizations.append(immunization)
                    immunization_counter += 1
            
            if random.random() < 0.50:
                # 流感疫苗
                vacc_date = self.random_date(self.start_date, self.end_date)
                immunization = self.generate_immunization(patient_id, immunization_counter, vacc_date, 'influenza')
                self.immunizations.append(immunization)
                immunization_counter += 1
            
            if (i + 1) % 100 == 0:
                print(f"已生成 {i + 1}/{self.num_patients} 筆病人資料...")
        
        print(f"\n生成完成！")
        print(f"病人總數: {len(self.patients)}")
        print(f"就診記錄: {len(self.encounters)}")
        print(f"診斷記錄: {len(self.conditions)}")
        print(f"觀察記錄: {len(self.observations)}")
        print(f"疫苗接種: {len(self.immunizations)}")
        print(f"總資源數: {len(self.patients) + len(self.encounters) + len(self.conditions) + len(self.observations) + len(self.immunizations)}")
    
    def create_bundle(self) -> Dict:
        """創建 FHIR Bundle"""
        entries = []
        
        # 加入所有資源
        for patient in self.patients:
            entries.append({
                "resource": patient,
                "request": {
                    "method": "PUT",
                    "url": f"Patient/{patient['id']}"
                }
            })
        
        for encounter in self.encounters:
            entries.append({
                "resource": encounter,
                "request": {
                    "method": "PUT",
                    "url": f"Encounter/{encounter['id']}"
                }
            })
        
        for condition in self.conditions:
            entries.append({
                "resource": condition,
                "request": {
                    "method": "PUT",
                    "url": f"Condition/{condition['id']}"
                }
            })
        
        for observation in self.observations:
            entries.append({
                "resource": observation,
                "request": {
                    "method": "PUT",
                    "url": f"Observation/{observation['id']}"
                }
            })
        
        for immunization in self.immunizations:
            entries.append({
                "resource": immunization,
                "request": {
                    "method": "PUT",
                    "url": f"Immunization/{immunization['id']}"
                }
            })
        
        bundle = {
            "resourceType": "Bundle",
            "type": "transaction",
            "entry": entries
        }
        
        return bundle
    
    def save_to_file(self, filename: str = 'infectious_disease_bundle.json'):
        """保存到文件"""
        bundle = self.create_bundle()
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(bundle, f, ensure_ascii=False, indent=2)
        
        print(f"\n已保存到文件: {filename}")
        print(f"文件大小: {len(json.dumps(bundle)) / 1024 / 1024:.2f} MB")
        
        # 保存統計資訊
        stats = {
            'total_patients': len(self.patients),
            'total_encounters': len(self.encounters),
            'total_conditions': len(self.conditions),
            'total_observations': len(self.observations),
            'total_immunizations': len(self.immunizations),
            'total_resources': len(bundle['entry']),
            'disease_distribution': {
                'covid19': {'total': 0, 'severity': {}},
                'influenza': {'total': 0, 'severity': {}},
                'conjunctivitis': {'total': 0, 'severity': {}},
                'enterovirus': {'total': 0, 'severity': {}},
                'diarrhea': {'total': 0, 'severity': {}}
            },
            'vaccine_distribution': {
                'covid19': 0,
                'influenza': 0
            }
        }
        
        # 統計疾病分布（按疾病類別）
        for condition in self.conditions:
            code = condition['code']['coding'][0]['code']
            severity = condition.get('severity', {}).get('coding', [{}])[0].get('code', 'mild')
            
            # 判斷疾病類別
            disease_type = None
            for dtype, dcodes in DISEASE_CODES.items():
                if code in dcodes['codes']:
                    disease_type = dtype
                    break
            
            if disease_type:
                stats['disease_distribution'][disease_type]['total'] += 1
                if severity not in stats['disease_distribution'][disease_type]['severity']:
                    stats['disease_distribution'][disease_type]['severity'][severity] = 0
                stats['disease_distribution'][disease_type]['severity'][severity] += 1
        
        # 統計疫苗分布
        for immunization in self.immunizations:
            code = immunization['vaccineCode']['coding'][0]['code']
            if code in [v['code'] for v in COVID_VACCINES]:
                stats['vaccine_distribution']['covid19'] += 1
            else:
                stats['vaccine_distribution']['influenza'] += 1
        
        with open('infectious_disease_stats.json', 'w', encoding='utf-8') as f:
            json.dump(stats, f, ensure_ascii=False, indent=2)
        
        print(f"已保存統計資訊到: infectious_disease_stats.json")

def main():
    # 生成 900 筆病人資料（可在 800-1000 之間調整）
    generator = InfectiousDiseaseDataGenerator(num_patients=900)
    generator.generate_all_data()
    generator.save_to_file('infectious_disease_bundle.json')
    
    print("\n=== 數據生成完成 ===")
    print("文件已準備好，等待您確認後上傳到 FHIR 伺服器")

if __name__ == '__main__':
    main()
