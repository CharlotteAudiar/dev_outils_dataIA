# AGENTS.md — instructions de dev pour l'outil IA Audiar

Source de vérité des instructions de développement (stack, conventions, structure).
Lu nativement par Cursor. `CLAUDE.md` importe ce fichier pour Claude Code.

## Stack

- Framework d'orchestration : **Open WebUI** (instance "Open WebUI Audiar" — décision et justification dans `docs/architecture/decisions.md`)
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

- Lancer Open WebUI (déjà installé) : `./scripts/start-openwebui.sh` (installation initiale : `docs/guides.md`)
- Lancer mcp-qgis : `./servers/mcp-qgis/start.sh` (requiert `MCPO_API_KEY_QGIS` dans `.env` racine + plugin QGIS MCP démarré côté QGIS Desktop)
- Lancer mcp-postgres : `./servers/mcp-postgres/start.sh` (requiert `DATABASE_URI` et `MCPO_API_KEY_POSTGRES` dans `.env` racine)
- Lancer mcp-dbhub (**phase 1, en comparaison avec mcp-postgres — pas encore tranché**, voir `servers/mcp-dbhub/README.md` et `docs/architecture/decisions.md`) : `./servers/mcp-dbhub/start.ps1` (requiert `DATABASE_URI`, `MCPO_API_KEY_DBHUB` dans `.env` racine, et `dbhub.toml` copié depuis `dbhub.toml.example`, même dossier)
- Logs Open WebUI : `docker logs open-webui` (`-f` pour suivre en direct, `--tail 100` pour les 100 dernières lignes)
- Pas de lint/tests à ce stade : le repo assemble des outils existants (Open WebUI, serveurs MCP tiers) — aucun code applicatif propre au projet pour l'instant.

## Note de style pour ce fichier

Rester court et actionnable (commandes exactes, conventions qui diffèrent des défauts du langage) — pas de pavé théorique.
