# AEGIS Protocol

> **A**utonomous **E**nhanced **G**uard & **I**nspection **S**ystem

Claude Code와 함께 사용하는 7-Layer 검증 프레임워크입니다.

---

## 개요

AEGIS는 소프트웨어 개발 시 품질을 보장하기 위한 체계적인 검증 프로토콜입니다.

```
┌─────────────────────────────────────────────────────────────────┐
│                        AEGIS v3.1                               │
├─────────────────────────────────────────────────────────────────┤
│  ⚡ COGNITIVE LAYER (사고 도구)                                  │
│     ├─ ultrathink: 모든 작업에 기본 적용                         │
│     └─ Sequential Thinking MCP: 복잡한 문제 시 필수             │
├─────────────────────────────────────────────────────────────────┤
│  📋 TASK LAYER (작업 추적)                                       │
│     └─ TodoWrite: 모든 작업 현황 추적                            │
├─────────────────────────────────────────────────────────────────┤
│  🔍 VALIDATION LAYERS (7-Layer 검증)                            │
│     Layer 0: Schema Validation    | DB 스키마 검증              │
│     Layer 1: Static Analysis      | 빌드 검증                   │
│     Layer 2: Unit Test            | 단위 테스트                 │
│     Layer 3: Integration Test     | 통합 테스트                 │
│     Layer 4: E2E Test             | Playwright MCP              │
│     Layer 5: Staging Validation   | 스테이징 검증               │
│     Layer 6: Production Monitor   | 프로덕션 모니터링           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 빠른 시작

### 1. 새 프로젝트에 AEGIS 적용

```bash
# 방법 1: setup.sh 사용 (권장)
curl -fsSL https://raw.githubusercontent.com/minjaebaaak/aegis-protocol/master/scripts/setup.sh | bash -s -- /path/to/your/project

# 방법 2: 수동 복사
git clone https://github.com/minjaebaaak/aegis-protocol.git
cp aegis-protocol/CLAUDE.md.template your-project/CLAUDE.md
cp aegis-protocol/aegis.config.example.js your-project/aegis.config.js
cp -r aegis-protocol/scripts your-project/
```

### 2. 설정 파일 수정

`aegis.config.js`를 프로젝트에 맞게 수정:

```javascript
module.exports = {
  project: {
    name: 'your-project-name',
    port: 3001,
  },
  server: {
    ip: 'your.server.ip',
    user: 'your-user',
    path: '/path/to/project',
  },
  pm2: {
    processName: 'your-app-production',
  },
  database: {
    type: 'postgresql', // postgresql, mysql, mongodb
    host: 'localhost',
    port: 5432,
  },
};
```

### 3. CLAUDE.md 커스터마이징

`CLAUDE.md.template`을 `CLAUDE.md`로 복사하고 `{{PLACEHOLDER}}`를 실제 값으로 교체:

```bash
cp CLAUDE.md.template CLAUDE.md
# 편집기로 열어서 {{PROJECT_NAME}}, {{SERVER_IP}} 등 수정
```

---

## 파일 구조

```
aegis-protocol/
├── README.md                    # 이 파일
├── CLAUDE.md.template           # 프로젝트용 CLAUDE.md 템플릿
├── aegis.config.example.js      # 설정 파일 예시
├── .0/
│   └── AEGIS_PROTOCOL.md        # 7-Layer 검증 프로토콜 상세
├── scripts/
│   ├── aegis-validate.sh        # 범용 검증 스크립트
│   ├── deploy.sh.template       # 배포 스크립트 템플릿
│   ├── rollback.sh              # 롤백 스크립트
│   └── setup.sh                 # 초기 설정 스크립트
├── .npmrc                       # pnpm 설정
├── .gitignore                   # Git 무시 파일
└── LICENSE                      # MIT 라이선스
```

---

## 7-Layer 검증 상세

| Layer | 이름 | 검증 대상 | 도구/명령어 |
|-------|------|----------|------------|
| 0 | Schema Validation | DB 스키마 변경 | `--schema <table>` |
| 1 | Static Analysis | 빌드, 타입 체크 | `pnpm build` |
| 2 | Unit Test | 개별 함수/모듈 | `pnpm test` |
| 3 | Integration Test | API 엔드포인트 | `--api` |
| 4 | E2E Test | 전체 사용자 흐름 | Playwright MCP |
| 5 | Staging Validation | 스테이징 환경 | 수동 검증 |
| 6 | Production Monitor | 프로덕션 상태 | `--monitor` |

### 필수 체크리스트

**Pre-Commit:**
```
[ ] Layer 0: 새 DB 컬럼 검증
[ ] Layer 1: 빌드 검증
```

**Pre-Deploy:**
```
[ ] Layer 0-4 모두 통과
[ ] git push 완료
```

**Post-Deploy:**
```
[ ] Layer 6: 에러 로그 확인
[ ] Layer 4: 프로덕션 E2E 검증
```

---

## 사용 예시

### AEGIS 검증 실행

```bash
# 전체 검증
./scripts/aegis-validate.sh --all

# 빌드만 검증
./scripts/aegis-validate.sh --build

# API 테스트
./scripts/aegis-validate.sh --api

# 스키마 검증
./scripts/aegis-validate.sh --schema users email
```

### 배포

```bash
# Production 배포
./scripts/deploy.sh production

# Dry-run (미리보기)
./scripts/deploy.sh production --dry-run
```

### 롤백

```bash
# 특정 백업으로 롤백
./scripts/rollback.sh backups/20241028_211630
```

---

## Claude Code와 함께 사용

AEGIS는 Claude Code의 다음 기능과 통합됩니다:

| Claude 기능 | AEGIS 활용 |
|------------|-----------|
| ultrathink | 모든 작업에 기본 적용 |
| Sequential Thinking MCP | 복잡한 문제 분석 |
| TodoWrite | 작업 추적 |
| Playwright MCP | Layer 4 E2E 테스트 |

### CLAUDE.md 예시

```markdown
# AEGIS Protocol v3.1

## 필수 준수 사항
- ultrathink 사용
- Sequential Thinking MCP로 복잡한 문제 분석
- TodoWrite로 작업 추적
- 7-Layer 검증 준수
```

---

## 기술 스택 호환성

| 스택 | 지원 |
|------|------|
| Node.js (pnpm) | ✅ 완벽 지원 |
| Python (pip/poetry) | ✅ 지원 |
| Go | ✅ 지원 |
| PostgreSQL | ✅ 완벽 지원 |
| MySQL | ✅ 지원 |
| MongoDB | ✅ 지원 |
| Docker | ✅ 지원 |
| PM2 | ✅ 완벽 지원 |

---

## 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능

---

## 기여

이슈와 PR을 환영합니다!

1. Fork
2. Feature branch 생성
3. Commit
4. PR 생성

---

**Created by**: Claude AI & minjaebaaak
**Version**: 3.1
**Last Updated**: 2026-01-04
