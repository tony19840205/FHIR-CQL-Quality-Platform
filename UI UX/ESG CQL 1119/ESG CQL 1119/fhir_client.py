"""
SMART on FHIR Client Module
連接外部FHIR伺服器並擷取資料
"""

import requests
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from urllib.parse import urljoin

logger = logging.getLogger(__name__)


class FHIRClient:
    """FHIR Client for connecting to SMART on FHIR servers"""
    
    def __init__(self, base_url: str, name: str = "FHIR Server", auth_token: Optional[str] = None):
        """
        初始化FHIR客戶端
        
        Args:
            base_url: FHIR伺服器基礎URL
            name: 伺服器名稱
            auth_token: OAuth認證token (如需要)
        """
        self.base_url = base_url.rstrip('/')
        self.name = name
        self.auth_token = auth_token
        self.session = requests.Session()
        
        # 設定headers
        self.session.headers.update({
            'Accept': 'application/fhir+json',
            'Content-Type': 'application/fhir+json'
        })
        
        if auth_token:
            self.session.headers.update({
                'Authorization': f'Bearer {auth_token}'
            })
    
    def _make_request(self, resource_type: str, params: Optional[Dict] = None) -> Dict:
        """
        執行FHIR API請求
        
        Args:
            resource_type: FHIR資源類型 (Patient, Encounter, etc.)
            params: 查詢參數
            
        Returns:
            FHIR Bundle資源
        """
        url = urljoin(self.base_url + '/', resource_type)
        
        try:
            logger.info(f"請求 {self.name}: {resource_type}")
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            logger.info(f"成功從 {self.name} 取得 {resource_type} 資料")
            return data
            
        except requests.exceptions.RequestException as e:
            logger.error(f"從 {self.name} 請求 {resource_type} 失敗: {e}")
            return {'resourceType': 'Bundle', 'entry': []}
    
    def get_patients(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得Patient資源列表"""
        bundle = self._make_request('Patient', params)
        return self._extract_resources(bundle)
    
    def get_encounters(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得Encounter資源列表"""
        bundle = self._make_request('Encounter', params)
        return self._extract_resources(bundle)
    
    def get_medication_requests(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得MedicationRequest資源列表"""
        bundle = self._make_request('MedicationRequest', params)
        return self._extract_resources(bundle)
    
    def get_medication_administrations(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得MedicationAdministration資源列表"""
        bundle = self._make_request('MedicationAdministration', params)
        return self._extract_resources(bundle)
    
    def get_observations(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得Observation資源列表"""
        bundle = self._make_request('Observation', params)
        return self._extract_resources(bundle)
    
    def get_procedures(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得Procedure資源列表"""
        bundle = self._make_request('Procedure', params)
        return self._extract_resources(bundle)
    
    def get_document_references(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得DocumentReference資源列表"""
        bundle = self._make_request('DocumentReference', params)
        return self._extract_resources(bundle)
    
    def get_diagnostic_reports(self, params: Optional[Dict] = None) -> List[Dict]:
        """取得DiagnosticReport資源列表"""
        bundle = self._make_request('DiagnosticReport', params)
        return self._extract_resources(bundle)
    
    def _extract_resources(self, bundle: Dict) -> List[Dict]:
        """從Bundle中提取資源"""
        if 'entry' not in bundle:
            return []
        
        resources = []
        for entry in bundle.get('entry', []):
            if 'resource' in entry:
                resources.append(entry['resource'])
        
        return resources
    
    def get_all_resources_for_cql(self, date_range: Optional[tuple] = None) -> Dict[str, List[Dict]]:
        """
        取得CQL執行所需的所有資源
        
        Args:
            date_range: (start_date, end_date) 日期範圍
            
        Returns:
            包含所有資源類型的字典
        """
        params = {}
        if date_range:
            start_date, end_date = date_range
            params['_lastUpdated'] = f'ge{start_date.isoformat()}'
        
        logger.info(f"開始從 {self.name} 擷取所有CQL所需資源...")
        
        resources = {
            'Patient': self.get_patients(params),
            'Encounter': self.get_encounters(params),
            'MedicationRequest': self.get_medication_requests(params),
            'MedicationAdministration': self.get_medication_administrations(params),
            'Observation': self.get_observations(params),
            'Procedure': self.get_procedures(params),
            'DocumentReference': self.get_document_references(params),
            'DiagnosticReport': self.get_diagnostic_reports(params),
        }
        
        # 統計資料量
        total_count = sum(len(r) for r in resources.values())
        logger.info(f"從 {self.name} 共取得 {total_count} 筆資源")
        
        for resource_type, resource_list in resources.items():
            logger.info(f"  - {resource_type}: {len(resource_list)} 筆")
        
        return resources


class MultiServerFHIRClient:
    """管理多個FHIR伺服器的客戶端"""
    
    def __init__(self, server_configs: List[Dict]):
        """
        初始化多伺服器客戶端
        
        Args:
            server_configs: 伺服器配置列表
        """
        self.clients = []
        
        for config in server_configs:
            if config.get('enabled', True):
                client = FHIRClient(
                    base_url=config['base_url'],
                    name=config.get('name', 'FHIR Server'),
                    auth_token=config.get('auth_token')
                )
                self.clients.append(client)
        
        logger.info(f"已初始化 {len(self.clients)} 個FHIR伺服器連線")
    
    def get_all_resources_from_all_servers(self, date_range: Optional[tuple] = None) -> Dict[str, Dict[str, List[Dict]]]:
        """
        從所有伺服器取得資源
        
        Returns:
            {
                'server1': {'Patient': [...], 'Encounter': [...]},
                'server2': {'Patient': [...], 'Encounter': [...]}
            }
        """
        all_data = {}
        
        for idx, client in enumerate(self.clients, 1):
            server_key = f"server{idx}"
            logger.info(f"\n{'='*60}")
            logger.info(f"正在從 {client.name} 擷取資料...")
            logger.info(f"{'='*60}")
            
            all_data[server_key] = client.get_all_resources_for_cql(date_range)
        
        return all_data
    
    def merge_resources(self, all_server_data: Dict[str, Dict[str, List[Dict]]]) -> Dict[str, List[Dict]]:
        """
        合併所有伺服器的資源（去重）
        
        Returns:
            {'Patient': [...], 'Encounter': [...]}
        """
        merged = {}
        resource_types = ['Patient', 'Encounter', 'MedicationRequest', 'MedicationAdministration',
                         'Observation', 'Procedure', 'DocumentReference', 'DiagnosticReport']
        
        for resource_type in resource_types:
            merged[resource_type] = []
            seen_ids = set()
            
            for server_data in all_server_data.values():
                for resource in server_data.get(resource_type, []):
                    resource_id = resource.get('id')
                    if resource_id and resource_id not in seen_ids:
                        merged[resource_type].append(resource)
                        seen_ids.add(resource_id)
        
        total = sum(len(r) for r in merged.values())
        logger.info(f"\n合併後總計 {total} 筆資源（已去重）")
        
        for resource_type, resources in merged.items():
            if resources:
                logger.info(f"  - {resource_type}: {len(resources)} 筆")
        
        return merged
