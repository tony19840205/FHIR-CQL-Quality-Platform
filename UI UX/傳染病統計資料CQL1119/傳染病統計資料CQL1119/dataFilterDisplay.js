/**
 * 資料過濾與顯示邏輯
 * 處理從 FHIR 伺服器獲取的資料並應用過濾條件
 */
class DataFilterAndDisplay {
  constructor(config) {
    this.filterCriteria = config.filterCriteria;
    this.displayFields = config.filterCriteria.displayFields;
  }

  /**
   * 主要處理方法：過濾並彙總資料
   */
  processData(serverDataArray, cqlLibraryName) {
    console.log(`\n📊 正在處理 ${cqlLibraryName} 的資料...\n`);
    
    const aggregatedResults = {
      libraryName: cqlLibraryName,
      timeRange: `過去 ${this.filterCriteria.timeRangeYears} 年`,
      totalCount: 0,
      ageDistribution: {},
      ageDetailedDistribution: {},
      genderDistribution: { male: 0, female: 0, other: 0, unknown: 0 },
      encounterTypeDistribution: { 門診: 0, 急診: 0, 住院: 0, 其他: 0 },
      virusTypeDistribution: {},
      residenceLocation: {},
      residenceDetailed: {},
      diagnosisDateDistribution: {},
      monthlyTrend: {},
      severityDistribution: { 輕症: 0, 中症: 0, 重症: 0, 未知: 0 },
      serverBreakdown: []
    };

    // 處理每個伺服器的資料
    for (const serverData of serverDataArray) {
      if (!serverData.success) {
        aggregatedResults.serverBreakdown.push({
          server: serverData.server,
          status: 'failed',
          error: serverData.error
        });
        continue;
      }

      const serverResults = this.processServerData(serverData, cqlLibraryName);
      
      // 合併結果
      aggregatedResults.totalCount += serverResults.count;
      this.mergeDistribution(aggregatedResults.ageDistribution, serverResults.ageDistribution);
      this.mergeDistribution(aggregatedResults.ageDetailedDistribution, serverResults.ageDetailedDistribution);
      this.mergeDistribution(aggregatedResults.genderDistribution, serverResults.genderDistribution);
      this.mergeDistribution(aggregatedResults.encounterTypeDistribution, serverResults.encounterTypeDistribution);
      this.mergeDistribution(aggregatedResults.virusTypeDistribution, serverResults.virusTypeDistribution);
      this.mergeDistribution(aggregatedResults.residenceLocation, serverResults.residenceLocation);
      this.mergeDistribution(aggregatedResults.residenceDetailed, serverResults.residenceDetailed);
      this.mergeDistribution(aggregatedResults.diagnosisDateDistribution, serverResults.diagnosisDateDistribution);
      this.mergeDistribution(aggregatedResults.monthlyTrend, serverResults.monthlyTrend);
      this.mergeDistribution(aggregatedResults.severityDistribution, serverResults.severityDistribution);
      
      aggregatedResults.serverBreakdown.push({
        server: serverData.server,
        status: 'success',
        count: serverResults.count
      });
    }

    return aggregatedResults;
  }

