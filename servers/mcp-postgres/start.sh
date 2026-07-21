#!/usr/bin/env bash
# Lance mcp-postgres exposé à Open WebUI via mcpo (proxy MCP -> OpenAPI).
# Variables d'environnement requises : DATABASE_URI, MCPO_API_KEY_POSTGRES (voir config/.env.example).
# Mode restreint (lecture seule) par défaut — voir README.md (même dossier) pour la justification.


set -euo pipefail

# Charge automatiquement le .env à la racine du repo s'il existe (non versionné, voir .gitignore).
# Sinon, les variables doivent déjà être exportées dans l'environnement appelant.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

: "${DATABASE_URI:?Variable DATABASE_URI non définie (voir config/.env.example)}"
: "${MCPO_API_KEY_POSTGRES:?Variable MCPO_API_KEY_POSTGRES non définie (voir config/.env.example)}"

uvx mcpo --port 8002 --api-key "$MCPO_API_KEY_POSTGRES" -- \
  uvx postgres-mcp --access-mode=restricted
