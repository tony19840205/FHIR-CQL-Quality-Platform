/**
 * 範例資料產生器
 * 用於測試系統功能（當外部 FHIR 伺服器沒有資料時）
 */
class SampleDataGenerator {
  constructor() {
    this.samplePatients = this.generateSamplePatients();
    this.sampleConditions = this.generateSampleConditions();
    this.sampleObservations = this.generateSampleObservations();
    this.sampleEncounters = this.generateSampleEncounters();
  }

  /**
   * 產生範例患者資料
   */
  generateSamplePatients() {
    const patients = [];
    const cities = [
      { state: 'Massachusetts', city: 'Boston' },
      { state: 'New York', city: 'New York' },
      { state: 'California', city: 'Los Angeles' },
      { state: 'Texas', city: 'Houston' },
      { state: 'Florida', city: 'Miami' }
    ];

    for (let i = 1; i <= 50; i++) {
      const location = cities[i % cities.length];
      const birthYear = 1940 + Math.floor(Math.random() * 70);
      
      patients.push({
        resource: {
          resourceType: 'Patient',
          id: `patient-${i}`,
          gender: i % 3 === 0 ? 'male' : 'female',
          birthDate: `${birthYear}-${String(Math.floor(Math.random() * 12) + 1).padStart(2, '0')}-15`,
          address: [{
            state: location.state,
            city: location.city,
            postalCode: '12345'
          }]
        }
      });
    }

    return patients;
  }

  /**
   * 產生範例診斷條件（模擬真實情況：不同疾病有不同數量）
   */
  generateSampleConditions() {
    const conditions = [];
    const diseaseTypes = [
      { code: 'U07.1', display: 'COVID-19', system: 'http://hl7.org/fhir/sid/icd-10-cm', count: 45 },
      { code: 'J10', display: 'Influenza due to identified influenza virus', system: 'http://hl7.org/fhir/sid/icd-10-cm', count: 38 },
      { code: 'B08.4', display: 'Enteroviral vesicular stomatitis with exanthem', system: 'http://hl7.org/fhir/sid/icd-10-cm', count: 12 },
      { code: 'H10.0', display: 'Mucopurulent conjunctivitis', system: 'http://hl7.org/fhir/sid/icd-10-cm', count: 28 },
      { code: 'A09', display: 'Infectious gastroenteritis and colitis', system: 'http://hl7.org/fhir/sid/icd-10-cm', count: 0 } // 測試無資料情況
    ];

    let conditionId = 1;
    for (const disease of diseaseTypes) {
      for (let i = 0; i < disease.count; i++) {
        const patientId = `patient-${Math.floor(Math.random() * 50) + 1}`;
        const daysAgo = Math.floor(Math.random() * 365 * 2); // 2年內
        const recordDate = new Date();
        recordDate.setDate(recordDate.getDate() - daysAgo);

        conditions.push({
          resource: {
            resourceType: 'Condition',
            id: `condition-${conditionId++}`,
            code: {
              coding: [{
                system: disease.system,
                code: disease.code,
                display: disease.display
              }]
            },
            subject: {
              reference: `Patient/${patientId}`
            },
            encounter: {
              reference: `Encounter/encounter-${conditionId}`
            },
            recordedDate: recordDate.toISOString(),
            onsetDateTime: recordDate.toISOString()
          }
        });
      }
    }

    return conditions;
  }

  /**
   * 產生範例實驗室檢驗
   */
  generateSampleObservations() {
    const observations = [];
    const labTests = [
      { code: '94500-6', display: 'SARS-CoV-2 RNA [Presence] in Respiratory specimen', virus: 'COVID-19' },
      { code: '29505-3', display: 'Enterovirus RNA [Presence] in Specimen', virus: 'Enterovirus' },
      { code: '88891-7', display: 'Adenovirus Ag [Presence] in Conjunctiva', virus: 'Adenovirus' }
    ];

    for (let i = 1; i <= 50; i++) {
      const test = labTests[i % labTests.length];
      const patientId = `patient-${Math.floor(Math.random() * 50) + 1}`;
      const daysAgo = Math.floor(Math.random() * 365 * 2);
      const testDate = new Date();
      testDate.setDate(testDate.getDate() - daysAgo);

      observations.push({
        resource: {
          resourceType: 'Observation',
          id: `observation-${i}`,
          status: 'final',
          code: {
            coding: [{
              system: 'http://loinc.org',
              code: test.code,
              display: test.display
            }]
          },
          subject: {
            reference: `Patient/${patientId}`
          },
          encounter: {
            reference: `Encounter/encounter-lab-${i}`
          },
          effectiveDateTime: testDate.toISOString(),
          issued: testDate.toISOString(),
          valueCodeableConcept: {
            text: 'Detected'
          }
        }
      });
    }

    return observations;
  }

  /**
   * 產生範例就醫記錄
   */
  generateSampleEncounters() {
    const encounters = [];
    const encounterTypes = [
      { code: 'AMB', display: 'Ambulatory' },
      { code: 'EMER', display: 'Emergency' },
      { code: 'IMP', display: 'Inpatient' }
    ];

    for (let i = 1; i <= 150; i++) {
      const type = encounterTypes[i % encounterTypes.length];
      const patientId = `patient-${Math.floor(Math.random() * 50) + 1}`;
      const daysAgo = Math.floor(Math.random() * 365 * 2);
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - daysAgo);
      
      const endDate = new Date(startDate);
      if (type.code === 'IMP') {
        endDate.setDate(endDate.getDate() + Math.floor(Math.random() * 7) + 1); // 住院1-7天
      } else {
        endDate.setHours(endDate.getHours() + Math.floor(Math.random() * 4) + 1); // 門急診1-4小時
      }

      encounters.push({
        resource: {
          resourceType: 'Encounter',
          id: `encounter-${i}`,
          status: 'finished',
          class: {
            code: type.code,
            display: type.display
          },
          subject: {
            reference: `Patient/${patientId}`
          },
          period: {
            start: startDate.toISOString(),
            end: endDate.toISOString()
          }
        }
      });
    }

    return encounters;
  }

  /**
   * 取得完整的範例資料集
   */
  getSampleData() {
    return {
      patients: this.samplePatients,
      conditions: this.sampleConditions,
      observations: this.sampleObservations,
      encounters: this.sampleEncounters
    };
  }
}

module.exports = SampleDataGenerator;