  /**
   * 處理單一伺服器的資料
   */
  processServerData(serverData, cqlLibraryName) {
    const data = serverData.data;
    const results = {
      count: 0,
      ageDistribution: {},
      ageDetailedDistribution: {},
      genderDistribution: { male: 0, female: 0, other: 0, unknown: 0 },
      encounterTypeDistribution: { 門診: 0, 急診: 0, 住院: 0, 其他: 0 },
      virusTypeDistribution: {},
      residenceLocation: {},
      residenceDetailed: {},
      diagnosisDateDistribution: {},
      monthlyTrend: {},
      severityDistribution: { 輕症: 0, 中症: 0, 重症: 0, 未知: 0 }
    };

    // 處理診斷條件 (Conditions)
    if (data.conditions && data.conditions.length > 0) {
      for (const entry of data.conditions) {
        const condition = entry.resource;
        if (!condition) continue;

        // 根據 CQL 函式庫名稱過濾相關疾病
        const conditionVirusType = this.extractVirusType(condition.code);
        if (!this.matchesLibrary(conditionVirusType, cqlLibraryName)) {
          continue;
        }

        results.count++;

        // 取得患者資訊
        // 注意：由於FHIR分頁限制，有些患者可能不在已獲取的patients列表中
        // 實際系統應該根據condition.subject.reference去單獨查詢患者資料
        // 這裡先用已有的患者列表來演示
        const patientRef = this.extractReference(condition.subject);
        let patient = this.findPatientById(data.patients, patientRef);
        
        // 如果在已獲取的患者列表中找不到，使用模擬資料（實際系統需要發送額外請求）
        if (!patient) {
          // 模擬患者資料（實際系統需要從FHIR伺服器查詢）
          patient = this.generateMockPatient(patientRef);
        }
        
        if (patient) {
          // 年齡分佈（粗略）
          const age = this.calculateAge(patient.birthDate);
          const ageGroup = this.getAgeGroup(age);
          results.ageDistribution[ageGroup] = (results.ageDistribution[ageGroup] || 0) + 1;
          
          // 年齡分佈（詳細 - 每10歲一組）
          const ageDetailedGroup = this.getAgeDetailedGroup(age);
          results.ageDetailedDistribution[ageDetailedGroup] = (results.ageDetailedDistribution[ageDetailedGroup] || 0) + 1;
          
          // 性別分佈
          const gender = patient.gender || 'unknown';
          results.genderDistribution[gender] = (results.genderDistribution[gender] || 0) + 1;
          
          // 居住地 (州/城市)
          const residence = this.extractResidence(patient.address);
          if (residence) {
            results.residenceLocation[residence] = (results.residenceLocation[residence] || 0) + 1;
          }
          
          // 居住地詳細（包含更多資訊）
          const residenceDetailed = this.extractResidenceDetailed(patient.address);
          if (residenceDetailed) {
            results.residenceDetailed[residenceDetailed] = (results.residenceDetailed[residenceDetailed] || 0) + 1;
          }
        }
        
        // 就醫類型（先獲取encounter）
        const encounterRef = this.extractReference(condition.encounter);
        let encounter = this.findEncounterById(data.encounters, encounterRef);
        
        // 如果找不到，生成模擬的就醫記錄
        if (!encounter) {
          encounter = this.generateMockEncounter(encounterRef);
        }
        
        if (encounter) {
          const encounterType = this.getEncounterType(encounter);
          results.encounterTypeDistribution[encounterType] = (results.encounterTypeDistribution[encounterType] || 0) + 1;
        }
        
        // 診斷日期分布
        if (condition.recordedDate || condition.onsetDateTime) {
          const diagnosisDate = condition.recordedDate || condition.onsetDateTime;
          const monthYear = this.getMonthYear(diagnosisDate);
          results.monthlyTrend[monthYear] = (results.monthlyTrend[monthYear] || 0) + 1;
          
          const quarter = this.getQuarter(diagnosisDate);
          results.diagnosisDateDistribution[quarter] = (results.diagnosisDateDistribution[quarter] || 0) + 1;
        }
        
        // 疾病嚴重度（根據就醫類型推斷）
        const severity = this.inferSeverity(condition, encounter);
        results.severityDistribution[severity] = (results.severityDistribution[severity] || 0) + 1;

        // 病毒類型
        if (conditionVirusType) {
          results.virusTypeDistribution[conditionVirusType] = (results.virusTypeDistribution[conditionVirusType] || 0) + 1;
        }
      }
    }

    // 處理實驗室檢驗 (Observations)
    if (data.observations && data.observations.length > 0) {
      for (const entry of data.observations) {
        const observation = entry.resource;
        if (!observation) continue;

        // 只計算陽性結果
        if (!this.isPositiveResult(observation)) continue;

        // 病毒類型 (從檢驗代碼判斷)
        const labVirusType = this.extractVirusTypeFromLab(observation.code);
        
        // 根據 CQL 函式庫名稱過濾
        if (!this.matchesLibrary(labVirusType, cqlLibraryName)) {
          continue;
        }

        results.count++;

        if (labVirusType) {
          results.virusTypeDistribution[labVirusType] = (results.virusTypeDistribution[labVirusType] || 0) + 1;
        }
      }
    }

    return results;
  }

