#!/usr/bin/env bash
set -euo pipefail

log() { echo "[bootstrap] $1"; }
warn() { echo "[bootstrap] Warning: $1"; }
has_command() { command -v "$1" >/dev/null 2>&1; }

log "Starting bootstrap..."

# Required commands
for cmd in git; do
  has_command "$cmd" || warn "Missing: $cmd"
done

has_command claude || warn "claude CLI is not available in this environment."

# MCP-related setup (only acts on .mcp.json if present)
if [[ -f .mcp.json ]]; then
  if grep -q "@playwright/mcp" .mcp.json && [[ "${PLAYWRIGHT_SKIP_INSTALL:-0}" != "1" ]]; then
    log "Playwright MCP detected. Installing Chromium..."
    npx -y playwright install chromium || warn "Playwright Chromium install failed."
  fi

  if grep -q "@upstash/context7-mcp" .mcp.json; then
    if [[ -z "${UPSTASH_REDIS_REST_URL:-}" || -z "${UPSTASH_REDIS_REST_TOKEN:-}" ]]; then
      warn "UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN are not set; Context7 MCP will fail at startup."
    fi
  fi
fi

log "Bootstrap completed."
