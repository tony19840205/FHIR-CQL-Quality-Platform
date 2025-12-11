"""
生成 100 筆台灣在地化傳染病測試數據
基於 HAPI FHIR 樣本格式
"""

import json
import random
from datetime import datetime, timedelta
from typing import List, Dict

# 台灣常見姓氏和名字
SURNAMES = ['陳', '林', '黃', '張', '李', '王', '吳', '劉', '蔡', '楊', '許', '鄭', '謝', '郭', '洪', '邱', '曾', '廖', '賴', '徐']
GIVEN_NAMES_MALE = ['志明', '建宏', '家豪', '俊傑', '冠廷', '宗翰', '柏翰', '承翰', '彥廷', '宇軒', '哲瑋', '宥廷', '冠霖', '秉翰', '彥碩']
GIVEN_NAMES_FEMALE = ['淑芬', '雅婷', '怡君', '佳穎', '詩涵', '宜庭', '怡婷', '欣怡', '筱涵', '雅筠', '欣妤', '語彤', '依婷', '芷瑄', '思妤']

# 台灣縣市
TAIWAN_CITIES = [
    '台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市',
    '基隆市', '新竹市', '嘉義市', '新竹縣', '苗栗縣', '彰化縣',
    '南投縣', '雲林縣', '嘉義縣', '屏東縣', '宜蘭縣', '花蓮縣',
    '台東縣', '澎湖縣', '金門縣', '連江縣'
]

# 疾病代碼配置（基於HAPI格式）
DISEASE_CONFIG = {
    'covid19': {
        'codes': ['U07.1', 'U07.2'],
        'display': ['COVID-19, virus identified', 'COVID-19, virus not identified'],
        'severity': ['mild', 'moderate', 'severe'],
        'severity_weight': [0.70, 0.25, 0.05],
        'percentage': 0.30  # 30%
    },
    'influenza': {
        'codes': ['J09', 'J10.0', 'J10.1', 'J11.0', 'J11.1'],
        'display': ['Influenza due to identified influenza virus', 
                   'Influenza with pneumonia', 
                   'Influenza with other respiratory manifestations',
                   'Influenza with pneumonia, virus not identified',
                   'Influenza with other respiratory manifestations, virus not identified'],
        'severity': ['mild', 'moderate', 'severe'],
        'severity_weight': [0.65, 0.30, 0.05],
        'percentage': 0.30  # 30%
    },
    'conjunctivitis': {
        'codes': ['H10.0', 'H10.1', 'H10.2', 'H10.3'],
        'display': ['Mucopurulent conjunctivitis', 'Acute atopic conjunctivitis', 
                   'Other acute conjunctivitis', 'Acute conjunctivitis, unspecified'],
        'severity': ['mild', 'moderate'],
        'severity_weight': [0.85, 0.15],
        'percentage': 0.00  # 0%
    },
    'enterovirus': {
        'codes': ['A87.0', 'B08.4', 'B08.5', 'B34.1'],
        'display': ['Enteroviral meningitis', 'Enteroviral vesicular stomatitis with exanthem',
                   'Enteroviral vesicular pharyngitis', 'Enterovirus infection'],
        'severity': ['mild', 'moderate', 'severe'],
        'severity_weight': [0.75, 0.20, 0.05],
        'percentage': 0.20  # 20%
    },
    'diarrhea': {
        'codes': ['A00.0', 'A00.9', 'A02.0', 'A04.0', 'A08.0', 'A09'],
        'display': ['Cholera due to Vibrio cholerae', 'Cholera, unspecified',
                   'Salmonella enteritis', 'Enteropathogenic Escherichia coli infection',
                   'Rotaviral enteritis', 'Infectious gastroenteritis and colitis'],
        'severity': ['mild', 'moderate', 'severe'],
        'severity_weight': [0.70, 0.25, 0.05],
        'percentage': 0.20  # 20%
    }
}

