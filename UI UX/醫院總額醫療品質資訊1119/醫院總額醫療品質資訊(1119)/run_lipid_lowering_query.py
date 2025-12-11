#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
指標4: 同醫院門診同藥理用藥日數重疊率-降血脂(口服)
連接 SMART on FHIR 伺服器，撈取降血脂藥品處方數據
計算用藥日數重疊率
"""

import requests
import pandas as pd
from datetime import datetime, timedelta
from collections import defaultdict
import json

# SMART on FHIR 伺服器配置
FHIR_SERVERS = {
    'SMART_Health_IT': 'https://r4.smarthealthit.org',
    'HAPI_FHIR_Test': 'https://hapi.fhir.org/baseR4'
}

# 降血脂藥品 ATC 代碼 (依健保指標 1711)
LIPID_LOWERING_ATC_CODES = [
    'C10AA',   # HMG CoA reductase inhibitors - Statins
    'C10AB',   # Fibrates
    'C10AC',   # Bile acid sequestrants
    'C10AD',   # Nicotinic acid and derivatives
    'C10AX',   # Other lipid modifying agents
]

def fetch_medication_requests(server_name, server_url, start_date='2024-01-01'):
    """
    撈取降血脂藥品處方
    """
    print(f"\n{'='*60}")
    print(f"連接伺服器: {server_name}")
    print(f"URL: {server_url}")
    print(f"{'='*60}\n")
    
    all_medications = []
    
    # 查詢參數
    params = {
        '_count': 100,  # 每頁100筆
        '_sort': '-_lastUpdated'
    }
    
    try:
        url = f"{server_url}/MedicationRequest"
        print(f"查詢 MedicationRequest...")
        print(f"參數: {params}\n")
        
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        bundle = response.json()
        
        if 'entry' not in bundle:
            print("❌ 未找到任何處方記錄")
            return []
        
        print(f"✓ 找到 {len(bundle['entry'])} 筆處方記錄\n")
        
        for entry in bundle['entry']:
            resource = entry.get('resource', {})
            if resource.get('resourceType') != 'MedicationRequest':
                continue
            
            # 解析處方資訊
            medication_data = parse_medication_request(resource, server_name)
            if medication_data:
                all_medications.append(medication_data)
        
        print(f"✓ 成功解析 {len(all_medications)} 筆降血脂藥品處方\n")
        return all_medications
        
    except requests.exceptions.RequestException as e:
        print(f"❌ 連接錯誤: {e}")
        return []
    except Exception as e:
        print(f"❌ 處理錯誤: {e}")
        return []

def parse_medication_request(resource, server_name):
    """
    解析 MedicationRequest 資源
    """
    try:
        # 取得藥品代碼
        medication_codeable = resource.get('medicationCodeableConcept', {})
        codings = medication_codeable.get('coding', [])
        
        atc_code = None
        drug_name = medication_codeable.get('text', 'Unknown')
        
        # 尋找 ATC 代碼
        for coding in codings:
            system = coding.get('system', '')
            code = coding.get('code', '')
            display = coding.get('display', '')
            
            if 'atc' in system.lower() or code.startswith(tuple(LIPID_LOWERING_ATC_CODES)):
                atc_code = code
                if display:
                    drug_name = display
                break
        
        # 如果沒有 ATC 代碼，檢查是否為降血脂相關藥品
        if not atc_code:
            drug_name_lower = drug_name.lower()
            keywords = ['atorvastatin', 'simvastatin', 'rosuvastatin', 'pravastatin',
                       'lovastatin', 'fluvastatin', 'pitavastatin', 'statin',
                       'fenofibrate', 'gemfibrozil', 'bezafibrate', 'fibrate',
                       'cholestyramine', 'colestipol', 'ezetimibe', 'niacin']
            
            if any(keyword in drug_name_lower for keyword in keywords):
                # 根據藥品名稱推測 ATC 代碼
                if 'atorvastatin' in drug_name_lower:
                    atc_code = 'C10AA05'  # Atorvastatin
                elif 'simvastatin' in drug_name_lower:
                    atc_code = 'C10AA01'  # Simvastatin
                elif 'rosuvastatin' in drug_name_lower:
                    atc_code = 'C10AA07'  # Rosuvastatin
                elif 'pravastatin' in drug_name_lower:
                    atc_code = 'C10AA03'  # Pravastatin
                elif 'lovastatin' in drug_name_lower:
                    atc_code = 'C10AA02'  # Lovastatin
                elif 'fenofibrate' in drug_name_lower:
                    atc_code = 'C10AB05'  # Fenofibrate
                elif 'gemfibrozil' in drug_name_lower:
                    atc_code = 'C10AB04'  # Gemfibrozil
                elif 'ezetimibe' in drug_name_lower:
                    atc_code = 'C10AX09'  # Ezetimibe
                elif 'statin' in drug_name_lower:
                    atc_code = 'C10AA01'  # Generic statin
        
        # 檢查是否為降血脂藥品
        if not atc_code:
            return None
        
        is_lipid_lowering = False
        for prefix in LIPID_LOWERING_ATC_CODES:
            if atc_code.startswith(prefix):
                is_lipid_lowering = True
                break
        
        if not is_lipid_lowering:
            return None
        
        # 取得處方日期
        authored_on = resource.get('authoredOn', '')
        if not authored_on:
            return None
        
        prescription_date = datetime.fromisoformat(authored_on.replace('Z', '+00:00')).date()
        
        # 取得給藥日數
        dosage_instructions = resource.get('dosageInstruction', [])
        drug_days = 30  # 預設30天
        
        if dosage_instructions:
            timing = dosage_instructions[0].get('timing', {})
            repeat = timing.get('repeat', {})
            duration = repeat.get('duration', 0)
            duration_unit = repeat.get('durationUnit', 'd')
            
            if duration and duration_unit == 'd':
                drug_days = int(duration)
        
        # 計算用藥結束日期
        end_date = prescription_date + timedelta(days=drug_days - 1)
        
        # 取得病人ID
        patient_ref = resource.get('subject', {}).get('reference', '')
        patient_id = patient_ref.split('/')[-1] if patient_ref else 'Unknown'
        
        # 取得醫院ID
        requester_ref = resource.get('requester', {}).get('reference', '')
        hospital_id = requester_ref.split('/')[-1] if requester_ref else server_name
        
        # 取得處方ID
        claim_id = resource.get('id', 'Unknown')
        
        return {
            'server': server_name,
            'hospital_id': hospital_id,
            'patient_id': patient_id,
            'claim_id': claim_id,
            'prescription_date': prescription_date,
            'start_date': prescription_date,
            'end_date': end_date,
            'drug_days': drug_days,
            'drug_name': drug_name,
            'atc_code': atc_code,
        }
        
    except Exception as e:
        print(f"⚠ 解析處方時發生錯誤: {e}")
        return None

def calculate_overlaps(medications_df):
    """
    計算同院同病人不同處方的用藥日數重疊
    """
    print(f"\n{'='*60}")
    print("計算用藥日數重疊")
    print(f"{'='*60}\n")
    
    overlaps = []
    
    # 依醫院和病人分組
    grouped = medications_df.groupby(['hospital_id', 'patient_id'])
    
    for (hospital_id, patient_id), group in grouped:
        if len(group) < 2:
            continue  # 需要至少2筆處方才能計算重疊
        
        # 將群組轉為列表以便比較
        prescriptions = group.to_dict('records')
        
        # 兩兩比較處方
        for i in range(len(prescriptions)):
            for j in range(i + 1, len(prescriptions)):
                p1 = prescriptions[i]
                p2 = prescriptions[j]
                
                # 檢查日期是否重疊
                overlap_start = max(p1['start_date'], p2['start_date'])
                overlap_end = min(p1['end_date'], p2['end_date'])
                
                if overlap_start <= overlap_end:
                    overlap_days = (overlap_end - overlap_start).days + 1
                    
                    overlaps.append({
                        'hospital_id': hospital_id,
                        'patient_id': patient_id,
                        'claim_id_1': p1['claim_id'],
                        'claim_id_2': p2['claim_id'],
                        'drug_name_1': p1['drug_name'],
                        'drug_name_2': p2['drug_name'],
                        'atc_code_1': p1['atc_code'],
                        'atc_code_2': p2['atc_code'],
                        'start_date_1': p1['start_date'],
                        'end_date_1': p1['end_date'],
                        'start_date_2': p2['start_date'],
                        'end_date_2': p2['end_date'],
                        'overlap_start': overlap_start,
                        'overlap_end': overlap_end,
                        'overlap_days': overlap_days,
                    })
    
    print(f"✓ 找到 {len(overlaps)} 筆重疊記錄\n")
    return pd.DataFrame(overlaps)

def generate_report(medications_df, overlaps_df):
    """
    生成健保格式報告
    """
    print(f"\n{'='*60}")
    print("生成報告")
    print(f"{'='*60}\n")
    
    # 計算季度
    medications_df['quarter'] = medications_df['prescription_date'].apply(
        lambda x: f"{x.year}Q{(x.month - 1) // 3 + 1}"
    )
    
    # 依季度和醫院分組統計
    quarterly_stats = []
    
    for (quarter, hospital_id), group in medications_df.groupby(['quarter', 'hospital_id']):
        # 總給藥日數
        total_drug_days = group['drug_days'].sum()
        
        # 處方件數
        prescription_count = len(group)
        
        # 病人數
        patient_count = group['patient_id'].nunique()
        
        # 計算該季度該醫院的重疊日數
        if not overlaps_df.empty:
            hospital_overlaps = overlaps_df[overlaps_df['hospital_id'] == hospital_id]
            total_overlap_days = hospital_overlaps['overlap_days'].sum()
        else:
            total_overlap_days = 0
        
        # 計算重疊率
        overlap_rate = (total_overlap_days / total_drug_days * 100) if total_drug_days > 0 else 0
        
        quarterly_stats.append({
            'quarter': quarter,
            'hospital_id': hospital_id,
            'prescription_count': prescription_count,
            'patient_count': patient_count,
            'total_drug_days': total_drug_days,
            'total_overlap_days': total_overlap_days,
            'overlap_rate': round(overlap_rate, 2)
        })
    
    report_df = pd.DataFrame(quarterly_stats)
    
    # 依季度排序
    quarter_order = ['2024Q1', '2024Q2', '2024Q3', '2024Q4', '2025Q1', '2025Q2', '2025Q3', '2025Q4']
    report_df['quarter_sort'] = report_df['quarter'].apply(
        lambda x: quarter_order.index(x) if x in quarter_order else 999
    )
    report_df = report_df.sort_values('quarter_sort').drop('quarter_sort', axis=1)
    
    return report_df

def main():
    """
    主程式
    """
    print("="*60)
    print("指標4: 同醫院門診同藥理用藥日數重疊率-降血脂(口服)")
    print("="*60)
    print(f"執行時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"查詢期間: 2024-01-01 ~ {datetime.now().strftime('%Y-%m-%d')}")
    print("="*60)
    
    # 選擇伺服器
    server_name = 'SMART_Health_IT'
    server_url = FHIR_SERVERS[server_name]
    
    # 撈取藥品處方
    medications = fetch_medication_requests(server_name, server_url)
    
    if not medications:
        print("❌ 未取得任何數據")
        return
    
    # 轉換為 DataFrame
    medications_df = pd.DataFrame(medications)
    
    print(f"\n{'='*60}")
    print("數據概覽")
    print(f"{'='*60}")
    print(f"總處方數: {len(medications_df)}")
    print(f"醫院數: {medications_df['hospital_id'].nunique()}")
    print(f"病人數: {medications_df['patient_id'].nunique()}")
    print(f"總給藥日數: {medications_df['drug_days'].sum()}")
    print(f"日期範圍: {medications_df['prescription_date'].min()} ~ {medications_df['prescription_date'].max()}")
    
    # 顯示 ATC 分類統計
    print(f"\n{'='*60}")
    print("降血脂藥品分類統計 (依 ATC 代碼)")
    print(f"{'='*60}")
    atc_stats = medications_df.groupby('atc_code').agg({
        'claim_id': 'count',
        'drug_days': 'sum',
        'patient_id': 'nunique'
    }).rename(columns={
        'claim_id': '處方數',
        'drug_days': '總給藥日數',
        'patient_id': '病人數'
    })
    print(atc_stats)
    
    # 計算重疊
    overlaps_df = calculate_overlaps(medications_df)
    
    # 生成報告
    report_df = generate_report(medications_df, overlaps_df)
    
    # 顯示報告
    print(f"\n{'='*60}")
    print("季度報告 (依健保格式)")
    print(f"{'='*60}\n")
    
    # 設定顯示選項
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', None)
    pd.set_option('display.max_colwidth', None)
    
    # 重新命名欄位為中文
    report_display = report_df.rename(columns={
        'quarter': '季度',
        'hospital_id': '醫療機構代碼',
        'prescription_count': '處方件數',
        'patient_count': '病人數',
        'total_drug_days': '降血脂(口服)總給藥日數',
        'total_overlap_days': '降血脂(口服)重疊用藥日數',
        'overlap_rate': '降血脂(口服)不同處方用藥日數重疊率'
    })
    
    print(report_display.to_string(index=False))
    
    # 儲存報告
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # 儲存詳細數據
    output_file_1 = f'results/lipid_lowering_medications_{server_name}_{timestamp}.csv'
    medications_df.to_csv(output_file_1, index=False, encoding='utf-8-sig')
    print(f"\n✓ 詳細處方數據已儲存: {output_file_1}")
    
    # 儲存重疊數據
    if not overlaps_df.empty:
        output_file_2 = f'results/lipid_lowering_overlaps_{server_name}_{timestamp}.csv'
        overlaps_df.to_csv(output_file_2, index=False, encoding='utf-8-sig')
        print(f"✓ 重疊數據已儲存: {output_file_2}")
    
    # 儲存季度報告
    output_file_3 = f'results/lipid_lowering_quarterly_report_{server_name}_{timestamp}.csv'
    report_display.to_csv(output_file_3, index=False, encoding='utf-8-sig')
    print(f"✓ 季度報告已儲存: {output_file_3}")
    
    print(f"\n{'='*60}")
    print("執行完成!")
    print(f"{'='*60}\n")

if __name__ == '__main__':
    main()
