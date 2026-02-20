# /autonomous v4.2

> **Claude Code를 위한 자율 실행 모드 - 범용 프레임워크**
>
> AEGIS + Ralph Loop + Phase 0 강제 + 에이전트 결과 검증 + 문서 동기화 + 양방향 동기화 + Agent Teams 필수 판단 + 자동 커밋 + NotebookLM 통합

`/autonomous [작업]` 하나로 모든 최적화가 자동 적용됩니다.

---

## 최신 변경사항

### v4.2: Phase 0 복잡도 기반 분기 (2026-02-20)

- **Phase 0 Step 0 신설**: 작업 복잡도 판정 (Simple/Complex) 필수 출력
- **Simple** (텍스트 교체, 스타일링, 오타): grep만으로 충분 → nlm/기술문서 Read 생략
- **Complex** (코드 로직, 버그, 새 기능): nlm query 강제 (v4.1 유지)
- **배경**: v4.1에서 nlm 강제했으나, 간단한 작업에서도 "불필요" 자체 판단으로 건너뜀
  - 원인: "모든 작업에 nlm"은 비효율 → Claude가 합리적으로 건너뜀
  - 해결: 복잡도 분기로 Simple은 공식적으로 면제, Complex만 강제

### v4.1: Phase 0 nlm query 강제 실행 (2026-02-20)

- **Phase 0 Step 1**: 선언적 지시 → 절차적 Bash 명령으로 전환
- `nlm notebook query` 실행을 구체적 코드 블록으로 명시
- `Read 도구로 기술문서 직접 읽기 금지` 명시적 금지 추가

### v4.0: NotebookLM 자동 동기화 (2026-02-20)

- **Phase 6.5**: 커밋 후 NotebookLM 소스 자동 동기화 (문서 변경 감지 → `nlm-sync.sh` 실행)
- nlm 실패 시 경고만 출력 (블로커 아님)

### v3.9: Phase 0 NotebookLM 질의 통합 (2026-02-20)

- **Phase 0 Step 1**: 기술문서 직접 Read → `nlm notebook query` 우선 사용
- NotebookLM 설정이 CLAUDE.md에 있으면 자동 활성화
- nlm 실패 시 직접 Read fallback

### v3.8 이전 변경사항
- **v3.8**: 횡단 관심사 계층별 sweep (Phase 5.9)
- **v3.7**: 사용자 여정 일관성 (Phase 5.8)
- **v3.6**: 작업 완료 자동 commit & push (Phase 6.5)
- **v3.5**: Source-Sink 정합성 (Phase 5.6) + 멱등성 원칙 (Phase 5.7)
- **v3.0**: 범용화 완료 — 프로젝트 특화 분리, Phase 확장 체계

---

## 🔭 미래 방향

autonomous는 세 가지 축을 중심으로 진화합니다.

### 축 1: 지식 외재화 — "컨텍스트 윈도우 밖으로"

**문제**: Claude Code의 컨텍스트 윈도우는 유한합니다. CLAUDE.md(~18K 토큰) + MEMORY.md(~4.5K 토큰) = 매 턴 ~22.5K 토큰이 자동 소비됩니다. 프로젝트가 커지면 규칙/경험/문서가 증가하고, 컨텍스트 윈도우 대비 자동 소비 비율이 위험 수준에 도달합니다.

**해결 방향**:
```
Phase 1 (완료): CLAUDE.md/MEMORY.md 압축 → ~2,900 토큰/턴 절약
Phase 2 (완료): NotebookLM에 지식 외재화 → Phase 0에서 ~47K 토큰 절약
Phase 3 (계획): 규칙/교훈의 자동 분류 → 빈번한 것만 CLAUDE.md에 유지
Phase 4 (구상): MCP 서버 없이 외부 지식 접근 → CLI 기반 질의로 상시 비용 0
```