class Taiwan100DataGenerator:
    def __init__(self):
        self.patients = []
        self.conditions = []
        self.encounters = []
        self.observations = []
        
        # 計算每種疾病的人數
        self.disease_counts = {
            disease: int(100 * config['percentage'])
            for disease, config in DISEASE_CONFIG.items()
        }
        
    def generate_patient_id(self, index):
        """生成台灣身分證字號格式的ID"""
        return f"TW{index:05d}"
    
    def generate_patient(self, index):
        """生成病人資料"""
        gender = random.choice(['male', 'female'])
        given_names = GIVEN_NAMES_MALE if gender == 'male' else GIVEN_NAMES_FEMALE
        
        # 年齡分布：10-80歲
        age = random.randint(10, 80)
        birth_date = datetime.now() - timedelta(days=age*365 + random.randint(0, 364))
        
        patient = {
            'resourceType': 'Patient',
            'id': self.generate_patient_id(index),
            'identifier': [{
                'system': 'urn:oid:2.16.886.101.20003.20001',
                'value': self.generate_patient_id(index)
            }],
            'name': [{
                'family': random.choice(SURNAMES),
                'given': [random.choice(given_names)],
                'text': ''
            }],
            'gender': gender,
            'birthDate': birth_date.strftime('%Y-%m-%d'),
            'address': [{
                'city': random.choice(TAIWAN_CITIES),
                'country': 'TW'
            }]
        }
        
        # 組合全名
        patient['name'][0]['text'] = patient['name'][0]['family'] + patient['name'][0]['given'][0]
        
        return patient
    
    def generate_condition(self, patient_id, disease_type, index):
        """生成診斷記錄（基於HAPI格式）"""
        config = DISEASE_CONFIG[disease_type]
        
        # 隨機選擇代碼和嚴重度
        code_index = random.randint(0, len(config['codes']) - 1)
        code = config['codes'][code_index]
        display = config['display'][code_index]
        severity = random.choices(config['severity'], weights=config['severity_weight'])[0]
        
        # 發病日期：過去6個月內
        onset_date = datetime.now() - timedelta(days=random.randint(1, 180))
        
        # 嚴重度對應
        severity_map = {
            'mild': {'code': '255604002', 'display': 'Mild'},
            'moderate': {'code': '6736007', 'display': 'Moderate'},
            'severe': {'code': '24484000', 'display': 'Severe'}
        }
        
        condition = {
            'resourceType': 'Condition',
            'id': f'{patient_id}-condition-{index}',
            'clinicalStatus': {
                'coding': [{
                    'system': 'http://terminology.hl7.org/CodeSystem/condition-clinical',
                    'code': 'resolved'
                }]
            },
            'verificationStatus': {
                'coding': [{
                    'system': 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                    'code': 'confirmed'
                }]
            },
            'severity': {
                'coding': [{
                    'system': 'http://snomed.info/sct',
                    'code': severity_map[severity]['code'],
                    'display': severity_map[severity]['display']
                }]
            },
            'code': {
                'coding': [{
                    'system': 'http://hl7.org/fhir/sid/icd-10',
                    'code': code,
                    'display': display
                }],
                'text': display
            },
            'subject': {
                'reference': f'Patient/{patient_id}'
            },
            'onsetDateTime': onset_date.strftime('%Y-%m-%d')
        }
        
        return condition
    
    def generate_all_data(self):
        """生成所有數據"""
        print(f"開始生成 100 筆台灣在地化傳染病數據...")
        print(f"分配：COVID-19 {self.disease_counts['covid19']}人, "
              f"流感 {self.disease_counts['influenza']}人, "
              f"結膜炎 {self.disease_counts['conjunctivitis']}人, "
              f"腸病毒 {self.disease_counts['enterovirus']}人, "
              f"腹瀉 {self.disease_counts['diarrhea']}人")
        
        patient_index = 0
        
        for disease_type, count in self.disease_counts.items():
            if count == 0:
                continue
                
            for i in range(count):
                # 生成病人
                patient = self.generate_patient(patient_index)
                self.patients.append(patient)
                
                # 生成診斷
                condition = self.generate_condition(patient['id'], disease_type, 0)
                self.conditions.append(condition)
                
                patient_index += 1
                
                if (patient_index) % 20 == 0:
                    print(f"已生成 {patient_index}/100 筆病人資料...")
        
        print(f"\n生成完成！")
        print(f"病人總數: {len(self.patients)}")
        print(f"診斷記錄: {len(self.conditions)}")
    
    def save_to_bundle(self, filename):
        """保存為 FHIR Bundle"""
        bundle = {
            'resourceType': 'Bundle',
            'type': 'transaction',
            'entry': []
        }
        
        # 添加所有資源
        for patient in self.patients:
            bundle['entry'].append({
                'resource': patient,
                'request': {
                    'method': 'PUT',
                    'url': f"Patient/{patient['id']}"
                }
            })
        
        for condition in self.conditions:
            bundle['entry'].append({
                'resource': condition,
                'request': {
                    'method': 'PUT',
                    'url': f"Condition/{condition['id']}"
                }
            })
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(bundle, f, ensure_ascii=False, indent=2)
        
        print(f"\n已保存到文件: {filename}")
        print(f"文件大小: {len(json.dumps(bundle)) / 1024:.2f} KB")
        
        # 保存統計
        stats = {
            'total_patients': len(self.patients),
            'total_conditions': len(self.conditions),
            'total_resources': len(bundle['entry']),
            'disease_distribution': {}
        }
        
        for disease_type, count in self.disease_counts.items():
            if count > 0:
                stats['disease_distribution'][disease_type] = count
        
        with open('taiwan_100_stats.json', 'w', encoding='utf-8') as f:
            json.dump(stats, f, ensure_ascii=False, indent=2)
        
        print(f"已保存統計資訊到: taiwan_100_stats.json")

def main():
    generator = Taiwan100DataGenerator()
    generator.generate_all_data()
    generator.save_to_bundle('taiwan_100_bundle.json')
    
    print("\n=== 數據生成完成 ===")
    print("準備上傳到 emr-smart.appx.com.tw")

if __name__ == '__main__':
    main()
