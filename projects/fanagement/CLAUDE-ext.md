# Fanagement

## 기술 스택
- Next.js 16.1.6 (App Router, Turbopack)
- SQLite (better-sqlite3) + Drizzle ORM
- Auth.js v5 (NextAuth)
- TypeScript, Tailwind CSS, shadcn/ui
- Zustand (클라이언트 상태)

## 개발/배포 환경
- **개발**: Mac (localhost:3000)
- **프로덕션**: Windows 데스크탑 + Cloudflare Tunnel
- **도메인**: https://fanagement.net
- **GitHub**: minjaebaaak/fanagement (private)

## SSH 접속 (Windows 서버)
- `ssh Admin@219.250.105.170` (같은 네트워크)
- 프로젝트 경로: `C:\Projects\fanagement`

## Windows 서버 프로세스 관리
- **Next.js**: WMIC로 시작 (Task Scheduler "Fanagement NextJS" 부팅 시 자동 시작)
- **Cloudflared**: WMIC로 시작 (Task Scheduler "Fanagement Tunnel" 부팅 시 자동 시작)
- **Tunnel UUID**: caca1423-5709-4502-93e9-b669a65a5507

---

## /autonomous Phase 확장 설정

### Phase 0 확장: 기술문서

| 문서 | 경로 | 용도 |
|------|------|------|
| **CLAUDE.md** | `CLAUDE.md` | 프로젝트 설정 + Phase 확장 |
| **DB 스키마** | `src/db/schema/` | 테이블 정의 |
| **라우트 맵** | `src/app/` | 페이지/API 구조 |

### Phase 0 확장: 섹션 매핑

| 작업 유형 | 참조 섹션 |
|----------|---------|
| DB/스키마 변경 | `src/db/schema/`, `src/db/client.ts` |
| 인증/로그인 | `src/lib/auth.ts`, `src/lib/auth.config.ts`, `middleware.ts` |
| API 엔드포인트 | `src/app/api/` |
| UI 컴포넌트 | `src/components/` |
| 고객 관리 | `src/app/admin/[brandSlug]/customers/` |
| 대시보드 | `src/app/admin/[brandSlug]/dashboard/` |
| 설정/커스텀필드 | `src/app/admin/[brandSlug]/settings/` |
| 스토어 (상태관리) | `src/stores/` |

### Phase 0 확장: repomix 설정

- includePatterns: `src/**/*.ts,src/**/*.tsx`
- ignorePatterns: `node_modules/**,.next/**,data/**`
- compress: true
- 출력 디렉토리: 프로젝트 루트 (attach_packed_output 우선 사용)

### Phase 2 확장: 파일→문서 매핑

| 수정 영역 | 업데이트 대상 |
|----------|-------------|
| `src/db/schema/` | CLAUDE.md 기술 스택 / DB 스키마 섹션 |
| `src/app/api/` | CLAUDE.md API 엔드포인트 목록 |
| `src/stores/` | CLAUDE.md 스토어 목록 |
| `.env.local` (Windows) | CLAUDE.md 환경변수 섹션 |
| 전체 아키텍처 변경 | CLAUDE.md 기술 스택 + 배포 환경 |

### Phase 6.5 확장: 배포

프로덕션 = 메인 환경 (Windows 데스크탑)

```bash
# 1. Mac에서 push
git push

# 2. Windows에서 pull + build
ssh Admin@219.250.105.170 "cd /d C:\Projects\fanagement && git pull && pnpm install && pnpm build"

# 3. Next.js 재시작
ssh Admin@219.250.105.170 "taskkill /F /IM node.exe 2>nul"
ssh Admin@219.250.105.170 "wmic process call create \"cmd.exe /c cd /d C:\Projects\fanagement && C:\Projects\fanagement\node_modules\.bin\next.CMD start\""

# 4. 검증 (8초 대기 후)
sleep 8 && curl -sI https://fanagement.net
```

### Phase 7 확장: 검증 명령어

```bash
# 빌드 검증
pnpm build

# 프로덕션 검증
curl -sI https://fanagement.net  # HTTP 200 확인
curl -s https://fanagement.net/api/auth/session  # null 또는 세션 반환

# Windows 프로세스 확인
ssh Admin@219.250.105.170 "tasklist /FI \"IMAGENAME eq node.exe\" /FO CSV /NH"
ssh Admin@219.250.105.170 "tasklist /FI \"IMAGENAME eq cloudflared.exe\" /FO CSV /NH"
```

---

## Agent Teams 운영

### SSOT 파일 (동시 수정 금지)
- `src/db/schema/` (DB 스키마)
- `src/lib/auth.ts` (인증 설정)
- `middleware.ts` (미들웨어)
- `CLAUDE.md` (프로젝트 문서)

---

## 주요 주의사항

### AUTH_TRUST_HOST
Cloudflare 프록시 뒤에서 Auth.js 사용 시 `.env.local`에 `AUTH_TRUST_HOST=true` 필수.
없으면 `UntrustedHost` 에러 발생.

### Windows SSH 프로세스 관리
SSH에서 Start-Process로 시작한 프로세스는 세션 종료 시 사라짐.
**반드시 `wmic process call create`로 분리된 프로세스 생성.**

### DB 경로 (Windows)
WMIC로 시작 시 작업 디렉토리가 달라짐.
`.env.local`에 **절대 경로** 사용: `DATABASE_PATH=C:\Projects\fanagement\data\fanagement.db`
