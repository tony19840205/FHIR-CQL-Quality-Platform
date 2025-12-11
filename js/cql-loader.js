// CQL 文件加载器和执行器
// 负责加载39个CQL文件并执行查询

class CQLLoader {
    constructor() {
        this.cqlFiles = [
            { id: 'indicator-01', file: 'Indicator_01_Outpatient_Injection_Usage_Rate_3127.cql', name: '門診注射劑使用率', code: '3127' },
            { id: 'indicator-02', file: 'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql', name: '門診抗生素使用率', code: '1140.01' },
            { id: 'indicator-03-1', file: 'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql', name: '同院降血壓藥重複用藥率', code: '1710' },
            { id: 'indicator-03-2', file: 'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql', name: '同院降血脂藥重複用藥率', code: '1711' },
            { id: 'indicator-03-3', file: 'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql', name: '同院降血糖藥重複用藥率', code: '1712' },
            { id: 'indicator-03-4', file: 'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql', name: '同院抗精神病藥重複用藥率', code: '1726' },
            { id: 'indicator-03-5', file: 'Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727.cql', name: '同院抗憂鬱藥重複用藥率', code: '1727' },
            { id: 'indicator-03-6', file: 'Indicator_03_6_Same_Hospital_Sedative_Overlap_1728.cql', name: '同院鎮靜安眠藥重複用藥率', code: '1728' },
            { id: 'indicator-03-7', file: 'Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375.cql', name: '同院抗血栓藥重複用藥率', code: '3375' },
            { id: 'indicator-03-8', file: 'Indicator_03_8_Same_Hospital_Prostate_Overlap_3376.cql', name: '同院攝護腺肥大用藥重複用藥率', code: '3376' },
            { id: 'indicator-03-9', file: 'Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713.cql', name: '跨院降血壓藥重複用藥率', code: '1713' },
            { id: 'indicator-03-10', file: 'Indicator_03_10_Cross_Hospital_Lipid_Lowering_Overlap_1714.cql', name: '跨院降血脂藥重複用藥率', code: '1714' },
            { id: 'indicator-03-11', file: 'Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.cql', name: '跨院降血糖藥重複用藥率', code: '1715' },
            { id: 'indicator-03-12', file: 'Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.cql', name: '跨院抗精神病藥重複用藥率', code: '1729' },
            { id: 'indicator-03-13', file: 'Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730.cql', name: '跨院抗憂鬱藥重複用藥率', code: '1730' },
            { id: 'indicator-03-14', file: 'Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731.cql', name: '跨院鎮靜安眠藥重複用藥率', code: '1731' },
            { id: 'indicator-03-15', file: 'Indicator_03_15_Cross_Hospital_Antithrombotic_Overlap_3377.cql', name: '跨院抗血栓藥重複用藥率', code: '3377' },
            { id: 'indicator-03-16', file: 'Indicator_03_16_Cross_Hospital_Prostate_Overlap_3378.cql', name: '跨院攝護腺肥大用藥重複用藥率', code: '3378' },
            { id: 'indicator-04', file: 'Indicator_04_Chronic_Continuous_Prescription_Rate_1318.cql', name: '慢性病連續處方箋使用率', code: '1318' },
            { id: 'indicator-05', file: 'Indicator_05_Prescription_10_Plus_Drugs_Rate_3128.cql', name: '處方10種(含)以上品項用藥人次率', code: '3128' },
            { id: 'indicator-06', file: 'Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y.cql', name: '小兒氣喘急診利用率', code: '1315Q/1317Y' },
            { id: 'indicator-07', file: 'Indicator_07_Diabetes_HbA1c_Testing_Rate_109_01Q_110_01Y.cql', name: '糖尿病人HbA1c檢驗率', code: '109.01Q/110.01Y' },
            { id: 'indicator-08', file: 'Indicator_08_Same_Day_Same_Disease_Revisit_Rate_1322.cql', name: '當日同病因複診率', code: '1322' },
            { id: 'indicator-09', file: 'Indicator_09_14_Day_Non_Scheduled_Readmission_Rate_1077_01Q_1809Y.cql', name: '14天內非計劃再入院率', code: '1077.01Q/1809Y' },
            { id: 'indicator-10', file: 'Indicator_10_Post_Discharge_3_Day_Emergency_Rate_108_01.cql', name: '出院後3天內急診率', code: '108.01' },
            { id: 'indicator-11-1', file: 'Indicator_11_1_Cesarean_Section_Rate_1136_01.cql', name: '整體剖腹產率', code: '1136.01' },
            { id: 'indicator-11-2', file: 'Indicator_11_2_First_Time_Cesarean_Section_Rate_1137_01.cql', name: '產婦初次剖腹產率', code: '1137.01' },
            { id: 'indicator-11-3', file: 'Indicator_11_3_Vaginal_Birth_After_Cesarean_Rate_1138_01.cql', name: '有過剖腹產史陰道生產率', code: '1138.01' },
            { id: 'indicator-11-4', file: 'Indicator_11_4_Initial_Cesarean_Section_Rate_1075_01.cql', name: '初次剖腹產率', code: '1075.01' },
            { id: 'indicator-12-1', file: 'Indicator_12_1_Normal_Delivery_Episiotomy_Rate_1135_01.cql', name: '自然生產會陰切開率', code: '1135.01' },
            { id: 'indicator-12-2', file: 'Indicator_12_2_Induced_Labor_Rate_112_01.cql', name: '引產率', code: '112.01' },
            { id: 'indicator-13', file: 'Indicator_13_Low_Birth_Weight_Ventilator_Use_Over_29_Days_Rate_113_01.cql', name: '低出生體重早產兒使用呼吸器29天以上比率', code: '113.01' },
            { id: 'indicator-14', file: 'Indicator_14_Appendectomy_Perforation_Rate_1640Q_1648Y.cql', name: '闌尾切除併穿孔比率', code: '1640Q/1648Y' },
            { id: 'indicator-15', file: 'Indicator_15_Laparoscopic_Cholecystectomy_Conversion_Rate_114_01.cql', name: '腹腔鏡膽囊切除術中轉傳統手術比率', code: '114.01' },
            { id: 'indicator-16', file: 'Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y.cql', name: '住院病人手術傷口感染率', code: '1658Q/1666Y' },
            { id: 'indicator-17', file: 'Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y.cql', name: '急性心肌梗塞住院死亡率', code: '1662Q/1668Y' },
            { id: 'indicator-18', file: 'Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y.cql', name: '失智症住院病人安寧緩和醫療利用率', code: '2795Q/2796Y' },
            { id: 'indicator-19', file: 'Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y.cql', name: '清潔手術傷口感染率', code: '2524Q/2526Y' }
        ];
        
        this.basePath = '../醫院總額醫療品質資訊1119/醫院總額醫療品質資訊(1119)/';
        this.cqlCache = {};
    }

