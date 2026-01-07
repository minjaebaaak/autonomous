# AEGIS Protocol - 설치 가이드

## 요구사항

- macOS 또는 Linux
- Claude Code CLI
- Git
- Node.js (권장: 18+)
- pnpm 또는 npm

---

## 빠른 설치

### 1. AEGIS 저장소 클론

```bash
git clone git@github.com:minjaebaak/aegis-protocol.git
cd aegis-protocol
```

### 2. 프로젝트에 설치

```bash
./scripts/install.sh /path/to/your/project
```

### 3. 설정 파일 수정

프로젝트로 이동하여 다음 파일을 수정합니다:

```bash
cd /path/to/your/project

# CLAUDE.md 수정
vim CLAUDE.md

# 설정 파일 수정
vim aegis.config.js
```

---

## 수동 설치

자동 설치 대신 수동으로 설치하려면:

### 1. 디렉토리 복사

```bash
# .claude 디렉토리 복사
cp -r aegis-protocol/.claude/ your-project/.claude/

# .0 디렉토리 복사
cp -r aegis-protocol/.0/ your-project/.0/

# 스크립트 복사
cp -r aegis-protocol/scripts/ your-project/scripts/
```

### 2. 템플릿에서 설정 파일 생성

```bash
cp aegis-protocol/CLAUDE.md.template your-project/CLAUDE.md
cp aegis-protocol/templates/aegis.config.js.template your-project/aegis.config.js
```

### 3. 실행 권한 부여

```bash
chmod +x your-project/.claude/hooks/*.sh
chmod +x your-project/scripts/*.sh
```

---

## Hook 설정 (선택)

알림 기능을 사용하려면 `~/.claude/settings.json`에 다음을 추가합니다:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "*",
        "command": ".claude/hooks/notify-user.sh"
      }
    ],
    "Stop": [
      {
        "command": ".claude/hooks/notify-user.sh '사용자 입력 필요'"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": ".claude/hooks/post-tool-format.sh"
      }
    ]
  }
}
```

---

## 업그레이드

새 버전의 AEGIS Protocol로 업그레이드하려면:

```bash
# AEGIS 저장소 업데이트
cd aegis-protocol
git pull origin main

# 프로젝트에 재설치
./scripts/install.sh /path/to/your/project
```

> **주의**: 기존 CLAUDE.md와 aegis.config.js는 덮어쓰지 않습니다.

---

## 문제 해결

### Hook 스크립트가 실행되지 않음

1. 실행 권한 확인:
   ```bash
   ls -la .claude/hooks/
   ```

2. 권한 부여:
   ```bash
   chmod +x .claude/hooks/*.sh
   ```

### 알림이 오지 않음 (macOS)

1. 시스템 환경설정 > 알림 > 터미널(또는 osascript) 확인
2. 알림 권한이 활성화되어 있는지 확인

### Commands가 인식되지 않음

1. `.claude/commands/` 디렉토리가 존재하는지 확인
2. 파일 확장자가 `.md`인지 확인
3. Claude Code를 재시작

---

## 다음 단계

- [CONFIGURATION.md](./CONFIGURATION.md) - 설정 파일 가이드
- [COMMANDS.md](./COMMANDS.md) - 명령어 레퍼런스
