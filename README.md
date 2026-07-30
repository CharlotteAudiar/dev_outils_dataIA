# Audiar IA Toolkit

Outil IA associant **Open WebUI** (framework retenu, cf. `docs/architecture/decisions.md`) et des serveurs MCP métier (QGIS, filesystem, PostgreSQL) pour les chargés d'études de l'agence.

## Contenu

- `servers/` — serveurs MCP (`mcp-qgis`, `mcp-filesystem`, `mcp-postgres`), chacun avec son `README.md` + `start.sh`
- `config/` — `.env.example` (variables d'environnement attendues)
- `scripts/` — scripts transverses (ex. `start-openwebui.sh`)
- `docs/` — documentation technique (`architecture/`, `sources/`) et fonctionnelle (`specs.md`, `guides.md`, `knowledge.md`)

## Démarrage

1. Copier `config/.env.example` vers un `.env` à la racine (non commité — voir `.gitignore`), et renseigner `DATABASE_URI` et les clés `MCPO_API_KEY_*`.
2. Installer Open WebUI en local : suivre `docs/guides.md`, section "Installer Open WebUI en local".
3. Lancer les serveurs MCP nécessaires (`./servers/mcp-qgis/start.sh`, `./servers/mcp-postgres/start.sh` — laisser les terminaux ouverts), puis les connecter dans Open WebUI (Réglages → Intégrations → Gérer les serveurs d'outils). Détail complet par serveur : `servers/mcp-*/README.md`.

## Documentation — par où commencer

Pour comprendre le projet dans l'ordre plutôt que de naviguer au hasard entre les fichiers :

1. Ce README (vue d'ensemble du repo).
2. `docs/architecture/decisions.md`, section "Vue d'ensemble" — les choix retenus et leur statut, en un coup d'œil.
3. `docs/guides.md` — installation et usage pas-à-pas.
4. `servers/mcp-<nom>/README.md` — détail technique du serveur qui t'intéresse.
5. `docs/architecture/benchmark-techno.md` — seulement si tu veux la recherche comparative complète derrière une décision (pas nécessaire pour utiliser l'outil au quotidien).

Voir aussi `AGENTS.md` pour les conventions de dev et les commandes du projet.
