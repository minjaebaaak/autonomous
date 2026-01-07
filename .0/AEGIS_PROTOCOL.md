# AEGIS Protocol v3.5 Unified

> **A**utonomous **E**nhanced **G**uard & **I**nspection **S**ystem
>
> 안전한 자율 코딩을 위한 **완전 통합 프레임워크**
>
> v3.5 Unified: CI/CD + Observability + Resource Layer 추가

---

## 1. 개요

### 1.1 목적
AEGIS v3.5 Unified는 Claude Code와 함께 사용하는 체계적인 검증 프레임워크입니다.

**핵심 철학:**
- 안정적이고 최상의 방향으로 개발
- 시간은 충분함 - 성급하게 진행하지 말 것
- 재발 방지를 최우선으로 고려
- 한 번 다룬 문제는 재발하지 않도록 정확하게 구축

### 1.2 v3.5 Unified 핵심 변경

| 영역 | v3.1 | v3.5 Unified | 변경 |
|------|------|--------------|------|
| CI/CD | 없음 | GitHub Actions | **신규** |
| Observability | 없음 | Slack + 외부 모니터링 | **신규** |
| Resource Layer | 없음 | 메모리/디스크 감시 | **신규** |
| Feedback Loop | 없음 | 자동 검증 + 수정 | **신규** |
| Infinite Loop | 없음 | 목표 달성까지 반복 | **신규** |
| 병렬 실행 | 없음 | 5개 Claude 동시 | **신규** |

### 1.3 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                    AEGIS v3.5 Unified                           │
├─────────────────────────────────────────────────────────────────┤
│  ⚡ COGNITIVE LAYER (사고 도구)                                  │
│     ├─ ultrathink: 모든 작업에 기본 적용                         │
│     └─ Sequential Thinking MCP: 복잡한 문제 시 필수             │
├─────────────────────────────────────────────────────────────────┤
│  📋 TASK LAYER (작업 추적)                                       │
│     └─ TodoWrite: Layer 상태 자동 동기화                        │
├─────────────────────────────────────────────────────────────────┤
│  🔄 CI/CD LAYER (자동화) - v3.5 신규                             │
│     ├─ GitHub Actions: Push 시 자동 검증                        │
│     └─ Slack 알림: 성공/실패 자동 전송 (선택)                   │
├─────────────────────────────────────────────────────────────────┤
│  🔍 VALIDATION LAYERS (7-Layer)                                 │
│     ├─ Layer 0: Schema Validation (SQLite)                     │
│     ├─ Layer 1: Static Analysis (Build)                        │
│     ├─ Layer 2: Unit Test                                      │
│     ├─ Layer 3: Integration Test (API)                         │
│     ├─ Layer 4: E2E Test (Chrome MCP / Playwright MCP)         │
│     ├─ Layer 5: Staging Validation                             │
│     └─ Layer 6: Production Monitoring                          │
├─────────────────────────────────────────────────────────────────┤
│  📊 OBSERVABILITY LAYER - v3.5 신규                              │
│     ├─ 에러 로그 모니터링                                        │
│     └─ Slack/Discord 알림 (선택)                                │
├─────────────────────────────────────────────────────────────────┤
│  🧹 RESOURCE LAYER - v3.5 신규                                   │
│     ├─ Memory Guard: 과도한 메모리 사용 감지                     │
│     └─ Disk Alert: 디스크 용량 알림                             │
├─────────────────────────────────────────────────────────────────┤
│  🔁 AUTOMATION LAYER - v3.5 신규                                 │
│     ├─ Feedback Loop: 자동 검증 + 자동 수정                     │
│     └─ Infinite Loop: 목표 달성까지 무한 반복                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Cognitive Layer (사고 도구)

### 2.1 ultrathink 모드

**적용 시점**: 모든 AEGIS 작업에 기본 적용

**사용 방법**:
- 사용자가 `ultrathink` 키워드를 포함하면 자동 활성화
- 복잡한 분석, 다중 옵션 비교 시 깊은 사고 수행

### 2.2 Sequential Thinking MCP