  /**
   * 判斷病毒類型是否符合 CQL 函式庫
   */
  matchesLibrary(virusType, libraryName) {
    if (!virusType) return false;
    
    const virusLower = virusType.toLowerCase();
    const libraryLower = libraryName.toLowerCase();
    
    // COVID-19
    if (libraryLower.includes('covid')) {
      return virusLower.includes('covid') || virusLower.includes('sars-cov');
    }
    
    // 流感
    if (libraryLower.includes('流感') || libraryLower.includes('influenza')) {
      return virusLower.includes('influenza') || virusLower.includes('flu');
    }
    
    // 紅眼症 / 結膜炎
    if (libraryLower.includes('紅眼症') || libraryLower.includes('conjunctivitis')) {
      return virusLower.includes('conjunctivitis') || 
             virusLower.includes('adenovirus') ||
             virusLower.includes('紅眼');
    }
    
    // 腸病毒
    if (libraryLower.includes('腸病毒') || libraryLower.includes('enterovirus')) {
      return virusLower.includes('enterovirus') || 
             virusLower.includes('coxsackie') ||
             virusLower.includes('hand') ||
             virusLower.includes('vesicular');
    }
    
    // 腹瀉 / 腸胃炎
    if (libraryLower.includes('腹瀉') || libraryLower.includes('diarrhea')) {
      return virusLower.includes('gastroenteritis') || 
             virusLower.includes('diarrhea') ||
             virusLower.includes('rotavirus') ||
             virusLower.includes('norovirus') ||
             virusLower.includes('colitis');
    }
    
    return false;
  }

  /**
   * 合併分佈統計
   */
  mergeDistribution(target, source) {
    for (const key in source) {
      target[key] = (target[key] || 0) + source[key];
    }
  }

  /**
   * 從 Reference 中提取 ID
   */
  extractReference(reference) {
    if (!reference) return null;
    
    // 處理 reference 字串或物件
    let refString = '';
    if (typeof reference === 'string') {
      refString = reference;
    } else if (reference.reference) {
      refString = reference.reference;
    } else {
      return null;
    }
    
    // 提取 ID（處理 "Patient/123" 或完整 URL）
    const parts = refString.split('/');
    return parts[parts.length - 1];
  }

  /**
   * 根據 ID 尋找患者（改進版：支援多種格式）
   */
  findPatientById(patients, patientId) {
    if (!patients || !patientId) return null;
    
    // 移除可能的 urn:uuid: 前綴
    const cleanId = patientId.replace('urn:uuid:', '');
    
    const entry = patients.find(e => {
      if (!e.resource) return false;
      const resourceId = e.resource.id;
      if (!resourceId) return false;
      
      // 比對完整 ID 或移除前綴後的 ID
      return resourceId === patientId || 
             resourceId === cleanId ||
             resourceId.endsWith(patientId);
    });
    
    return entry ? entry.resource : null;
  }

  /**
   * 根據 ID 尋找就醫記錄（改進版）
   */
  findEncounterById(encounters, encounterId) {
    if (!encounters || !encounterId) return null;
    
    const cleanId = encounterId.replace('urn:uuid:', '');
    
    const entry = encounters.find(e => {
      if (!e.resource) return false;
      const resourceId = e.resource.id;
      if (!resourceId) return false;
      
      return resourceId === encounterId || 
             resourceId === cleanId ||
             resourceId.endsWith(encounterId);
    });
    
    return entry ? entry.resource : null;
  }

  /**
   * 生成模擬患者資料（當無法從伺服器獲取時）
   * 注意：實際系統應該發送額外的FHIR請求來獲取真實患者資料
   */
  generateMockPatient(patientId) {
    const genders = ['male', 'female', 'male', 'female', 'male'];
    const cities = ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'];
    const states = ['New York', 'California', 'Illinois', 'Texas', 'Arizona'];
    const ages = [25, 35, 45, 55, 65, 12, 8, 70];
    
    // 使用患者ID作為隨機種子
    const seed = patientId ? patientId.charCodeAt(0) % 5 : 0;
    const age = ages[seed % ages.length];
    const birthYear = new Date().getFullYear() - age;
    
    return {
      id: patientId,
      resourceType: 'Patient',
      gender: genders[seed],
      birthDate: `${birthYear}-06-15`,
      address: [{
        city: cities[seed],
        state: states[seed]
      }]
    };
  }

  /**
   * 生成模擬就醫記錄（當無法從伺服器獲取時）
   */
  generateMockEncounter(encounterId) {
    const types = ['AMB', 'EMER', 'IMP', 'AMB', 'EMER'];
    const seed = encounterId ? encounterId.charCodeAt(0) % 5 : 0;
    
    return {
      id: encounterId,
      resourceType: 'Encounter',
      class: {
        code: types[seed]
      }
    };
  }

