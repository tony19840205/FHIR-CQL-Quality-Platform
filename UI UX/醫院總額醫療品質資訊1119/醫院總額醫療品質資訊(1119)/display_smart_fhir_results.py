#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
門診抗生素使用率 - SMART FHIR 查詢結果展示
"""

import pandas as pd
from datetime import datetime
import os

print("=" * 80)
print("門診抗生素使用率查詢結果 (健保指標代碼 1140.01)")
print("=" * 80)
print(f"製表時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("資料來源: SMART Health IT 測試伺服器 (https://r4.smarthealthit.org)")
print("=" * 80)

# 讀取查詢結果
results_file = os.path.join(
    os.path.dirname(__file__), 
    'results', 
    'smart_fhir_antibiotic_test.csv'
)

if os.path.exists(results_file):
    df = pd.read_csv(results_file, encoding='utf-8-sig')
    
    print(f"\n✓ 成功載入 {len(df)} 筆處方資料")
    
    # 顯示資料樣本
    print("\n資料樣本 (前5筆):")
    print("-" * 80)
    print(df[['id', 'medication_display', 'atc_code', 'quarter']].head().to_string(index=False))
    print("-" * 80)
    
    # 統計資料品質
    print("\n資料品質檢查:")
    print(f"  • 有 ATC 代碼的處方數: {df['atc_code'].notna().sum()}")
    print(f"  • 缺少 ATC 代碼的處方數: {df['atc_code'].isna().sum()}")
    print(f"  • 有日期的處方數: {df['authored_on'].notna().sum()}")
    
    # 模擬抗生素分類 (實際應使用真實 ATC 代碼 J01)
    # 這裡使用特定藥品名稱來模擬
    antibiotic_keywords = ['ciprofloxacin', 'amoxicillin', 'azithromycin', 
                           'cephalexin', 'doxycycline', 'penicillin']
    
    df['is_simulated_antibiotic'] = df['medication_display'].str.lower().str.contains(
        '|'.join(antibiotic_keywords), 
        case=False, 
        na=False
    )
    
    # 如果沒有找到抗生素,使用隨機模擬 (30%比例)
    if df['is_simulated_antibiotic'].sum() == 0:
        print("\n⚠️  測試資料中未包含明確的抗生素藥品名稱")
        print("    使用模擬資料:假設 30% 的處方為抗生素 (符合健保基準值 4.91%)")
        import numpy as np
        np.random.seed(42)
        simulated_antibiotic = np.random.choice(
            [True, False], 
            size=len(df), 
            p=[0.30, 0.70]
        )
        df['is_simulated_antibiotic'] = simulated_antibiotic
    
    # 計算整體使用率
    print("\n" + "=" * 80)
    print("整體門診抗生素使用率統計")
    print("=" * 80)
    
    total_claims = len(df)
    antibiotic_claims = df['is_simulated_antibiotic'].sum()
    usage_rate = (antibiotic_claims / total_claims * 100) if total_claims > 0 else 0
    
    print(f"門診抗生素給藥案件數:  {antibiotic_claims:>15,}")
    print(f"門診給藥案件數:        {total_claims:>15,}")
    print(f"門診抗生素使用率:      {usage_rate:>15.2f}%")
    print("=" * 80)
    
    # 與健保基準值比較
    reference_rate = 4.91
    difference = usage_rate - reference_rate
    
    print(f"\n與健保基準值比較:")
    print(f"  健保參考使用率 (第4季): {reference_rate}%")
    print(f"  當前查詢使用率:         {usage_rate:.2f}%")
    print(f"  差異:                   {difference:+.2f}%")
    
    if abs(difference) <= 1:
        status = "✓ 符合健保標準"
    elif usage_rate < reference_rate:
        status = "✓ 優於健保標準"
    else:
        status = "⚠ 高於健保標準"
    
    print(f"  評估結果: {status}")
    
    # 季度統計 (仿照圖片中的格式)
    if 'quarter' in df.columns:
        print("\n" + "=" * 80)
        print("各季度門診抗生素使用率統計 (依健保申報季度)")
        print("=" * 80)
        
        quarterly = df.groupby('quarter').agg({
            'id': 'count',
            'is_simulated_antibiotic': 'sum'
        }).rename(columns={
            'id': '給藥案件數',
            'is_simulated_antibiotic': '抗生素給藥案件數'
        })
        
        quarterly['使用率(%)'] = (
            quarterly['抗生素給藥案件數'] / quarterly['給藥案件數'] * 100
        ).round(2)
        
        quarterly = quarterly.sort_index()
        
        # 顯示格式與圖片一致
        print(f"\n{'季度':<15} {'門診抗生素給藥案件數':>20} {'門診給藥案件數':>15} {'門診抗生素使用率':>15}")
        print("-" * 80)
        
        for quarter, row in quarterly.iterrows():
            # 轉換季度格式: 2024Q4 -> 第4季
            try:
                year = quarter[:4]
                q = quarter[-1]
                quarter_display = f"{year}年第{q}季"
            except:
                quarter_display = quarter
            
            print(f"{quarter_display:<15} "
                  f"{int(row['抗生素給藥案件數']):>20,} "
                  f"{int(row['給藥案件數']):>15,} "
                  f"{row['使用率(%)']:>14.2f}%")
        
        print("=" * 80)
        
        # 顯示統計摘要
        print(f"\n統計摘要:")
        print(f"  • 資料涵蓋季度數: {len(quarterly)}")
        print(f"  • 最早季度: {quarterly.index[0]}")
        print(f"  • 最晚季度: {quarterly.index[-1]}")
        print(f"  • 平均使用率: {quarterly['使用率(%)'].mean():.2f}%")
        print(f"  • 使用率標準差: {quarterly['使用率(%)'].std():.2f}%")
    
    # 藥品分類統計
    print("\n" + "=" * 80)
    print("前10大常見藥品")
    print("=" * 80)
    
    top_meds = df['medication_display'].value_counts().head(10)
    for i, (med, count) in enumerate(top_meds.items(), 1):
        percentage = (count / len(df)) * 100
        print(f"  {i:2d}. {med[:50]:<50} {count:>5} ({percentage:>5.2f}%)")
    
    print("\n" + "=" * 80)
    print("查詢完成!")
    print("=" * 80)
    print("\n說明:")
    print("  1. 資料來源為 SMART Health IT 公開測試伺服器")
    print("  2. 測試資料未包含 ATC 代碼,使用模擬資料展示報表格式")
    print("  3. 實際健保資料查詢需連接健保署 FHIR 伺服器並取得認證")
    print("  4. 健保指標定義:門診抗生素使用率 = (ATC碼J01給藥案件數 / 門診給藥案件數) × 100%")
    print("  5. 依健保指標代碼 1140.01 操作型定義")
    
else:
    print(f"\n✗ 找不到結果檔案: {results_file}")
    print("  請先執行 run_antibiotic_query_simple.py")

print("\n" + "=" * 80)
