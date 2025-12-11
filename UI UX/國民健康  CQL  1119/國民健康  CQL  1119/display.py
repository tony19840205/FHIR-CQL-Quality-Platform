"""
Display Module
資料呈現模組，將統計資料以美觀的格式輸出到終端機
"""

from typing import Dict, Any
import json


class ReportDisplay:
    """報告顯示器"""
    
    def __init__(self):
        self.width = 80
    
    def print_header(self, title: str):
        """列印標題"""
        print("\n" + "=" * self.width)
        print(f"{title:^{self.width}}")
        print("=" * self.width)
    
    def print_section(self, title: str):
        """列印區段標題"""
        print(f"\n{title}")
        print("-" * self.width)
    
    def print_subsection(self, title: str):
        """列印子區段標題"""
        print(f"\n  【{title}】")
    
    def print_key_value(self, key: str, value: Any, indent: int = 2):
        """列印鍵值對"""
        spaces = " " * indent
        print(f"{spaces}{key}: {value}")
    
    def print_dict(self, data: Dict, indent: int = 4):
        """列印字典資料"""
        spaces = " " * indent
        for key, value in data.items():
            print(f"{spaces}{key}: {value}")
    
    def display_demographics(self, demographics: Dict):
        """顯示人口統計資料"""
        self.print_section("📊 病人人口統計")
        
        self.print_key_value("總病人數", demographics['total_count'])
        
        self.print_subsection("性別分布")
        gender_dist = demographics['gender_distribution']
        for gender, count in gender_dist.items():
            percentage = (count / demographics['total_count'] * 100) if demographics['total_count'] > 0 else 0
            self.print_key_value(f"  {gender}", f"{count} 人 ({percentage:.1f}%)", indent=4)
        
        self.print_subsection("年齡分布")
        age_dist = demographics['age_distribution']
        # 排序年齡組
        age_order = ['0-17歲', '18-39歲', '40-64歲', '65歲以上', '未知']
        for age_group in age_order:
            if age_group in age_dist:
                count = age_dist[age_group]
                percentage = (count / demographics['total_count'] * 100) if demographics['total_count'] > 0 else 0
                self.print_key_value(f"  {age_group}", f"{count} 人 ({percentage:.1f}%)", indent=4)
        
        self.print_subsection("地區分布（前10名）")
        location_dist = demographics['location_distribution']
        for location, count in list(location_dist.items())[:10]:
            percentage = (count / demographics['total_count'] * 100) if demographics['total_count'] > 0 else 0
            self.print_key_value(f"  {location}", f"{count} 人 ({percentage:.1f}%)", indent=4)
    
    def display_covid19_vaccination(self, covid_data: Dict, total_patients: int):
        """顯示 COVID-19 疫苗接種統計"""
        self.print_section("💉 COVID-19 疫苗接種統計")
        
        self.print_key_value("總接種劑數", covid_data['total_doses'])
        self.print_key_value("已接種人數", covid_data['vaccinated_patients'])
        
        if total_patients > 0:
            coverage = (covid_data['vaccinated_patients'] / total_patients * 100)
            self.print_key_value("接種涵蓋率", f"{coverage:.2f}%")
        
        self.print_subsection("劑數分布")
        dose_dist = covid_data['dose_distribution']
        for dose_type, count in dose_dist.items():
            self.print_key_value(f"  {dose_type}", f"{count} 人", indent=4)
        
        self.print_subsection("疫苗類型")
        vaccine_types = covid_data['vaccine_types']
        for vaccine, count in list(vaccine_types.items())[:10]:
            self.print_key_value(f"  {vaccine}", f"{count} 劑", indent=4)
        
        self.print_subsection("年齡分組統計")
        age_order = ['0-17歲', '18-39歲', '40-64歲', '65歲以上']
        for age_group in age_order:
            if age_group in covid_data['by_age_group']:
                count = covid_data['by_age_group'][age_group]
                self.print_key_value(f"  {age_group}", f"{count} 劑", indent=4)
        
        self.print_subsection("性別統計")
        for gender, count in covid_data['by_gender'].items():
            self.print_key_value(f"  {gender}", f"{count} 劑", indent=4)
        
        self.print_subsection("地區統計（前10名）")
        for location, count in list(covid_data['by_location'].items())[:10]:
            self.print_key_value(f"  {location}", f"{count} 劑", indent=4)
    
    def display_influenza_vaccination(self, flu_data: Dict, total_patients: int):
        """顯示流感疫苗接種統計"""
        self.print_section("💉 流感疫苗接種統計")
        
        self.print_key_value("總接種劑數", flu_data['total_doses'])
        self.print_key_value("已接種人數", flu_data['vaccinated_patients'])
        
        if total_patients > 0:
            coverage = (flu_data['vaccinated_patients'] / total_patients * 100)
            self.print_key_value("接種涵蓋率", f"{coverage:.2f}%")
        
        self.print_subsection("疫苗類型")
        vaccine_types = flu_data['vaccine_types']
        for vaccine, count in list(vaccine_types.items())[:10]:
            self.print_key_value(f"  {vaccine}", f"{count} 劑", indent=4)
        
        self.print_subsection("年齡分組統計")
        age_order = ['0-17歲', '18-39歲', '40-64歲', '65歲以上']
        for age_group in age_order:
            if age_group in flu_data['by_age_group']:
                count = flu_data['by_age_group'][age_group]
                self.print_key_value(f"  {age_group}", f"{count} 劑", indent=4)
        
        self.print_subsection("性別統計")
        for gender, count in flu_data['by_gender'].items():
            self.print_key_value(f"  {gender}", f"{count} 劑", indent=4)
        
        self.print_subsection("地區統計（前10名）")
        for location, count in list(flu_data['by_location'].items())[:10]:
            self.print_key_value(f"  {location}", f"{count} 劑", indent=4)
    
    def display_hypertension(self, htn_data: Dict, total_patients: int):
        """顯示高血壓診斷統計"""
        self.print_section("🩺 高血壓診斷統計")
        
        self.print_key_value("高血壓病人數", htn_data['total_patients'])
        self.print_key_value("診斷紀錄總數", htn_data['total_conditions'])
        
        if total_patients > 0:
            prevalence = (htn_data['total_patients'] / total_patients * 100)
            self.print_key_value("盛行率", f"{prevalence:.2f}%")
        
        self.print_subsection("年齡分組統計")
        age_order = ['0-17歲', '18-39歲', '40-64歲', '65歲以上']
        for age_group in age_order:
            if age_group in htn_data['by_age_group']:
                count = htn_data['by_age_group'][age_group]
                self.print_key_value(f"  {age_group}", f"{count} 人", indent=4)
        
        self.print_subsection("性別統計")
        for gender, count in htn_data['by_gender'].items():
            self.print_key_value(f"  {gender}", f"{count} 人", indent=4)
        
        self.print_subsection("地區統計（前10名）")
        for location, count in list(htn_data['by_location'].items())[:10]:
            self.print_key_value(f"  {location}", f"{count} 人", indent=4)
    
    def display_full_report(self, report: Dict):
        """顯示完整報告"""
        self.print_header("國民健康 CQL 測量指標報告")
        
        print(f"\n報告產生時間: {report['report_time']}")
        print(f"資料時間範圍: 過去 {report['time_period_years']} 年")
        
        # 人口統計
        self.display_demographics(report['patient_demographics'])
        
        # COVID-19 疫苗
        self.display_covid19_vaccination(
            report['covid19_vaccination'],
            report['patient_demographics']['total_count']
        )
        
        # 流感疫苗
        self.display_influenza_vaccination(
            report['influenza_vaccination'],
            report['patient_demographics']['total_count']
        )
        
        # 高血壓
        self.display_hypertension(
            report['hypertension'],
            report['patient_demographics']['total_count']
        )
        
        print("\n" + "=" * self.width)
        print("報告結束")
        print("=" * self.width + "\n")
    
    def save_report_to_json(self, report: Dict, filename: str = "report.json"):
        """儲存報告為 JSON 檔案"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        print(f"\n✓ 報告已儲存到: {filename}")
    
    def save_report_to_html(self, report: Dict, filename: str = "report.html"):
        """儲存報告為 HTML 檔案"""
        html_content = self._generate_html_report(report)
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"✓ HTML 報告已儲存到: {filename}")
    
    def _generate_html_report(self, report: Dict) -> str:
        """生成 HTML 報告"""
        html = f"""<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>國民健康 CQL 測量指標報告</title>
    <style>
        body {{
            font-family: "Microsoft JhengHei", Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }}
        h1 {{
            color: #2c3e50;
            text-align: center;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }}
        h2 {{
            color: #34495e;
            margin-top: 30px;
            border-left: 5px solid #3498db;
            padding-left: 10px;
        }}
        h3 {{
            color: #7f8c8d;
            margin-top: 20px;
        }}
        .info {{
            background-color: #fff;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }}
        .stat {{
            background-color: #fff;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }}
        .key {{
            font-weight: bold;
            color: #2c3e50;
        }}
        .value {{
            color: #16a085;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            background-color: #fff;
            margin: 10px 0;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }}
        th, td {{
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background-color: #3498db;
            color: white;
        }}
        tr:hover {{
            background-color: #f5f5f5;
        }}
    </style>
</head>
<body>
    <h1>🏥 國民健康 CQL 測量指標報告</h1>
    
    <div class="info">
        <p><span class="key">報告產生時間:</span> <span class="value">{report['report_time']}</span></p>
        <p><span class="key">資料時間範圍:</span> <span class="value">過去 {report['time_period_years']} 年</span></p>
    </div>

    <h2>📊 病人人口統計</h2>
    <div class="stat">
        <p><span class="key">總病人數:</span> <span class="value">{report['patient_demographics']['total_count']}</span></p>
    </div>

    <h3>性別分布</h3>
    <table>
        <tr><th>性別</th><th>人數</th><th>百分比</th></tr>
"""
        
        total_patients = report['patient_demographics']['total_count']
        for gender, count in report['patient_demographics']['gender_distribution'].items():
            percentage = (count / total_patients * 100) if total_patients > 0 else 0
            html += f"        <tr><td>{gender}</td><td>{count}</td><td>{percentage:.1f}%</td></tr>\n"
        
        html += """    </table>

    <h3>年齡分布</h3>
    <table>
        <tr><th>年齡組</th><th>人數</th><th>百分比</th></tr>
"""
        
        age_order = ['0-17歲', '18-39歲', '40-64歲', '65歲以上', '未知']
        for age_group in age_order:
            if age_group in report['patient_demographics']['age_distribution']:
                count = report['patient_demographics']['age_distribution'][age_group]
                percentage = (count / total_patients * 100) if total_patients > 0 else 0
                html += f"        <tr><td>{age_group}</td><td>{count}</td><td>{percentage:.1f}%</td></tr>\n"
        
        html += """    </table>

    <h2>💉 COVID-19 疫苗接種統計</h2>
    <div class="stat">
"""
        covid_data = report['covid19_vaccination']
        coverage = (covid_data['vaccinated_patients'] / total_patients * 100) if total_patients > 0 else 0
        
        html += f"""        <p><span class="key">總接種劑數:</span> <span class="value">{covid_data['total_doses']}</span></p>
        <p><span class="key">已接種人數:</span> <span class="value">{covid_data['vaccinated_patients']}</span></p>
        <p><span class="key">接種涵蓋率:</span> <span class="value">{coverage:.2f}%</span></p>
    </div>

    <h2>💉 流感疫苗接種統計</h2>
    <div class="stat">
"""
        
        flu_data = report['influenza_vaccination']
        flu_coverage = (flu_data['vaccinated_patients'] / total_patients * 100) if total_patients > 0 else 0
        
        html += f"""        <p><span class="key">總接種劑數:</span> <span class="value">{flu_data['total_doses']}</span></p>
        <p><span class="key">已接種人數:</span> <span class="value">{flu_data['vaccinated_patients']}</span></p>
        <p><span class="key">接種涵蓋率:</span> <span class="value">{flu_coverage:.2f}%</span></p>
    </div>

    <h2>🩺 高血壓診斷統計</h2>
    <div class="stat">
"""
        
        htn_data = report['hypertension']
        htn_prevalence = (htn_data['total_patients'] / total_patients * 100) if total_patients > 0 else 0
        
        html += f"""        <p><span class="key">高血壓病人數:</span> <span class="value">{htn_data['total_patients']}</span></p>
        <p><span class="key">診斷紀錄總數:</span> <span class="value">{htn_data['total_conditions']}</span></p>
        <p><span class="key">盛行率:</span> <span class="value">{htn_prevalence:.2f}%</span></p>
    </div>

</body>
</html>
"""
        
        return html
