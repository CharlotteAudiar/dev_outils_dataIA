# Audiar IA Toolkit

Outil IA associant **Open WebUI** (framework retenu, cf. `docs/architecture/decision-framework.md`) et des serveurs MCP métier (QGIS, filesystem, PostgreSQL) pour les chargés d'études de l'agence.

## Contenu

- `servers/` — serveurs MCP (`mcp-qgis`, `mcp-filesystem`, `mcp-postgres`), chacun avec son `README.md` + `start.sh`
- `config/` — `.env.example` (variables d'environnement attendues)
- `scripts/` — scripts transverses (ex. `start-openwebui.sh`)
- `docs/` — documentation technique (`architecture/`, `sources/`) et fonctionnelle (`specs.md`, `guides.md`, `knowledge.md`)

## Démarrage

_À compléter._

## Documentation

Voir `docs/architecture/` pour les décisions techniques et `AGENTS.md` pour les conventions de dev.
