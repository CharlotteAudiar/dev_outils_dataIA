#!/usr/bin/env bash
# Lance mcp-dbhub (bytebase/dbhub) via mcpo — phase 1 (poste individuel, identifiants
# personnels), en comparaison avec mcp-postgres (crystaldba/postgres-mcp) — voir README.md et
# docs/architecture/decisions.md, section "Modèle de déploiement de mcp-postgres : plan en
# 3 phases". Statut (24/07/2026) : test en cours, comparaison pas encore tranchée.

## Variables d'environnement requises : DATABASE_URI, MCPO_API_KEY_DBHUB (voir config/.env.example
## — DATABASE_URI est la même variable que pour mcp-postgres, donc le même compte personnel)
## Prérequis : Node.js >= 22.5.0 (vérifier avec node -v) ; uv/uvx déjà installé (pour mcpo).
## Node.js reste une dépendance nouvelle pour ce projet (voir README.md, "Montage technique") —
## à peser dans la comparaison avec mcp-postgres, qui n'en ajoute aucune.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

: "${DATABASE_URI:?Variable DATABASE_URI non définie (voir config/.env.example)}"
: "${MCPO_API_KEY_DBHUB:?Variable MCPO_API_KEY_DBHUB non définie (voir config/.env.example)}"

CONFIG_PATH="$SCRIPT_DIR/dbhub.toml"
if [ ! -f "$CONFIG_PATH" ]; then
  echo "Fichier dbhub.toml manquant (copier dbhub.toml.example, même dossier, puis l'adapter)" >&2
  exit 1
fi

# dbhub tourne en --transport stdio (pas son mode HTTP natif) : c'est mcpo qui l'expose en
# OpenAPI et qui permet la connexion "Direct" personnelle attendue par Open WebUI pour ce
# montage par poste (voir README.md, "Pourquoi stdio + mcpo, pas le HTTP natif").
#
# "cmd //c" devant npx : sous Windows, npx est un script .cmd, pas un exécutable. mcpo (Python)
# spawne ce sous-processus directement via l'API Windows, sans passer par un shell — donc sans
# résolution PATHEXT (.cmd/.bat). Sans "cmd //c", le process ne démarre jamais et mcpo échoue
# avec "McpError: Connection closed" dès l'initialize(). Bash, lui, résout npx correctement
# (d'où le test manuel réussi en direct), ce qui masquait le problème une fois passé par mcpo.
# Double slash ("//c", pas "/c") : Git Bash/MSYS convertit automatiquement tout argument de la
# forme "/c" en chemin Windows ("C:/") avant de le transmettre à un exécutable natif comme cmd —
# "//c" échappe cette conversion et arrive intact comme option "/c" côté cmd.
uvx --with "mcp==1.29.0" mcpo@0.0.20 --port 8003 --api-key "$MCPO_API_KEY_DBHUB" -- \
  cmd //c npx --yes "@bytebase/dbhub@latest" --transport stdio --config "$CONFIG_PATH"
