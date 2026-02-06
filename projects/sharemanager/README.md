# ShareManager 프로젝트

> 네이버/구글 검색 결과 모니터링 및 경쟁사 분석 서비스

## 기술 스택
- **Backend**: FastAPI (Python)
- **Frontend**: Next.js, React, TypeScript
- **Database**: SQLite
- **배포**: PM2 + serpering.com

## autonomous 연동

### 구조 (v3.0)
```
sharemanager/
├── CLAUDE.md                           # 프로젝트 규칙 + Phase 확장 설정
├── .claude/commands/                   # 프로젝트 커맨드 (autonomous.md 없음!)
│   ├── commit.md, deploy.md ...       # 프로젝트 전용 커맨드
│   └── (autonomous.md 삭제됨)         # → 전역 범용 v3.0 사용
└── docs/technical-reference.html       # Phase 0에서 참조하는 기술문서
```

### Phase 확장 위치
- **CLAUDE.md 하단**: "/autonomous Phase 확장 설정" 섹션
- Phase 0 확장: 기술문서 경로, 섹션 매핑
- Phase 2 확장: 파일→문서 매핑
- Phase 7 확장: 검증/배포 명령어

### 교훈 기록
- `autonomous-history.md`: v2.0~v2.9 교훈 아카이브
- `CLAUDE-ext.md`: Phase 확장 설정 백업/템플릿

## 히스토리
- 2026-01-19: autonomous v2.0 AEGIS 통합의 원조 프로젝트
- 2026-02-06: v3.0 범용화 — 프로젝트별 autonomous.md 삭제, Phase 확장으로 전환
