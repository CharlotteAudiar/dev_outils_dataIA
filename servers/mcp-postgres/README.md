# mcp-postgres

Serveur MCP pour interroger la base de données PostgreSQL (cas d'usage 2 de l'analyse fonctionnelle : "extraction de données depuis une table en base").
Neutre : servable à n'importe quel client MCP.

## Implémentation retenue (20/07/2026)

**[crystaldba/postgres-mcp](https://github.com/crystaldba/postgres-mcp)** ("Postgres MCP Pro") — retenu plutôt que l'ancienne implémentation de référence Anthropic (archivée, faille d'injection SQL documentée). Voir `docs/architecture/benchmark-frameworks.md` pour le comparatif complet.

Fonctionnalités au-delà de la simple exécution SQL : santé de la base (index, cache, vacuum...), plans d'exécution (`EXPLAIN`), recommandations d'index. Utilise `psycopg3`/`libpq` pour la connexion.

## Montage technique (même logique que `mcp-qgis`)

Comme pour QGIS, le serveur est exposé à Open WebUI via `mcpo` (proxy MCP stdio → OpenAPI) — voir `docs/architecture/decision-framework.md`, section "Connexion des serveurs MCP à Open WebUI : pourquoi `mcpo`", pour la justification détaillée de ce choix (pas de MCP natif direct dans Open WebUI en pratique).

**Commande de lancement** — packagée dans `start.sh` (même dossier) :
```
uvx mcpo --port 8002 --api-key "<une-clé-au-choix>" -- uvx postgres-mcp --access-mode=restricted
```
- `start.sh` charge automatiquement le `.env` à la racine du repo s'il existe (`DATABASE_URI`, `MCPO_API_KEY_POSTGRES` — voir `config/.env.example` pour le modèle) ; sinon ces variables doivent déjà être exportées dans l'environnement appelant. Ne jamais committer le `.env` réel — voir `.gitignore`.
- Port `8002` choisi arbitrairement pour ne pas entrer en conflit avec `mcpo` de `mcp-qgis` (port `8001`) si les deux tournent en même temps.

**Connexion côté Open WebUI** : *Intégrations → Gérer les serveurs d'outils* (pas "Connexions", cf. `servers/mcp-qgis/README.md`) → Type OpenAPI, URL `http://localhost:8002` (ou `http://host.docker.internal:8002` si Open WebUI tourne en Docker), Auth Bearer + la même clé que `--api-key`.

## Mode d'accès : restreint par défaut

`postgres-mcp` propose deux modes :
- `--access-mode=unrestricted` : lecture/écriture complète — à réserver à un environnement de dev jetable.
- `--access-mode=restricted` : lecture seule (transactions read-only + limite de temps d'exécution) — **mode retenu par défaut ici**, cohérent avec la mise en garde de l'analyse fonctionnelle sur les données sensibles (cas d'usage 2 : "Gestion données sensibles >>> solution souveraine") et avec le besoin réel (extraction/consultation, pas modification de la base depuis le chat).

Recommandation complémentaire : utiliser un rôle PostgreSQL dédié en lecture seule (`GRANT SELECT` uniquement) plutôt que le compte administrateur de la base, en plus du mode `restricted` côté serveur MCP (défense en profondeur).

## Prérequis restants avant premier test

1. Identifiants de connexion à une base réelle (host, port, nom de la base, utilisateur, mot de passe) — idéalement un rôle dédié en lecture seule créé pour ce prototype.
2. Confirmer l'accessibilité réseau depuis le poste de Charlotte (VPN, pare-feu, etc.) vers le serveur PostgreSQL cible.
3. `uv`/`uvx` déjà installé (fait lors du montage `mcp-qgis`).

- `src/` — code source
- `tests/` — tests
