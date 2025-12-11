"""
Data Processor Module
資料處理與過濾模組，負責依照各種條件篩選與統計 FHIR 資料
"""

from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from collections import Counter, defaultdict
import logging

logger = logging.getLogger(__name__)


class FHIRDataProcessor:
    """FHIR 資料處理器"""
    
    def __init__(self, fhir_data: Dict[str, List[Dict]]):
        """
        初始化資料處理器
        
        Args:
            fhir_data: 包含各類 FHIR 資源的字典
        """
        self.patients = fhir_data.get('Patient', [])
        self.immunizations = fhir_data.get('Immunization', [])
        self.conditions = fhir_data.get('Condition', [])
        self.observations = fhir_data.get('Observation', [])
        
        # 建立病人索引
        self.patient_index = {self._get_id(p): p for p in self.patients}
    
    def _get_id(self, resource: Dict) -> str:
        """提取資源 ID"""
        return resource.get('id', '')
    
    def _get_patient_reference_id(self, reference: str) -> str:
        """從參照字串提取病人 ID"""
        if not reference:
            return ''
        # 處理 "Patient/123" 格式
        if '/' in reference:
            return reference.split('/')[-1]
        return reference
    
    def _calculate_age(self, birth_date: str, reference_date: datetime = None) -> Optional[int]:
        """
        計算年齡
        
        Args:
            birth_date: 出生日期字串 (YYYY-MM-DD)
            reference_date: 參考日期（預設為今天）
            
        Returns:
            年齡（整數）
        """
        if not birth_date:
            return None
        
        try:
            birth = datetime.strptime(birth_date[:10], '%Y-%m-%d')
            ref_date = reference_date or datetime.now()
            age = ref_date.year - birth.year
            
            # 檢查是否已過生日
            if (ref_date.month, ref_date.day) < (birth.month, birth.day):
                age -= 1
            
            return age
        except:
            return None
    
    def _extract_address_info(self, patient: Dict) -> Dict[str, str]:
        """
        提取病人地址資訊
        
        Returns:
            包含 city, state, postalCode, country 的字典
        """
        addresses = patient.get('address', [])
        if not addresses:
            return {'city': '未知', 'state': '未知', 'postalCode': '未知', 'country': '未知'}
        
        # 取第一個地址
        addr = addresses[0]
        return {
            'city': addr.get('city', '未知'),
            'state': addr.get('state', '未知'),
            'postalCode': addr.get('postalCode', '未知'),
            'country': addr.get('country', '未知')
        }
    
    def _extract_vaccine_code(self, immunization: Dict) -> str:
        """提取疫苗代碼文字"""
        vaccine_code = immunization.get('vaccineCode', {})
        coding = vaccine_code.get('coding', [])
        
        if coding:
            # 取第一個 coding 的 display 或 code
            return coding[0].get('display', coding[0].get('code', '未知'))
        
        return vaccine_code.get('text', '未知')
    
    def _is_within_time_period(self, date_str: str, years: int) -> bool:
        """
        檢查日期是否在指定的時間範圍內
        
        Args:
            date_str: 日期字串
            years: 年數
            
        Returns:
            是否在範圍內
        """
        if not date_str:
            return False
        
        try:
            # 處理多種日期格式
            date_str_clean = date_str[:10]  # 取 YYYY-MM-DD
            date = datetime.strptime(date_str_clean, '%Y-%m-%d')
            
            cutoff_date = datetime.now() - timedelta(days=365 * years)
            return date >= cutoff_date
        except:
            return False
    
    def get_patient_demographics(self) -> Dict[str, Any]:
        """
        獲取病人人口統計資訊
        
        Returns:
            包含總人數、年齡分布、性別分布、地區分布的字典
        """
        total_count = len(self.patients)
        
        # 性別統計
        genders = Counter()
        # 年齡分組統計
        age_groups = Counter()
        # 地區統計
        locations = Counter()
        
        for patient in self.patients:
            # 性別
            gender = patient.get('gender', '未知')
            genders[gender] += 1
            
            # 年齡
            birth_date = patient.get('birthDate')
            age = self._calculate_age(birth_date)
            if age is not None:
                if age < 18:
                    age_groups['0-17歲'] += 1
                elif age < 40:
                    age_groups['18-39歲'] += 1
                elif age < 65:
                    age_groups['40-64歲'] += 1
                else:
                    age_groups['65歲以上'] += 1
            else:
                age_groups['未知'] += 1
            
            # 地區
            addr_info = self._extract_address_info(patient)
            location_key = f"{addr_info['state']} - {addr_info['city']}"
            locations[location_key] += 1
        
        return {
            'total_count': total_count,
            'gender_distribution': dict(genders),
            'age_distribution': dict(age_groups),
            'location_distribution': dict(locations.most_common(10))  # 前10個地區
        }
    
    def get_covid19_vaccination_statistics(self, time_period_years: int = 2) -> Dict[str, Any]:
        """
        獲取 COVID-19 疫苗接種統計
        
        Args:
            time_period_years: 時間範圍（年）
            
        Returns:
            詳細統計資料
        """
        # COVID-19 疫苗相關關鍵字
        covid_keywords = ['covid', 'sars-cov-2', 'coronavirus', 'moderna', 'pfizer', 'astrazeneca', 'johnson']
        
        # 篩選 COVID-19 疫苗接種紀錄
        covid_immunizations = []
        for imm in self.immunizations:
            vaccine_name = self._extract_vaccine_code(imm).lower()
            occurrence = imm.get('occurrenceDateTime', '')
            
            # 檢查是否為 COVID-19 疫苗且在時間範圍內
            is_covid = any(keyword in vaccine_name for keyword in covid_keywords)
            is_in_period = self._is_within_time_period(occurrence, time_period_years)
            
            if is_covid and is_in_period:
                covid_immunizations.append(imm)
        
        # 統計資料
        total_doses = len(covid_immunizations)
        
        # 按病人分組統計劑數
        patient_doses = Counter()
        vaccine_types = Counter()
        vaccination_by_age = defaultdict(int)
        vaccination_by_gender = defaultdict(int)
        vaccination_by_location = defaultdict(int)
        
        for imm in covid_immunizations:
            # 病人 ID
            patient_ref = imm.get('patient', {}).get('reference', '')
            patient_id = self._get_patient_reference_id(patient_ref)
            patient_doses[patient_id] += 1
            
            # 疫苗類型
            vaccine_name = self._extract_vaccine_code(imm)
            vaccine_types[vaccine_name] += 1
            
            # 病人資訊
            if patient_id in self.patient_index:
                patient = self.patient_index[patient_id]
                
                # 年齡
                age = self._calculate_age(patient.get('birthDate'))
                if age is not None:
                    if age < 18:
                        age_group = '0-17歲'
                    elif age < 40:
                        age_group = '18-39歲'
                    elif age < 65:
                        age_group = '40-64歲'
                    else:
                        age_group = '65歲以上'
                    vaccination_by_age[age_group] += 1
                
                # 性別
                gender = patient.get('gender', '未知')
                vaccination_by_gender[gender] += 1
                
                # 地區
                addr_info = self._extract_address_info(patient)
                location_key = f"{addr_info['state']} - {addr_info['city']}"
                vaccination_by_location[location_key] += 1
        
        # 計算劑數分布
        dose_distribution = Counter()
        for patient_id, doses in patient_doses.items():
            if doses == 1:
                dose_distribution['1劑'] += 1
            elif doses == 2:
                dose_distribution['2劑（基礎）'] += 1
            elif doses >= 3:
                dose_distribution['3劑以上（含加強劑）'] += 1
        
        return {
            'total_doses': total_doses,
            'vaccinated_patients': len(patient_doses),
            'dose_distribution': dict(dose_distribution),
            'vaccine_types': dict(vaccine_types.most_common()),
            'by_age_group': dict(vaccination_by_age),
            'by_gender': dict(vaccination_by_gender),
            'by_location': dict(sorted(vaccination_by_location.items(), key=lambda x: x[1], reverse=True)[:10])
        }
    
    def get_influenza_vaccination_statistics(self, time_period_years: int = 2) -> Dict[str, Any]:
        """
        獲取流感疫苗接種統計
        
        Args:
            time_period_years: 時間範圍（年）
            
        Returns:
            詳細統計資料
        """
        # 流感疫苗相關關鍵字
        flu_keywords = ['influenza', 'flu', 'fluvirin', 'fluzone', 'fluad', 'flucelvax']
        
        # 篩選流感疫苗接種紀錄
        flu_immunizations = []
        for imm in self.immunizations:
            vaccine_name = self._extract_vaccine_code(imm).lower()
            occurrence = imm.get('occurrenceDateTime', '')
            
            # 檢查是否為流感疫苗且在時間範圍內
            is_flu = any(keyword in vaccine_name for keyword in flu_keywords)
            is_in_period = self._is_within_time_period(occurrence, time_period_years)
            
            if is_flu and is_in_period:
                flu_immunizations.append(imm)
        
        # 統計資料
        total_doses = len(flu_immunizations)
        
        # 按病人統計
        vaccinated_patients = set()
        vaccine_types = Counter()
        vaccination_by_age = defaultdict(int)
        vaccination_by_gender = defaultdict(int)
        vaccination_by_location = defaultdict(int)
        
        for imm in flu_immunizations:
            # 病人 ID
            patient_ref = imm.get('patient', {}).get('reference', '')
            patient_id = self._get_patient_reference_id(patient_ref)
            vaccinated_patients.add(patient_id)
            
            # 疫苗類型
            vaccine_name = self._extract_vaccine_code(imm)
            vaccine_types[vaccine_name] += 1
            
            # 病人資訊
            if patient_id in self.patient_index:
                patient = self.patient_index[patient_id]
                
                # 年齡
                age = self._calculate_age(patient.get('birthDate'))
                if age is not None:
                    if age < 18:
                        age_group = '0-17歲'
                    elif age < 40:
                        age_group = '18-39歲'
                    elif age < 65:
                        age_group = '40-64歲'
                    else:
                        age_group = '65歲以上'
                    vaccination_by_age[age_group] += 1
                
                # 性別
                gender = patient.get('gender', '未知')
                vaccination_by_gender[gender] += 1
                
                # 地區
                addr_info = self._extract_address_info(patient)
                location_key = f"{addr_info['state']} - {addr_info['city']}"
                vaccination_by_location[location_key] += 1
        
        return {
            'total_doses': total_doses,
            'vaccinated_patients': len(vaccinated_patients),
            'vaccine_types': dict(vaccine_types.most_common()),
            'by_age_group': dict(vaccination_by_age),
            'by_gender': dict(vaccination_by_gender),
            'by_location': dict(sorted(vaccination_by_location.items(), key=lambda x: x[1], reverse=True)[:10])
        }
    
    def get_hypertension_statistics(self) -> Dict[str, Any]:
        """
        獲取高血壓診斷統計
        
        Returns:
            詳細統計資料
        """
        # 高血壓相關關鍵字（ICD-10 I10-I15）
        htn_keywords = ['hypertension', 'high blood pressure', 'i10', 'i11', 'i12', 'i13', 'i14', 'i15']
        
        # 篩選高血壓診斷紀錄
        htn_conditions = []
        for cond in self.conditions:
            # 檢查 clinicalStatus 是否為 active
            clinical_status = cond.get('clinicalStatus', {})
            is_active = False
            
            if 'coding' in clinical_status:
                for coding in clinical_status['coding']:
                    if coding.get('code') == 'active':
                        is_active = True
                        break
            
            # 檢查診斷碼
            code = cond.get('code', {})
            coding_list = code.get('coding', [])
            code_text = code.get('text', '').lower()
            
            is_htn = False
            for coding in coding_list:
                code_value = coding.get('code', '').lower()
                display = coding.get('display', '').lower()
                if any(keyword in code_value or keyword in display for keyword in htn_keywords):
                    is_htn = True
                    break
            
            if not is_htn and any(keyword in code_text for keyword in htn_keywords):
                is_htn = True
            
            if is_htn and is_active:
                htn_conditions.append(cond)
        
        # 統計資料
        htn_patients = set()
        htn_by_age = defaultdict(int)
        htn_by_gender = defaultdict(int)
        htn_by_location = defaultdict(int)
        
        for cond in htn_conditions:
            # 病人 ID
            patient_ref = cond.get('subject', {}).get('reference', '')
            patient_id = self._get_patient_reference_id(patient_ref)
            htn_patients.add(patient_id)
            
            # 病人資訊
            if patient_id in self.patient_index:
                patient = self.patient_index[patient_id]
                
                # 年齡
                age = self._calculate_age(patient.get('birthDate'))
                if age is not None:
                    if age < 18:
                        age_group = '0-17歲'
                    elif age < 40:
                        age_group = '18-39歲'
                    elif age < 65:
                        age_group = '40-64歲'
                    else:
                        age_group = '65歲以上'
                    htn_by_age[age_group] += 1
                
                # 性別
                gender = patient.get('gender', '未知')
                htn_by_gender[gender] += 1
                
                # 地區
                addr_info = self._extract_address_info(patient)
                location_key = f"{addr_info['state']} - {addr_info['city']}"
                htn_by_location[location_key] += 1
        
        return {
            'total_patients': len(htn_patients),
            'total_conditions': len(htn_conditions),
            'by_age_group': dict(htn_by_age),
            'by_gender': dict(htn_by_gender),
            'by_location': dict(sorted(htn_by_location.items(), key=lambda x: x[1], reverse=True)[:10])
        }
    
    def generate_full_report(self, time_period_years: int = 2) -> Dict[str, Any]:
        """
        生成完整報告
        
        Args:
            time_period_years: 時間範圍（年）
            
        Returns:
            完整統計報告
        """
        logger.info("正在生成完整報告...")
        
        report = {
            'report_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'time_period_years': time_period_years,
            'patient_demographics': self.get_patient_demographics(),
            'covid19_vaccination': self.get_covid19_vaccination_statistics(time_period_years),
            'influenza_vaccination': self.get_influenza_vaccination_statistics(time_period_years),
            'hypertension': self.get_hypertension_statistics()
        }
        
        logger.info("報告生成完成")
        return report
