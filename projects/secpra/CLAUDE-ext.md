# SECPRA - 사회공학범죄대응협회

## 기술 스택
- Next.js 16 (App Router)
- TypeScript strict
- Tailwind CSS v4 + shadcn/ui
- pnpm

## 개발/배포 환경
- **개발**: Mac (localhost:3000)
- **프로덕션**: 자체 서버 (추후 설정)
- **도메인**: https://secpra.org
- **GitHub**: minjaebaaak/secpra (private)

---

## /autonomous Phase 확장 설정

### Phase 0 확장: 기술문서

| 문서 | 경로 | 용도 |
|------|------|------|
| **CLAUDE.md** | `CLAUDE.md` | 프로젝트 설정 + Phase 확장 |
| **라우트 맵** | `app/` | 페이지 구조 |
| **컴포넌트** | `components/` | UI 컴포넌트 목록 |

### Phase 0 확장: 섹션 매핑

| 작업 유형 | 참조 섹션 |
|----------|---------|
| 페이지/라우트 | `app/` |
| UI 컴포넌트 | `components/` |
| shadcn/ui 컴포넌트 | `components/ui/` |
| 아이콘 | `components/icons.tsx` |
| 유틸리티 | `lib/utils.ts` |
| 훅 | `hooks/` |
| 정적 자산 | `public/` |
| 스타일링 | `app/globals.css` |

### Phase 0 확장: repomix 설정

- includePatterns: `app/**/*.tsx,app/**/*.ts,components/**/*.tsx,lib/**/*.ts,hooks/**/*.ts`
- ignorePatterns: `node_modules/**,.next/**`
- compress: true
- 출력 디렉토리: 프로젝트 루트 (attach_packed_output 우선 사용)

### Phase 2 확장: 파일→문서 매핑

| 수정 영역 | 업데이트 대상 |
|----------|-------------|
| `app/` | CLAUDE.md 라우트 맵 |
| `components/` | CLAUDE.md 컴포넌트 목록 |
| 전체 아키텍처 변경 | CLAUDE.md 기술 스택 |

### Phase 6.5 확장: 배포

프로덕션 배포 (추후 서버 설정 시 업데이트):

```bash
# 1. push
git push

# 2. 서버에서 pull + build (서버 설정 후 업데이트)
# ssh user@server "cd /path/to/secpra && git pull && pnpm install && pnpm build"

# 3. 검증
# curl -sI https://secpra.org
```

### Phase 7 확장: 검증 명령어

```bash
# 빌드 검증
pnpm build

# 개발 서버 확인
pnpm dev

# 프로덕션 검증 (서버 설정 후)
# curl -sI https://secpra.org
```

---

## Agent Teams 운영

### SSOT 파일 (동시 수정 금지)
- `CLAUDE.md` (프로젝트 문서)
- `app/layout.tsx` (루트 레이아웃)
- `app/globals.css` (전역 스타일)
- `app/page.tsx` (랜딩 페이지 구성)

---

## 컴포넌트 목록

| 컴포넌트 | 경로 | 용도 |
|---------|------|------|
| Header | `components/header.tsx` | 고정 네비게이션 |
| Hero | `components/hero.tsx` | 메인 히어로 섹션 |
| About | `components/about.tsx` | 협회 소개 |
| Services | `components/services.tsx` | 서비스 안내 |
| Statistics | `components/statistics.tsx` | 활동 통계 |
| Resources | `components/resources.tsx` | 자료실 |
| News | `components/news.tsx` | 뉴스/보도자료 |
| Contact | `components/contact.tsx` | 문의/연락처 |
| Footer | `components/footer.tsx` | 푸터 |
| Experts | `components/experts.tsx` | 전문가 소개 |
| CaseStudies | `components/case-studies.tsx` | 사례 연구 |
| ThreatIntelligence | `components/threat-intelligence.tsx` | 위협 정보 |
| TrustIndicators | `components/trust-indicators.tsx` | 신뢰 지표 |
| Icons | `components/icons.tsx` | 아이콘 모음 |
| ThemeProvider | `components/theme-provider.tsx` | 테마 관리 |
