#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
醫院總額醫療品質資訊 - 指標5
同醫院門診同藥理用藥日數重疊率-降血糖(口服及注射)
查詢 SMART on FHIR 測試伺服器
指標代碼: 1712
"""

import requests
import json
from datetime import datetime, timedelta
from collections import defaultdict
import csv

# SMART on FHIR 測試伺服器
FHIR_SERVER = "https://r4.smarthealthit.org"

def get_antidiabetic_medications():
    """
    查詢降血糖藥品的 MedicationRequest
    ATC代碼: A10 (Drugs used in diabetes)
    """
    print("=" * 80)
    print("查詢降血糖藥品處方 (口服及注射)")
    print("=" * 80)
    
    # 查詢 MedicationRequest (降血糖藥品)
    url = f"{FHIR_SERVER}/MedicationRequest"
    params = {
        "status": "completed",
        "intent": "order",
        "_count": 100,
        "_include": "MedicationRequest:patient",
        "_include": "MedicationRequest:medication"
    }
    
    try:
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        bundle = response.json()
        
        medications = []
        patients = {}
        medication_details = {}
        
        if bundle.get("entry"):
            for entry in bundle["entry"]:
                resource = entry.get("resource", {})
                resource_type = resource.get("resourceType")
                
                if resource_type == "MedicationRequest":
                    med_req = resource
                    
                    # 取得藥品代碼
                    med_code = None
                    med_display = None
                    
                    # 檢查 medicationCodeableConcept
                    if "medicationCodeableConcept" in med_req:
                        codings = med_req["medicationCodeableConcept"].get("coding", [])
                        for coding in codings:
                            code = coding.get("code", "")
                            # 檢查是否為降血糖藥品 (A10開頭)
                            if code.startswith("A10"):
                                med_code = code
                                med_display = coding.get("display", "Unknown Antidiabetic Drug")
                                break
                    
                    # 如果找到降血糖藥品
                    if med_code:
                        # 取得病人ID
                        patient_ref = med_req.get("subject", {}).get("reference", "")
                        patient_id = patient_ref.replace("Patient/", "")
                        
                        # 取得處方日期
                        authored_on = med_req.get("authoredOn", "")
                        
                        # 取得給藥日數
                        dosage_instruction = med_req.get("dosageInstruction", [])
                        drug_days = 0
                        if dosage_instruction:
                            timing = dosage_instruction[0].get("timing", {})
                            repeat = timing.get("repeat", {})
                            duration = repeat.get("duration", 0)
                            duration_unit = repeat.get("durationUnit", "d")
                            if duration_unit == "d":
                                drug_days = int(duration) if duration else 30  # 預設30天
                        
                        if drug_days == 0:
                            drug_days = 30  # 預設30天
                        
                        # 計算結束日期
                        if authored_on:
                            start_date = datetime.fromisoformat(authored_on.replace("Z", "+00:00"))
                            end_date = start_date + timedelta(days=drug_days - 1)
                        else:
                            start_date = datetime.now()
                            end_date = start_date + timedelta(days=drug_days - 1)
                        
                        medications.append({
                            "id": med_req.get("id"),
                            "patient_id": patient_id,
                            "drug_code": med_code,
                            "drug_name": med_display,
                            "start_date": start_date,
                            "end_date": end_date,
                            "drug_days": drug_days,
                            "status": med_req.get("status")
                        })
                
                elif resource_type == "Patient":
                    patient_id = resource.get("id")
                    name = resource.get("name", [{}])[0]
                    given = " ".join(name.get("given", []))
                    family = name.get("family", "")
                    patients[patient_id] = f"{given} {family}".strip()
        
        print(f"\n找到 {len(medications)} 筆降血糖藥品處方")
        print(f"涉及 {len(set(m['patient_id'] for m in medications))} 位病人")
        
        return medications, patients
    
    except Exception as e:
        print(f"錯誤: {e}")
        return [], {}

def calculate_overlap(med1, med2):
    """
    計算兩個處方的重疊日數
    """
    # 重疊開始日 = max(start_date_1, start_date_2)
    overlap_start = max(med1["start_date"], med2["start_date"])
    
    # 重疊結束日 = min(end_date_1, end_date_2)
    overlap_end = min(med1["end_date"], med2["end_date"])
    
    # 重疊日數
    if overlap_start <= overlap_end:
        overlap_days = (overlap_end - overlap_start).days + 1
        return overlap_days
    else:
        return 0

def calculate_antidiabetic_overlap_rate(medications, patients):
    """
    計算降血糖藥品用藥日數重疊率
    """
    print("\n" + "=" * 80)
    print("計算降血糖藥品用藥日數重疊率")
    print("=" * 80)
    
    # 依病人分組
    patient_meds = defaultdict(list)
    for med in medications:
        patient_meds[med["patient_id"]].append(med)
    
    results = []
    total_overlap_days = 0
    total_drug_days = 0
    
    for patient_id, meds in patient_meds.items():
        if len(meds) < 2:
            # 只有一個處方，沒有重疊
            patient_total_days = sum(m["drug_days"] for m in meds)
            total_drug_days += patient_total_days
            continue
        
        # 計算該病人的重疊日數
        patient_overlap_days = 0
        patient_total_days = sum(m["drug_days"] for m in meds)
        
        # 檢查所有處方對
        for i in range(len(meds)):
            for j in range(i + 1, len(meds)):
                overlap = calculate_overlap(meds[i], meds[j])
                if overlap > 0:
                    patient_overlap_days += overlap
                    
                    print(f"\n病人 {patient_id} ({patients.get(patient_id, 'Unknown')})")
                    print(f"  處方1: {meds[i]['drug_name']} ({meds[i]['start_date'].date()} ~ {meds[i]['end_date'].date()}, {meds[i]['drug_days']}天)")
                    print(f"  處方2: {meds[j]['drug_name']} ({meds[j]['start_date'].date()} ~ {meds[j]['end_date'].date()}, {meds[j]['drug_days']}天)")
                    print(f"  重疊日數: {overlap} 天")
        
        total_overlap_days += patient_overlap_days
        total_drug_days += patient_total_days
        
        # 計算該病人的重疊率
        if patient_total_days > 0:
            patient_overlap_rate = (patient_overlap_days / patient_total_days) * 100
        else:
            patient_overlap_rate = 0
        
        results.append({
            "patient_id": patient_id,
            "patient_name": patients.get(patient_id, "Unknown"),
            "total_prescriptions": len(meds),
            "total_drug_days": patient_total_days,
            "overlap_days": patient_overlap_days,
            "overlap_rate": round(patient_overlap_rate, 2)
        })
    
    # 計算整體重疊率
    if total_drug_days > 0:
        overall_overlap_rate = (total_overlap_days / total_drug_days) * 100
    else:
        overall_overlap_rate = 0
    
    return results, total_overlap_days, total_drug_days, overall_overlap_rate

def display_results(results, total_overlap_days, total_drug_days, overall_overlap_rate):
    """
    顯示查詢結果
    """
    print("\n" + "=" * 80)
    print("查詢結果摘要")
    print("=" * 80)
    
    print(f"\n【整體統計】")
    print(f"降血糖(口服及注射)重疊用藥日數: {total_overlap_days:,} 天")
    print(f"降血糖(口服及注射)之給藥日數: {total_drug_days:,} 天")
    print(f"降血糖(口服及注射)不同處方用藥日數重疊率: {overall_overlap_rate:.2f}%")
    
    if results:
        print(f"\n【各病人統計】")
        print(f"{'病人ID':<20} {'病人姓名':<20} {'處方數':<10} {'總給藥日數':<12} {'重疊日數':<12} {'重疊率(%)':<12}")
        print("-" * 100)
        
        for result in results:
            print(f"{result['patient_id']:<20} {result['patient_name']:<20} "
                  f"{result['total_prescriptions']:<10} {result['total_drug_days']:<12} "
                  f"{result['overlap_days']:<12} {result['overlap_rate']:<12.2f}")
    
    # 儲存結果到CSV
    save_results_to_csv(results, total_overlap_days, total_drug_days, overall_overlap_rate)

def save_results_to_csv(results, total_overlap_days, total_drug_days, overall_overlap_rate):
    """
    儲存結果到CSV檔案
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"results/antidiabetic_medications_SMART_Health_IT_{timestamp}.csv"
    
    try:
        with open(filename, 'w', newline='', encoding='utf-8-sig') as f:
            writer = csv.writer(f)
            
            # 寫入標題
            writer.writerow(['醫院總額醫療品質資訊 - 指標5: 同醫院門診同藥理用藥日數重疊率-降血糖(口服及注射)'])
            writer.writerow(['資料來源: SMART Health IT FHIR R4 測試伺服器'])
            writer.writerow(['查詢時間: ' + datetime.now().strftime("%Y-%m-%d %H:%M:%S")])
            writer.writerow([])
            
            # 整體統計
            writer.writerow(['整體統計'])
            writer.writerow(['降血糖(口服及注射)重疊用藥日數', total_overlap_days])
            writer.writerow(['降血糖(口服及注射)之給藥日數', total_drug_days])
            writer.writerow(['降血糖(口服及注射)不同處方用藥日數重疊率(%)', f"{overall_overlap_rate:.2f}%"])
            writer.writerow([])
            
            # 各病人統計
            writer.writerow(['各病人統計'])
            writer.writerow(['病人ID', '病人姓名', '處方數', '總給藥日數', '重疊日數', '重疊率(%)'])
            
            for result in results:
                writer.writerow([
                    result['patient_id'],
                    result['patient_name'],
                    result['total_prescriptions'],
                    result['total_drug_days'],
                    result['overlap_days'],
                    f"{result['overlap_rate']:.2f}%"
                ])
        
        print(f"\n結果已儲存至: {filename}")
    
    except Exception as e:
        print(f"儲存CSV時發生錯誤: {e}")

def main():
    """
    主程式
    """
    print("=" * 80)
    print("醫院總額醫療品質資訊 - 指標5")
    print("同醫院門診同藥理用藥日數重疊率-降血糖(口服及注射)")
    print("指標代碼: 1712")
    print("資料來源: SMART Health IT FHIR R4 測試伺服器")
    print("查詢時間:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    print("=" * 80)
    
    # 1. 查詢降血糖藥品
    medications, patients = get_antidiabetic_medications()
    
    if not medications:
        print("\n未找到降血糖藥品處方資料")
        return
    
    # 2. 計算重疊率
    results, total_overlap_days, total_drug_days, overall_overlap_rate = calculate_antidiabetic_overlap_rate(medications, patients)
    
    # 3. 顯示結果
    display_results(results, total_overlap_days, total_drug_days, overall_overlap_rate)
    
    print("\n" + "=" * 80)
    print("查詢完成")
    print("=" * 80)

if __name__ == "__main__":
    main()