    // 加载单个CQL文件
    async loadCQLFile(filename) {
        if (this.cqlCache[filename]) {
            return this.cqlCache[filename];
        }

        try {
            const response = await fetch(this.basePath + filename);
            if (!response.ok) {
                throw new Error(`无法加载 ${filename}: ${response.statusText}`);
            }
            const cqlText = await response.text();
            this.cqlCache[filename] = this.parseCQL(cqlText);
            return this.cqlCache[filename];
        } catch (error) {
            console.error(`加载CQL文件失败: ${filename}`, error);
            return null;
        }
    }

    // 解析CQL文件，提取关键信息
    parseCQL(cqlText) {
        const parsed = {
            library: null,
            numeratorLogic: null,
            denominatorLogic: null,
            exclusionLogic: null,
            description: null
        };

        // 提取library名称
        const libraryMatch = cqlText.match(/library\s+(\S+)\s+version/);
        if (libraryMatch) {
            parsed.library = libraryMatch[1];
        }

        // 提取分子定义
        const numeratorMatch = cqlText.match(/define\s+"?(Numerator|分子)"?[^:]*:([^d]*?)(?=define|$)/s);
        if (numeratorMatch) {
            parsed.numeratorLogic = numeratorMatch[2].trim();
        }

        // 提取分母定义
        const denominatorMatch = cqlText.match(/define\s+"?(Denominator|分母)"?[^:]*:([^d]*?)(?=define|$)/s);
        if (denominatorMatch) {
            parsed.denominatorLogic = denominatorMatch[2].trim();
        }

        // 提取排除条件
        const exclusionMatch = cqlText.match(/define\s+"?(Exclusion|排除)"?[^:]*:([^d]*?)(?=define|$)/s);
        if (exclusionMatch) {
            parsed.exclusionLogic = exclusionMatch[2].trim();
        }

        // 提取描述信息
        const descMatch = cqlText.match(/\/\/\s*【公式說明】([^\/]*)/s);
        if (descMatch) {
            parsed.description = descMatch[1].trim();
        }

        return parsed;
    }

    // 获取所有CQL文件的元数据
    getAllIndicators() {
        return this.cqlFiles;
    }

    // 根据指标ID获取CQL信息
    async getCQLForIndicator(indicatorId) {
        const indicator = this.cqlFiles.find(i => i.id === indicatorId);
        if (!indicator) {
            console.error(`未找到指标: ${indicatorId}`);
            return null;
        }

        return await this.loadCQLFile(indicator.file);
    }
}

// 导出全局实例
window.cqlLoader = new CQLLoader();
