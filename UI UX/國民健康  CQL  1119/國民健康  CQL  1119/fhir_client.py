"""
FHIR Client Module
用於連接外部 SMART FHIR 伺服器，擷取 FHIR 資源資料
"""

import requests
import json
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class FHIRClient:
    """FHIR 客戶端類別，用於與 SMART FHIR 伺服器互動"""
    
    def __init__(self, base_url: str, name: str = "FHIR Server"):
        """
        初始化 FHIR 客戶端
        
        Args:
            base_url: FHIR 伺服器基礎 URL
            name: 伺服器名稱
        """
        self.base_url = base_url.rstrip('/')
        self.name = name
        self.session = requests.Session()
        self.session.headers.update({
            'Accept': 'application/fhir+json',
            'Content-Type': 'application/fhir+json'
        })
        
    def get_capability_statement(self) -> Optional[Dict]:
        """獲取伺服器能力聲明"""
        try:
            url = f"{self.base_url}/metadata"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"無法獲取 {self.name} 能力聲明: {e}")
            return None
    
    def search_resource(self, resource_type: str, params: Dict[str, Any] = None) -> List[Dict]:
        """
        搜尋 FHIR 資源
        
        Args:
            resource_type: 資源類型 (Patient, Immunization, Condition, Observation, etc.)
            params: 搜尋參數
            
        Returns:
            資源列表
        """
        try:
            url = f"{self.base_url}/{resource_type}"
            
            # 預設參數：獲取較多結果
            default_params = {'_count': 100}
            if params:
                default_params.update(params)
            
            response = self.session.get(url, params=default_params, timeout=30)
            response.raise_for_status()
            
            bundle = response.json()
            resources = []
            
            # 提取資源
            if bundle.get('resourceType') == 'Bundle':
                entries = bundle.get('entry', [])
                resources = [entry['resource'] for entry in entries if 'resource' in entry]
                
                logger.info(f"從 {self.name} 獲取了 {len(resources)} 筆 {resource_type} 資料")
                
                # 處理分頁 (最多獲取 3 頁)
                page_count = 1
                while page_count < 3:
                    next_link = self._get_next_link(bundle)
                    if not next_link:
                        break
                    
                    try:
                        response = self.session.get(next_link, timeout=30)
                        response.raise_for_status()
                        bundle = response.json()
                        
                        entries = bundle.get('entry', [])
                        page_resources = [entry['resource'] for entry in entries if 'resource' in entry]
                        resources.extend(page_resources)
                        
                        logger.info(f"獲取第 {page_count + 1} 頁: {len(page_resources)} 筆資料")
                        page_count += 1
                    except Exception as e:
                        logger.warning(f"獲取下一頁時發生錯誤: {e}")
                        break
            
            return resources
            
        except Exception as e:
            logger.error(f"搜尋 {resource_type} 時發生錯誤 ({self.name}): {e}")
            return []
    
    def _get_next_link(self, bundle: Dict) -> Optional[str]:
        """從 Bundle 中提取下一頁連結"""
        links = bundle.get('link', [])
        for link in links:
            if link.get('relation') == 'next':
                return link.get('url')
        return None
    
    def get_patients(self, time_period_years: int = 2) -> List[Dict]:
        """
        獲取病人資料
        
        Args:
            time_period_years: 時間範圍（年）
            
        Returns:
            Patient 資源列表
        """
        params = {}
        return self.search_resource('Patient', params)
    
    def get_immunizations(self, time_period_years: int = 2) -> List[Dict]:
        """
        獲取疫苗接種紀錄（過去 N 年內）
        
        Args:
            time_period_years: 時間範圍（年）
            
        Returns:
            Immunization 資源列表
        """
        # 計算時間範圍
        end_date = datetime.now()
        start_date = end_date - timedelta(days=365 * time_period_years)
        
        params = {
            'date': f'ge{start_date.strftime("%Y-%m-%d")}',
            'status': 'completed'
        }
        
        return self.search_resource('Immunization', params)
    
    def get_conditions(self, time_period_years: int = 2) -> List[Dict]:
        """
        獲取診斷紀錄
        
        Args:
            time_period_years: 時間範圍（年）
            
        Returns:
            Condition 資源列表
        """
        params = {
            'clinical-status': 'active'
        }
        
        return self.search_resource('Condition', params)
    
    def get_observations(self, code: str = None, time_period_years: int = 2) -> List[Dict]:
        """
        獲取觀察值紀錄
        
        Args:
            code: LOINC 代碼
            time_period_years: 時間範圍（年）
            
        Returns:
            Observation 資源列表
        """
        end_date = datetime.now()
        start_date = end_date - timedelta(days=365 * time_period_years)
        
        params = {
            'date': f'ge{start_date.strftime("%Y-%m-%d")}',
            'status': 'final,amended,corrected'
        }
        
        if code:
            params['code'] = code
        
        return self.search_resource('Observation', params)