**핵심 원칙**: 자주 참조하는 지식은 가까이(CLAUDE.md), 가끔 참조하는 지식은 멀리(NotebookLM) — 캐시 계층 구조와 동일한 철학.

### 축 2: 자율 학습 루프 — "실수에서 규칙으로"

**현재 메커니즘**:
```
실수 발생 → 교훈 추출 → CLAUDE.md/MEMORY.md에 기록 → 규칙화
→ 범용화 가능하면 autonomous.md에 추상화 버전 추가
→ NotebookLM에 동기화 (v4.0)
```

**미래 목표**:
- 교훈의 "빈도 기반 승격/강등" — 3회 이상 참조된 교훈은 자동으로 CLAUDE.md Tier 1 후보
- 6개월간 미참조 규칙은 MEMORY.md → NotebookLM으로 아카이브 제안
- 프로젝트 간 교훈 교차 검증 — 2개+ 프로젝트에서 동일 패턴 발견 시 자동 범용화 후보

### 축 3: 다중 프로젝트 확장 — "하나의 지혜, 여러 프로젝트"

**현재 구조**:
```
autonomous.md (범용, 전역)
  └─ CLAUDE.md Phase 확장 (프로젝트별)
       ├─ ShareManager: SERP 모니터링 (탄생 프로젝트)
       └─ (미래 프로젝트들)
```

**확장 시 검증할 가설**:
- 범용 autonomous.md가 다른 기술 스택(Django, Vue, Go 등)에서도 유효한가?
- Phase 확장 체계가 프로젝트 규모에 따라 스케일하는가?
- 프로젝트 간 교훈 이전이 실제로 생산성을 높이는가?

---

## 📚 규칙/경험/기억 관리 체계

autonomous 생태계는 4계층으로 지식을 관리합니다. 각 계층은 접근 속도, 용량, 지속성이 다릅니다.

### 아키텍처 개요

