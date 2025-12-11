import requests

base_url = "https://emr-smart.appx.com.tw/v/r4/fhir"

print("\n🔍 檢查 Observation (死亡記錄)...")
response = requests.get(f"{base_url}/Observation?subject=Patient/TW20006")
if response.status_code == 200:
    data = response.json()
    print(f"找到 {len(data.get('entry', []))} 筆 Observations")
    for entry in data.get('entry', []):
        obs = entry['resource']
        print(f"  - Observation/{obs['id']}")
        print(f"    encounter: {obs.get('encounter', {}).get('reference', 'N/A')}")
        print(f"    code: {obs.get('code', {})}")
        print(f"    value: {obs.get('valueString', 'N/A')}")
else:
    print(f"❌ 查詢失敗: {response.status_code}")

print("\n🔍 檢查 Procedure (安寧療護)...")
response = requests.get(f"{base_url}/Procedure?subject=Patient/TW20007")
if response.status_code == 200:
    data = response.json()
    print(f"找到 {len(data.get('entry', []))} 筆 Procedures")
    for entry in data.get('entry', []):
        proc = entry['resource']
        print(f"  - Procedure/{proc['id']}")
        print(f"    encounter: {proc.get('encounter', {}).get('reference', 'N/A')}")
        print(f"    code: {proc.get('code', {}).get('coding', [{}])[0].get('code', 'N/A')}")
else:
    print(f"❌ 查詢失敗: {response.status_code}")
