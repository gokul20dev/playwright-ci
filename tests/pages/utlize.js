// ============================================
// CONSTANTS
// ============================================
const STUDENT_TYPES = {
  ALL: 'ALL',
  RANGE: 'RANGE',
  SINGLE: 'SINGLE'
};

// ============================================
// EXAM TAKER UTILITIES (STUDENTS)
// ============================================
const ExamTakerUtils = {
  // Common student configuration
  config: {
    studentCount: 15,
    nationalId: '123',
    
    // Student selection per environment
    selection: {
      staging: {
        type: STUDENT_TYPES.SINGLE,
        options: { startFrom: 1, endAt: 5, studentNumber: 2 }
      },
      production: {
        type: STUDENT_TYPES.ALL,
        options: { startFrom: 1, endAt: 5, studentNumber: 11 }
      }
    }
  },
  
  // Generate student accounts
  generate(count, nationalId) {
    return Array.from({ length: count }, (_, i) => ({
      email: `student${String(i + 1).padStart(2, '0')}@gmail.com`,
      nationalId,
      name: `Student ${i + 1}`
    }));
  },
  
  // Get students based on selection type
  getStudents(selectionConfig, count, nationalId) {
    const { type, options } = selectionConfig;
    const students = this.generate(count, nationalId);
    
    switch (type) {
      case STUDENT_TYPES.ALL:
        console.log(`Running ALL students (1-${count})`);
        return students;
        
      case STUDENT_TYPES.RANGE:
        const { startFrom, endAt } = options;
        if (!startFrom || !endAt || startFrom < 1 || endAt > count || startFrom > endAt) {
          throw new Error(`Invalid range: ${startFrom}-${endAt}`);
        }
        console.log(`Running RANGE (${startFrom}-${endAt})`);
        return students.slice(startFrom - 1, endAt);
        
      case STUDENT_TYPES.SINGLE:
        const { studentNumber } = options;
        if (!studentNumber || studentNumber < 1 || studentNumber > count) {
          throw new Error(`Invalid student number: ${studentNumber}`);
        }
        console.log(`Running SINGLE (#${studentNumber})`);
        return [students[studentNumber - 1]];
        
      default:
        throw new Error(`Invalid type: ${type}`);
    }
  },
  
  // Get students for specific environment
  getForEnvironment(env) {
    const selection = this.config.selection[env];
    if (!selection) throw new Error(`No student config for: ${env}`);
    
    return this.getStudents(
      selection,
      this.config.studentCount,
      this.config.nationalId
    );
  }
};

// ============================================
// EXAM MAKER UTILITIES (COLLEGE)
// ============================================
const ExamMakerUtils = {
  // College/Organization configurations
  colleges: {
    staging: {
      orgId: 'DIGI-002',
      email: 'sakthiganesh@digivalsolutions.com',
      password: 'SG',
      baseUrl: 'https://digiscreener-staging.gcp.digivalitsolutions.com/fullscreenexam/'
    },
    
    production: {
      orgId: 'DI',
      email: 'karthik@digivalsolutions.com',
      password: '123',
      baseUrl: 'https://screener.digi-val.com/fullscreenexam/'
    }
  },
  
  // Get college configuration
  getCollege(env = 'staging') {
    const college = this.colleges[env];
    if (!college) throw new Error(`Invalid environment: ${env}`);
    return college;
  }
};

// ============================================
// EXPORTS
// ============================================
const env = process.env.TEST_ENV || 'staging';

// Export college config (no student data)
const examMakerConfig = ExamMakerUtils.getCollege(env);

// Export student config (no college data)
const examTakerConfig = {
  studentCount: ExamTakerUtils.config.studentCount,
  nationalId: ExamTakerUtils.config.nationalId,
  getStudents: () => ExamTakerUtils.getForEnvironment(env)
};

export { 
  STUDENT_TYPES, 
  ExamTakerUtils, 
  ExamMakerUtils,
  examMakerConfig,
  examTakerConfig
};