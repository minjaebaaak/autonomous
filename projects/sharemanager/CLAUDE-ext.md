# ShareManager - /autonomous Phase 확장 설정

> ShareManager 프로젝트의 CLAUDE.md에 포함된 Phase 확장 섹션의 백업/템플릿입니다.
> 실제 운영본: `sharemanager/CLAUDE.md` 하단의 "/autonomous Phase 확장 설정" 섹션
> 백업 날짜: 2026-02-23

---

## Phase 0 확장: 기술문서

- `docs/technical-reference.html` + `PROJECT_DOCUMENTATION.md`
- 기술표 섹션 가이드는 `/checklist-bug` 참조

## Phase 0 확장: NotebookLM (카테고리별 노트북 v4.7)

- 규칙: `nlm notebook query sm-rules "..."` (= `139b4dd6-a8e2-448d-86b7-f3c4f572e24b`)
- 대화: `nlm notebook query sm-conv "..."` (= `65e68fc7-a8ff-43a9-b9f9-19566cbd2709`)
- 기술: `nlm notebook query sm-tech "..."` (= `8502add4-4166-459e-8a8f-3fdcec505215`)
- sm alias = sm-rules (하위 호환)
- 문서 동기화: `bash scripts/nlm-sync.sh <파일>` (카테고리 자동 분류)
- 대화 동기화: `bash scripts/conversation-sync.sh` → sm-conv
- 로컬 인덱스: `~/.claude/conversation-index.json` (캐시 + 보완)

## Phase 0 확장: repomix 설정

- includePatterns: `backend/app/**/*.py,frontend/app/**/*.tsx,frontend/lib/**/*.ts,frontend/components/**/*.tsx`
- ignorePatterns: `node_modules/**,venv/**,__pycache__/**,.next/**,*.pyc`
- compress: true (항상)
- 출력 디렉토리: `docs/repomix/` (attach_packed_output 우선 사용)

## Phase 0 확장: 대화 동기화 (v4.7)

- 세션 JSONL: `~/.claude/projects/-Users-minjaebaak-Desktop-Develop-project-sharemanager/*.jsonl`
- Stop 훅: 세션 종료 시 자동 업로드 (10턴+, 5KB+ 조건)
- 수동 동기화: `bash scripts/conversation-sync.sh --title "<작업명>"`
- 노트 네이밍: `{타이틀}-{YYYY-MM-DD}-{순번}-{HHMM}` (크기 기반 멀티 노트)
- 타이틀: `--title` 미지정 시 첫 사용자 메시지에서 주제 자동 추출

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