```
┌──────────────────────────────────────────────────────────────┐
│                    지식 관리 4계층 아키텍처                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  L1: autonomous.md (범용 원칙)                                │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: ~/.claude/commands/ (전역)  │  매 /autonomous 호출 시 │
│  │ 크기: ~520줄, ~15K 토큰          │  자동 로드             │
│  │ 수명: 영구 (전 프로젝트 공유)     │                        │
│  │ 내용: Phase 체계, 검증 원칙,     │                        │
│  │       자가 점검, 에이전트 규칙    │                        │
│  └──────────────────────────────────┘                        │
│       ↕ 양방향 동기화 (교훈 범용화)                            │
│  L2: CLAUDE.md (프로젝트 규칙)                                │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: 프로젝트 루트              │  매 턴 자동 로드        │
│  │ 크기: ~1100줄, ~18K 토큰         │  (항상 컨텍스트에)     │
│  │ 수명: 프로젝트 생애주기          │                        │
│  │ 내용: Tier 1 원칙, Tier 2 체크,  │                        │
│  │       Tier 3 도메인, Phase 확장  │                        │
│  └──────────────────────────────────┘                        │
│       ↕ 세션 간 학습 전이                                     │
│  L3: MEMORY.md (세션 간 기억)                                 │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: ~/.claude/projects/...     │  매 턴 자동 로드        │
│  │ 크기: ~80줄, ~4.5K 토큰          │  (200줄 초과 시 잘림)  │
│  │ 수명: 프로젝트 생애주기          │                        │
│  │ 내용: 핵심 정보 요약, 교훈 색인, │                        │
│  │       운영 가이드, 패턴 기록      │                        │
│  └──────────────────────────────────┘                        │
│       ↕ 외재화 (무제한 저장)                                   │
│  L4: NotebookLM (외부 지식 저장소)                             │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: Google NotebookLM (클라우드)│  nlm query 시에만 접근  │
│  │ 크기: 무제한                      │  (상시 비용 0)         │
│  │ 수명: 영구                       │                        │
│  │ 내용: 기술표 전문, 프로젝트 문서, │                        │
│  │       교훈 원본, 코드 묶음        │                        │
│  └──────────────────────────────────┘                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 계층별 상세

#### L1: autonomous.md — 범용 원칙 (전역 SSOT)

| 항목 | 설명 |
|------|------|
| **위치** | `~/.claude/commands/autonomous.md` |
| **로드 시점** | `/autonomous` 커맨드 호출 시 |
| **SSOT** | 전역 파일이 유일한 원본. 레포는 복사본 |
| **수정 규칙** | 전역에서만 수정 → 레포에 복사 → 커밋 & 푸시 |
| **내용 범위** | Phase 0~9 체계, 검증 원칙(P1~P6), 에이전트 규칙, 자가 점검 질문 |
| **성장 방식** | 프로젝트 교훈 → 추상화 → 범용 원칙으로 승격 |

**핵심**: autonomous.md는 "어떤 프로젝트에서든 적용 가능한 원칙"만 포함합니다. 프로젝트 특화 내용(파일 경로, 배포 명령, 노트북 ID 등)은 포함하지 않습니다.

#### L2: CLAUDE.md — 프로젝트 규칙

| 항목 | 설명 |
|------|------|
| **위치** | 각 프로젝트 루트 `CLAUDE.md` |
| **로드 시점** | 매 턴 자동 (Claude Code 기본 동작) |
| **구조** | Tier 1(핵심 원칙) → Tier 2(체크리스트) → Tier 3(도메인) → Phase 확장 |
| **Phase 확장** | autonomous.md가 참조하는 프로젝트별 설정 (기술문서 경로, 섹션 매핑, 배포 명령) |
| **성장 방식** | 버그/실수 → 교훈 → 규칙 Tier에 추가 |

**핵심**: CLAUDE.md는 "이 프로젝트에서 반드시 지켜야 할 규칙"을 담습니다. autonomous.md의 범용 Phase가 CLAUDE.md의 Phase 확장을 참조하여 프로젝트별로 커스터마이징됩니다.

#### L3: MEMORY.md — 세션 간 기억

| 항목 | 설명 |
|------|------|
| **위치** | `~/.claude/projects/{project-hash}/memory/MEMORY.md` |
| **로드 시점** | 매 턴 자동 (Claude Code auto memory) |
| **제한** | 200줄 초과 시 잘림 → 핵심만 유지해야 함 |
| **내용** | 프로젝트 핵심 정보 요약, 교훈 색인, 운영 노하우 |
| **성장 방식** | 반복 패턴 확인 시 기록, 오래된 정보 정리 |

**핵심**: MEMORY.md는 "CLAUDE.md에 넣기엔 범용적이지 않지만, 세션마다 알아야 할 정보"를 담습니다. 200줄 제한 때문에 정기적인 압축이 필요합니다.

#### L4: NotebookLM — 외부 지식 저장소

| 항목 | 설명 |
|------|------|
| **위치** | Google NotebookLM (클라우드) |
| **접근 방식** | `nlm notebook query` CLI (상시 비용 0) |
| **용량** | 무제한 (여러 소스 업로드 가능) |
| **동기화** | 문서 변경 → 커밋 후 자동 `nlm-sync.sh` (v4.0) |
| **소스 예시** | 기술표(HTML→텍스트 변환), 프로젝트 문서, 교훈 원본, Repomix 코드 묶음 |

**핵심**: NotebookLM은 "컨텍스트 윈도우에 넣을 수 없는 대용량 지식"을 저장합니다. Phase 0에서 필요한 부분만 질의하여 토큰을 절약합니다.

### 지식 흐름도

```
실수/경험 발생
    │
    ▼
