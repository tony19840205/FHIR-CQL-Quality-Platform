#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
測試資料分析工具
分析所有測試資料檔案並產生整理報告
"""
import json
import os
from datetime import datetime

def analyze_test_files():
    """分析所有測試資料檔案"""
    
    # 測試資料檔案列表
    test_files = [
        'test_data_3day_ed_6_patients.json',
        'test_data_antihypertensive_overlap_3_patients.json',
        'test_data_cesarean_3_simple.json',
        'test_data_cesarean_6_patients.json',
        'test_data_diabetes_2_patients.json',
        'test_data_eswl_3_patients.json',
        'test_single_cesarean.json'
    ]
    
    # 對應的上傳腳本
    upload_scripts = {
        '3day_ed': 'upload_3day_ed.py',
        'antihypertensive': 'upload_antihypertensive_overlap.py',
        'cesarean': 'upload_cesarean.py',
        'cesarean_simple': 'upload_cesarean_simple.py',
        'diabetes': 'upload_diabetes.py',
        'eswl': 'upload_eswl.py',
        'single': 'upload_single.py'
    }
    
    print("=" * 80)
    print("測試資料完整分析報告")
    print(f"生成時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    print()
    
    total_patients = 0
    total_files = 0
    all_data = []
    
    for filename in test_files:
        if not os.path.exists(filename):
            print(f"⚠️  檔案不存在: {filename}")
            continue
            
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # 統計資源
            patients = []
            encounters = []
            procedures = []
            conditions = []
            medications = []
            observations = []
            
            for entry in data.get('entry', []):
                resource = entry.get('resource', {})
                resource_type = resource.get('resourceType')
                resource_id = resource.get('id', 'N/A')
                
                if resource_type == 'Patient':
                    name = resource.get('name', [{}])[0]
                    family = name.get('family', '')
                    given = ' '.join(name.get('given', []))
                    patients.append({
                        'id': resource_id,
                        'name': f"{family}{given}",
                        'gender': resource.get('gender', 'N/A'),
                        'birthDate': resource.get('birthDate', 'N/A')
                    })
                elif resource_type == 'Encounter':
                    encounters.append(resource_id)
                elif resource_type == 'Procedure':
                    procedures.append(resource_id)
                elif resource_type == 'Condition':
                    conditions.append(resource_id)
                elif resource_type == 'MedicationRequest':
                    medications.append(resource_id)
                elif resource_type == 'Observation':
                    observations.append(resource_id)
            
            file_size = os.path.getsize(filename) / 1024
            
            print(f"📄 {filename}")
            print(f"   ├─ 檔案大小: {file_size:.2f} KB")
            print(f"   ├─ 病患數: {len(patients)} 人")
            print(f"   ├─ 就診: {len(encounters)} 筆")
            print(f"   ├─ 手術: {len(procedures)} 筆")
            print(f"   ├─ 診斷: {len(conditions)} 筆")
            print(f"   ├─ 用藥: {len(medications)} 筆")
            print(f"   └─ 檢驗: {len(observations)} 筆")
            
            if patients:
                print(f"\n   病患清單:")
                for p in patients:
                    print(f"      • {p['id']}: {p['name']} ({p['gender']}, {p['birthDate']})")
            
            print()
            
            total_patients += len(patients)
            total_files += 1
            
            all_data.append({
                'filename': filename,
                'patients': patients,
                'encounters': len(encounters),
                'procedures': len(procedures),
                'conditions': len(conditions),
                'medications': len(medications),
                'observations': len(observations)
            })
            
        except Exception as e:
            print(f"❌ 讀取失敗: {filename}")
            print(f"   錯誤: {str(e)}")
            print()
    
    print("=" * 80)
    print(f"總結")
    print("=" * 80)
    print(f"✅ 分析檔案: {total_files} 個")
    print(f"👥 總病患數: {total_patients} 人")
    print()
    
    print("=" * 80)
    print(f"上傳腳本對應表")
    print("=" * 80)
    for key, script in upload_scripts.items():
        if os.path.exists(script):
            print(f"✅ {script}")
        else:
            print(f"⚠️  {script} (檔案不存在)")
    print()
    
    # 產生 Markdown 報告
    with open('測試資料清單.md', 'w', encoding='utf-8') as f:
        f.write(f"# 測試資料完整清單\n\n")
        f.write(f"**生成時間**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"## 📊 統計摘要\n\n")
        f.write(f"- 測試資料檔案: **{total_files}** 個\n")
        f.write(f"- 總病患數: **{total_patients}** 人\n\n")
        
        f.write(f"## 📁 詳細資料\n\n")
        for item in all_data:
            f.write(f"### {item['filename']}\n\n")
            f.write(f"**統計**:\n")
            f.write(f"- 病患: {len(item['patients'])} 人\n")
            f.write(f"- 就診: {item['encounters']} 筆\n")
            f.write(f"- 手術: {item['procedures']} 筆\n")
            f.write(f"- 診斷: {item['conditions']} 筆\n")
            f.write(f"- 用藥: {item['medications']} 筆\n")
            f.write(f"- 檢驗: {item['observations']} 筆\n\n")
            
            if item['patients']:
                f.write(f"**病患清單**:\n\n")
                f.write(f"| ID | 姓名 | 性別 | 生日 |\n")
                f.write(f"|---|---|---|---|\n")
                for p in item['patients']:
                    f.write(f"| {p['id']} | {p['name']} | {p['gender']} | {p['birthDate']} |\n")
                f.write(f"\n")
        
        f.write(f"## 🔧 上傳腳本\n\n")
        for key, script in upload_scripts.items():
            status = "✅" if os.path.exists(script) else "⚠️"
            f.write(f"- {status} `{script}`\n")
    
    print("✅ 已產生報告: 測試資料清單.md")

if __name__ == '__main__':
    analyze_test_files()