**필수 사용 시점**:
| 상황 | Sequential Thinking 필요 |
|------|-------------------------|
| 같은 주제 2회 이상 다룸 | 필수 |
| 복잡한 문제 해결 | 필수 |
| 다중 옵션 분석/비교 | 필수 |
| 보안 관련 의사결정 | 필수 |
| 단순 코드 수정 | 선택 |

---

## 3. Task Layer (작업 추적)

### 3.1 TodoWrite 통합

**사용 규칙**:
1. 작업 시작 시 전체 계획을 TodoWrite로 등록
2. Layer 진행 시 각 Layer를 개별 todo로 관리
3. 완료 즉시 상태를 `completed`로 업데이트
4. 동시에 하나의 작업만 `in_progress`

---

## 4. Validation Layers (7-Layer 검증)

### Layer 0: Schema Validation

**목적**: DB 스키마 존재 확인 (SQLite)

**실행**:
```bash
./scripts/aegis-validate.sh --schema <table> <column>
```

### Layer 1: Static Analysis

**목적**: TypeScript 빌드/타입 검증

**실행 (모노레포)**:
```bash
# Frontend
cd app && pnpm build

# Backend
cd server && pnpm build
```

### Layer 2: Unit Test

**목적**: 개별 함수/모듈 동작 검증

**실행**:
```bash
pnpm test
```

### Layer 3: Integration Test

**목적**: API 엔드포인트 동작 검증

**실행**:
```bash
pnpm test:integration
```

### Layer 4: E2E Test

**목적**: 브라우저에서 전체 사용자 흐름 검증

#### Layer 4-A: Playwright MCP (로컬)

**사용 시점**: 로컬 개발 환경 (localhost:3000)

**사전 준비**:
```bash
# Playwright Chromium만 종료 (일반 Chrome은 유지!)
pkill -f "ms-playwright" || true
```

#### Layer 4-B: Chrome MCP (프로덕션)

**사용 시점**: 배포 후 프로덕션 환경

**주의사항**:
- `about:blank` 무한 접속 방지를 위해 스크린샷으로 수시 상태 확인
- 실제 사용자 관점에서 검증

### Layer 5: Staging Validation

**목적**: 스테이징 환경 검증 (배포 환경 구축 후 활성화)

### Layer 6: Production Monitoring

**목적**: 배포 후 에러 조기 발견

**실행**:
```bash
./scripts/aegis-validate.sh --monitor
```

---

## 5. Automation Layer (자동화) - v3.5 신규

### 5.1 Feedback Loop (피드백 루프)

**모든 코드 작업 완료 후 Claude가 자동으로:**

1. AEGIS Layer 0-3 검증 실행
   ```bash
   cd app && pnpm build
   cd server && pnpm build
   pnpm lint
   pnpm test
   ```

2. 실패 시 자동 수정 시도:
   - 에러 메시지 분석
   - 코드 수정
   - 재검증
   - **최대 3회 반복**

3. 3회 실패 시:
   - 사용자에게 상세 보고
   - 중단

**수동 호출**: `/feedback-loop`

### 5.2 Infinite Loop (무한 이터레이션 / Ralph Wiggum 모드)

**복잡한 작업 시 Claude가 자동으로:**

1. 목표 달성까지 반복 실행
2. 각 이터레이션마다 검증
3. 실패 시 분석 → 수정 → 재시도
4. **최대 10회 반복**
5. 10회 초과 시 사용자 확인 요청

**적용 시점**:
- 기능 구현 (feat)
- 버그 수정 (fix)
- 리팩토링 (refactor)

**수동 호출**: `/infinite-loop`

### 5.3 자동화 체크리스트

**코드 작업 시작 전:**
- [ ] 작업 범위 확인
- [ ] 영향 받는 파일 목록 파악

**코드 작업 완료 후 (자동 실행):**
- [ ] Layer 1: TypeScript 빌드 검증 (app + server)
- [ ] Layer 1: ESLint 코드 품질 검사
- [ ] Layer 2: 단위 테스트
- [ ] 실패 시 자동 수정 (최대 3회)

