# AEGIS Protocol - 설정 가이드

## aegis.config.js

프로젝트의 루트에 위치하는 설정 파일입니다.

---

## 필수 설정

### 1. 프로젝트 기본 정보

```javascript
project: {
  name: 'your-project-name',
  type: 'monorepo',  // 'monorepo' 또는 'single'
  packageManager: 'pnpm',  // 'pnpm', 'npm', 'yarn'
  version: '3.6',
}
```

### 2. 패키지 구조 (모노레포)

```javascript
packages: {
  frontend: {
    path: 'app',
    port: 3000,
    framework: 'react-vite',
    buildCommand: 'pnpm build',
    devCommand: 'pnpm dev',
    typeCheckCommand: 'pnpm tsc --noEmit',
    lintCommand: 'pnpm lint',
  },
  backend: {
    path: 'server',
    port: 8787,
    framework: 'hono',  // 또는 'express', 'fastify' 등
    buildCommand: 'pnpm build',
    devCommand: 'pnpm dev',
    typeCheckCommand: 'pnpm tsc --noEmit',
  },
}
```

### 3. 검증 설정

```javascript
validation: {
  // Layer 1: Static Analysis
  buildCommands: {
    frontend: 'cd app && pnpm build',
    backend: 'cd server && pnpm build',
  },
  typeCheckCommands: {
    frontend: 'cd app && pnpm tsc --noEmit',
    backend: 'cd server && pnpm tsc --noEmit',
  },
  lintCommands: {
    frontend: 'cd app && pnpm lint',
  },

  // Layer 2: Unit Test
  unitTestCommand: 'pnpm test',

  // Layer 3: Integration Test
  integrationTestCommand: 'pnpm test:integration',

  // Layer 4: E2E Test
  e2eTestTool: 'chrome-mcp',  // 또는 'playwright-mcp'
  e2eBaseUrl: 'http://localhost:3000',
}
```

---

## 선택 설정

### 서버 정보 (배포용)

```javascript
server: {
  ip: '123.45.67.89',
  user: 'deploy',
  path: '/var/www/project',
  sshKey: '~/.ssh/id_rsa',
}
```

### 데이터베이스 설정

```javascript
database: {
  type: 'sqlite',  // 또는 'postgres', 'mysql'
  path: 'server/data/local.db',

  // Layer 0 스키마 검증용
  criticalTables: [
    'users',
    'contents',
    'settings',
  ],
}
```

### Automation Layer

```javascript
automation: {
  // Feedback Loop 설정
  feedbackLoop: {
    enabled: true,
    maxRetries: 3,
    commands: [
      'cd app && pnpm build',
      'cd server && pnpm build',
      'pnpm lint',
      'pnpm test',
    ],
  },

  // Infinite Loop 설정
  infiniteLoop: {
    enabled: true,
    maxIterations: 10,
    breakOnSuccess: true,
  },
}
```

### 병렬 실행 설정

```javascript
parallelExecution: {
  maxClaudes: 5,
  workAreas: {
    claude1: ['server/src/routes/', 'server/src/services/'],
    claude2: ['app/src/components/', 'app/src/pages/'],
    claude3: ['app/src/stores/', 'app/src/hooks/'],
    claude4: ['__tests__/', '.0/'],
    claude5: ['*'],  // 버그 수정
  },
  conflictPrevention: {
    buildResponsible: 'claude4',
    gitCommitSequential: true,
  },
}
```

### 알림 설정

```javascript
notifications: {
  slack: {
    enabled: true,
    webhookUrl: 'https://hooks.slack.com/services/xxx',
    channel: '#deployments',
  },
  discord: {
    enabled: false,
    webhookUrl: '',
  },
}
```

---

## CLAUDE.md 커스터마이징

### 필수 수정 항목

1. **프로젝트 이름**: 상단의 프로젝트 설명
2. **디렉토리 구조**: 실제 프로젝트 구조에 맞게 수정
3. **테스트 계정**: 개발/테스트용 계정 정보
4. **빌드 명령어**: 프로젝트의 빌드/테스트 명령어

### 프로젝트별 섹션 추가

```markdown
---

## 프로젝트 특화 규칙

### API 엔드포인트
- `/api/v1/users` - 사용자 관리
- `/api/v1/contents` - 콘텐츠 관리

### 코딩 컨벤션
- 컴포넌트: PascalCase
- 함수: camelCase
- 상수: UPPER_SNAKE_CASE
```

---

## 환경별 설정

```javascript
environments: {
  development: {
    frontendPort: 3000,
    backendPort: 8787,
    debug: true,
  },
  staging: {
    frontendPort: 3000,
    backendPort: 8787,
    debug: true,
  },
  production: {
    frontendPort: 3000,
    backendPort: 8787,
    debug: false,
  },
}
```

---

## 다음 단계

- [COMMANDS.md](./COMMANDS.md) - 명령어 레퍼런스
- [INSTALLATION.md](./INSTALLATION.md) - 설치 가이드
