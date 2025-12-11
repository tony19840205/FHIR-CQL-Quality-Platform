"""
同院用藥重疊測試資料上傳腳本
將生成的42位病患Bundle上傳到FHIR伺服器
"""

import json
import requests

# FHIR伺服器設定
FHIR_SERVER = "https://emr-smart.appx.com.tw/v/r4/fhir"

def upload_bundle(bundle_file):
    """上傳Bundle到FHIR伺服器"""
    print("=" * 80)
    print("同院用藥重疊測試資料上傳")
    print("=" * 80)
    print(f"FHIR伺服器: {FHIR_SERVER}")
    print(f"Bundle檔案: {bundle_file}")
    print()
    
    # 讀取Bundle
    try:
        with open(bundle_file, 'r', encoding='utf-8') as f:
            bundle = json.load(f)
        
        print(f"✓ 已載入Bundle")
        print(f"  - 資源總數: {len(bundle['entry'])}")
        print()
    except Exception as e:
        print(f"✗ 讀取Bundle失敗: {e}")
        return False
    
    # 上傳Bundle
    print("正在上傳資料到FHIR伺服器...")
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
        
        print(f"狀態碼: {response.status_code}")
        print()
        
        if response.status_code in [200, 201]:
            result = response.json()
            
            # 統計成功/失敗
            success_count = 0
            error_count = 0
            
            if "entry" in result:
                for entry in result["entry"]:
                    if "response" in entry:
                        status = entry["response"].get("status", "")
                        if status.startswith("20"):
                            success_count += 1
                        else:
                            error_count += 1
            
            print("=" * 80)
            print("上傳完成!")
            print("=" * 80)
            print(f"成功: {success_count} 個資源")
            if error_count > 0:
                print(f"失敗: {error_count} 個資源")
            print("=" * 80)
            return True
        else:
            print(f"✗ 上傳失敗!")
            print(f"  狀態碼: {response.status_code}")
            print(f"  回應: {response.text[:500]}")
            return False
            
    except Exception as e:
        print(f"✗ 上傳過程發生錯誤: {e}")
        return False

if __name__ == "__main__":
    bundle_file = "same_hospital_overlap_42_bundle.json"
    upload_bundle(bundle_file)