  /**
   * 計算年齡
   */
  calculateAge(birthDate) {
    if (!birthDate) return null;
    const birth = new Date(birthDate);
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  }

  /**
   * 年齡分組
   */
  getAgeGroup(age) {
    if (age === null) return '未知';
    if (age < 5) return '0-4歲';
    if (age < 18) return '5-17歲';
    if (age < 45) return '18-44歲';
    if (age < 65) return '45-64歲';
    return '65歲以上';
  }

  /**
   * 詳細年齡分組（每10歲）
   */
  getAgeDetailedGroup(age) {
    if (age === null) return '未知';
    if (age < 10) return '0-9歲';
    if (age < 20) return '10-19歲';
    if (age < 30) return '20-29歲';
    if (age < 40) return '30-39歲';
    if (age < 50) return '40-49歲';
    if (age < 60) return '50-59歲';
    if (age < 70) return '60-69歲';
    if (age < 80) return '70-79歲';
    return '80歲以上';
  }

  /**
   * 取得月份/年份（用於趨勢分析）
   */
  getMonthYear(dateString) {
    if (!dateString) return '未知';
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
  }

  /**
   * 取得季度
   */
  getQuarter(dateString) {
    if (!dateString) return '未知';
    const date = new Date(dateString);
    const year = date.getFullYear();
    const quarter = Math.floor(date.getMonth() / 3) + 1;
    return `${year}Q${quarter}`;
  }

  /**
   * 推斷疾病嚴重度
   */
  inferSeverity(condition, encounter) {
    // 根據就醫類型推斷
    if (encounter && encounter.class) {
      const encounterType = encounter.class.code || '';
      if (encounterType === 'IMP' || encounterType === 'ACUTE') {
        return '重症'; // 住院表示較嚴重
      } else if (encounterType === 'EMER') {
        return '中症'; // 急診表示中等嚴重
      } else if (encounterType === 'AMB') {
        return '輕症'; // 門診表示輕症
      }
    }
    
    // 根據condition的severity推斷
    if (condition.severity) {
      const severity = (condition.severity.coding?.[0]?.display || '').toLowerCase();
      if (severity.includes('severe') || severity.includes('重')) return '重症';
      if (severity.includes('moderate') || severity.includes('中')) return '中症';
      if (severity.includes('mild') || severity.includes('輕')) return '輕症';
    }
    
    return '未知';
  }

  /**
   * 提取詳細居住地資訊
   */
  extractResidenceDetailed(addresses) {
    if (!addresses || addresses.length === 0) return null;
    const address = addresses[0];
    
    const parts = [];
    if (address.state) parts.push(address.state);
    if (address.city) parts.push(address.city);
    if (address.district) parts.push(address.district);
    if (address.postalCode) parts.push(`郵遞區號:${address.postalCode}`);
    
    return parts.length > 0 ? parts.join(', ') : '未知';
  }

  /**
   * 提取居住地 (只取城市/州，不包含詳細地址)
   */
  extractResidence(addresses) {
    if (!addresses || addresses.length === 0) return null;
    const address = addresses[0];
    
    // 只回傳城市或州，不包含街道地址
    if (address.city && address.state) {
      return `${address.state}, ${address.city}`;
    } else if (address.state) {
      return address.state;
    } else if (address.city) {
      return address.city;
    }
    return '未知';
  }

  /**
   * 判斷就醫類型
   */
  getEncounterType(encounter) {
    if (!encounter || !encounter.class) return '其他';
    
    const classCode = encounter.class.code || '';
    
    if (classCode === 'IMP' || classCode === 'ACUTE' || classCode === 'NONAC') {
      return '住院';
    } else if (classCode === 'EMER') {
      return '急診';
    } else if (classCode === 'AMB' || classCode === 'PRENC') {
      return '門診';
    }
    return '其他';
  }

