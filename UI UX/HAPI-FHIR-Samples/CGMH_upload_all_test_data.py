"""
CGMH測試資料統一上傳腳本
將所有10個測試資料Bundle依序上傳到FHIR伺服器
"""

import json
import requests
import time

# FHIR伺服器設定
FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"

# 所有測試資料Bundle檔案
BUNDLES = [
    {
        "file": "CGMH_test_data_taiwan_100_bundle.json",
        "name": "傳染病監測資料 (100位病患)",
        "patients": "TW00001-TW00100",
        "indicators": "COVID-19, 流感, 腸病毒, 腹瀉, 急性結膜炎"
    },
    {
        "file": "CGMH_test_data_vaccine_100_bundle.json",
        "name": "疫苗接種資料 (100位病患)",
        "patients": "TW00101-TW00200",
        "indicators": "COVID-19疫苗接種覆蓋率, 高血壓活動病例數"
    },
    {
        "file": "CGMH_test_data_antibiotic_49_bundle.json",
        "name": "抗生素使用資料 (49位病患)",
        "patients": "TW00201-TW00249",
        "indicators": "抗生素使用率"
    },
    {
        "file": "CGMH_test_data_waste_9_bundle.json",
        "name": "醫療廢棄物資料 (9筆觀察)",
        "patients": "N/A",
        "indicators": "醫療廢棄物產生量"
    },
    {
        "file": "CGMH_test_data_quality_50_bundle.json",
        "name": "用藥安全品質指標 (50位病患)",
        "patients": "TW00250-TW00299",
        "indicators": "門診注射使用率(01), 門診抗生素使用率(02)"
    },
    {
        "file": "CGMH_test_data_outpatient_quality_53_bundle.json",
        "name": "門診品質指標 (53位病患)",
        "patients": "TW00309-TW00361",
        "indicators": "慢性病處方(04), 10種藥品率(05), 氣喘急診(06), 糖尿病HbA1c(07), 同日再就診(08)"
    },
    {
        "file": "CGMH_test_data_inpatient_quality_46_bundle.json",
        "name": "住院品質指標 (46位病患)",
        "patients": "TW00404-TW00449",
        "indicators": "14天再入院率(09), 3日內急診率(10)"
    },
    {
        "file": "CGMH_test_data_surgical_quality_46_bundle.json",
        "name": "手術品質指標 (46位病患)",
        "patients": "TW00450-TW00495",
        "indicators": "手術預防性抗生素(11), 術後30天死亡率(12), 術後30天再住院率(13)"
    },
    {
        "file": "CGMH_test_data_outcome_quality_12_bundle.json",
        "name": "疾病結果品質指標 (12位病患)",
        "patients": "TW00496-TW00507",
        "indicators": "AMI住院30天死亡率(14), 中風住院30天死亡率(15), 心衰竭住院30天死亡率(16), AMI再住院率(17), 中風再住院率(18), 心衰竭再住院率(19)"
    },
    {
        "file": "CGMH_test_data_same_hospital_overlap_42_bundle.json",
        "name": "同院用藥重疊指標 (42位病患)",
        "patients": "TW00362-TW00403",
        "indicators": "同院降血糖(03-3), 抗思覺失調(03-4), 抗憂鬱(03-5), 安眠鎮靜(03-6), 抗血栓(03-7), 前列腺(03-8), 跨院降血壓(03-9), 跨院降血脂(03-10)"
    }
]

def upload_bundle(bundle_file, bundle_name):
    """上傳單個Bundle到FHIR伺服器"""
    print(f"\n上傳: {bundle_name}")
    print(f"檔案: {bundle_file}")
    
    # 讀取Bundle
    try:
        with open(bundle_file, 'r', encoding='utf-8') as f:
            bundle = json.load(f)
        
        resource_count = len(bundle['entry'])
        print(f"  ✓ 已載入Bundle，共 {resource_count} 個資源")
    except Exception as e:
        print(f"  ✗ 讀取Bundle失敗: {e}")
        return False
    
    # 上傳Bundle
    try:
        response = requests.post(
            FHIR_SERVER,
            json=bundle,
            headers={
                "Content-Type": "application/fhir+json",
                "Accept": "application/fhir+json"
            },
            timeout=300  # 5分鐘超時
        )
        
        if response.status_code in [200, 201]:
            result = response.json()
            
            # 統計成功/失敗
            success_count = 0
            if "entry" in result:
                for entry in result["entry"]:
                    if "response" in entry:
                        status = entry["response"].get("status", "")
                        if status.startswith("20"):
                            success_count += 1
            
            print(f"  ✅ 上傳成功! {success_count}/{resource_count} 個資源")
            return True
        else:
            print(f"  ✗ 上傳失敗! 狀態碼: {response.status_code}")
            print(f"  錯誤: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"  ✗ 上傳過程發生錯誤: {e}")
        return False

def main():
    """主函數"""
    print("=" * 80)
    print("CGMH測試資料統一上傳")
    print("=" * 80)
    print(f"FHIR伺服器: {FHIR_SERVER}")
    print(f"總Bundle數: {len(BUNDLES)}")
    print("=" * 80)
    
    success_count = 0
    failed_bundles = []
    
    for i, bundle_info in enumerate(BUNDLES, 1):
        print(f"\n[{i}/{len(BUNDLES)}] {bundle_info['name']}")
        print(f"病患: {bundle_info['patients']}")
        print(f"指標: {bundle_info['indicators']}")
        
        if upload_bundle(bundle_info['file'], bundle_info['name']):
            success_count += 1
        else:
            failed_bundles.append(bundle_info['name'])
        
        # 每次上傳後等待2秒
        if i < len(BUNDLES):
            print("\n等待2秒...")
            time.sleep(2)
    
    # 總結
    print("\n" + "=" * 80)
    print("上傳完成!")
    print("=" * 80)
    print(f"成功: {success_count}/{len(BUNDLES)}")
    if failed_bundles:
        print(f"失敗: {len(failed_bundles)}")
        print("失敗清單:")
        for name in failed_bundles:
            print(f"  - {name}")
    print("=" * 80)

if __name__ == "__main__":
    main()
