# NAVIFACT 프로젝트

> 팩트 기반 역사적 사건 추적 포털 — "진실을 향한 내비게이션"

## 기술 스택
- **Frontend**: Next.js 15 (App Router) + TypeScript + Tailwind CSS v4
- **Backend**: FastAPI (Python) + Pydantic v2
- **Graph DB**: Neo4j 5 (인과관계 체인)
- **Relational DB**: PostgreSQL 17 + pgvector
- **Cache/Queue**: Redis 7
- **Search**: Meilisearch v1.12
- **Graph Viz**: React Flow v12 (@xyflow/react) + D3.js
- **Monorepo**: Turborepo + pnpm

## autonomous 연동

### 구조
```
NAVIFACT/
├── apps/
│   ├── web/                          # Next.js 15 프론트엔드
│   │   ├── app/(portal)/             # 공개 포털 (9개 라우트)
│   │   ├── components/               # 시각화 컴포넌트 (graph, timeline, narrative 등)
│   │   ├── lib/data.ts               # 데이터 접근 레이어 (API + 정적 폴백)
│   │   └── data/seed/                # 시드 JSON (한미 관세 시나리오)
│   └── api/                          # FastAPI 백엔드
│       ├── app/api/v1/               # 8 라우터, 23 엔드포인트
│       ├── app/models/               # Pydantic 스키마
│       ├── app/db/                   # Neo4j, PostgreSQL, Redis, Meilisearch
│       └── scripts/seed_data.py      # Neo4j 시드 (결정론적 UUID 매핑)
├── infrastructure/docker/            # Docker Compose (Neo4j+PG+Redis+Meili)
└── packages/shared-types/            # FE-BE 공유 타입
```

### Phase 확장 위치
- **CLAUDE.md** 미생성 상태 (Phase 확장 미설정)
- 향후 설정 시 이 파일에 백업

### 핵심 아키텍처 결정
1. **Neo4j 필수** — 5홉 인과관계 쿼리 (SQL로 불가)
2. **데이터 접근 레이어** — API fetch + static JSON fallback (ISR 60s)
3. **결정론적 UUID** — `uuid5(fixed_namespace, "evt-001")` 매핑
4. **검열 저항** — IPFS + Arweave + OpenTimestamps (Phase 3+)

## 히스토리
- 2026-02-27: 세션 1~3 — MVP 완성 (9개 라우트, 9개 시각화 컴포넌트, 시드 데이터)
- 2026-02-27: 세션 4 — 백엔드-프론트엔드 연결 (데이터 레이어, 시드 교체)
