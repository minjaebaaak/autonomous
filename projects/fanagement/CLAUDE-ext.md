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

## /autonomous Phase 확장 설정

### Phase 6.5 확장: 배포
배포 명령어 (Mac에서 SSH로 실행):
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
