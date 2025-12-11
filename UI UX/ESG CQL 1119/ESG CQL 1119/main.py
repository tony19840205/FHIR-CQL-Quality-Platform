"""
ESG CQL Testing Main Program
主程式：整合FHIR連線、CQL執行、資料過濾與顯示

執行流程：
1. 連接2個外部SMART on FHIR伺服器
2. 擷取FHIR資料（範圍開很大）
3. 執行3個CQL檔案
4. 在VS Code中過濾並顯示結果（2年內、總人數、年齡、性別、居住地）
"""

import logging
import yaml
import json
from pathlib import Path
from datetime import datetime
from tabulate import tabulate
from colorama import Fore, Style, init

# 初始化colorama
init(autoreset=True)

# 導入自定義模組
from fhir_client import MultiServerFHIRClient
from cql_processor import CQLExecutor
from data_filter import DataFilter, DataDisplay

# 設定logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('esg_cql_test.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class ESGCQLTester:
    """ESG CQL測試主類別"""
    
    def __init__(self, config_path: str = 'config.yaml'):
        """初始化測試器"""
        self.config = self._load_config(config_path)
        self.workspace_dir = Path(__file__).parent
        
        logger.info("="*80)
        logger.info("ESG CQL 測試系統啟動")
        logger.info("="*80)
    
    def _load_config(self, config_path: str) -> dict:
        """載入設定檔"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
            logger.info(f"已載入設定檔: {config_path}")
            return config
        except Exception as e:
            logger.error(f"載入設定檔失敗: {e}")
            raise
    
    def setup_fhir_clients(self) -> MultiServerFHIRClient:
        """設定FHIR客戶端連線"""
        logger.info("\n" + "="*80)
        logger.info("步驟 1: 設定FHIR伺服器連線")
        logger.info("="*80)
        
        server_configs = []
        for server_key, server_config in self.config['fhir_servers'].items():
            if server_config.get('enabled', True):
                server_configs.append(server_config)
                logger.info(f"✓ {server_config['name']}: {server_config['base_url']}")
        
        return MultiServerFHIRClient(server_configs)
    
    def fetch_fhir_data(self, fhir_client: MultiServerFHIRClient) -> dict:
        """從所有伺服器擷取FHIR資料"""
        logger.info("\n" + "="*80)
        logger.info("步驟 2: 從SMART on FHIR伺服器擷取資料（範圍：全部）")
        logger.info("="*80)
        
        # 擷取所有資料（不限時間，CQL範圍開很大）
        all_server_data = fhir_client.get_all_resources_from_all_servers(date_range=None)
        
        # 合併資料
        merged_data = fhir_client.merge_resources(all_server_data)
        
        return merged_data
    
    def execute_cql_libraries(self, fhir_data: dict) -> dict:
        """執行所有CQL檔案"""
        logger.info("\n" + "="*80)
        logger.info("步驟 3: 執行CQL Libraries")
        logger.info("="*80)
        
        # 準備CQL檔案列表
        cql_files = []
        for cql_config in self.config['cql_libraries']:
            if cql_config.get('enabled', True):
                cql_path = self.workspace_dir / cql_config['file']
                if cql_path.exists():
                    cql_files.append(str(cql_path))
                    logger.info(f"✓ {cql_config['name']}: {cql_config['file']}")
                else:
                    logger.warning(f"✗ CQL檔案不存在: {cql_config['file']}")
        
        # 建立CQL執行器
        cql_executor = CQLExecutor(cql_files)
        
        # 設定測量期間（無限大，實際過濾在VS Code控制）
        measurement_period = (
            datetime(1900, 1, 1),
            datetime(2100, 12, 31)
        )
        
        # 執行所有CQL
        results = cql_executor.execute_all(fhir_data, measurement_period)
        
        logger.info(f"\n已執行 {len(results)} 個CQL Library")
        return results
    
    def filter_and_display(self, fhir_data: dict, cql_results: dict):
        """過濾資料並顯示結果（VS Code控制）"""
        logger.info("\n" + "="*80)
        logger.info("步驟 4: 資料過濾與顯示（VS Code控制）")
        logger.info("="*80)
        
        # 建立資料過濾器（2年內資料）
        data_filter = DataFilter(self.config['data_filters'])
        filtered_fhir_data = data_filter.filter_fhir_data(fhir_data)
        
        # 建立資料顯示處理器
        data_display = DataDisplay(self.config['data_filters']['display_fields'])
        
        # 提取病患基本資料統計
        demographics = data_display.extract_patient_demographics(filtered_fhir_data)
        
        # 格式化顯示結果
        display_results = data_display.format_results_for_display(cql_results, demographics)
        
        # 添加過濾後的資料供詳細顯示使用
        display_results['filtered_data'] = filtered_fhir_data
        
        return display_results
    
    def print_results(self, results: dict):
        """美化輸出結果"""
        logger.info("\n" + "="*80)
        logger.info("測試結果總覽")
        logger.info("="*80)
        
        print(f"\n{Fore.CYAN}{'='*80}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}【ESG CQL 測試結果】{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'='*80}{Style.RESET_ALL}\n")
        
        # 檢查過濾後是否有資料
        filtered_data = results.get('filtered_data', {})
        
        # 獲取時間範圍設定
        years = self.config.get('data_filters', {}).get('time_range', {}).get('years', 2)
        
        # 統計過濾後的資源數量
        encounter_count = len(filtered_data.get('Encounter', []))
        med_count = len(filtered_data.get('MedicationRequest', []))
        obs_count = len(filtered_data.get('Observation', []))
        proc_count = len(filtered_data.get('Procedure', []))
        
        total_filtered = encounter_count + med_count + obs_count + proc_count
        
        if total_filtered == 0:
            print(f"{Fore.YELLOW}⚠️  警告：資料庫中無相關資料（{years}年內）{Style.RESET_ALL}")
            print(f"{Fore.CYAN}ℹ️  說明：CQL已使用全部FHIR資料計算（無時間限制），但過濾後{years}年內無資料記錄{Style.RESET_ALL}\n")
        else:
            print(f"{Fore.GREEN}✓ 資料狀態：已找到{years}年內的相關資料{Style.RESET_ALL}")
            print(f"{Fore.CYAN}   - Encounter: {encounter_count} 筆 | MedicationRequest: {med_count} 筆{Style.RESET_ALL}")
            print(f"{Fore.CYAN}   - Observation: {obs_count} 筆 | Procedure: {proc_count} 筆{Style.RESET_ALL}\n")
        
        # 病患統計
        if 'demographics' in results:
            print(f"{Fore.YELLOW}▼ 病患基本資料統計 ({years}年內資料){Style.RESET_ALL}\n")
            
            demo = results['demographics']
            
            # 總人數
            if '總病患人數' in demo:
                print(f"  {Fore.WHITE}總病患人數: {Fore.GREEN}{demo['總病患人數']}{Fore.WHITE} 人{Style.RESET_ALL}")
            
            # 年齡分布
            if '年齡分布' in demo:
                print(f"\n  {Fore.WHITE}年齡分布:{Style.RESET_ALL}")
                age_data = []
                for age_group, count in demo['年齡分布'].items():
                    age_data.append([f"    {age_group}", f"{count} 人"])
                print(tabulate(age_data, tablefmt='plain'))
                
                if '平均年齡' in demo:
                    print(f"    {Fore.WHITE}平均年齡: {Fore.GREEN}{demo['平均年齡']}{Fore.WHITE} 歲{Style.RESET_ALL}")
            
            # 性別分布
            if '性別分布' in demo:
                print(f"\n  {Fore.WHITE}性別分布:{Style.RESET_ALL}")
                gender_data = []
                for gender, count in demo['性別分布'].items():
                    percentage = demo.get('性別百分比', {}).get(gender, 0)
                    gender_data.append([f"    {gender}", f"{count} 人", f"({percentage}%)"])
                print(tabulate(gender_data, tablefmt='plain'))
            
            # 居住地分布
            if '居住地分布（前10名）' in demo:
                print(f"\n  {Fore.WHITE}居住地分布（前10名）:{Style.RESET_ALL}")
                location_data = []
                for location, count in demo['居住地分布（前10名）'][:10]:
                    location_data.append([f"    {location}", f"{count} 人"])
                print(tabulate(location_data, tablefmt='plain'))
        
        # CQL執行結果
        if 'cql_results' in results:
            print(f"\n{Fore.CYAN}{'='*80}{Style.RESET_ALL}")
            print(f"{Fore.YELLOW}▼ CQL執行結果{Style.RESET_ALL}\n")
            
            for library_name, library_result in results['cql_results'].items():
                print(f"{Fore.GREEN}■ {library_name}{Style.RESET_ALL}")
                
                if 'error' in library_result:
                    print(f"  {Fore.RED}錯誤: {library_result['error']}{Style.RESET_ALL}\n")
                    continue
                
                # 顯示主要指標
                self._print_library_metrics(library_name, library_result)
                print()
        
        print(f"{Fore.CYAN}{'='*80}{Style.RESET_ALL}\n")
    
    def _print_library_metrics(self, library_name: str, result: dict):
        """顯示CQL Library的主要指標"""
        metrics = []
        
        if library_name == "Antibiotic_Utilization":
            metrics = [
                ["  總病患數", result.get('total_patients', 0)],
                ["  總就醫次數", result.get('total_encounters', 0)],
                ["  抗生素醫囑數", result.get('total_antibiotic_orders', 0)],
                ["  抗生素給藥次數", result.get('total_antibiotic_administrations', 0)],
                ["  抗生素使用率", f"{result.get('antibiotic_use_rate_percent', 0)}%"],
                ["  總住院日數", result.get('total_bed_days', 0)],
                ["  DDD per 100 Bed-Days", result.get('ddd_per_100_bed_days', 'N/A')],
                ["  資料狀態", result.get('data_status', 'Unknown')]
            ]
        
        elif library_name == "EHR_Adoption_Rate":
            metrics = [
                ["  總病患數", result.get('total_patients', 0)],
                ["  總就醫次數", result.get('total_encounters', 0)],
                ["  EHR文件數", result.get('total_ehr_documents', 0)],
                ["  電子處方數", result.get('total_electronic_prescriptions', 0)],
                ["  EHR採用率（就醫次數）", f"{result.get('ehr_adoption_rate_encounter_percent', 0)}%"],
                ["  電子處方使用率", f"{result.get('electronic_prescription_rate_percent', 0)}%"],
                ["  電子檢驗結果率", f"{result.get('electronic_lab_results_rate_percent', 0)}%"],
                ["  HIMSS EMRAM等級", f"Level {result.get('himss_emram_level', 0)}"],
                ["  資料狀態", result.get('data_status', 'Unknown')]
            ]
        
        elif library_name == "Waste":
            metrics = [
                ["  總病患數", result.get('total_patients', 0)],
                ["  總就醫次數", result.get('total_encounters', 0)],
                ["  總廢棄物量", f"{result.get('total_waste_kg', 0)} kg"],
                ["  可回收廢棄物", f"{result.get('recyclable_waste_kg', 0)} kg"],
                ["  有害廢棄物", f"{result.get('hazardous_waste_kg', 0)} kg"],
                ["  回收率", f"{result.get('recycling_rate_percent', 0)}%"],
                ["  每次就醫廢棄物量", f"{result.get('waste_per_encounter_kg', 0)} kg"],
                ["  資料狀態", result.get('data_status', 'Unknown')]
            ]
        
        if metrics:
            print(tabulate(metrics, tablefmt='plain'))
            
            # 顯示計算方法說明（廢棄物）
            if library_name == "Waste" and 'waste_calculation_method' in result:
                print(f"  {Fore.CYAN}ℹ️ 計算方式: {result['waste_calculation_method']}{Style.RESET_ALL}")
            
            # 顯示CQL資料範圍說明（僅在第一個CQL顯示）
            if library_name == "Antibiotic_Utilization" and 'data_scope' in result:
                years = self.config.get('data_filters', {}).get('time_range', {}).get('years', 2)
                time_desc = "全部資料（無時間限制）" if years >= 999 else f"{years}年內資料"
                print(f"\n{Fore.CYAN}ℹ️  {result['data_scope']}{Style.RESET_ALL}")
                print(f"{Fore.CYAN}   顯示過濾條件：{time_desc}（由VS Code控制）{Style.RESET_ALL}")
    
    def save_results(self, results: dict, output_path: str = 'esg_cql_results.json'):
        """儲存結果到JSON檔案"""
        output_file = self.workspace_dir / output_path
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        logger.info(f"結果已儲存至: {output_file}")
        print(f"\n{Fore.GREEN}✓ 結果已儲存至: {output_file}{Style.RESET_ALL}")
    
    def print_detailed_data(self, results: dict):
        """顯示過濾後的詳細資料"""
        filtered_data = results.get('filtered_data', {})
        years = self.config.get('data_filters', {}).get('time_range', {}).get('years', 2)
        
        print(f"\n{Fore.CYAN}{'='*80}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}▼ {years}年內詳細資料統計{Style.RESET_ALL}\n")
        
        # 統計各資源類型的數量
        resource_summary = []
        for resource_type, resources in filtered_data.items():
            if resource_type != 'Patient':  # Patient不過濾，不顯示
                resource_summary.append([
                    f"  {resource_type}",
                    f"{Fore.GREEN}{len(resources)} 筆{Style.RESET_ALL}"
                ])
        
        if not resource_summary:
            print(f"{Fore.YELLOW}無{years}年內的詳細資料{Style.RESET_ALL}")
            print(f"{Fore.CYAN}{'='*80}{Style.RESET_ALL}")
            return
        
        print(f"{Fore.WHITE}過濾後資源統計:{Style.RESET_ALL}")
        print(tabulate(resource_summary, tablefmt='plain'))
        
        # 顯示詳細資料
        if resource_summary:
            
            # 顯示Encounter詳細資訊
            encounters = filtered_data.get('Encounter', [])
            if encounters:
                print(f"\n{Fore.WHITE}就醫記錄 (Encounter) 詳細:{Style.RESET_ALL}")
                for idx, enc in enumerate(encounters[:5], 1):  # 最多顯示5筆
                    enc_id = enc.get('id', 'N/A')
                    enc_type = enc.get('class', {}).get('display', 'Unknown')
                    period = enc.get('period', {})
                    start = period.get('start', 'N/A')
                    print(f"  {idx}. ID: {enc_id[:20]}... | 類型: {enc_type} | 時間: {start[:10]}")
                
                if len(encounters) > 5:
                    print(f"  ... 共 {len(encounters)} 筆記錄")
            
            # 顯示MedicationRequest詳細資訊
            meds = filtered_data.get('MedicationRequest', [])
            if meds:
                print(f"\n{Fore.WHITE}藥物醫囑 (MedicationRequest) 詳細:{Style.RESET_ALL}")
                for idx, med in enumerate(meds[:5], 1):
                    med_id = med.get('id', 'N/A')
                    authored = med.get('authoredOn', 'N/A')
                    status = med.get('status', 'N/A')
                    print(f"  {idx}. ID: {med_id[:20]}... | 狀態: {status} | 時間: {authored[:10]}")
                
                if len(meds) > 5:
                    print(f"  ... 共 {len(meds)} 筆記錄")
            
            # 顯示Observation詳細資訊
            obs = filtered_data.get('Observation', [])
            if obs:
                print(f"\n{Fore.WHITE}觀察記錄 (Observation) 詳細:{Style.RESET_ALL}")
                for idx, ob in enumerate(obs[:5], 1):
                    ob_id = ob.get('id', 'N/A')
                    effective = ob.get('effectiveDateTime', 'N/A')
                    code = ob.get('code', {}).get('text', 'N/A')
                    print(f"  {idx}. ID: {ob_id[:20]}... | 項目: {code[:30]} | 時間: {effective[:10]}")
                
                if len(obs) > 5:
                    print(f"  ... 共 {len(obs)} 筆記錄")
        
        print(f"{Fore.CYAN}{'='*80}{Style.RESET_ALL}")
    
    def print_metrics_explanation(self):
        """顯示ESG CQL指標詳細說明"""
        print(f"\n{Fore.CYAN}{'='*80}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}▼ ESG CQL 指標說明{Style.RESET_ALL}\n")
        
        print(f"{Fore.GREEN}【Antibiotic_Utilization - 抗生素使用率】{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}1. 總病患數{Style.RESET_ALL}: Patient資源的總數量")
        print(f"  {Fore.WHITE}2. 總就醫次數{Style.RESET_ALL}: Encounter資源的總數量（包含門診、急診、住院等）")
        print(f"  {Fore.WHITE}3. 抗生素醫囑數{Style.RESET_ALL}: MedicationRequest資源的總數量")
        print(f"  {Fore.WHITE}4. 抗生素給藥次數{Style.RESET_ALL}: MedicationAdministration資源的總數量")
        print(f"  {Fore.WHITE}5. 抗生素使用率{Style.RESET_ALL}: (抗生素給藥次數對應的病患數 / 總病患數) × 100%")
        print(f"     {Fore.CYAN}→ 衡量醫療機構中抗生素的使用普及程度{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}6. 總住院日數{Style.RESET_ALL}: 所有住院類型Encounter的累計天數")
        print(f"  {Fore.WHITE}7. DDD per 100 Bed-Days{Style.RESET_ALL}: (總DDD × 100) / 總住院日數")
        print(f"     {Fore.CYAN}→ WHO標準，衡量每100個住院日的抗生素使用強度{Style.RESET_ALL}\n")
        
        print(f"{Fore.GREEN}【EHR_Adoption_Rate - 電子病歷採用率】{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}1. EHR文件數{Style.RESET_ALL}: DocumentReference資源的總數量")
        print(f"  {Fore.WHITE}2. 電子處方數{Style.RESET_ALL}: MedicationRequest資源的總數量")
        print(f"  {Fore.WHITE}3. EHR採用率（就醫次數）{Style.RESET_ALL}: (有EHR文件的就醫次數 / 總就醫次數) × 100%")
        print(f"     {Fore.CYAN}→ 衡量醫療機構電子病歷的覆蓋率{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}4. 電子處方使用率{Style.RESET_ALL}: (電子處方數 / 總就醫次數) × 100%")
        print(f"     {Fore.CYAN}→ 電子化處方的普及程度{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}5. 電子檢驗結果率{Style.RESET_ALL}: (電子檢驗結果數 / 總就醫次數) × 100%")
        print(f"  {Fore.WHITE}6. HIMSS EMRAM等級{Style.RESET_ALL}: 電子病歷採用成熟度模型（0-7級）")
        print(f"     {Fore.CYAN}Level 0: 無EHR系統{Style.RESET_ALL}")
        print(f"     {Fore.CYAN}Level 1: 部分臨床自動化{Style.RESET_ALL}")
        print(f"     {Fore.CYAN}Level 2: CDR臨床資料庫{Style.RESET_ALL}")
        print(f"     {Fore.CYAN}Level 3: 護理/臨床文件電子化{Style.RESET_ALL}")
        print(f"     {Fore.CYAN}Level 4: CPOE醫囑輸入系統{Style.RESET_ALL}")
        print(f"     {Fore.CYAN}Level 5: 閉環給藥管理{Style.RESET_ALL}")
        print(f"     {Fore.CYAN}Level 6: 完整CDSS臨床決策支援{Style.RESET_ALL}")
        print(f"     {Fore.CYAN}Level 7: 完整電子病歷（EMR){Style.RESET_ALL}\n")
        
        print(f"{Fore.GREEN}【Waste - 醫療廢棄物管理】{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}1. 總廢棄物量{Style.RESET_ALL}: 估算值 = 就醫次數 × 2.5kg/次")
        print(f"     {Fore.CYAN}→ 註：FHIR R4無標準廢棄物資源，此為估算值{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}2. 可回收廢棄物{Style.RESET_ALL}: 總廢棄物量 × 30% (假設值)")
        print(f"  {Fore.WHITE}3. 有害廢棄物{Style.RESET_ALL}: 總廢棄物量 × 15% (假設值)")
        print(f"     {Fore.CYAN}→ 包含感染性廢棄物、化學廢棄物等{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}4. 回收率{Style.RESET_ALL}: (可回收廢棄物 / 總廢棄物) × 100%")
        print(f"     {Fore.CYAN}→ 符合SASB HC-DY-150a.1永續發展指標{Style.RESET_ALL}")
        print(f"  {Fore.WHITE}5. 每次就醫廢棄物量{Style.RESET_ALL}: 總廢棄物量 / 就醫次數")
        print(f"     {Fore.CYAN}→ 衡量單次醫療服務的環境影響{Style.RESET_ALL}\n")
        
        print(f"{Fore.YELLOW}💡 資料來源說明:{Style.RESET_ALL}")
        print(f"  • FHIR R4標準資源: Patient, Encounter, MedicationRequest, MedicationAdministration")
        print(f"  • Observation, Procedure, DocumentReference, DiagnosticReport")
        print(f"  • WHO ATC/DDD標準: 抗生素使用測量")
        print(f"  • HIMSS EMRAM: 電子病歷成熟度評估")
        print(f"  • SASB HC-DY標準: 醫療廢棄物管理指標")
        
        print(f"{Fore.CYAN}{'='*80}{Style.RESET_ALL}")
    
    def run(self):
        """執行完整測試流程"""
        try:
            # 1. 設定FHIR客戶端
            fhir_client = self.setup_fhir_clients()
            
            # 2. 擷取FHIR資料
            fhir_data = self.fetch_fhir_data(fhir_client)
            
            # 3. 執行CQL
            cql_results = self.execute_cql_libraries(fhir_data)
            
            # 4. 過濾與顯示
            display_results = self.filter_and_display(fhir_data, cql_results)
            
            # 5. 輸出結果
            self.print_results(display_results)
            
            # 5.5 顯示詳細資料（如果config啟用）
            if self.config.get('data_filters', {}).get('display_fields', {}).get('encounter_details', False):
                self.print_detailed_data(display_results)
            
            # 5.6 顯示指標說明
            self.print_metrics_explanation()
            
            # 6. 儲存結果
            self.save_results(display_results)
            
            logger.info("\n" + "="*80)
            logger.info("測試完成！")
            logger.info("="*80)
            
            return display_results
            
        except Exception as e:
            logger.error(f"測試執行失敗: {e}", exc_info=True)
            print(f"\n{Fore.RED}✗ 錯誤: {e}{Style.RESET_ALL}")
            raise


def main():
    """主函數"""
    print(f"""
{Fore.CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                        ESG CQL 測試系統 v1.0.0                                 ║
║                                                                               ║
║  功能:                                                                         ║
║  1. 連接外部SMART on FHIR伺服器                                                 ║
║  2. 執行3個CQL檔案 (Antibiotic_Utilization, EHR_Adoption_Rate, Waste)         ║
║  3. 過濾並顯示資料（時間範圍可設定）                                            ║
║  4. 統計: 總人數、年齡、性別、居住地、詳細指標                                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
{Style.RESET_ALL}""")
    
    # 建立測試器並執行
    tester = ESGCQLTester()
    tester.run()


if __name__ == "__main__":
    main()
