#!/bin/bash
# ============================================================
# aaAI-Free installer
# ============================================================
# Patches aaPanel AICS so you can use your OWN API keys
# without aaPanel server quota/PRO restrictions.
#
# Usage:
#   sudo bash install.sh          # Install
#   sudo bash install.sh --uninstall  # Remove
# ============================================================

set -e

PANEL_ROOT="/www/server/panel"
AGENT_DIR="${PANEL_ROOT}/mod/project/agent"
AGENT_PY="${AGENT_DIR}/chat_client/agent.py"
PATCH_FILE="${AGENT_DIR}/aaai_free.py"
IMPORT_MARKER="# aaai-free"
IMPORT_LINE="import mod.project.agent.aaai_free  ${IMPORT_MARKER}"
BACKUP_DIR="${AGENT_DIR}/.aaai_free_backup"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[aaai-free]${NC} $1"; }
warn()  { echo -e "${YELLOW}[aaai-free]${NC} $1"; }
err()   { echo -e "${RED}[aaai-free]${NC} $1"; exit 1; }

uninstall() {
    log "Removing aaAI-Free..."

    # Restore agent.py from backup
    if [ -f "${BACKUP_DIR}/agent.py" ]; then
        cp "${BACKUP_DIR}/agent.py" "${AGENT_PY}"
        log "Restored agent.py from backup"
    else
        # Fallback: just remove the line
        if grep -q "${IMPORT_MARKER}" "${AGENT_PY}" 2>/dev/null; then
            sed -i "/${IMPORT_MARKER}/d" "${AGENT_PY}"
            log "Removed import line from agent.py"
        fi
    fi

    # Remove patch file
    rm -f "${PATCH_FILE}"
    log "Removed aaai_free.py"

    # Remove backup dir (keep log for debugging)
    rm -rf "${BACKUP_DIR}"

    log "Uninstall complete."
    log "Restart aaPanel to fully apply: /etc/init.d/bt restart"
    exit 0
}

do_install() {
    log "aaAI-Free installer"
    echo ""

    # ---- Checks ----
    [ "$(id -u)" -eq 0 ] || err "Please run as root: sudo bash install.sh"

    [ -f "${AGENT_PY}" ] || err "aaPanel AI Assistant not found.\n  Expected: ${AGENT_PY}\n  Install AICS plugin in aaPanel first."

    if grep -q "${IMPORT_MARKER}" "${AGENT_PY}" 2>/dev/null; then
        warn "Already installed! Use --uninstall to remove first."
        exit 0
    fi

    # ---- Backup agent.py ----
    mkdir -p "${BACKUP_DIR}"
    cp "${AGENT_PY}" "${BACKUP_DIR}/agent.py"
    log "Backed up: ${AGENT_PY}"

    # ---- Copy patch module ----
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cp "${SCRIPT_DIR}/aaai_free.py" "${PATCH_FILE}"
    chmod 644 "${PATCH_FILE}"
    log "Installed: ${PATCH_FILE}"

    # ---- Inject import into agent.py ----
    # Add right after the docstring/first imports so it runs early
    if head -1 "${AGENT_PY}" | grep -q '^"""'; then
        # Has docstring — insert after it
        python3 -c "
text = open('${AGENT_PY}').read()
lines = text.split('\n')
# Find end of docstring
depth = 0
insert_at = 0
for i, line in enumerate(lines):
    if line.strip().startswith('\"\"\"') or line.strip().startswith(\"'\"''\"'):
        if depth == 0:
            depth = 1
        elif depth == 1 and i > 0:
            insert_at = i + 1
            break
lines.insert(insert_at, '${IMPORT_LINE}')
open('${AGENT_PY}', 'w').write('\n'.join(lines))
" 2>&1
    else
        # No docstring — insert at line 1
        sed -i "1i${IMPORT_LINE}" "${AGENT_PY}"
    fi
    log "Patched: ${AGENT_PY}"

    # ---- Verify ----
    if grep -q "${IMPORT_MARKER}" "${AGENT_PY}"; then
        log ""
        log "=============================================="
        log "  aaAI-Free installed successfully!"
        log "=============================================="
        log ""
        log "What changed:"
        log "  1. ${PATCH_FILE}"
        log "  2. 1 line added to ${AGENT_PY}"
        log ""
        log "To apply: RESTART aaPanel"
        log "  /etc/init.d/bt restart"
        log ""
        log "Check it works:"
        log "  cat ${PANEL_ROOT}/data/agent/aaai_free.log"
        log ""
        log "Uninstall:"
        log "  sudo bash install.sh --uninstall"
    else
        err "Verification failed — import line not found in agent.py"
    fi
}

case "${1:-}" in
    --uninstall|-u) uninstall ;;
    --help|-h)
        echo "aaAI-Free Installer"
        echo ""
        echo "  install:      sudo bash install.sh"
        echo "  uninstall:    sudo bash install.sh --uninstall"
        echo ""
        echo "Project: https://github.com/trvanthanhhmaster-spec/aaai-free"
        ;;
    *) do_install ;;
esac
