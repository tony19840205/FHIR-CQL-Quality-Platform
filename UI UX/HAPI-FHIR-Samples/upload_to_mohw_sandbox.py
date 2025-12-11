"""
上傳測試資料到台灣衛福部 FHIR SAND-BOX
Upload Test Data to Taiwan MOHW FHIR SAND-BOX

目標伺服器: https://thas.mohw.gov.tw/v/r4/fhir
總病患數: 509位 (508位 + Mr. FHIR CQL)
總資源數: 2,457+ 筆 FHIR 資源
"""

import json
import requests
import time
import os

# 台灣衛福部 FHIR SAND-BOX 伺服器
FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

# Bearer Token (如需要，請填入)
# 從 SAND-BOX 取得的 Access Token
BEARER_TOKEN = ""  # 如果需要授權，請填入

# 所有測試資料Bundle檔案 (11個Bundle，包含 Mr. FHIR CQL)
BUNDLES = [
    {
        "file": "CGMH_test_data_taiwan_100_bundle.json",
        "name": "傳染病監測資料",
        "patients": 100,
        "resources": 200,
        "indicators": "COVID-19、流感、腸病毒、腹瀉、急性結膜炎"
    },
    {
        "file": "CGMH_test_data_vaccine_100_bundle.json",
        "name": "疫苗接種資料",
        "patients": 100,
        "resources": 219,
        "indicators": "COVID-19疫苗、流感疫苗、高血壓活動病例"
    },
    {
        "file": "CGMH_test_data_antibiotic_49_bundle.json",
        "name": "抗生素使用資料",
        "patients": 49,
        "resources": 241,
        "indicators": "ESG抗生素使用率"
    },
    {
        "file": "CGMH_test_data_waste_9_bundle.json",
        "name": "醫療廢棄物資料",
        "patients": 0,
        "resources": 45,
        "indicators": "ESG醫療廢棄物管理"
    },
    {
        "file": "CGMH_test_data_quality_50_bundle.json",
        "name": "用藥安全品質指標",
        "patients": 50,
        "resources": 502,
        "indicators": "指標01-02 (注射劑、抗生素)"
    },
    {
        "file": "CGMH_test_data_outpatient_quality_53_bundle.json",
        "name": "門診品質指標",
        "patients": 53,
        "resources": 585,
        "indicators": "指標04-08 (慢性病處方、10種藥品、氣喘急診、糖尿病HbA1c、同日再就診)"
    },
    {
        "file": "CGMH_test_data_inpatient_quality_46_bundle.json",
        "name": "住院品質指標",
        "patients": 46,
        "resources": 172,
        "indicators": "指標09-10 (14天再入院、3日急診)"
    },
    {
        "file": "CGMH_test_data_surgical_quality_46_bundle.json",
        "name": "手術品質指標",
        "patients": 46,
        "resources": 196,
        "indicators": "指標11-13 (預防性抗生素、術後死亡率、術後再住院)"
    },
    {
        "file": "CGMH_test_data_outcome_quality_12_bundle.json",
        "name": "疾病結果品質指標",
        "patients": 12,
        "resources": 45,
        "indicators": "指標14-19 (AMI、中風、心衰竭死亡率與再住院率)"
    },
    {
        "file": "CGMH_test_data_same_hospital_overlap_42_bundle.json",
        "name": "同院用藥重疊指標",
        "patients": 42,
        "resources": 252,
        "indicators": "指標03-3至03-10 (8種藥物重疊監測)"
    },
    {
        "file": "Mr_FHIR_CQL_Demo_Patient.json",
        "name": "Mr. FHIR CQL 虛擬病患",
        "patients": 1,
        "resources": "估計50+",
        "indicators": "展示用完整病患資料"
    }
]