교훈 추출 (세션 내)
    │
    ├─→ MEMORY.md에 요약 기록 (L3)
    │
    ├─→ CLAUDE.md에 규칙 추가 (L2)
    │       │
    │       └─→ 범용화 가능? ──Yes──→ autonomous.md에 추상화 추가 (L1)
    │                                       │
    │                                       └─→ autonomous 레포 커밋
    │
    └─→ docs/claude-rules-lessons.md에 원본 보존
            │
            └─→ NotebookLM에 동기화 (L4, v4.0 자동)
```

---

## 🧠 컨텍스트 관리 전략

### 토큰 예산 구조

Claude Code의 컨텍스트 윈도우에서 자동 소비되는 토큰:

| 소스 | 크기 | 로드 시점 | 비고 |
|------|------|----------|------|
| CLAUDE.md | ~18K 토큰 | 매 턴 | 압축 후 (원래 ~23K) |
| MEMORY.md | ~4.5K 토큰 | 매 턴 | 압축 후 (원래 ~7K) |
| autonomous.md | ~15K 토큰 | /autonomous 시 | Phase 전체 |
| **합계** | **~37.5K 토큰/턴** | | /autonomous 세션 기준 |

### 최적화 결과 (v4.0 기준)

| 최적화 | 절약량 | 방법 |
|--------|--------|------|
| CLAUDE.md 압축 | ~5K 토큰/턴 | 교훈 블록 → 1줄 요약 + 원본 외부 파일 |
| MEMORY.md 압축 | ~2.5K 토큰/턴 | 중복 제거, 핵심만 유지 |
| Phase 0 nlm query | ~47K 토큰/세션 | 기술표 319KB Read → nlm query 3K 응답 |
| **총 절약** | **~7.5K/턴 + ~47K/세션** | |

### 미래 최적화 로드맵

```
현재 (v4.0):
  CLAUDE.md 18K + MEMORY.md 4.5K = 22.5K/턴 자동 소비
  Phase 0: nlm query 우선, fallback Read

목표 1 - 규칙 핫/콜드 분리:
  CLAUDE.md를 "hot rules"(자주 참조, ~10K)와 "cold rules"(가끔 참조, ~8K)로 분리
  cold rules는 NotebookLM으로 이동 → 필요 시 nlm query
  예상 효과: ~8K/턴 추가 절약

목표 2 - Phase 0 zero-read:
  기술표를 한 번도 Read하지 않고 nlm query만으로 Phase 0 완료
  현재: nlm 실패 시 fallback Read → 미래: nlm 안정화 후 fallback 제거

목표 3 - MEMORY.md 동적 로딩:
  MEMORY.md 200줄 제한 대신, 핵심 색인(~50줄)만 유지
  상세 내용은 topic 파일(debugging.md, patterns.md)로 분리
  필요 시 topic 파일 Read → 평소에는 색인만 로드
```

---

## 자동 활성화 기능

| 기능 | 설명 | 상태 |
|------|------|------|
| **Phase 0 강제** | 작업 전 기술문서 확인 필수 (건너뛰기 불가) | ✅ 자동 (v2.8) |
| **에이전트 결과 검증** | 서브에이전트 보고값 원본 대조 필수 | ✅ 자동 (v2.9) |
| **양방향 동기화** | 프로젝트 교훈 → 범용화 | ✅ 자동 (v3.0) |
| **Agent Teams 필수 판단** | 매 작업마다 팀원 필요 여부 판단 + 출력 의무 | ✅ 강제 (v3.2) |
| **Agent 결과 교차 검증** | Agent 보고 수량을 독립 Grep으로 교차 검증 + 결과 출력 | ✅ 강제 (v3.3) |
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
| **작업 완료 자동 커밋** | 작업 완료 시 자동 git commit & push | ✅ 강제 (v3.6) |
| **사용자 여정 일관성** | 단일 함수 정확성 ≠ 시스템 정확성 | ✅ 자동 (v3.7) |
| **횡단 관심사 sweep** | 전 계층 체크리스트 + ORM write path 추적 | ✅ 자동 (v3.8) |
| **NotebookLM 질의** | Phase 0에서 nlm query 우선 사용 | ✅ 자동 (v3.9) |
| **NotebookLM 자동 동기화** | 문서 커밋 후 NotebookLM 소스 자동 동기화 | ✅ 자동 (v4.0) |

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

- **Phase 0 기술문서**: `docs/technical-reference.html`. 섹션 매핑은 #14 참조.
- **Phase 0 NotebookLM**: 노트북 `{NOTEBOOK_UUID}`
  - 질의: `nlm notebook query "{NOTEBOOK_UUID}" "질의 내용"`
  - 기술표 동기화: `bash scripts/nlm-sync.sh docs/technical-reference.html`
  - 전체 동기화: `bash scripts/repomix-sync.sh`
  - 자동 동기화 대상: `docs/technical-reference.html`, `PROJECT_DOCUMENTATION.md`
- **Phase 2 파일→문서 매핑**: 매핑 규칙 정의.
- **Phase 7**: 검증/배포 명령어.
```