class MultiServerFHIRClient:
    """多伺服器 FHIR 客戶端"""
    
    def __init__(self, server_configs: List[Dict]):
        """
        初始化多伺服器客戶端
        
        Args:
            server_configs: 伺服器配置列表
        """
        self.clients = []
        for config in server_configs:
            client = FHIRClient(
                base_url=config['base_url'],
                name=config.get('name', 'FHIR Server')
            )
            self.clients.append(client)
    
    def fetch_all_data(self, time_period_years: int = 2) -> Dict[str, List[Dict]]:
        """
        從所有伺服器擷取資料
        
        Args:
            time_period_years: 時間範圍（年）
            
        Returns:
            包含所有資源類型的字典
        """
        logger.info(f"開始從 {len(self.clients)} 個伺服器擷取資料...")
        
        all_data = {
            'Patient': [],
            'Immunization': [],
            'Condition': [],
            'Observation': []
        }
        
        for i, client in enumerate(self.clients, 1):
            logger.info(f"\n正在連接第 {i} 個伺服器: {client.name}")
            logger.info(f"URL: {client.base_url}")
            
            # 檢查伺服器連接
            capability = client.get_capability_statement()
            if capability:
                logger.info("✓ 伺服器連接成功")
            else:
                logger.warning("✗ 伺服器連接失敗，跳過此伺服器")
                continue
            
            # 獲取各類資源
            patients = client.get_patients(time_period_years)
            immunizations = client.get_immunizations(time_period_years)
            conditions = client.get_conditions(time_period_years)
            observations = client.get_observations(time_period_years=time_period_years)
            
            all_data['Patient'].extend(patients)
            all_data['Immunization'].extend(immunizations)
            all_data['Condition'].extend(conditions)
            all_data['Observation'].extend(observations)
        
        # 輸出統計
        logger.info("\n" + "="*60)
        logger.info("資料擷取完成統計:")
        logger.info(f"  Patient: {len(all_data['Patient'])} 筆")
        logger.info(f"  Immunization: {len(all_data['Immunization'])} 筆")
        logger.info(f"  Condition: {len(all_data['Condition'])} 筆")
        logger.info(f"  Observation: {len(all_data['Observation'])} 筆")
        logger.info("="*60 + "\n")
        
        return all_data
    
    def save_data_to_file(self, data: Dict[str, List[Dict]], output_dir: str = "."):
        """
        將資料儲存到 JSON 檔案
        
        Args:
            data: 資料字典
            output_dir: 輸出目錄
        """
        import os
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        for resource_type, resources in data.items():
            if resources:
                filename = os.path.join(output_dir, f"{resource_type}_{timestamp}.json")
                with open(filename, 'w', encoding='utf-8') as f:
                    json.dump(resources, f, ensure_ascii=False, indent=2)
                logger.info(f"已儲存 {resource_type} 資料到: {filename}")


if __name__ == "__main__":
    # 測試程式碼
    import os
    
    # 讀取配置
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    # 建立多伺服器客戶端
    multi_client = MultiServerFHIRClient(config['fhir_servers'])
    
    # 擷取資料
    time_period = config['filters']['time_period_years']
    data = multi_client.fetch_all_data(time_period_years=time_period)
    
    # 儲存資料
    multi_client.save_data_to_file(data)
