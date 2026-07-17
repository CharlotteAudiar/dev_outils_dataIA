# AGENTS.md — instructions de dev pour l'outil IA Audiar

Source de vérité des instructions de développement (stack, conventions, structure).
Lu nativement par Cursor. `CLAUDE.md` importe ce fichier pour Claude Code.

## Stack

- Framework d'orchestration : à définir
- Serveurs MCP métier : QGIS, filesystem, PostgreSQL, Excel (voir `servers/`)
- Langage(s) : à définir

## Structure du repo

- `framework/` — cœur applicatif (orchestration, logique métier)
- `servers/mcp-*/` — un serveur MCP par dossier, isolé, sans logique spécifique à un client
- `config/` — configuration canonique (`mcp-servers.yaml`) + gabarits `.example` par client
- `docs/architecture/` — décisions techniques (ADR)
- `docs/specs/` — specs fonctionnelles pour les chargés d'études (utilisateurs finaux, pas les devs)
- `docs/guides/` — installation, usage, onboarding
- `docs/knowledge/` — synthèses à uploader dans les Projects Claude Desktop/Cowork des chargés d'études
- `scripts/` — installation, déploiement, migrations

## Conventions

- Un serveur MCP = un dossier sous `servers/`, ses propres dépendances, son propre `README.md`.
- Les vrais fichiers de config (`claude_desktop_config.json`, `.cursor/mcp.json`, `.env`, `CLAUDE.local.md`) ne sont jamais commités : seules leurs versions `.example` le sont (voir `.gitignore`).
- `config/mcp-servers.yaml` est la source canonique ; les fichiers `config/*.example.json` en sont dérivés.
- Transport stdio = un client à la fois ; passer en HTTP streamable si plusieurs outils doivent interroger le même serveur simultanément.

## Commandes

_À compléter au fur et à mesure (install, lint, tests, run)._
