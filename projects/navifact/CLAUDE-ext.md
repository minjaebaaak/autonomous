# 프로젝트 규칙

> NAVIFACT — "진실을 향한 내비게이션"
> 팩트 기반 역사적 사건 추적 포털

---

## 언어
- 한국어로 사고하고, 한국어로 소통할 것

## 행동 원칙
- 질문보다 실행 우선
- 오류 발생 시 자체 해결 시도 (최대 3회)
- TodoWrite로 진행 상황 추적

---

## 기술 스택

| 레이어 | 기술 |
|--------|------|
| **Frontend** | Next.js 15 (App Router) + TypeScript strict + Tailwind CSS v4 |
| **Backend** | FastAPI (Python) + Pydantic v2 |
| **Graph DB** | Neo4j 5 (인과관계 체인 — 핵심) |
| **Relational DB** | PostgreSQL 17 + pgvector |
| **Cache** | Redis 7 |
| **Search** | Meilisearch v1.12 |
| **Graph Viz** | React Flow v12 (@xyflow/react) + D3.js |
| **Monorepo** | Turborepo + pnpm |
| **Infra** | Docker Compose (Neo4j + PG + Redis + Meili) |

---

## 프로젝트 구조

```
NAVIFACT/
├── apps/
│   ├── web/                          # Next.js 15 프론트엔드
│   │   ├── app/(portal)/             # 공개 포털 (9개 라우트)
│   │   ├── components/               # 시각화 컴포넌트
│   │   │   ├── graph/                # CausalGraph, EventNode, CausalEdge
│   │   │   ├── timeline/             # InteractiveTimeline
│   │   │   ├── narrative/            # NarrativeComparison
│   │   │   ├── scorecard/            # TruthScorecard
│   │   │   ├── agreement/            # ObligationChecklist
│   │   │   ├── prediction/           # PredictionCard
│   │   │   └── shared/               # EventCard, VerificationBadge, ConfidenceMeter
│   │   ├── lib/
│   │   │   ├── data.ts               # 데이터 접근 레이어 (API + 정적 폴백)
│   │   │   └── api-client.ts         # 범용 API 클라이언트
│   │   └── data/seed/                # 시드 JSON 6개 (한미 관세 시나리오)
│   └── api/                          # FastAPI 백엔드
│       ├── app/api/v1/               # 8 라우터, 23 엔드포인트
│       ├── app/models/               # Pydantic 스키마
│       ├── app/db/                   # Neo4j, PostgreSQL, Redis, Meilisearch
│       └── scripts/seed_data.py      # Neo4j 시드 (결정론적 UUID 매핑)
├── infrastructure/docker/            # Docker Compose
└── packages/shared-types/            # FE-BE 공유 타입 (미구현)
```

---

## 핵심 아키텍처 결정

1. **데이터 접근 레이어 (`lib/data.ts`)**: API fetch → transform → 반환. 실패 시 정적 JSON 폴백. ISR 60초.
2. **결정론적 UUID**: `uuid5("a1b2c3d4-e5f6-7890-abcd-ef1234567890", "evt-001")` — 프론트/백엔드 ID 양방향 매핑.
3. **React Flow v12 제약**: Node/Edge data는 `Record<string, unknown>` 확장 필수. 인덱스 시그니처 추가.
4. **JSON import 타입**: TypeScript JSON import → union type이 string으로 추론됨. 명시적 type assertion 필요.
5. **Server/Client 경계**: 페이지 = Server Component (async). 인터랙티브 부분 = "use client" wrapper.

---

## autonomous.md 관리 규칙

> **autonomous.md = 범용 1개만. 프로젝트 특화 = CLAUDE.md Phase 확장.**

- 전역: `~/.claude/commands/autonomous.md` (범용)
- 프로젝트 로컬 autonomous.md 금지 (전역 오버라이드 방지)

---

## 계획 파일

- 아키텍처 플랜: `~/.claude/plans/recursive-imagining-lamport.md`

---

## /autonomous Phase 확장 설정

### Phase 0 확장: 기술문서

| 문서 | 경로 | 용도 |
|------|------|------|
| 아키텍처 플랜 | `~/.claude/plans/recursive-imagining-lamport.md` | 전체 설계, 데이터 모델, 시각화 모드 |
| 시드 데이터 | `apps/web/data/seed/tariff-*.json` (6개) | 한미 관세 시나리오 |

### Phase 0 확장: repomix 설정

- includePatterns: `apps/web/app/**/*.tsx,apps/web/components/**/*.tsx,apps/web/lib/**/*.ts,apps/api/app/**/*.py,apps/api/scripts/**/*.py`
- ignorePatterns: `node_modules/**,__pycache__/**,.next/**,*.pyc,venv/**`
- compress: true
- 출력 디렉토리: 프로젝트 루트

### Phase 2 확장: 파일→문서 매핑

| 수정 영역 | 업데이트 대상 |
|----------|-------------|
| `apps/web/components/graph/` | 플랜 "시각화 모드" 섹션 |
| `apps/web/components/timeline/` | 플랜 "시각화 모드" 섹션 |
| `apps/web/lib/data.ts` | 플랜 "데이터 접근 레이어" 섹션 |
| `apps/api/app/models/` | 플랜 "핵심 데이터 모델" 섹션 |
| `apps/api/app/api/v1/` | 플랜 "주요 API 엔드포인트" 섹션 |
| `apps/api/scripts/seed_data.py` | 플랜 "시드 데이터" 섹션 |
| `infrastructure/docker/` | 플랜 "기술 스택" 섹션 |

### Phase 7 확장: 검증 명령어

```bash
# Frontend 빌드
pnpm --filter @navifact/web build
```

### Phase 7 확장: 배포 명령어

```bash
# 로컬 개발 (프로덕션 배포 미설정)
# 인프라:
cd infrastructure/docker && docker compose up -d
# 시드:
cd apps/api && python -m scripts.seed_data
# 백엔드:
cd apps/api && uvicorn app.main:app --reload --port 8000
# 프론트엔드:
pnpm --filter @navifact/web dev
```

---

## API 타임존 규칙

> 모든 datetime API 응답에 타임존 정보 포함 필수

```python
# ✅ 필수
from datetime import timezone
dt.replace(tzinfo=timezone.utc).isoformat()

# ❌ 금지
dt.isoformat()  # 타임존 없음
```
