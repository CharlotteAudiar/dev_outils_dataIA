#!/usr/bin/env bash
# Lance mcp-qgis exposé à Open WebUI via mcpo (proxy MCP -> OpenAPI).
# Prérequis : plugin "QGIS MCP" démarré dans QGIS Desktop (voir README.md, même dossier).
# Variable d'environnement requise : MCPO_API_KEY_QGIS (voir config/.env.example).


set -euo pipefail

# Charge automatiquement le .env à la racine du repo s'il existe (non versionné, voir .gitignore).
# Sinon, la variable doit déjà être exportée dans l'environnement appelant.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

: "${MCPO_API_KEY_QGIS:?Variable MCPO_API_KEY_QGIS non définie (voir config/.env.example)}"

uvx mcpo --port 8001 --api-key "$MCPO_API_KEY_QGIS" -- \
  uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