---

## 사용법

```
/autonomous 배포해줘
/autonomous REST API 만들어줘
/autonomous 버그 수정해줘
```

---

## 동기화 규칙 (전역 → 레포 단방향)

> **전역 파일(`~/.claude/commands/autonomous.md`)이 유일한 원본.**
> **레포의 autonomous.md를 직접 수정하면 전역과 불일치 발생 → 버전 혼동.**

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
3. (선택) NotebookLM 노트북 생성 + nlm-sync.sh 설정
4. (선택) autonomous_temp/projects/[프로젝트]/ 디렉토리 생성
   - CLAUDE-ext.md: Phase 확장 백업
   - autonomous-history.md: 교훈 아카이브
   - README.md: 프로젝트 설명
```

---

## Phase 구조

| Phase | 이름 | 설명 |
|-------|------|------|
| **Phase 0** | 사전 점검 | 기술문서 참조 — nlm query 우선, fallback Read (CLAUDE.md Phase 확장 참조) |
| **Phase 1** | 초기화 | 상태 파일 생성 |
| **Phase 2** | 문서 업데이트 | 코드 변경 후 기술문서 업데이트 (CLAUDE.md 매핑 참조) |
| **Phase 3** | autonomous 동기화 | autonomous.md 변경 시 전역 + 레포 동기화 |
| **Phase 3.5** | 양방향 동기화 | 프로젝트 교훈 범용화, CLAUDE.md Phase 확장 백업 |
| **Phase 4** | AEGIS 인지 레이어 | ultrathink, Sequential Thinking, TodoWrite |
| **Phase 4.5** | Agent Teams 필수 판단 | 매 작업마다 팀원 필요 여부 판단 + 출력 의무 |
| **Phase 5** | 자율 실행 | 사용자 의도 확인, 모호성 즉시 확인 |
| **Phase 5.5** | 에이전트 검증 | 에이전트 결과 원본 대조 |
| **Phase 5.6** | Source-Sink 정합성 | 데이터 저장/조회 대상 일치 확인 |
| **Phase 5.7** | 멱등성 원칙 | 반복 실행 로직 2회 이상 테스트 |
| **Phase 5.8** | 사용자 여정 일관성 | "계산이 맞다 ≠ 시스템이 맞다" |
| **Phase 5.9** | 횡단 관심사 sweep | 6계층 체크리스트 + ORM write path 추적 |
| **Phase 6** | 커밋 전 문서 확인 | 문서 업데이트 없이 커밋 금지 |
| **Phase 6.5** | 자동 커밋 & 동기화 | commit & push + NotebookLM 자동 동기화 |
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

## 가이드

| 가이드 | 경로 | 설명 |
|--------|------|------|
| **NotebookLM 세팅** | [`guides/notebooklm-setup.md`](guides/notebooklm-setup.md) | OS별(macOS/Linux/Windows) NotebookLM + Claude Code 통합 가이드 |

---

## 템플릿

프로젝트에 복사하여 사용하는 스크립트/설정 템플릿입니다.

| 템플릿 | 경로 | 설명 |
|--------|------|------|
| **nlm-sync.sh** | [`templates/nlm-sync.sh`](templates/nlm-sync.sh) | NotebookLM 소스 동기화 스크립트 (상단 수정 영역만 커스터마이징) |
| **repomix-sync.sh** | [`templates/repomix-sync.sh`](templates/repomix-sync.sh) | Repomix 코드 묶음 재생성 + NotebookLM 업로드 파이프라인 |
| **CLAUDE.md Phase 확장** | [`templates/claude-md-notebooklm-phase.md`](templates/claude-md-notebooklm-phase.md) | CLAUDE.md에 붙이는 NotebookLM Phase 확장 템플릿 |

### 템플릿 사용법 (Quick Start)

```bash
# 1. nlm-sync.sh 복사 + 실행 권한
cp templates/nlm-sync.sh 내프로젝트/scripts/nlm-sync.sh
chmod +x 내프로젝트/scripts/nlm-sync.sh

