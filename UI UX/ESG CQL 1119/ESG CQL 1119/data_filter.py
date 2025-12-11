"""
Data Filter and Display Module
資料過濾與顯示控制模組
實現：2年內資料、總人數、年齡、性別、居住地等過濾和顯示
"""

import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from collections import Counter

logger = logging.getLogger(__name__)


class DataFilter:
    """資料過濾器 - 依據config控制顯示條件"""
    
    def __init__(self, filter_config: Dict):
        """
        初始化資料過濾器
        
        Args:
            filter_config: 過濾配置 (來自config.yaml的data_filters)
        """
        self.filter_config = filter_config
        self.time_range = self._calculate_time_range()
    
    def _calculate_time_range(self) -> tuple:
        """計算時間範圍（預設2年內）"""
        years = self.filter_config.get('time_range', {}).get('years', 2)
        end_date = datetime.now()
        start_date = end_date - timedelta(days=years * 365)
        
        logger.info(f"時間範圍: {start_date.date()} 至 {end_date.date()} ({years}年)")
        return (start_date, end_date)
    
    def filter_fhir_data(self, fhir_data: Dict[str, List[Dict]]) -> Dict[str, List[Dict]]:
        """
        過濾FHIR資料（依時間範圍）
        
        Args:
            fhir_data: 原始FHIR資料
            
        Returns:
            過濾後的FHIR資料
        """
        filtered_data = {}
        start_date, end_date = self.time_range
        
        for resource_type, resources in fhir_data.items():
            filtered_resources = []
            
            for resource in resources:
                # 根據不同資源類型檢查日期
                if self._is_within_time_range(resource, start_date, end_date):
                    filtered_resources.append(resource)
            
            filtered_data[resource_type] = filtered_resources
            
            if len(filtered_resources) != len(resources):
                logger.info(f"{resource_type}: {len(resources)} -> {len(filtered_resources)} 筆（已過濾）")
        
        return filtered_data
    
    def _is_within_time_range(self, resource: Dict, start_date: datetime, end_date: datetime) -> bool:
        """檢查資源是否在時間範圍內"""
        resource_type = resource.get('resourceType')
        
        try:
            # 依資源類型取得相關日期欄位
            if resource_type == 'Patient':
                # Patient資源不過濾（保留所有病人）
                return True
            
            elif resource_type == 'Encounter':
                period = resource.get('period', {})
                start_str = period.get('start')
                if start_str:
                    resource_date = self._parse_fhir_datetime(start_str)
                    return start_date <= resource_date <= end_date
            
            elif resource_type == 'MedicationRequest':
                authored_on = resource.get('authoredOn')
                if authored_on:
                    resource_date = self._parse_fhir_datetime(authored_on)
                    return start_date <= resource_date <= end_date
            
            elif resource_type == 'MedicationAdministration':
                effective = resource.get('effectiveDateTime') or resource.get('effectivePeriod', {}).get('start')
                if effective:
                    resource_date = self._parse_fhir_datetime(effective)
                    return start_date <= resource_date <= end_date
            
            elif resource_type == 'Observation':
                effective = resource.get('effectiveDateTime') or resource.get('effectivePeriod', {}).get('start')
                if effective:
                    resource_date = self._parse_fhir_datetime(effective)
                    return start_date <= resource_date <= end_date
            
            elif resource_type == 'Procedure':
                performed = resource.get('performedDateTime') or resource.get('performedPeriod', {}).get('start')
                if performed:
                    resource_date = self._parse_fhir_datetime(performed)
                    return start_date <= resource_date <= end_date
            
            elif resource_type == 'DocumentReference':
                date = resource.get('date')
                if date:
                    resource_date = self._parse_fhir_datetime(date)
                    return start_date <= resource_date <= end_date
            
            elif resource_type == 'DiagnosticReport':
                effective = resource.get('effectiveDateTime') or resource.get('effectivePeriod', {}).get('start')
                if effective:
                    resource_date = self._parse_fhir_datetime(effective)
                    return start_date <= resource_date <= end_date
            
            # 如果無法判斷日期，預設保留
            return True
            
        except Exception as e:
            logger.debug(f"日期解析失敗: {e}")
            return True
    
    def _parse_fhir_datetime(self, date_str: str) -> datetime:
        """解析FHIR datetime字串"""
        # 移除時區資訊並解析
        date_str = date_str.replace('Z', '+00:00')
        
        # 嘗試多種格式
        formats = [
            '%Y-%m-%dT%H:%M:%S.%f%z',
            '%Y-%m-%dT%H:%M:%S%z',
            '%Y-%m-%dT%H:%M:%S.%f',
            '%Y-%m-%dT%H:%M:%S',
            '%Y-%m-%d'
        ]
        
        for fmt in formats:
            try:
                # 移除時區後解析
                clean_str = date_str.split('+')[0].split('-', 3)
                if len(clean_str) >= 3:
                    clean_str = '-'.join(clean_str[:3])
                else:
                    clean_str = date_str.split('+')[0]
                
                return datetime.strptime(clean_str, fmt.split('%z')[0].strip())
            except:
                continue
        
        # 如果都失敗，回傳當前時間
        return datetime.now()