---

## 6. 병렬 실행 가이드 - v3.5 신규

### 6.1 5개 Claude 동시 운영

**작업 영역 분리 (필수)**:

| 터미널 | 담당 영역 | 주요 디렉토리 |
|--------|----------|--------------|
| Claude 1 | API 개발 | `server/src/routes/`, `server/src/services/` |
| Claude 2 | 프론트엔드 | `app/src/components/`, `app/src/pages/` |
| Claude 3 | 상태 관리 | `app/src/stores/`, `app/src/hooks/` |
| Claude 4 | 테스트/문서 | `__tests__/`, `.0/` |
| Claude 5 | 버그 수정 | 특정 이슈에 집중 |

**원칙**: 같은 파일을 2개 이상의 Claude가 동시에 수정하지 않음

### 6.2 충돌 방지

| 영역 | 충돌 여부 | 대응 |
|------|----------|------|
| Sequential Thinking | 없음 | 자동 |
| Chrome/Playwright MCP | 없음 | 새 탭만 사용 |
| **로컬 빌드** | 있음 | **1개 Claude만 담당** |
| **Git 커밋** | 있음 | **순차 실행**, git pull 필수 |

### 6.3 실행 예시

```bash
# 터미널 1 - API
cd ~/project/post_style && claude
> "server/src/routes/ API 최적화"

# 터미널 2 - 프론트엔드
cd ~/project/post_style && claude
> "app/src/components/ UI 개선"

# 터미널 3 - 상태 관리
cd ~/project/post_style && claude
> "app/src/stores/ Zustand 리팩토링"

# 터미널 4 - 테스트
cd ~/project/post_style && claude
> "테스트 케이스 추가"

# 터미널 5 - 버그 수정
cd ~/project/post_style && claude
> "#123 이슈 버그 수정"
```

---

## 7. Plan 모드 워크플로우 - v3.5 신규

**대부분의 세션을 Plan 모드에서 시작**

1. Plan 모드에서 계획 수립
2. 계획을 여러 번 수정
3. 마음에 드는 계획이 나왔을 때 Auto 모드로 실행
4. 대부분 한 번에 원하는 결과 달성

**반복 워크플로우는 커맨드로 저장**:
- `.claude/commands/` 디렉토리에 저장
- 팀원과 공유
- 토큰 절약 효과

---

## 8. 체크리스트

### Pre-Commit
```
[ ] Layer 0: 새 DB 테이블/컬럼 검증 (--schema)
[ ] Layer 1: cd app && pnpm build
[ ] Layer 1: cd server && pnpm build
[ ] Layer 1: pnpm lint (있는 경우)
```

### Pre-Deploy
```
[ ] Layer 0-4 모두 통과
[ ] git push 완료
```

### Post-Deploy
```
[ ] Layer 6: 에러 로그 확인 (--monitor)
[ ] Layer 4-B: 프로덕션 E2E 검증 (Chrome MCP)
```

---

## 9. CLI 사용법

```bash
# 전체 검증 (Layer 0-4)
./scripts/aegis-validate.sh --all

# 스키마 검증만 (Layer 0)
./scripts/aegis-validate.sh --schema <table> <column>

# 빌드 검증만 (Layer 1)
./scripts/aegis-validate.sh --build

# API 테스트만 (Layer 3)
./scripts/aegis-validate.sh --api

# 배포 후 모니터링 (Layer 6)
./scripts/aegis-validate.sh --monitor
```

---

## 10. 버전 히스토리

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| v1.0 | - | 기본 5단계 체크리스트 |
| v2.0 | - | Cognitive Layer 추가 |
| v3.0 | - | 7-Layer 시스템으로 개편 |
| v3.1 | 2026-01-04 | npm → pnpm 전환 |
| **v3.5** | **2026-01-06** | **Unified** - Automation Layer (Feedback/Infinite Loop), 병렬 실행 가이드, Plan 모드 워크플로우, CI/CD/Observability/Resource Layer 추가 |

---

**Last Updated**: 2026-01-06
**Maintainer**: Claude AI & minjaebaak
