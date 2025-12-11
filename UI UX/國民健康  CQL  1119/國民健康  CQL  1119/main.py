"""
Main Application
主程式：連接 SMART FHIR 伺服器、擷取資料、處理並顯示結果
"""

import os
import json
import logging
from datetime import datetime

from fhir_client import MultiServerFHIRClient
from data_processor import FHIRDataProcessor
from display import ReportDisplay

# 設定日誌
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_config(config_path: str = 'config.json') -> dict:
    """載入配置檔案"""
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.error(f"找不到配置檔案: {config_path}")
        raise
    except json.JSONDecodeError as e:
        logger.error(f"配置檔案格式錯誤: {e}")
        raise


def main():
    """主程式"""
    print("\n" + "="*80)
    print("國民健康 CQL 測量指標系統".center(80))
    print("="*80 + "\n")
    
    # 1. 載入配置
    logger.info("步驟 1/5: 載入配置檔案...")
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(script_dir, 'config.json')
        config = load_config(config_path)
        
        print(f"✓ 配置檔案載入成功")
        print(f"  - FHIR 伺服器數量: {len(config['fhir_servers'])}")
        print(f"  - 資料時間範圍: {config['filters']['time_period_years']} 年")
        print(f"  - CQL 測量庫數量: {len(config['cql_libraries'])}")
        
        for i, server in enumerate(config['fhir_servers'], 1):
            print(f"  - 伺服器 {i}: {server['name']} ({server['base_url']})")
        
    except Exception as e:
        logger.error(f"載入配置失敗: {e}")
        return
    
    # 2. 連接 FHIR 伺服器並擷取資料
    logger.info("\n步驟 2/5: 連接 FHIR 伺服器並擷取資料...")
    print("\n正在連接外部 SMART FHIR 伺服器...")
    
    try:
        multi_client = MultiServerFHIRClient(config['fhir_servers'])
        time_period = config['filters']['time_period_years']
        
        fhir_data = multi_client.fetch_all_data(time_period_years=time_period)
        
        print("\n✓ 資料擷取完成")
        
    except Exception as e:
        logger.error(f"資料擷取失敗: {e}")
        return
    
    # 3. 處理資料
    logger.info("\n步驟 3/5: 處理 FHIR 資料...")
    print("\n正在處理資料...")
    
    try:
        processor = FHIRDataProcessor(fhir_data)
        report = processor.generate_full_report(time_period_years=time_period)
        
        print("✓ 資料處理完成")
        
    except Exception as e:
        logger.error(f"資料處理失敗: {e}")
        return
    
    # 4. 顯示報告
    logger.info("\n步驟 4/5: 顯示報告...")
    
    try:
        display = ReportDisplay()
        display.display_full_report(report)
        
    except Exception as e:
        logger.error(f"報告顯示失敗: {e}")
        return
    
    # 5. 儲存報告
    logger.info("\n步驟 5/5: 儲存報告...")
    
    try:
        # 儲存 JSON 報告
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        json_filename = os.path.join(script_dir, f"report_{timestamp}.json")
        html_filename = os.path.join(script_dir, f"report_{timestamp}.html")
        
        display.save_report_to_json(report, json_filename)
        display.save_report_to_html(report, html_filename)
        
        print(f"\n完成！報告已產生:")
        print(f"  - JSON: {json_filename}")
        print(f"  - HTML: {html_filename}")
        
    except Exception as e:
        logger.error(f"報告儲存失敗: {e}")
        return
    
    print("\n" + "="*80)
    print("程式執行完成".center(80))
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
