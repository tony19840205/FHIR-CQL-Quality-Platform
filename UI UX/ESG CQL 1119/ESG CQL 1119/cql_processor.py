"""
CQL Processor Module
處理CQL檔案解析和模擬執行
注意: 由於Python缺乏完整的CQL引擎，此模組提供模擬執行功能
"""

import re
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from pathlib import Path

logger = logging.getLogger(__name__)


class CQLProcessor:
    """CQL處理器 - 解析CQL並基於FHIR資料進行計算"""
    
    def __init__(self, cql_file_path: str):
        """
        初始化CQL處理器
        
        Args:
            cql_file_path: CQL檔案路徑
        """
        self.cql_file_path = Path(cql_file_path)
        self.cql_content = ""
        self.library_name = ""
        self.version = ""
        self.definitions = {}
        
        self._load_cql()
        self._parse_metadata()
    
    def _load_cql(self):
        """載入CQL檔案內容"""
        try:
            with open(self.cql_file_path, 'r', encoding='utf-8') as f:
                self.cql_content = f.read()
            logger.info(f"已載入CQL檔案: {self.cql_file_path.name}")
        except Exception as e:
            logger.error(f"載入CQL檔案失敗: {e}")
            raise
    
    def _parse_metadata(self):
        """解析CQL metadata"""
        # 提取library名稱和版本
        library_match = re.search(r'library\s+(\w+)\s+version\s+[\'"]([^\'\"]+)[\'"]', self.cql_content)
        if library_match:
            self.library_name = library_match.group(1)
            self.version = library_match.group(2)
            logger.info(f"CQL Library: {self.library_name} v{self.version}")
    
    def execute(self, fhir_data: Dict[str, List[Dict]], measurement_period: tuple) -> Dict[str, Any]:
        """
        執行CQL邏輯（模擬）
        
        Args:
            fhir_data: FHIR資源數據 {'Patient': [...], 'Encounter': [...]}
            measurement_period: (start_date, end_date) 測量期間
            
        Returns:
            執行結果字典
        """
        logger.info(f"開始執行CQL: {self.library_name}")
        
        # 根據不同的CQL library執行不同的邏輯
        if self.library_name == "Antibiotic_Utilization":
            return self._execute_antibiotic_utilization(fhir_data, measurement_period)
        elif self.library_name == "EHR_Adoption_Rate":
            return self._execute_ehr_adoption(fhir_data, measurement_period)
        elif self.library_name == "Waste":
            return self._execute_waste(fhir_data, measurement_period)
        else:
            logger.warning(f"未知的CQL library: {self.library_name}")
            return {"error": "Unknown CQL library"}
    
    def _execute_antibiotic_utilization(self, fhir_data: Dict, measurement_period: tuple) -> Dict:
        """執行抗生素使用率計算"""
        results = {
            "library": self.library_name,
            "version": self.version,
            "measurement_period": {
                "start": measurement_period[0].isoformat(),
                "end": measurement_period[1].isoformat()
            }
        }
        
        # 取得資源
        patients = fhir_data.get('Patient', [])
        encounters = fhir_data.get('Encounter', [])
        med_requests = fhir_data.get('MedicationRequest', [])
        med_admins = fhir_data.get('MedicationAdministration', [])
        
        # 基礎計數
        results['total_patients'] = len(patients)
        results['total_encounters'] = len(encounters)
        results['total_antibiotic_orders'] = len(med_requests)
        results['total_antibiotic_administrations'] = len(med_admins)
        
        # 資料有效性警告
        if len(encounters) == 0:
            results['data_warning'] = '⚠️ 2年內無就醫記錄，部分指標無法計算'
        
        # 使用抗生素的病人數（模擬）
        antibiotic_patients = set()
        for med in med_admins:
            if 'subject' in med and 'reference' in med['subject']:
                antibiotic_patients.add(med['subject']['reference'])
        
        results['antibiotic_use_patient_count'] = len(antibiotic_patients)
        
        # 計算使用率
        if len(patients) > 0:
            results['antibiotic_use_rate_percent'] = round(
                (len(antibiotic_patients) / len(patients)) * 100, 2
            )
        else:
            results['antibiotic_use_rate_percent'] = 0
        
        # 住院日數（簡化計算）
        total_bed_days = 0
        for encounter in encounters:
            if encounter.get('class', {}).get('code') in ['IMP', 'ACUTE']:
                # 簡化：假設每次住院3天
                total_bed_days += 3
        
        results['total_bed_days'] = total_bed_days
        results['data_scope'] = 'CQL計算範圍：全部FHIR資料（無時間限制）'
        
        # DOT和DDD（模擬值）
        results['total_dot'] = len(med_admins)
        results['total_ddd'] = len(med_admins) * 1.5  # 模擬值
        
        if total_bed_days > 0:
            results['ddd_per_100_bed_days'] = round(
                (results['total_ddd'] * 100) / total_bed_days, 2
            )
        else:
            results['ddd_per_100_bed_days'] = None
        
        results['data_status'] = 'FHIR 資料已載入' if len(patients) > 0 else 'FHIR 無資料記載'
        
        logger.info(f"抗生素使用率計算完成: {results['antibiotic_use_rate_percent']}%")
        return results
    
    def _execute_ehr_adoption(self, fhir_data: Dict, measurement_period: tuple) -> Dict:
        """執行電子病歷採用率計算"""
        results = {
            "library": self.library_name,
            "version": self.version,
            "measurement_period": {
                "start": measurement_period[0].isoformat(),
                "end": measurement_period[1].isoformat()
            }
        }
        
        # 取得資源
        patients = fhir_data.get('Patient', [])
        encounters = fhir_data.get('Encounter', [])
        documents = fhir_data.get('DocumentReference', [])
        observations = fhir_data.get('Observation', [])
        procedures = fhir_data.get('Procedure', [])
        med_requests = fhir_data.get('MedicationRequest', [])
        
        # 基礎計數
        results['total_patients'] = len(patients)
        results['total_encounters'] = len(encounters)
        results['total_ehr_documents'] = len(documents)
        results['total_electronic_prescriptions'] = len(med_requests)
        results['total_electronic_lab_results'] = len([o for o in observations 
                                                        if any(c.get('code') == 'laboratory' 
                                                              for c in o.get('category', [{}]))])
        results['total_electronic_procedures'] = len(procedures)
        results['data_scope'] = 'CQL計算範圍：全部FHIR資料（無時間限制）'
        
        # 計算採用率
        if len(encounters) > 0:
            # 有電子記錄的就醫次數
            encounters_with_ehr = len([e for e in encounters 
                                       if any(d.get('context', {}).get('reference', '').endswith(e.get('id', '')) 
                                             for d in documents)])
            
            results['ehr_adoption_rate_encounter_percent'] = round(
                (encounters_with_ehr / len(encounters)) * 100, 2
            )
            
            # 功能別採用率
            results['electronic_prescription_rate_percent'] = round(
                (len(med_requests) / len(encounters)) * 100, 2
            )
            
            results['electronic_lab_results_rate_percent'] = round(
                (results['total_electronic_lab_results'] / len(encounters)) * 100, 2
            )
        else:
            results['ehr_adoption_rate_encounter_percent'] = 0
            results['electronic_prescription_rate_percent'] = 0
            results['electronic_lab_results_rate_percent'] = 0
        
        # HIMSS EMRAM Level 評估
        ehr_rate = results.get('ehr_adoption_rate_encounter_percent', 0)
        if ehr_rate >= 95:
            results['himss_emram_level'] = 7
        elif ehr_rate >= 85:
            results['himss_emram_level'] = 6
        elif ehr_rate >= 70:
            results['himss_emram_level'] = 5
        elif ehr_rate >= 50:
            results['himss_emram_level'] = 4
        elif ehr_rate >= 30:
            results['himss_emram_level'] = 3
        else:
            results['himss_emram_level'] = 2
        
        results['data_status'] = 'FHIR 資料已載入' if len(patients) > 0 else 'FHIR 無資料記載'
        
        logger.info(f"EHR採用率計算完成: {results['ehr_adoption_rate_encounter_percent']}%")
        return results
    
    def _execute_waste(self, fhir_data: Dict, measurement_period: tuple) -> Dict:
        """執行廢棄物管理計算"""
        results = {
            "library": self.library_name,
            "version": self.version,
            "measurement_period": {
                "start": measurement_period[0].isoformat(),
                "end": measurement_period[1].isoformat()
            }
        }
        
        # 取得資源
        patients = fhir_data.get('Patient', [])
        encounters = fhir_data.get('Encounter', [])
        observations = fhir_data.get('Observation', [])
        
        # 基礎計數
        results['total_patients'] = len(patients)
        results['total_encounters'] = len(encounters)
        
        # 廢棄物相關觀察記錄（模擬）
        waste_observations = [o for o in observations 
                             if 'waste' in str(o.get('code', {})).lower()]
        
        results['total_waste_records'] = len(waste_observations)
        
        # 模擬廢棄物量（kg）- 說明：FHIR無標準廢棄物資源，此為估算
        results['total_waste_kg'] = len(encounters) * 2.5  # 每次就醫平均2.5kg
        results['waste_calculation_method'] = '估算（基於就醫次數 × 2.5kg/次）'
        results['data_scope'] = 'CQL計算範圍：全部FHIR資料（無時間限制）'
        results['recyclable_waste_kg'] = results['total_waste_kg'] * 0.3  # 30%可回收
        results['hazardous_waste_kg'] = results['total_waste_kg'] * 0.15  # 15%有害廢棄物
        
        # 廢棄物強度
        if len(encounters) > 0:
            results['waste_per_encounter_kg'] = round(
                results['total_waste_kg'] / len(encounters), 2
            )
        else:
            results['waste_per_encounter_kg'] = 0
        
        # 回收率
        if results['total_waste_kg'] > 0:
            results['recycling_rate_percent'] = round(
                (results['recyclable_waste_kg'] / results['total_waste_kg']) * 100, 2
            )
        else:
            results['recycling_rate_percent'] = 0
        
        results['data_status'] = 'FHIR 資料已載入' if len(patients) > 0 else 'FHIR 無資料記載'
        
        logger.info(f"廢棄物管理計算完成: 總廢棄物 {results['total_waste_kg']} kg")
        return results


class CQLExecutor:
    """CQL執行器 - 管理多個CQL檔案的執行"""
    
    def __init__(self, cql_files: List[str]):
        """
        初始化CQL執行器
        
        Args:
            cql_files: CQL檔案路徑列表
        """
        self.processors = []
        
        for cql_file in cql_files:
            if Path(cql_file).exists():
                processor = CQLProcessor(cql_file)
                self.processors.append(processor)
            else:
                logger.warning(f"CQL檔案不存在: {cql_file}")
        
        logger.info(f"已初始化 {len(self.processors)} 個CQL處理器")
    
    def execute_all(self, fhir_data: Dict[str, List[Dict]], measurement_period: tuple) -> Dict[str, Any]:
        """
        執行所有CQL
        
        Returns:
            {
                'Antibiotic_Utilization': {...},
                'EHR_Adoption_Rate': {...},
                'Waste': {...}
            }
        """
        results = {}
        
        for processor in self.processors:
            try:
                result = processor.execute(fhir_data, measurement_period)
                results[processor.library_name] = result
            except Exception as e:
                logger.error(f"執行 {processor.library_name} 失敗: {e}")
                results[processor.library_name] = {"error": str(e)}
        
        return results