# 2. 상단 "프로젝트별 수정 영역"에서 노트북 ID + 파일 매핑 수정

# 3. CLAUDE.md Phase 확장 복사
cat templates/claude-md-notebooklm-phase.md >> 내프로젝트/CLAUDE.md
# → <YOUR_NOTEBOOK_ID> 교체

# 4. 동기화 테스트
zsh 내프로젝트/scripts/nlm-sync.sh CLAUDE.md
```

상세 절차: [`guides/notebooklm-setup.md`](guides/notebooklm-setup.md) 참조

---

## 프로젝트 디렉토리

| 프로젝트 | 디렉토리 | 설명 |
|---------|---------|------|
| ShareManager | `projects/sharemanager/` | SERP 모니터링 서비스 — autonomous 탄생 프로젝트 |

---

## 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| **v4.0** | **2026-02-20** | **NotebookLM 자동 동기화**: Phase 6.5에 문서 커밋 후 nlm-sync.sh 자동 실행 |
| **v3.9** | **2026-02-20** | **Phase 0 NotebookLM 질의**: 기술문서 직접 Read → nlm query 우선, fallback Read |
| v3.8 | 2026-02-19 | 횡단 관심사 계층별 sweep Phase 5.9 |
| v3.7 | 2026-02-15 | 사용자 여정 일관성 Phase 5.8 |
| v3.6 | 2026-02-12 | 작업 완료 자동 commit & push Phase 6.5 |
| v3.5 | 2026-02-12 | Source-Sink 정합성 (Phase 5.6) + 멱등성 원칙 (Phase 5.7) |
| v3.4 | 2026-02-12 | 에이전트 수량 제한 전면 해제 |
| v3.3 | 2026-02-12 | Agent 결과 교차 검증 강화 |
| v3.2 | 2026-02-07 | Agent Teams 필수 판단 강제화 |
| v3.1 | 2026-02-07 | Agent Teams 통합 |
| v3.0 | 2026-02-06 | 범용화 완료 — 프로젝트 특화 분리, Phase 확장 체계 |
| v2.9 | 2026-02-06 | Phase 5.5 에이전트 결과 검증 |
| v2.8 | 2026-02-06 | Phase 0 강제 도입 |
| v2.7 | 2026-02-05 | CLAUDE.md 타임존 규칙 |
| v2.6 | 2026-02-05 | 문서 동기화 시스템 |
| v2.5 | 2026-02-04 | autonomous.md 자동 커밋 & 푸시 |
| v2.2 | 2026-01-19 | 랄프 루프 완전 통합 |
| v2.1 | 2026-01-19 | 랄프 루프 기본 추가 |
| v2.0 | 2026-01-19 | AEGIS Protocol 통합 |

---

## 라이선스

MIT License
