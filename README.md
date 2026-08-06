# Audiar IA Toolkit

Outil IA associant **Open WebUI** (framework retenu, cf. `docs/architecture/decisions.md`), des serveurs MCP métier (QGIS, filesystem) et un outil Python natif pour l'accès à PostgreSQL, pour les chargés d'études de l'agence.

## Contenu

- `servers/` — serveurs MCP (`mcp-qgis`, `mcp-filesystem`), chacun avec son `README.md` + `start.sh`. `mcp-postgres` et `mcp-dbhub` y sont aussi présents mais **abandonnés** (03/08/2026, conservés pour mémoire).
- `outils-openwebui/` — outils Python natifs Open WebUI, dont `explorateur-postgres/` (accès PostgreSQL, retenu à la place d'un serveur MCP).
- `config/` — `.env.example` (variables d'environnement attendues) — n'est plus consommé que par de rares serveurs, `mcp-qgis` stocke désormais sa clé en dur dans `start.sh`.
- `scripts/` — scripts transverses (ex. `start-openwebui.sh`)
- `docs/` — documentation technique (`architecture/`, `sources/`) et fonctionnelle (`specs.md`, `guides.md`, `knowledge.md`)

## Démarrage

1. Installer Open WebUI : suivre `docs/guides.md`, section "Installer Open WebUI".
2. Lancer mcp-qgis : `docs/kit-demarrage-openwebui/start-mcp/start-mcp-qgis.bat`, qui appelle le script de référence `start-mcp/scripts/start-mcp-qgis.ps1` (clé `--api-key` en dur dans le script, à garder identique à celle de `outils-serveurs/serveur-mcp-qgis.json`). Puis le connecter dans Open WebUI (**Réglages** → **Intégrations** → **Gérer les serveurs d'outils**) — détail dans `docs/guides.md`, section « MCP QGIS (serveur externe) ».
3. Pour l'accès PostgreSQL : installer l'outil Python `outils-openwebui/explorateur-postgres/` dans Open WebUI (**Espaces de travail** → **Outils**) et renseigner ses identifiants personnels — voir son `README.md`, pas de serveur à lancer.

## Documentation — par où commencer

Pour comprendre le projet dans l'ordre plutôt que de naviguer au hasard entre les fichiers :

1. Ce README (vue d'ensemble du repo).
2. `docs/architecture/decisions.md`, section "Vue d'ensemble" — les choix retenus et leur statut, en un coup d'œil.
3. `docs/guides.md` — installation et usage pas-à-pas.
4. `servers/mcp-<nom>/README.md` — détail technique du serveur qui t'intéresse.
5. `docs/architecture/benchmark-techno.md` — seulement si tu veux la recherche comparative complète derrière une décision (pas nécessaire pour utiliser l'outil au quotidien).

Voir aussi `AGENTS.md` pour les conventions de dev et les commandes du projet.