class DataDisplay:
    """資料顯示處理器 - 提取和顯示指定欄位"""
    
    def __init__(self, display_config: Dict):
        """
        初始化資料顯示處理器
        
        Args:
            display_config: 顯示配置 (來自config.yaml的data_filters.display_fields)
        """
        self.display_config = display_config
    
    def extract_patient_demographics(self, fhir_data: Dict[str, List[Dict]]) -> Dict[str, Any]:
        """
        提取病患基本資料統計
        
        Returns:
            {
                'total_patient_count': 100,
                'age_distribution': {...},
                'gender_distribution': {...},
                'location_distribution': {...}
            }
        """
        patients = fhir_data.get('Patient', [])
        
        demographics = {
            'total_patient_count': len(patients),
            'age_distribution': {},
            'gender_distribution': {},
            'location_distribution': {},
            'patient_details': []
        }
        
        ages = []
        genders = []
        locations = []
        
        for patient in patients:
            # 提取年齡
            birth_date = patient.get('birthDate')
            if birth_date and self.display_config.get('patient_age', True):
                age = self._calculate_age(birth_date)
                ages.append(age)
            
            # 提取性別
            gender = patient.get('gender')
            if gender and self.display_config.get('patient_gender', True):
                genders.append(gender)
            
            # 提取居住地
            address = patient.get('address', [])
            if address and self.display_config.get('patient_location', True):
                location = self._extract_location(address)
                if location:
                    locations.append(location)
            
            # 病患詳細資料
            demographics['patient_details'].append({
                'id': patient.get('id'),
                'name': self._extract_name(patient.get('name', [])),
                'age': self._calculate_age(birth_date) if birth_date else None,
                'gender': gender,
                'location': self._extract_location(address) if address else None
            })
        
        # 統計分布
        if ages:
            demographics['age_distribution'] = self._create_age_distribution(ages)
            demographics['average_age'] = round(sum(ages) / len(ages), 1)
            demographics['age_range'] = {'min': min(ages), 'max': max(ages)}
        
        if genders:
            demographics['gender_distribution'] = dict(Counter(genders))
            demographics['gender_percentages'] = {
                k: round(v / len(genders) * 100, 1) 
                for k, v in demographics['gender_distribution'].items()
            }
        
        if locations:
            demographics['location_distribution'] = dict(Counter(locations))
            demographics['top_locations'] = sorted(
                demographics['location_distribution'].items(), 
                key=lambda x: x[1], 
                reverse=True
            )[:10]
        
        logger.info(f"已提取 {len(patients)} 位病患的基本資料")
        return demographics
    
    def _calculate_age(self, birth_date_str: str) -> int:
        """計算年齡"""
        try:
            birth_date = datetime.strptime(birth_date_str, '%Y-%m-%d')
            today = datetime.now()
            age = today.year - birth_date.year
            if (today.month, today.day) < (birth_date.month, birth_date.day):
                age -= 1
            return age
        except:
            return 0
    
    def _create_age_distribution(self, ages: List[int]) -> Dict[str, int]:
        """建立年齡分布"""
        distribution = {
            '0-17歲': 0,
            '18-30歲': 0,
            '31-50歲': 0,
            '51-65歲': 0,
            '66歲以上': 0
        }
        
        for age in ages:
            if age < 18:
                distribution['0-17歲'] += 1
            elif age <= 30:
                distribution['18-30歲'] += 1
            elif age <= 50:
                distribution['31-50歲'] += 1
            elif age <= 65:
                distribution['51-65歲'] += 1
            else:
                distribution['66歲以上'] += 1
        
        return distribution
    
    def _extract_name(self, name_list: List[Dict]) -> str:
        """提取姓名"""
        if not name_list:
            return "Unknown"
        
        name = name_list[0]
        family = name.get('family', '')
        given = ' '.join(name.get('given', []))
        
        return f"{family} {given}".strip() or "Unknown"
    
    def _extract_location(self, address_list: List[Dict]) -> Optional[str]:
        """提取居住地"""
        if not address_list:
            return None
        
        address = address_list[0]
        
        # 優先順序: city > state > country
        location = address.get('city') or address.get('state') or address.get('country')
        return location
    
    def format_results_for_display(self, cql_results: Dict, demographics: Dict) -> Dict[str, Any]:
        """
        格式化結果供顯示
        
        Args:
            cql_results: CQL執行結果
            demographics: 病患基本資料統計
            
        Returns:
            格式化後的結果
        """
        display_results = {
            'summary': {
                'execution_time': datetime.now().isoformat(),
                'cql_libraries_executed': len(cql_results),
            },
            'demographics': {},
            'cql_results': cql_results
        }
        
        # 依據config控制顯示欄位
        if self.display_config.get('total_patient_count', True):
            display_results['demographics']['總病患人數'] = demographics.get('total_patient_count', 0)
        
        if self.display_config.get('patient_age', True):
            display_results['demographics']['年齡分布'] = demographics.get('age_distribution', {})
            display_results['demographics']['平均年齡'] = demographics.get('average_age')
        
        if self.display_config.get('patient_gender', True):
            display_results['demographics']['性別分布'] = demographics.get('gender_distribution', {})
            display_results['demographics']['性別百分比'] = demographics.get('gender_percentages', {})
        
        if self.display_config.get('patient_location', True):
            display_results['demographics']['居住地分布（前10名）'] = demographics.get('top_locations', [])
        
        return display_results
