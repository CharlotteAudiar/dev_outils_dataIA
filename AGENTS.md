# AGENTS.md — instructions de dev pour l'outil IA Audiar

Source de vérité des instructions de développement (stack, conventions, structure).
Lu nativement par Cursor. `CLAUDE.md` importe ce fichier pour Claude Code.

## Stack

- Framework d'orchestration : **Open WebUI** (instance "Open WebUI Audiar" — décision et justification dans `docs/architecture/decision-framework.md`)
- Serveurs MCP métier : QGIS, filesystem, PostgreSQL, Excel (voir `servers/`), exposés à Open WebUI via le proxy `mcpo` (MCP → OpenAPI)
- Langage(s) : à définir

## Structure du repo

- `servers/mcp-*/` — un serveur MCP par dossier, isolé, sans logique spécifique à un client : `README.md` (décision, montage technique) + `start.sh` (commande `mcpo` validée), quand le serveur est actif
- `config/` — `.env.example` (variables d'environnement attendues, sans valeurs réelles)
- `scripts/` — scripts transverses, pas spécifiques à un serveur (ex. `start-openwebui.sh` pour l'instance elle-même)
- `docs/architecture/` — décisions techniques (ADR) + recherche comparative
- `docs/sources/` — documents source primaires (ex. analyse fonctionnelle CU1-CU9), versionnés car cités par `docs/architecture/`
- `docs/specs.md` — specs fonctionnelles pour les chargés d'études (utilisateurs finaux, pas les devs)
- `docs/guides.md` — installation, usage, onboarding
- `docs/knowledge.md` — synthèses à uploader dans les Projects Claude Desktop/Cowork des chargés d'études

## Conventions

- `CLAUDE.local.md` (gitignoré) : notes personnelles — chemins locaux, remarques en cours, journal de progression — jamais partagées.
- Un serveur MCP = un dossier sous `servers/`, ses propres dépendances, son propre `README.md` + `start.sh`.
- Les vrais fichiers de config (`.env`, `CLAUDE.local.md`) ne sont jamais commités : seules leurs versions `.example` le sont (voir `.gitignore`).
- Transport stdio = un client à la fois ; passer en HTTP streamable si plusieurs outils doivent interroger le même serveur simultanément.

## Commandes

_À compléter au fur et à mesure (install, lint, tests, run)._

## Note de style pour ce fichier

Rester court et actionnable (commandes exactes, conventions qui diffèrent des défauts du langage) — pas de pavé théorique.
