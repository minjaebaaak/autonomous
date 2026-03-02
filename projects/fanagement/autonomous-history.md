# Fanagement - Autonomous History

## 2026-03-03: 프로젝트 초기 설정

### 배포 아키텍처 결정
- Cloudflare Pages / Turso → 사용자가 거부 (자체 SQLite 유지)
- Fly.io 고려 → 사용자가 집 데스크탑 서버 선택
- **최종**: Windows 데스크탑 + Cloudflare Tunnel

### 해결된 이슈
1. **AUTH_TRUST_HOST**: Cloudflare 프록시 뒤에서 Auth.js v5 사용 시 필수
2. **WMIC 프로세스 관리**: SSH Start-Process는 세션 종료 시 프로세스 사라짐 → WMIC 사용
3. **cloudflared 서비스 경로**: LocalSystem은 systemprofile 경로 사용 → Task Scheduler로 대체
4. **config.yml 포맷**: Windows echo 명령의 trailing space 문제 → Mac에서 SCP로 전송

### 범용화 가능한 교훈
- "프록시 뒤의 Auth.js는 AUTH_TRUST_HOST=true 필수" → 범용 원칙
- "SSH에서 Windows 프로세스 지속: WMIC > Start-Process" → Windows 배포 시 범용 적용
