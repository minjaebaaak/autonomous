# ShareManager - /autonomous Phase 확장 설정

> ShareManager 프로젝트의 CLAUDE.md에 포함된 Phase 확장 섹션의 백업/템플릿입니다.
> 실제 운영본: `sharemanager/CLAUDE.md` 하단의 "/autonomous Phase 확장 설정" 섹션

---

## Phase 0 확장: 기술문서

| 문서 | 경로 | 용도 |
|------|------|------|
| **기술표 (메인)** | `docs/technical-reference.html` | 파일/함수/의존성/상태 전체 참조 |
| **프로젝트 문서** | `PROJECT_DOCUMENTATION.md` | 프로젝트 구조 SSOT |

## Phase 0 확장: 섹션 매핑

| 작업 유형 | 참조 섹션 |
|----------|---------|
| 파워링크/브랜드 콘텐츠/VIEW/뉴스 | **A. SERP 수집** |
| 네이버 로그인/세션/쿠키 | **B. 로그인/세션** |
| 자사 콘텐츠 표시/소유권 | **C. 소유권 감지** |
| 스크래핑/OCR/LLM 분석 | **D. 콘텐츠 분석** |
| 스케줄러/알림/배치 | **E. 모니터링** |
| 경쟁사 기능 | **F. 경쟁사 분석** |
| UI 페이지/버그 | **G. 프론트엔드** |
| 전체 구조 이해 | **H. 아키텍처** |

## Phase 2 확장: 파일→문서 매핑

> 코드 수정 후 기술표 업데이트 시 아래 매핑에 따라 해당 섹션 업데이트

| 수정 영역 | 업데이트 섹션 |
|----------|-------------|
| collectors/, serp_collector_service.py | A. SERP 수집 |
| auto_login_service.py, naver_*.py | B. 로그인/세션 |
| ownership_*, brand_checker.py | C. 소유권 감지 |
| enhanced_content_scraper.py, *_llm_*.py | D. 콘텐츠 분석 |
| scheduler_service.py, monitoring_*.py | E. 모니터링 |
| competitor_*.py | F. 경쟁사 분석 |
| frontend/ 페이지 컴포넌트 | G. 프론트엔드 |
| 전체 아키텍처 변경 | H. 아키텍처 |

## Phase 7 확장: 검증 명령어

```bash
# Backend
cd backend && source venv/bin/activate && python -m pytest tests/ -v

# Frontend
cd frontend && pnpm build:check
```

## Phase 7 확장: 배포 명령어

```bash
# 프론트엔드 배포
ssh arklink@39.121.73.114 "cd /home/arklink/Develop/project/sharemanager/frontend && git pull origin main && pnpm build && pm2 restart sharemanager-frontend"

# 백엔드 배포
ssh arklink@39.121.73.114 "cd /home/arklink/Develop/project/sharemanager/backend && git pull origin main && pm2 restart sharemanager-backend"

# 검증
ssh arklink@39.121.73.114 "pm2 status && curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:14567/ && curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:14566/api/v1/keywords/"
```