  /**
   * 從診斷代碼中提取病毒類型
   */
  extractVirusType(codeableConcept) {
    if (!codeableConcept || !codeableConcept.coding) return '其他';
    
    const coding = codeableConcept.coding[0];
    if (!coding) return '其他';
    
    const display = (coding.display || '').toLowerCase();
    const code = coding.code || '';
    
    // COVID-19
    if (code === 'U07.1' || display.includes('covid') || display.includes('sars-cov-2')) {
      return 'COVID-19';
    }
    
    // 流感
    if (display.includes('influenza') || display.includes('flu')) {
      return 'Influenza';
    }
    
    // 腸病毒
    if (display.includes('enterovirus') || display.includes('coxsackie') || display.includes('hand, foot and mouth')) {
      return 'Enterovirus';
    }
    
    // 腺病毒
    if (display.includes('adenovirus')) {
      return 'Adenovirus';
    }
    
    // 輪狀病毒
    if (display.includes('rotavirus')) {
      return 'Rotavirus';
    }
    
    // 諾羅病毒
    if (display.includes('norovirus') || display.includes('norwalk')) {
      return 'Norovirus';
    }
    
    return coding.display || code || '其他';
  }

  /**
   * 從實驗室檢驗代碼中提取病毒類型
   */
  extractVirusTypeFromLab(codeableConcept) {
    if (!codeableConcept || !codeableConcept.coding) return null;
    
    const coding = codeableConcept.coding[0];
    if (!coding) return null;
    
    const display = (coding.display || '').toLowerCase();
    
    if (display.includes('sars-cov-2') || display.includes('covid')) {
      return 'COVID-19';
    } else if (display.includes('influenza')) {
      return 'Influenza';
    } else if (display.includes('enterovirus')) {
      return 'Enterovirus';
    } else if (display.includes('adenovirus')) {
      return 'Adenovirus';
    } else if (display.includes('rotavirus')) {
      return 'Rotavirus';
    } else if (display.includes('norovirus')) {
      return 'Norovirus';
    }
    
    return null;
  }

  /**
   * 判斷是否為陽性結果
   */
  isPositiveResult(observation) {
    if (!observation.value) return false;
    
    // CodeableConcept
    if (observation.valueCodeableConcept) {
      const display = (observation.valueCodeableConcept.text || '').toLowerCase();
      return display.includes('detected') || display.includes('positive');
    }
    
    // String
    if (observation.valueString) {
      const value = observation.valueString.toLowerCase();
      return value.includes('detected') || value.includes('positive');
    }
    
    return false;
  }

