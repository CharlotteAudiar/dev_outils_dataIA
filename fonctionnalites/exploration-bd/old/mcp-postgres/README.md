# mcp-postgres (abandonné)

**Abandonné le 03/08/2026** : remplacé par un outil Python natif Open WebUI, retenu pour l'accès à la base de données plutôt qu'un serveur MCP dédié — voir `fonctionnalites/exploration-bd/README.md` pour la solution actuelle et `decisions.md`, section "Accès à la base de données", pour la justification complète. Contenu ci-dessous conservé pour mémoire (contexte de l'essai MCP), sans actualité opérationnelle.

Serveur MCP pour interroger la base de données PostgreSQL (cas d'usage 2 de l'analyse fonctionnelle : "extraction de données depuis une table en base").
Neutre : servable à n'importe quel client MCP.

## Implémentation testée (20/07/2026)

**[crystaldba/postgres-mcp](https://github.com/crystaldba/postgres-mcp)** ("Postgres MCP Pro") — retenu plutôt que l'ancienne implémentation de référence Anthropic (archivée, faille d'injection SQL documentée). Voir `benchmark-techno.md` pour le comparatif complet.

Fonctionnalités au-delà de la simple exécution SQL : santé de la base (index, cache, vacuum...), plans d'exécution (`EXPLAIN`), recommandations d'index. Utilise `psycopg3`/`libpq` pour la connexion.

## Montage technique (même logique que `mcp-qgis`)

Comme pour QGIS, le serveur est exposé à Open WebUI via `mcpo` (proxy MCP stdio → OpenAPI) — voir `plateforme/mecanismes-extension.md`, section « OpenAPI vs StreamableHTTP », pour la justification détaillée de ce choix (pas de MCP natif direct dans Open WebUI en pratique).

**Commande de lancement** — packagée dans `start.sh` (même dossier) :
```
uvx --with "mcp==1.29.0" mcpo@0.0.20 --port 8002 --api-key "<une-clé-au-choix>" -- uvx postgres-mcp --access-mode=restricted
```
- `start.sh` charge automatiquement le `.env` à la racine du repo s'il existe (`DATABASE_URI`, `MCPO_API_KEY_POSTGRES` — voir `config/.env.example` pour le modèle) ; sinon ces variables doivent déjà être exportées dans l'environnement appelant. Ne jamais committer le `.env` réel — voir `.gitignore`.
- Port `8002` choisi arbitrairement pour ne pas entrer en conflit avec `mcpo` de `mcp-qgis` (port `8001`) si les deux tournent en même temps.

**Connexion côté Open WebUI** : **Intégrations** → **Gérer les serveurs d'outils** (pas **Connexions**) → Type **OpenAPI**, URL `http://localhost:8002` (ou `http://host.docker.internal:8002` si Open WebUI tourne en Docker), Auth Bearer + la même clé que `--api-key`.

## Mode d'accès : restreint par défaut

`postgres-mcp` propose deux modes :
- `--access-mode=unrestricted` : lecture/écriture complète — à réserver à un environnement de dev jetable.
- `--access-mode=restricted` : lecture seule (transactions read-only + limite de temps d'exécution) — **mode retenu par défaut ici**, cohérent avec la mise en garde de l'analyse fonctionnelle sur les données sensibles (cas d'usage 2 : "Gestion données sensibles >>> solution souveraine") et avec le besoin réel (extraction/consultation, pas modification de la base depuis le chat).

Recommandation complémentaire : utiliser un rôle PostgreSQL dédié en lecture seule (`GRANT SELECT` uniquement) plutôt que le compte administrateur de la base, en plus du mode `restricted` côté serveur MCP (défense en profondeur).

## Vérification du rôle lecture seule

Le mode `restricted` de `postgres-mcp` protège au niveau applicatif ; le rôle PostgreSQL dédié protège au niveau base — les deux sont complémentaires, l'un ne remplace pas l'autre. Checklist à exécuter (ex. via `psql` ou un client graphique) avec les identifiants réellement utilisés dans `DATABASE_URI` :

```sql
-- 1. Identifier le rôle utilisé par la connexion
SELECT current_user;

-- 2. Vérifier l'absence de droits d'administration sur ce rôle
SELECT rolname, rolsuper, rolcreatedb, rolcreaterole, rolreplication
FROM pg_roles
WHERE rolname = current_user;
-- Attendu : rolsuper = f, rolcreatedb = f, rolcreaterole = f, rolreplication = f

-- 3. Vérifier qu'il n'a que SELECT sur les tables concernées (jamais INSERT/UPDATE/DELETE/TRUNCATE)
SELECT table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = current_user
ORDER BY table_schema, table_name;
```

Si ce rôle n'existe pas encore (connexion encore faite avec un compte administrateur), le créer (à adapter : nom de rôle, base, schéma réels) :

```sql
CREATE ROLE audiar_readonly LOGIN PASSWORD '<mot-de-passe-à-définir-en-sécurité>';
GRANT CONNECT ON DATABASE <nom_base> TO audiar_readonly;
GRANT USAGE ON SCHEMA public TO audiar_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO audiar_readonly;
-- Pour que les futures tables créées dans ce schéma restent aussi en lecture seule pour ce rôle :
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO audiar_readonly;
```

Puis mettre à jour `DATABASE_URI` dans le `.env` local pour utiliser ce rôle plutôt que le compte administrateur.

**Statut (21/07/2026) : pas encore exécuté** — l'existence réelle de ce rôle côté base n'est pas confirmée ; la recommandation était jusqu'ici documentée mais pas vérifiée concrètement.

## Prérequis restants avant premier test

1. Identifiants de connexion à une base réelle (host, port, nom de la base, utilisateur, mot de passe) — idéalement un rôle dédié en lecture seule créé pour ce prototype.
2. Confirmer l'accessibilité réseau depuis le poste de Charlotte (VPN, pare-feu, etc.) vers le serveur PostgreSQL cible.
3. `uv`/`uvx` déjà installé (fait lors du montage `mcp-qgis`).

- `src/` — code source
- `tests/` — tests
