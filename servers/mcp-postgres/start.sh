#!/usr/bin/env bash
# Lance mcp-postgres exposé à Open WebUI via mcpo (proxy MCP -> OpenAPI).
# Variables d'environnement requises : DATABASE_URI, MCPO_API_KEY_POSTGRES (voir config/.env.example).
# Mode restreint (lecture seule) par défaut — voir README.md (même dossier) pour la justification.


set -euo pipefail

: "${DATABASE_URI:?Variable DATABASE_URI non définie (voir config/.env.example)}"
: "${MCPO_API_KEY_POSTGRES:?Variable MCPO_API_KEY_POSTGRES non définie (voir config/.env.example)}"

uvx mcpo --port 8002 --api-key "$MCPO_API_KEY_POSTGRES" -- \
  uvx postgres-mcp --access-mode=restricted
