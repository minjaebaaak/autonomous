/**
 * AEGIS Protocol Configuration
 *
 * 이 파일을 aegis.config.js로 복사하고 프로젝트에 맞게 수정하세요.
 *
 * @version 3.1
 */

module.exports = {
  //===========================================================================
  // 프로젝트 기본 정보
  //===========================================================================
  project: {
    name: 'my-project',           // 프로젝트 이름
    port: 3001,                   // 개발 서버 포트
    framework: 'nextjs',          // nextjs, react, vue, express, fastapi, go
    packageManager: 'pnpm',       // pnpm, npm, yarn, pip, poetry, go
  },

  //===========================================================================
  // 서버 정보 (배포용)
  //===========================================================================
  server: {
    ip: '1.2.3.4',               // 서버 공인 IP
    user: 'ubuntu',              // SSH 사용자
    path: '/home/ubuntu/project', // 프로젝트 경로
    sshKey: '~/.ssh/id_rsa',     // SSH 키 경로 (선택)
  },

  //===========================================================================
  // PM2 설정 (Node.js 프로젝트용)
  //===========================================================================
  pm2: {
    processName: 'my-app-production',  // PM2 프로세스 이름
    instances: 'max',                   // 인스턴스 수 (max = CPU 코어 수)
    execMode: 'cluster',                // cluster 또는 fork
  },

  //===========================================================================
  // 데이터베이스 설정
  //===========================================================================
  database: {
    type: 'postgresql',          // postgresql, mysql, mongodb, sqlite
    host: 'localhost',
    port: 5432,
    name: 'my_database',
    user: 'db_user',
    // password는 환경 변수로 관리 (DATABASE_PASSWORD)

    // 스키마 검증용 테이블 목록 (Layer 0)
    criticalTables: [
      'users',
      'sessions',
      // 프로젝트의 중요 테이블 추가
    ],
  },

  //===========================================================================
  // 검증 설정 (7-Layer)
  //===========================================================================
  validation: {
    // Layer 1: Static Analysis
    buildCommand: 'pnpm build',
    typeCheckCommand: 'pnpm type-check',
    lintCommand: 'pnpm lint',

    // Layer 2: Unit Test
    unitTestCommand: 'pnpm test',

    // Layer 3: Integration Test
    integrationTestCommand: 'pnpm test:integration',

    // Layer 4: E2E Test
    e2eTestCommand: 'pnpm test:e2e',
    e2eBaseUrl: 'http://localhost:3001',

    // Layer 5: Staging
    stagingUrl: 'https://staging.example.com',

    // Layer 6: Production
    productionUrl: 'https://example.com',
    healthCheckEndpoint: '/api/health',
  },

  //===========================================================================
  // 백업 설정
  //===========================================================================
  backup: {
    directory: 'backups',        // 백업 디렉토리
    retentionDays: 7,            // 보관 일수
    compress: true,              // 압축 여부
    exclude: [                   // 백업 제외 항목
      'node_modules',
      '.next',
      '.git',
      'logs',
    ],
  },

  //===========================================================================
  // 알림 설정 (선택)
  //===========================================================================
  notifications: {
    slack: {
      enabled: false,
      webhookUrl: '',            // Slack Webhook URL
      channel: '#deployments',
    },
    discord: {
      enabled: false,
      webhookUrl: '',            // Discord Webhook URL
    },
  },

  //===========================================================================
  // 환경별 설정
  //===========================================================================
  environments: {
    development: {
      port: 3001,
      debug: true,
    },
    staging: {
      port: 3002,
      debug: true,
    },
    production: {
      port: 3001,
      debug: false,
    },
  },

  //===========================================================================
  // 테스트 계정 (개발/테스트용)
  //===========================================================================
  testAccounts: {
    admin: {
      email: 'admin@example.com',
      // password는 환경 변수로 관리 (TEST_ADMIN_PASSWORD)
    },
    user: {
      email: 'user@example.com',
      // password는 환경 변수로 관리 (TEST_USER_PASSWORD)
    },
  },
};