def upload_bundle(bundle_info):
    """上傳單個Bundle到FHIR伺服器"""
    bundle_file = bundle_info["file"]
    bundle_name = bundle_info["name"]
    
    print(f"\n{'='*70}")
    print(f"📦 {bundle_name}")
    print(f"{'='*70}")
    print(f"檔案: {bundle_file}")
    print(f"病患數: {bundle_info['patients']}")
    print(f"資源數: {bundle_info['resources']}")
    print(f"涵蓋指標: {bundle_info['indicators']}")
    print(f"{'-'*70}")
    
    # 檢查檔案是否存在
    if not os.path.exists(bundle_file):
        print(f"❌ 檔案不存在: {bundle_file}")
        return False
    
    # 讀取Bundle
    try:
        with open(bundle_file, 'r', encoding='utf-8') as f:
            bundle = json.load(f)
        
        resource_count = len(bundle.get('entry', []))
        print(f"✅ 已載入Bundle，共 {resource_count} 個資源")
    except Exception as e:
        print(f"❌ 讀取Bundle失敗: {e}")
        return False
    
    # 準備 HTTP Headers
    headers = {
        "Content-Type": "application/fhir+json",
        "Accept": "application/fhir+json"
    }
    
    # 如果有 Bearer Token，加入授權
    if BEARER_TOKEN:
        headers["Authorization"] = f"Bearer {BEARER_TOKEN}"
    
    # 上傳Bundle
    try:
        print(f"⏳ 正在上傳到 {FHIR_SERVER} ...")
        
        response = requests.post(
            FHIR_SERVER,
            json=bundle,
            headers=headers,
            timeout=120  # 2分鐘超時
        )
        
        # 檢查回應狀態
        if response.status_code in [200, 201]:
            print(f"✅ 上傳成功！HTTP {response.status_code}")
            return True
        else:
            print(f"❌ 上傳失敗！HTTP {response.status_code}")
            print(f"錯誤訊息: {response.text[:500]}")
            return False
            
    except requests.exceptions.Timeout:
        print(f"❌ 上傳超時 (>120秒)")
        return False
    except requests.exceptions.ConnectionError:
        print(f"❌ 連線失敗，請檢查網路或伺服器狀態")
        return False
    except Exception as e:
        print(f"❌ 上傳失敗: {e}")
        return False

def main():
    """主程式：依序上傳所有Bundle"""
    print("="*70)
    print("🏥 台灣衛福部 FHIR SAND-BOX 測試資料上傳程式")
    print("="*70)
    print(f"目標伺服器: {FHIR_SERVER}")
    print(f"總Bundle數: {len(BUNDLES)}")
    print(f"預估病患數: 509位")
    print(f"預估資源數: 2,500+ 筆")
    print("="*70)
    
    # 確認是否要上傳
    print("\n⚠️  請確認:")
    print(f"   1. FHIR Server: {FHIR_SERVER}")
    print(f"   2. 是否需要 Bearer Token? 目前: {'已設定' if BEARER_TOKEN else '未設定'}")
    print(f"   3. 將上傳 {len(BUNDLES)} 個Bundle")
    
    user_input = input("\n是否繼續上傳? (yes/no): ").strip().lower()
    if user_input not in ['yes', 'y']:
        print("❌ 取消上傳")
        return
    
    # 開始上傳
    print("\n" + "="*70)
    print("🚀 開始上傳...")
    print("="*70)
    
    start_time = time.time()
    success_count = 0
    fail_count = 0
    
    for i, bundle_info in enumerate(BUNDLES, 1):
        print(f"\n進度: {i}/{len(BUNDLES)}")
        
        if upload_bundle(bundle_info):
            success_count += 1
            print(f"✅ 成功 ({success_count}/{i})")
        else:
            fail_count += 1
            print(f"❌ 失敗 ({fail_count}/{i})")
        
        # 每次上傳後等待2秒，避免伺服器負載過大
        if i < len(BUNDLES):
            print("⏳ 等待 2 秒...")
            time.sleep(2)
    
    # 上傳完成統計
    elapsed_time = time.time() - start_time
    
    print("\n" + "="*70)
    print("📊 上傳完成統計")
    print("="*70)
    print(f"✅ 成功: {success_count}/{len(BUNDLES)}")
    print(f"❌ 失敗: {fail_count}/{len(BUNDLES)}")
    print(f"⏱️  總耗時: {elapsed_time:.1f} 秒")
    print("="*70)
    
    if success_count == len(BUNDLES):
        print("\n🎉 所有資料上傳成功！")
        print(f"✅ 509位病患的完整測試資料已上傳至衛福部 SAND-BOX")
    else:
        print(f"\n⚠️  部分資料上傳失敗，請檢查失敗的Bundle")

if __name__ == "__main__":
    main()
