"""
簡化測試腳本 - 驗證環境設定
"""

import sys
import importlib

def check_python_version():
    """檢查Python版本"""
    version = sys.version_info
    print(f"✓ Python版本: {version.major}.{version.minor}.{version.micro}")
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("⚠ 警告: 建議使用Python 3.8或以上版本")
        return False
    return True

def check_dependencies():
    """檢查必要套件"""
    required_packages = [
        'requests',
        'yaml',
        'tabulate',
        'colorama'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            if package == 'yaml':
                importlib.import_module('yaml')
            else:
                importlib.import_module(package)
            print(f"✓ {package} 已安裝")
        except ImportError:
            print(f"✗ {package} 未安裝")
            missing_packages.append(package)
    
    return missing_packages

def check_cql_files():
    """檢查CQL檔案"""
    from pathlib import Path
    
    cql_files = [
        'Antibiotic_Utilization.cql',
        'EHR_Adoption_Rate.cql',
        'Waste.cql'
    ]
    
    all_exist = True
    for cql_file in cql_files:
        if Path(cql_file).exists():
            print(f"✓ {cql_file} 存在")
        else:
            print(f"✗ {cql_file} 不存在")
            all_exist = False
    
    return all_exist

def main():
    print("="*60)
    print("ESG CQL 測試系統 - 環境檢查")
    print("="*60)
    print()
    
    # 檢查Python版本
    print("[1] 檢查Python版本")
    check_python_version()
    print()
    
    # 檢查套件
    print("[2] 檢查必要套件")
    missing = check_dependencies()
    print()
    
    # 檢查CQL檔案
    print("[3] 檢查CQL檔案")
    cql_ok = check_cql_files()
    print()
    
    # 總結
    print("="*60)
    if not missing and cql_ok:
        print("✓ 環境檢查完成！所有項目正常")
        print()
        print("請執行以下命令啟動測試:")
        print("  python main.py")
    else:
        print("⚠ 環境檢查發現問題:")
        if missing:
            print(f"  缺少套件: {', '.join(missing)}")
            print(f"  請執行: pip install {' '.join(missing)}")
        if not cql_ok:
            print("  缺少CQL檔案")
    print("="*60)

if __name__ == "__main__":
    main()
