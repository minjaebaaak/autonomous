# /autonomous v3.0

> **Claude Code를 위한 자율 실행 모드 - 범용 프레임워크**
>
> AEGIS + Ralph Loop + Phase 0 강제 + 에이전트 결과 검증 + 문서 동기화 + 양방향 동기화

`/autonomous [작업]` 하나로 모든 최적화가 자동 적용됩니다.

---

## v3.0: 범용화

v3.0에서 프로젝트 특화 내용을 모두 분리했습니다:

| 구분 | 위치 | 역할 |
|------|------|------|
| **범용 autonomous.md** | `~/.claude/commands/` (전역) | 지혜의 집약체 — 모든 프로젝트에 적용 |
| **프로젝트 Phase 확장** | 각 프로젝트 `CLAUDE.md` 하단 | 기술문서 경로, 섹션 매핑, 배포 명령어 |
| **프로젝트 아카이브** | `projects/[프로젝트명]/` | 교훈 원본, Phase 확장 백업, 설명 |

**핵심 설계**:
- autonomous.md = 범용 1개만 (전역 = 레포)
- 프로젝트별 autonomous.md 생성 금지 (전역 오버라이드 문제)
- CLAUDE.md는 항상 로드됨 → Phase 확장이 자동으로 합쳐짐

---

## 자동 활성화 기능

| 기능 | 설명 | 상태 |
|------|------|------|
| **Phase 0 강제** | 작업 전 기술문서 확인 필수 (건너뛰기 불가) | ✅ 자동 (v2.8) |
| **에이전트 결과 검증** | 서브에이전트 보고값 원본 대조 필수 | ✅ 자동 (v2.9) |
| **양방향 동기화** | 프로젝트 교훈 → 범용화 | ✅ 자동 (v3.0) |
| **기술문서 참조** | 작업 전 프로젝트 기술문서에서 파일/함수 확인 | ✅ 자동 |
| **문서 업데이트** | 코드 변경 후 관련 문서 자동 업데이트 | ✅ 자동 |
| **autonomous 자동 커밋** | autonomous.md 개선 시 자동 git 반영 | ✅ 자동 (v2.5) |
| **커밋 전 문서 확인** | 문서 업데이트 강제 확인 | ✅ 자동 (v2.6) |
| **AEGIS Protocol** | 7-Layer 검증 프레임워크 | ✅ 자동 |
| **ultrathink** | 심층 분석 모드 | ✅ 자동 |
| **Sequential Thinking** | 복잡한 문제 시 단계별 사고 | ✅ 필요 시 |
| **TodoWrite** | 진행 추적 | ✅ 자동 |
| **피드백 루프** | 완료 후 자동 검증 (3회) | ✅ 자동 |
| **랄프 루프** | 목표 달성까지 무한 반복 (최대 10회) | ✅ 자동 |

---

## 설치

### 전역 설치 (권장)

```bash
# autonomous.md 전역 설치
mkdir -p ~/.claude/commands
curl -o ~/.claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md
```

### CLAUDE.md 포함 설치

한국어 응답 및 기본 행동 규칙을 포함한 CLAUDE.md도 함께 설치합니다:

```bash
mkdir -p ~/.claude/commands
curl -o ~/.claude/CLAUDE.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/CLAUDE.md
curl -o ~/.claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md
```

> **CLAUDE.md vs autonomous.md**
> - `CLAUDE.md`: 프로젝트 규칙 (언어, 행동 방식, Phase 확장 가이드)
> - `autonomous.md`: 실행 모드 커맨드 (어떻게 작업할지)

### 프로젝트 Phase 확장 설정

> **주의**: 프로젝트 `.claude/commands/autonomous.md`를 생성하지 마세요.
> 프로젝트 로컬 파일이 전역 범용 autonomous.md를 오버라이드합니다.
> 프로젝트 특화 설정은 반드시 CLAUDE.md "Phase 확장" 섹션에만 추가하세요.

전역 설치 후, 각 프로젝트 CLAUDE.md 하단에 Phase 확장 섹션을 추가하세요:

```markdown
## /autonomous Phase 확장 설정

### Phase 0 확장: 기술문서
| 문서 | 경로 | 용도 |
|------|------|------|
| **기술표** | `docs/technical-reference.html` | 파일/함수/의존성 참조 |

### Phase 0 확장: 섹션 매핑
| 작업 유형 | 참조 섹션 |
|----------|---------|
| UI 페이지 | 프론트엔드 |
| API 작업 | 백엔드 |

### Phase 2 확장: 파일→문서 매핑
| 수정 영역 | 업데이트 섹션 |
|----------|-------------|
| frontend/ | 프론트엔드 |
| backend/api/ | API 문서 |

### Phase 7 확장: 검증/배포 명령어
# (프로젝트별 빌드/테스트/배포 명령어)
```

---

## 사용법

```
/autonomous 배포해줘
/autonomous REST API 만들어줘
/autonomous 버그 수정해줘
```

---

## 양방향 동기화

