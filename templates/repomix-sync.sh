#!/bin/bash
# ============================================================================
# repomix-sync.sh — Repomix 재생성 + NotebookLM 동기화 (범용 템플릿)
# ============================================================================
#
# 용도: 코드 변경 후 코드 묶음을 재생성하고 NotebookLM에 업로드
# 사용법: bash scripts/repomix-sync.sh
#
# 사전 요구사항:
#   - npx (Node.js)
#   - nlm CLI (notebooklm-mcp-cli)
#   - scripts/nlm-sync.sh 설정 완료
#
# 설치: autonomous 레포 templates/에서 프로젝트 scripts/로 복사 후
#       아래 "프로젝트별 수정 영역"만 수정하면 됩니다.
# ============================================================================

set -e
cd "$(dirname "$0")/.."
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"

# ── 프로젝트별 수정 영역 ──────────────────────────
# >>> 여기만 수정하면 됩니다 <<<

# Repomix include 패턴 (프로젝트 구조에 맞게 수정)
# 형식: "출력파일:include패턴"
REPOMIX_TARGETS=(
  "repomix-api-routes.md:backend/app/api/**/*.py"
  "repomix-frontend.md:frontend/app/**/*.tsx,frontend/lib/**/*.ts"
  "repomix-backend-services.md:backend/app/services/**/*.py"
  # 추가 타겟:
  # "repomix-models.md:backend/app/models/**/*.py"
  # "repomix-tests.md:tests/**/*.py"
)

# nlm-sync.sh 호출 방식 (OS에 맞게 수정)
NLM_SYNC_CMD="zsh scripts/nlm-sync.sh"     # macOS
# NLM_SYNC_CMD="bash scripts/nlm-sync.sh"  # Linux

# ── 공통 로직 (수정 불필요) ────────────────────────

echo "=== Repomix 재생성 시작 ==="

# 1. Repomix 재생성 (병렬 실행)
for target in "${REPOMIX_TARGETS[@]}"; do
  OUTPUT="${target%%:*}"
  INCLUDE="${target##*:}"
  npx repomix --include "$INCLUDE" -o "$OUTPUT" &
done

wait
echo "=== Repomix 재생성 완료 ==="

# 2. NotebookLM에 업로드
echo "=== NotebookLM 동기화 시작 ==="
for target in "${REPOMIX_TARGETS[@]}"; do
  OUTPUT="${target%%:*}"
  if [ -f "$OUTPUT" ]; then
    echo "--- $OUTPUT ---"
    $NLM_SYNC_CMD "$OUTPUT" main
  fi
done
echo "=== 전체 완료 ==="
