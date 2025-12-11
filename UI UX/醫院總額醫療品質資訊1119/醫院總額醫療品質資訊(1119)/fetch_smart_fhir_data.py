#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SMART on FHIR 資料抓取腳本
連接兩個FHIR伺服器，撷取門診注射劑使用率資料
時間範圍: 2024Q1 ~ 2025Q4 (至2025-11-06)
"""

import json
import requests
from datetime import datetime, date
from collections import defaultdict
import csv

# FHIR Server 配置
FHIR_SERVERS = {
    'server1': {
        'name': '台灣健保署FHIR伺服器',
        'base_url': 'https://fhir.nhi.gov.tw/fhir',
        'auth_required': False,
        'token': None  # 如需要請填入 Bearer token
    },
    'server2': {
        'name': '醫院總額FHIR伺服器', 
        'base_url': 'https://fhir.hospitals.tw/fhir',
        'auth_required': False,
        'token': None
    }
}

# 測試用公開FHIR伺服器 (如果上述伺服器無法連接)
FALLBACK_SERVERS = {
    'hapi': {
        'name': 'HAPI FHIR Test Server',
        'base_url': 'https://hapi.fhir.org/baseR4',
        'auth_required': False
    },
    'smart': {
        'name': 'SMART Health IT Sandbox',
        'base_url': 'https://launch.smarthealthit.org/v/r4/fhir',
        'auth_required': False
    }
}

# 季度定義
QUARTERS = [
    {'quarter': '2024Q1', 'start': '2024-01-01', 'end': '2024-03-31'},
    {'quarter': '2024Q2', 'start': '2024-04-01', 'end': '2024-06-30'},
    {'quarter': '2024Q3', 'start': '2024-07-01', 'end': '2024-09-30'},
    {'quarter': '2024Q4', 'start': '2024-10-01', 'end': '2024-12-31'},
    {'quarter': '2025Q1', 'start': '2025-01-01', 'end': '2025-03-31'},
    {'quarter': '2025Q2', 'start': '2025-04-01', 'end': '2025-06-30'},
    {'quarter': '2025Q3', 'start': '2025-07-01', 'end': '2025-09-30'},
    {'quarter': '2025Q4', 'start': '2025-10-01', 'end': '2025-11-06'}  # 至今天
]

# 歷史基準值 (111年第1季 = 2022Q1)
BASELINE = {
    'quarter': '111年第1季',
    'injection_claims': 54653,
    'total_claims': 5831409,
    'usage_rate': 0.94
}


def get_headers(server_config):
    """建立HTTP請求標頭"""
    headers = {
        'Accept': 'application/fhir+json',
        'Content-Type': 'application/fhir+json'
    }
    if server_config.get('auth_required') and server_config.get('token'):
        headers['Authorization'] = f"Bearer {server_config['token']}"
    return headers


def test_fhir_connection(base_url, server_name):
    """測試FHIR伺服器連接"""
    try:
        response = requests.get(
            f"{base_url}/metadata",
            headers={'Accept': 'application/fhir+json'},
            timeout=10
        )
        if response.status_code == 200:
            print(f"✅ {server_name} 連接成功")
            metadata = response.json()
            version = metadata.get('fhirVersion', 'Unknown')
            print(f"   FHIR版本: {version}")
            return True
        else:
            print(f"❌ {server_name} 連接失敗 (HTTP {response.status_code})")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ {server_name} 連接錯誤: {str(e)}")
        return False


def fetch_medication_requests(base_url, headers, start_date, end_date):
    """
    從FHIR伺服器撷取MedicationRequest (藥品處方)
    篩選條件: 注射劑 (route code = 385219001 SNOMED CT)
    """
    url = f"{base_url}/MedicationRequest"
    params = {
        'date': f'ge{start_date}',
        '_count': 100,
        'status': 'completed'
    }
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=30)
        if response.status_code != 200:
            print(f"  ⚠️  MedicationRequest查詢失敗 (HTTP {response.status_code})")
            return []
        
        bundle = response.json()
        entries = bundle.get('entry', [])
        
        medications = []
        for entry in entries:
            resource = entry.get('resource', {})
            if resource.get('resourceType') == 'MedicationRequest':
                # 檢查給藥途徑是否為注射
                dosage = resource.get('dosageInstruction', [{}])[0]
                route = dosage.get('route', {})
                route_code = route.get('coding', [{}])[0].get('code', '')
                
                # 只保留注射劑 (SNOMED: 385219001)
                if route_code == '385219001' or 'injection' in route.get('text', '').lower():
                    medications.append({
                        'id': resource.get('id'),
                        'patient': resource.get('subject', {}).get('reference'),
                        'medication': resource.get('medicationCodeableConcept', {}).get('text', 'Unknown'),
                        'authored_on': resource.get('authoredOn'),
                        'encounter': resource.get('encounter', {}).get('reference'),
                        'route': route.get('text', 'Injection')
                    })
        
        return medications
    
    except requests.exceptions.RequestException as e:
        print(f"  ⚠️  MedicationRequest查詢錯誤: {str(e)}")
        return []


def fetch_encounters(base_url, headers, start_date, end_date):
    """
    從FHIR伺服器撷取Encounter (就診紀錄)
    篩選條件: 門診 (class = AMB)
    """
    url = f"{base_url}/Encounter"
    params = {
        'date': f'ge{start_date}',
        '_count': 100,
        'class': 'AMB',
        'status': 'finished'
    }
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=30)
        if response.status_code != 200:
            print(f"  ⚠️  Encounter查詢失敗 (HTTP {response.status_code})")
            return []
        
        bundle = response.json()
        entries = bundle.get('entry', [])
        
        encounters = []
        for entry in entries:
            resource = entry.get('resource', {})
            if resource.get('resourceType') == 'Encounter':
                encounters.append({
                    'id': resource.get('id'),
                    'patient': resource.get('subject', {}).get('reference'),
                    'class': resource.get('class', {}).get('code'),
                    'period_start': resource.get('period', {}).get('start'),
                    'period_end': resource.get('period', {}).get('end'),
                    'organization': resource.get('serviceProvider', {}).get('display', 'Unknown')
                })
        
        return encounters
    
    except requests.exceptions.RequestException as e:
        print(f"  ⚠️  Encounter查詢錯誤: {str(e)}")
        return []


def analyze_by_quarter(medications, encounters):
    """按季度分析資料"""
    results = []
    
    for q in QUARTERS:
        quarter_meds = [m for m in medications 
                       if m['authored_on'] and q['start'] <= m['authored_on'][:10] <= q['end']]
        
        quarter_encounters = [e for e in encounters
                            if e['period_start'] and q['start'] <= e['period_start'][:10] <= q['end']]
        
        injection_count = len(quarter_meds)
        total_count = len(quarter_encounters)
        usage_rate = (injection_count / total_count * 100) if total_count > 0 else 0
        
        results.append({
            '期間': q['quarter'],
            '注射劑案件數': injection_count,
            '門診案件數': total_count,
            '使用率(%)': round(usage_rate, 2),
            '較基準差異': round(usage_rate - BASELINE['usage_rate'], 2),
            '評等': '低於基準(優)' if usage_rate <= BASELINE['usage_rate'] 
                   else '接近基準' if usage_rate <= 1.5 
                   else '高於基準(需注意)'
        })
    
    return results


def display_results(results, server_name):
    """顯示結果表格"""
    print(f"\n{'='*80}")
    print(f"📊 {server_name} - 門診注射劑使用率統計 (2024Q1~2025Q4)")
    print(f"{'='*80}")
    print(f"基準值: 111年第1季 = {BASELINE['usage_rate']}% ({BASELINE['injection_claims']:,}/{BASELINE['total_claims']:,})")
    print(f"{'-'*80}")
    print(f"{'期間':<10} {'注射劑案件數':>12} {'門診案件數':>12} {'使用率(%)':>10} {'較基準差異':>10} {'評等':<15}")
    print(f"{'-'*80}")
    
    for row in results:
        print(f"{row['期間']:<10} {row['注射劑案件數']:>12,} {row['門診案件數']:>12,} "
              f"{row['使用率(%)']:>10.2f} {row['較基準差異']:>+10.2f} {row['評等']:<15}")
    
    print(f"{'='*80}\n")


def save_to_csv(results, filename):
    """儲存結果為CSV"""
    with open(filename, 'w', newline='', encoding='utf-8-sig') as f:
        if results:
            writer = csv.DictWriter(f, fieldnames=results[0].keys())
            writer.writeheader()
            writer.writerows(results)
    print(f"✅ 結果已儲存至: {filename}")


def main():
    """主程式"""
    print("🚀 開始連接SMART on FHIR伺服器並撷取資料...")
    print(f"📅 資料期間: 2024-01-01 ~ 2025-11-06\n")
    
    all_results = {}
    
    # 嘗試連接兩個主要FHIR伺服器
    for server_id, config in FHIR_SERVERS.items():
        print(f"\n{'='*80}")
        print(f"🔌 連接 {config['name']}")
        print(f"{'='*80}")
        
        if not test_fhir_connection(config['base_url'], config['name']):
            print(f"⚠️  無法連接 {config['name']}，嘗試使用測試伺服器...\n")
            # 使用fallback伺服器
            fallback_id = 'hapi' if server_id == 'server1' else 'smart'
            fallback_config = FALLBACK_SERVERS[fallback_id]
            print(f"🔄 切換至 {fallback_config['name']}")
            
            if test_fhir_connection(fallback_config['base_url'], fallback_config['name']):
                config = fallback_config
            else:
                continue
        
        headers = get_headers(config)
        all_medications = []
        all_encounters = []
        
        # 撷取資料
        print(f"\n📥 正在撷取資料...")
        for q in QUARTERS:
            print(f"  處理 {q['quarter']}...")
            meds = fetch_medication_requests(config['base_url'], headers, q['start'], q['end'])
            encs = fetch_encounters(config['base_url'], headers, q['start'], q['end'])
            all_medications.extend(meds)
            all_encounters.extend(encs)
            print(f"    找到 {len(meds)} 筆注射劑處方, {len(encs)} 筆門診記錄")
        
        print(f"\n✅ 總計撷取:")
        print(f"   注射劑處方: {len(all_medications)} 筆")
        print(f"   門診記錄: {len(all_encounters)} 筆")
        
        # 分析並顯示結果
        results = analyze_by_quarter(all_medications, all_encounters)
        display_results(results, config['name'])
        
        # 儲存結果
        filename = f"results_{server_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        save_to_csv(results, filename)
        
        all_results[config['name']] = results
    
    # 總結
    print(f"\n{'='*80}")
    print(f"✅ 資料撷取完成!")
    print(f"📊 已從 {len(all_results)} 個FHIR伺服器撷取資料")
    print(f"{'='*80}\n")


if __name__ == '__main__':
    main()
