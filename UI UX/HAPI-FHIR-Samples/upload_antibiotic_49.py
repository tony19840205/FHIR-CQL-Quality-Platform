import requests
import json

print("📤 開始上傳 49 筆抗生素使用數據到 emr-smart...")

# 讀取生成的 bundle
with open('antibiotic_49_bundle.json', 'r', encoding='utf-8') as f:
    bundle = json.load(f)

print(f"Bundle 類型: {bundle['type']}")
print(f"資源總數: {len(bundle['entry'])} (49 Patient + 49 Encounter + 49 MedicationRequest + 94 MedicationAdministration)")
print(f"病人編號: TW00201-TW00249")

# 上傳到 emr-smart FHIR 伺服器
url = 'https://emr-smart.appx.com.tw/v/r4/fhir'
headers = {
    'Content-Type': 'application/fhir+json',
    'Accept': 'application/fhir+json'
}

print(f"\n正在上傳到: {url}")
print("這將覆蓋現有的 TW00201-TW00249 資料...")

try:
    response = requests.post(url, json=bundle, headers=headers, timeout=120)
    
    print(f"\n上傳結果:")
    print(f"狀態碼: {response.status_code}")
    
    if response.status_code in [200, 201]:
        print("✅ 上傳成功！")
        
        # 顯示回應內容
        try:
            result = response.json()
            if 'entry' in result:
                success_count = sum(1 for entry in result['entry'] 
                                  if entry.get('response', {}).get('status', '').startswith('2'))
                print(f"成功處理: {success_count} 筆資源")
        except:
            print(f"回應內容: {response.text[:500]}")
    else:
        print(f"❌ 上傳失敗")
        print(f"錯誤訊息: {response.text[:500]}")
        
except requests.exceptions.Timeout:
    print("❌ 上傳超時（120秒）")
except requests.exceptions.RequestException as e:
    print(f"❌ 網路錯誤: {e}")

print("\n完成！")
