#!/bin/bash
#==============================================================================
# AEGIS Protocol v3.6 - 설치 스크립트
#==============================================================================
# 사용법: ./install.sh /path/to/your/project
#
# 이 스크립트는 AEGIS Protocol을 프로젝트에 설치합니다.
# 설치 후 CLAUDE.md와 aegis.config.js를 프로젝트에 맞게 수정하세요.
#==============================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# AEGIS 저장소 경로 (이 스크립트가 있는 위치 기준)
AEGIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${1:-.}"

# 절대 경로로 변환
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
    echo -e "${RED}Error: 프로젝트 경로가 존재하지 않습니다: $1${NC}"
    exit 1
}

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           AEGIS Protocol v3.6 Installation                   ║"
echo "║    Autonomous Enhanced Guard & Inspection System             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}AEGIS 저장소:${NC} $AEGIS_DIR"
echo -e "${YELLOW}설치 대상:${NC} $PROJECT_PATH"
echo ""

# 확인
read -p "계속하시겠습니까? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}설치가 취소되었습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[1/6] .claude/ 디렉토리 복사 중...${NC}"
#------------------------------------------------------------------------------
mkdir -p "$PROJECT_PATH/.claude/commands"
mkdir -p "$PROJECT_PATH/.claude/skills"
mkdir -p "$PROJECT_PATH/.claude/hooks"

# Commands 복사
if [ -d "$AEGIS_DIR/.claude/commands" ]; then
    cp -r "$AEGIS_DIR/.claude/commands/"*.md "$PROJECT_PATH/.claude/commands/" 2>/dev/null || true
    echo "  - commands/ 복사 완료 (commit, feedback-loop, infinite-loop, verify)"
fi

# Skills 복사
if [ -d "$AEGIS_DIR/.claude/skills" ]; then
    cp -r "$AEGIS_DIR/.claude/skills/"* "$PROJECT_PATH/.claude/skills/" 2>/dev/null || true
    echo "  - skills/ 복사 완료 (verify-app, code-simplifier)"
fi

# Hooks 복사
if [ -d "$AEGIS_DIR/.claude/hooks" ]; then
    cp -r "$AEGIS_DIR/.claude/hooks/"*.sh "$PROJECT_PATH/.claude/hooks/" 2>/dev/null || true
    echo "  - hooks/ 복사 완료 (notify-user, post-tool-format)"
fi

echo ""
echo -e "${BLUE}[2/6] .0/ 디렉토리 복사 중...${NC}"
#------------------------------------------------------------------------------
mkdir -p "$PROJECT_PATH/.0"
if [ -f "$AEGIS_DIR/.0/AEGIS_PROTOCOL.md" ]; then
    cp "$AEGIS_DIR/.0/AEGIS_PROTOCOL.md" "$PROJECT_PATH/.0/"
    echo "  - AEGIS_PROTOCOL.md 복사 완료"
fi

echo ""
echo -e "${BLUE}[3/6] 템플릿에서 설정 파일 생성 중...${NC}"
#------------------------------------------------------------------------------

# CLAUDE.md
if [ -f "$AEGIS_DIR/CLAUDE.md.template" ]; then
    if [ -f "$PROJECT_PATH/CLAUDE.md" ]; then
        echo -e "  ${YELLOW}! CLAUDE.md가 이미 존재합니다. CLAUDE.md.aegis로 저장합니다.${NC}"
        cp "$AEGIS_DIR/CLAUDE.md.template" "$PROJECT_PATH/CLAUDE.md.aegis"
    else
        cp "$AEGIS_DIR/CLAUDE.md.template" "$PROJECT_PATH/CLAUDE.md"
        echo "  - CLAUDE.md 생성 완료"
    fi
fi

# aegis.config.js
if [ -f "$AEGIS_DIR/templates/aegis.config.js.template" ]; then
    if [ -f "$PROJECT_PATH/aegis.config.js" ]; then
        echo -e "  ${YELLOW}! aegis.config.js가 이미 존재합니다. aegis.config.example.js로 저장합니다.${NC}"
        cp "$AEGIS_DIR/templates/aegis.config.js.template" "$PROJECT_PATH/aegis.config.example.js"
    else
        cp "$AEGIS_DIR/templates/aegis.config.js.template" "$PROJECT_PATH/aegis.config.js"
        echo "  - aegis.config.js 생성 완료"
    fi
fi

echo ""
echo -e "${BLUE}[4/6] scripts/ 디렉토리 복사 중...${NC}"
#------------------------------------------------------------------------------
mkdir -p "$PROJECT_PATH/scripts"

# 검증 및 배포 스크립트 복사 (install.sh 제외)
for script in aegis-validate.sh deploy.sh.template rollback.sh setup.sh; do
    if [ -f "$AEGIS_DIR/scripts/$script" ]; then
        cp "$AEGIS_DIR/scripts/$script" "$PROJECT_PATH/scripts/"
        echo "  - $script 복사 완료"
    fi
done

echo ""
echo -e "${BLUE}[5/6] 실행 권한 설정 중...${NC}"
#------------------------------------------------------------------------------
chmod +x "$PROJECT_PATH/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_PATH/scripts/"*.sh 2>/dev/null || true
echo "  - .claude/hooks/*.sh 실행 권한 부여"
echo "  - scripts/*.sh 실행 권한 부여"

echo ""
echo -e "${BLUE}[6/6] .gitignore 업데이트 확인...${NC}"
#------------------------------------------------------------------------------
GITIGNORE_ENTRIES=(
    "# AEGIS Protocol"
    ".playwright-mcp/"
    "backups/"
    "*.log"
)

if [ -f "$PROJECT_PATH/.gitignore" ]; then
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if ! grep -qF "$entry" "$PROJECT_PATH/.gitignore"; then
            echo "$entry" >> "$PROJECT_PATH/.gitignore"
        fi
    done
    echo "  - .gitignore 업데이트 완료"
else
    printf '%s\n' "${GITIGNORE_ENTRIES[@]}" > "$PROJECT_PATH/.gitignore"
    echo "  - .gitignore 생성 완료"
fi

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              AEGIS Protocol 설치 완료!                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}다음 파일을 프로젝트에 맞게 수정하세요:${NC}"
echo ""
echo "  1. CLAUDE.md"
echo "     - 프로젝트 이름, 구조, 테스트 계정 등 설정"
echo ""
echo "  2. aegis.config.js"
echo "     - 프로젝트 타입 (monorepo/single)"
echo "     - 빌드/테스트 명령어"
echo "     - 서버 정보 (배포 시)"
echo ""
echo -e "${BLUE}사용 가능한 명령어:${NC}"
echo "  /commit         - 스마트 커밋 메시지 생성"
echo "  /feedback-loop  - 자동 검증 + 수정 (최대 3회)"
echo "  /infinite-loop  - 목표 달성까지 반복 (Ralph Wiggum)"
echo "  /verify         - 전체 Layer 검증"
echo ""
echo -e "${BLUE}Hook 설정 (선택):${NC}"
echo "  ~/.claude/settings.json에 다음 추가:"
echo '  {
    "hooks": {
      "PermissionRequest": [{"matcher": "*", "command": ".claude/hooks/notify-user.sh"}],
      "Stop": [{"command": ".claude/hooks/notify-user.sh '\''사용자 입력 필요'\''"}]
    }
  }'
echo ""
echo -e "${GREEN}Happy coding with AEGIS!${NC}"
