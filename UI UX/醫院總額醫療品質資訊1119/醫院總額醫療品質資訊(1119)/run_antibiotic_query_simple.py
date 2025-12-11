#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
門診抗生素使用率 - SMART on FHIR 簡易測試
"""

import requests
import pandas as pd
from datetime import datetime
import os

# FHIR伺服器配置
FHIR_SERVER = "https://r4.smarthealthit.org"

print("=" * 80)
print("門診抗生素使用率 - SMART on FHIR 資料查詢")
print("=" * 80)
print(f"FHIR Server: {FHIR_SERVER}")
print(f"執行時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 80)

# ============================================
# 1. 撈取 MedicationRequest
# ============================================
print("\n[1/3] 連接 SMART Health IT 測試伺服器...")

all_medications = []

try:
    # 使用簡單查詢參數
    params = {
        '_count': 50  # 限制筆數
    }
    
    headers = {
        'Accept': 'application/fhir+json'
    }
    
    print(f"    查詢 MedicationRequest 資源...")
    
    response = requests.get(
        f"{FHIR_SERVER}/MedicationRequest",
        params=params,
        headers=headers,
        timeout=10
    )
    
    print(f"    HTTP 狀態碼: {response.status_code}")
    
    if response.status_code == 200:
        bundle = response.json()
        
        print(f"    Bundle 類型: {bundle.get('type')}")
        print(f"    總筆數: {bundle.get('total', 'N/A')}")
        
        if 'entry' in bundle:
            for entry in bundle['entry']:
                resource = entry.get('resource', {})
                
                med_data = {
                    'id': resource.get('id'),
                    'status': resource.get('status'),
                    'authored_on': resource.get('authoredOn', ''),
                    'medication_display': '',
                    'atc_code': ''
                }
                
                # 提取藥品名稱
                med_codeable = resource.get('medicationCodeableConcept', {})
                if med_codeable:
                    med_data['medication_display'] = med_codeable.get('text', '')
                    codings = med_codeable.get('coding', [])
                    for coding in codings:
                        code = coding.get('code', '')
                        if code:
                            med_data['atc_code'] = code
                            break
                
                all_medications.append(med_data)
            
            print(f"    ✓ 成功撈取 {len(all_medications)} 筆處方資料")
        else:
            print("    ⚠️  Bundle 中無資料")
    else:
        print(f"    ✗ 錯誤: {response.status_code}")
        print(f"    {response.text[:300]}")
    
except requests.Timeout:
    print(f"    ✗ 連線逾時")
except Exception as e:
    print(f"    ✗ 錯誤: {str(e)}")

# ============================================
# 2. 模擬 ATC 碼並計算使用率
# ============================================
print("\n[2/3] 計算門診抗生素使用率...")

# 為測試資料添加 ATC 代碼 (模擬)
for i, med in enumerate(all_medications):
    if not med['atc_code'] or len(med['atc_code']) < 3:
        # 模擬: 30%為抗生素 (J01)
        if i % 3 == 0:
            med['atc_code'] = f'J01CA{(i % 20):02d}'
        else:
            med['atc_code'] = f'N02BA{(i % 20):02d}'

# 篩選抗生素
antibiotics = [m for m in all_medications if m['atc_code'].startswith('J01')]

antibiotic_claims = len(antibiotics)
total_claims = len(all_medications)

if total_claims > 0:
    usage_rate = (antibiotic_claims / total_claims) * 100
else:
    usage_rate = 0.0

print(f"\n    {'=' * 70}")
print(f"    門診抗生素使用率統計結果 (健保指標 1140.01)")
print(f"    {'=' * 70}")
print(f"    門診抗生素給藥案件數:  {antibiotic_claims:>10,}")
print(f"    門診給藥案件數:        {total_claims:>10,}")
print(f"    門診抗生素使用率:      {usage_rate:>10.2f}%")
print(f"    {'=' * 70}")

# 與基準值比較
reference_rate = 4.91
difference = usage_rate - reference_rate

print(f"\n    與健保基準值比較:")
print(f"    參考使用率 (第4季):      {reference_rate}%")
print(f"    當前使用率:             {usage_rate:.2f}%")
print(f"    差異:                   {difference:+.2f}%")

# ============================================
# 3. 季度統計
# ============================================
print("\n[3/3] 季度統計分析...")

if len(all_medications) > 0:
    df = pd.DataFrame(all_medications)
    
    # 解析日期
    df['date'] = pd.to_datetime(df['authored_on'], errors='coerce')
    df['quarter'] = df['date'].dt.to_period('Q').astype(str)
    df['is_antibiotic'] = df['atc_code'].str.startswith('J01', na=False)
    
    # 季度統計
    quarterly = df.groupby('quarter').agg({
        'id': 'count',
        'is_antibiotic': 'sum'
    }).rename(columns={
        'id': '給藥案件數',
        'is_antibiotic': '抗生素給藥案件數'
    })
    
    quarterly['使用率'] = (quarterly['抗生素給藥案件數'] / quarterly['給藥案件數'] * 100).round(2)
    
    print("\n    各季度統計:")
    print("    " + "=" * 70)
    print(f"    {'季度':<12} {'抗生素給藥案件數':>15} {'給藥案件數':>15} {'使用率':>10}")
    print("    " + "-" * 70)
    
    for quarter, row in quarterly.iterrows():
        print(f"    {quarter:<12} {int(row['抗生素給藥案件數']):>15,} "
              f"{int(row['給藥案件數']):>15,} {row['使用率']:>9.2f}%")
    
    print("    " + "=" * 70)
    
    # 儲存結果
    results_dir = os.path.join(os.path.dirname(__file__), 'results')
    os.makedirs(results_dir, exist_ok=True)
    
    output_file = os.path.join(results_dir, 'smart_fhir_antibiotic_test.csv')
    df.to_csv(output_file, index=False, encoding='utf-8-sig')
    print(f"\n    ✓ 結果已儲存: {output_file}")
else:
    print("    ⚠️  無資料可統計")

print("\n查詢完成!")
print("=" * 80)
print("\n提示: 這是從 SMART Health IT 測試伺服器擷取的真實資料")
print("      ATC 代碼為模擬資料,實際使用需連接真實健保 FHIR 伺服器")
print("\n" + "=" * 80)
