# NAVIFACT - /autonomous Phase 확장 설정

> NAVIFACT 프로젝트의 CLAUDE.md Phase 확장 설정 백업/템플릿입니다.
> 실제 운영본: `NAVIFACT/CLAUDE.md` 하단의 "/autonomous Phase 확장 설정" 섹션
> 백업 날짜: 2026-02-27

---

## Phase 0 확장: 기술문서

- 아키텍처 플랜: `~/.claude/plans/recursive-imagining-lamport.md`
- 시드 데이터: `apps/web/data/seed/tariff-*.json` (6개 파일)

## Phase 0 확장: repomix 설정

- includePatterns: `apps/web/app/**/*.tsx,apps/web/components/**/*.tsx,apps/web/lib/**/*.ts,apps/api/app/**/*.py,apps/api/scripts/**/*.py`
- ignorePatterns: `node_modules/**,__pycache__/**,.next/**,*.pyc,venv/**`
- compress: true
- 출력 디렉토리: 프로젝트 루트

## Phase 2 확장: 파일→문서 매핑

| 수정 영역 | 업데이트 대상 |
|----------|-------------|
| `apps/web/components/graph/` | 플랜 "시각화 모드" 섹션 |
| `apps/web/components/timeline/` | 플랜 "시각화 모드" 섹션 |
| `apps/web/lib/data.ts` | 플랜 "데이터 접근 레이어" 섹션 |
| `apps/api/app/models/` | 플랜 "핵심 데이터 모델" 섹션 |
| `apps/api/app/api/v1/` | 플랜 "주요 API 엔드포인트" 섹션 |
| `apps/api/scripts/seed_data.py` | 플랜 "시드 데이터" 섹션 |
| `infrastructure/docker/` | 플랜 "기술 스택" 섹션 |

## Phase 7 확장: 검증 명령어

```bash
# Frontend
pnpm --filter @navifact/web build

# Backend (Docker 필요)
cd apps/api && python -m pytest tests/ -v
```

## Phase 7 확장: 배포 명령어

```bash
# 미설정 (로컬 개발 단계)
# Docker Compose로 인프라 시작:
cd infrastructure/docker && docker compose up -d

# 백엔드 시드 데이터:
cd apps/api && python -m scripts.seed_data

# 백엔드 실행:
cd apps/api && uvicorn app.main:app --reload --port 8000

# 프론트엔드 실행:
pnpm --filter @navifact/web dev
```
