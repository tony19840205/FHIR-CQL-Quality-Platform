#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
顯示降血壓藥品用藥重疊率報告
指標3: 同醫院門診同藥理用藥日數重疊率-降血壓(口服)
"""

import pandas as pd
import glob
import os
from datetime import datetime

def display_report():
    """
    顯示報告
    """
    print("\n" + "="*70)
    print("   指標3: 同醫院門診同藥理用藥日數重疊率-降血壓(口服)")
    print("   健保指標代碼: 1710")
    print("="*70 + "\n")
    
    # 找最新的報告檔案
    report_files = glob.glob('results/antihypertensive_quarterly_report_*.csv')
    if not report_files:
        print("❌ 找不到報告檔案")
        return
    
    report_file = max(report_files, key=os.path.getctime)
    print(f"📊 報告檔案: {os.path.basename(report_file)}")
    print(f"📅 產生時間: {datetime.fromtimestamp(os.path.getctime(report_file)).strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # 讀取報告
    report_df = pd.read_csv(report_file, encoding='utf-8-sig')
    
    # 顯示季度報告表格
    print("="*70)
    print("   季度統計報告")
    print("="*70 + "\n")
    
    # 設定顯示格式
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', None)
    pd.set_option('display.unicode.east_asian_width', True)
    
    # 建立格式化表格
    for _, row in report_df.iterrows():
        quarter = row['季度']
        total_days = int(row['降血壓(口服)總給藥日數'])
        overlap_days = int(row['降血壓(口服)之給藥口數'])
        overlap_rate = float(row['降血壓(口服)不同處方用藥日數重疊率'])
        
        print(f"第{quarter}季 | ", end='')
        print(f"降血壓(口服)總給藥日數: {total_days:>6} | ", end='')
        print(f"重疊日數: {overlap_days:>4} | ", end='')
        print(f"重疊率: {overlap_rate:>5.2f}%")
    
    print("\n" + "="*70 + "\n")
    
    # 統計摘要
    total_drug_days = report_df['降血壓(口服)總給藥日數'].sum()
    total_overlap_days = report_df['降血壓(口服)之給藥口數'].sum()
    avg_overlap_rate = (total_overlap_days / total_drug_days * 100) if total_drug_days > 0 else 0
    
    print("📈 統計摘要")
    print(f"   總給藥日數: {int(total_drug_days):,}")
    print(f"   總重疊日數: {int(total_overlap_days):,}")
    print(f"   平均重疊率: {avg_overlap_rate:.2f}%")
    print()
    
    # 讀取詳細數據
    detail_files = glob.glob('results/antihypertensive_medications_*.csv')
    if detail_files:
        detail_file = max(detail_files, key=os.path.getctime)
        details_df = pd.read_csv(detail_file, encoding='utf-8-sig')
        
        print("="*70)
        print("   降血壓藥品分類統計 (依 ATC 代碼)")
        print("="*70 + "\n")
        
        # ATC 分類統計
        atc_stats = details_df.groupby('atc_code').agg({
            'claim_id': 'count',
            'drug_days': 'sum',
            'patient_id': 'nunique'
        }).rename(columns={
            'claim_id': '處方數',
            'drug_days': '總給藥日數',
            'patient_id': '病人數'
        }).sort_values('處方數', ascending=False)
        
        print(atc_stats.to_string())
        print()
        
        # ATC 代碼說明
        print("="*70)
        print("   ATC 代碼說明")
        print("="*70 + "\n")
        
        atc_descriptions = {
            'C03AA03': 'Thiazides (噻嗪類利尿劑) - Hydrochlorothiazide',
            'C07AB02': 'Beta Blocking Agents (β阻斷劑) - Metoprolol',
            'C08CA01': 'Dihydropyridine (鈣離子阻斷劑) - Amlodipine',
            'C09AA02': 'ACE Inhibitors (ACE抑制劑) - Enalapril',
            'C09CA01': 'Angiotensin II Antagonists (ARB) - Losartan',
        }
        
        for atc_code in details_df['atc_code'].unique():
            if atc_code in atc_descriptions:
                print(f"  {atc_code} : {atc_descriptions[atc_code]}")
        print()
        
        # 藥品明細
        print("="*70)
        print("   藥品處方明細 (前10筆)")
        print("="*70 + "\n")
        
        display_columns = ['prescription_date', 'drug_name', 'atc_code', 'drug_days', 'patient_id']
        print(details_df[display_columns].head(10).to_string(index=False))
        print()
    
    print("="*70)
    print("✅ 報告顯示完成")
    print("="*70 + "\n")

if __name__ == '__main__':
    display_report()