### 범용 autonomous.md 수정 시
```
1. ~/.claude/commands/autonomous.md 수정
2. autonomous_temp/.claude/commands/에 복사
3. README.md 업데이트
4. autonomous 레포 커밋 & 푸시
→ 모든 프로젝트에 즉시 반영 (전역)
```

### 프로젝트 교훈 → 범용화
```
1. 프로젝트 CLAUDE.md Phase 확장에 기록
2. 범용화 가능 → autonomous.md에 추상화 반영
3. autonomous_temp/projects/[프로젝트]/에 원본 백업
4. autonomous 레포 커밋 & 푸시
```

### 프로젝트 추가 방법
```
1. 전역 autonomous.md 설치 (이미 되어있으면 생략)
2. 프로젝트 CLAUDE.md에 "Phase 확장" 섹션 추가
3. (선택) autonomous_temp/projects/[프로젝트]/ 디렉토리 생성
   - CLAUDE-ext.md: Phase 확장 백업
   - autonomous-history.md: 교훈 아카이브
   - README.md: 프로젝트 설명
```

---

## Phase 구조

| Phase | 이름 | 설명 |
|-------|------|------|
| **Phase 0** | 사전 점검 | 기술문서 읽기 + 섹션 매핑 (CLAUDE.md Phase 확장 참조) |
| **Phase 1** | 초기화 | 상태 파일 생성, TodoWrite 설정 |
| **Phase 2** | 문서 업데이트 | 코드 변경 후 기술문서 업데이트 (CLAUDE.md 매핑 참조) |
| **Phase 3** | autonomous 동기화 | autonomous.md 변경 시 전역 + 레포 동기화 |
| **Phase 3.5** | 양방향 동기화 | 프로젝트 교훈 범용화, CLAUDE.md Phase 확장 백업 |
| **Phase 4** | AEGIS 인지 레이어 | ultrathink, Sequential Thinking, TodoWrite |
| **Phase 5** | 자율 실행 | 사용자 의도 확인, 모호성 즉시 확인 |
| **Phase 5.5** | 에이전트 검증 | 에이전트 결과 원본 대조 |
| **Phase 6** | 커밋 전 문서 확인 | 문서 업데이트 없이 커밋 금지 |
| **Phase 7** | AEGIS 검증 | 빌드 검증, 배포, 프로덕션 확인 |
| **Phase 8** | 피드백 루프 | 검증 실패 시 자동 수정 (최대 3회) |
| **Phase 9** | 랄프 루프 | 목표 달성까지 무한 반복 (최대 10회) |

---

## 랄프 루프 (Ralph Wiggum Mode)

### 놀이터 철학

> 랄프가 놀이터를 짓고 미끄럼틀에서 뛰어내리다 다칩니다(실패).
> 그러면 '뛰어내리지 마시오' 표지판(테스트)을 세웁니다.
> 다음번에는 표지판을 보고 안전하게 타고 내려옵니다.
> **실패할 때마다 표지판(검증 규칙)을 세워가며 완벽한 놀이터를 완성!**

### 작동 방식

```
Claude will:
1. Work on the task (작업 수행)
2. Try to exit (종료 시도)
3. Stop hook blocks exit (Stop 훅이 종료 차단)
4. Same prompt fed back (초기 프롬프트 재입력)
5. Repeat until RALPH_DONE (RALPH_DONE 출력까지 반복)
```

| 요소 | 설명 |
|------|------|
| **local.md** | 프롬프트/상태 기록으로 컨텍스트 유지 |
| **Stop 훅 연동** | 종료 시도 차단 메커니즘 |
| **RALPH_DONE** | 명시적 종료 조건 |
| **표지판 추가** | 실패 시 새로운 검증 규칙/테스트 추가 |

---

## 비상 정지

```bash
touch ~/.claude/state/EMERGENCY_STOP
```

---

## 프로젝트 디렉토리

| 프로젝트 | 디렉토리 | 설명 |
|---------|---------|------|
| ShareManager | `projects/sharemanager/` | SERP 모니터링 서비스 — autonomous 탄생 프로젝트 |

---

## 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| **v3.0** | **2026-02-06** | **범용화 완료**: 프로젝트 특화 분리, Phase 확장 체계, 양방향 동기화 |
| v2.9 | 2026-02-06 | Phase 5.5 에이전트 결과 검증 추가, Phase 5 자율실행 규칙 개선 |
| v2.8 | 2026-02-06 | Phase 0 강제 도입 (기술표 미확인 방지) |
| v2.7 | 2026-02-05 | CLAUDE.md 타임존 규칙, autonomous 전역 관리 규칙 추가 |
| v2.6 | 2026-02-05 | 문서 동기화 시스템, Phase 3.5 커밋 전 문서 확인 강제 |
| v2.5 | 2026-02-04 | autonomous.md 자동 커밋 & 푸시 |
| v2.2 | 2026-01-19 | 랄프 루프 완전 통합 (놀이터 철학, local.md, Stop 훅) |
| v2.1 | 2026-01-19 | 랄프 루프 기본 추가 |
| v2.0 | 2026-01-19 | AEGIS Protocol 통합 |

---

## 라이선스

MIT License