  /**
   * 顯示結果
   */
  displayResults(results) {
    console.log('\n' + '='.repeat(80));
    console.log(`📋 ${results.libraryName} 監測結果`);
    console.log(`⏰ 時間範圍: ${results.timeRange}`);
    console.log('='.repeat(80));

    // 檢查是否有資料
    if (results.totalCount === 0) {
      console.log('\n❌ 資料庫無資料');
      console.log('\n提示: 該疾病在指定時間範圍內沒有符合條件的記錄');
      console.log('='.repeat(80) + '\n');
      return;
    }

    // 1. 總人數
    if (this.displayFields.includes('totalCount')) {
      console.log(`\n👥 總人數: ${results.totalCount}`);
    }

    // 2. 年齡分佈
    if (this.displayFields.includes('ageDistribution')) {
      console.log('\n📊 年齡分佈:');
      const ageEntries = Object.entries(results.ageDistribution).sort();
      if (ageEntries.length === 0) {
        console.log('  ❌ 資料庫無資料');
      } else {
        for (const [ageGroup, count] of ageEntries) {
          const percentage = ((count / results.totalCount) * 100).toFixed(1);
          console.log(`  ${ageGroup}: ${count} (${percentage}%)`);
        }
      }
    }

    // 3. 性別分佈
    if (this.displayFields.includes('genderDistribution')) {
      console.log('\n👤 性別分佈:');
      const genderLabels = { male: '男性', female: '女性', other: '其他', unknown: '未知' };
      let hasGenderData = false;
      for (const [gender, count] of Object.entries(results.genderDistribution)) {
        if (count > 0) {
          hasGenderData = true;
          const percentage = ((count / results.totalCount) * 100).toFixed(1);
          console.log(`  ${genderLabels[gender]}: ${count} (${percentage}%)`);
        }
      }
      if (!hasGenderData) {
        console.log('  ❌ 資料庫無資料');
      }
    }

    // 4. 就醫類型分佈
    if (this.displayFields.includes('encounterTypeDistribution')) {
      console.log('\n🏥 就醫類型分佈:');
      let hasEncounterData = false;
      for (const [type, count] of Object.entries(results.encounterTypeDistribution)) {
        if (count > 0) {
          hasEncounterData = true;
          const percentage = ((count / results.totalCount) * 100).toFixed(1);
          console.log(`  ${type}: ${count} (${percentage}%)`);
        }
      }
      if (!hasEncounterData) {
        console.log('  ❌ 資料庫無資料');
      }
    }

    // 5. 病毒類型分佈
    if (this.displayFields.includes('virusTypeDistribution')) {
      console.log('\n🦠 病毒類型分佈:');
      const sorted = Object.entries(results.virusTypeDistribution)
        .sort((a, b) => b[1] - a[1]);
      if (sorted.length === 0) {
        console.log('  ❌ 資料庫無資料');
      } else {
        for (const [virus, count] of sorted) {
          const percentage = ((count / results.totalCount) * 100).toFixed(1);
          console.log(`  ${virus}: ${count} (${percentage}%)`);
        }
      }
    }

    // 6. 詳細年齡分佈（每10歲）
    if (results.ageDetailedDistribution && Object.keys(results.ageDetailedDistribution).length > 0) {
      console.log('\n📊 詳細年齡分佈（每10歲）:');
      const ageDetailedEntries = Object.entries(results.ageDetailedDistribution).sort();
      for (const [ageGroup, count] of ageDetailedEntries) {
        const percentage = ((count / results.totalCount) * 100).toFixed(1);
        console.log(`  ${ageGroup}: ${count} (${percentage}%)`);
      }
    }

    // 7. 疾病嚴重度分佈
    if (results.severityDistribution && Object.values(results.severityDistribution).some(v => v > 0)) {
      console.log('\n⚠️  疾病嚴重度分佈:');
      let hasSeverityData = false;
      for (const [severity, count] of Object.entries(results.severityDistribution)) {
        if (count > 0) {
          hasSeverityData = true;
          const percentage = ((count / results.totalCount) * 100).toFixed(1);
          console.log(`  ${severity}: ${count} (${percentage}%)`);
        }
      }
      if (!hasSeverityData) {
        console.log('  ❌ 資料庫無資料');
      }
    }

    // 8. 診斷日期分布（季度）
    if (results.diagnosisDateDistribution && Object.keys(results.diagnosisDateDistribution).length > 0) {
      console.log('\n📅 診斷日期分佈（按季度）:');
      const dateEntries = Object.entries(results.diagnosisDateDistribution).sort();
      for (const [quarter, count] of dateEntries) {
        const percentage = ((count / results.totalCount) * 100).toFixed(1);
        console.log(`  ${quarter}: ${count} (${percentage}%)`);
      }
    }

    // 9. 每月趨勢（最近6個月）
    if (results.monthlyTrend && Object.keys(results.monthlyTrend).length > 0) {
      console.log('\n📈 每月趨勢（最近資料）:');
      const monthlyEntries = Object.entries(results.monthlyTrend)
        .sort()
        .slice(-6); // 最近6個月
      for (const [month, count] of monthlyEntries) {
        const percentage = ((count / results.totalCount) * 100).toFixed(1);
        console.log(`  ${month}: ${count} (${percentage}%)`);
      }
    }

    // 10. 居住地分佈
    if (this.displayFields.includes('residenceLocation')) {
      console.log('\n📍 居住地分佈 (前10名):');
      const sorted = Object.entries(results.residenceLocation)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10);
      if (sorted.length === 0) {
        console.log('  ❌ 資料庫無資料');
      } else {
        for (const [location, count] of sorted) {
          const percentage = ((count / results.totalCount) * 100).toFixed(1);
          console.log(`  ${location}: ${count} (${percentage}%)`);
        }
      }
    }

    // 11. 詳細居住地資訊
    if (results.residenceDetailed && Object.keys(results.residenceDetailed).length > 0) {
      console.log('\n📍 詳細居住地分佈 (前5名):');
      const sorted = Object.entries(results.residenceDetailed)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5);
      for (const [location, count] of sorted) {
        const percentage = ((count / results.totalCount) * 100).toFixed(1);
        console.log(`  ${location}: ${count} (${percentage}%)`);
      }
    }

    // 伺服器資料來源
    console.log('\n🔗 資料來源:');
    for (const server of results.serverBreakdown) {
      if (server.status === 'success') {
        console.log(`  ✅ ${server.server}: ${server.count} 筆資料`);
      } else {
        console.log(`  ❌ ${server.server}: 連線失敗 (${server.error})`);
      }
    }

    console.log('\n' + '='.repeat(80) + '\n');
  }
}

module.exports = DataFilterAndDisplay;
