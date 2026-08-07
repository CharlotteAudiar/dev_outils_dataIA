# mcp-dbhub (abandonné)

**Abandonné le 03/08/2026** : remplacé par un outil Python natif Open WebUI, retenu pour l'accès à la base de données plutôt qu'un serveur MCP dédié (`mcp-dbhub` comme `mcp-postgres`) — voir `fonctionnalites/exploration-bd/README.md` pour la solution actuelle et `decisions.md`, section "Accès à la base de données", pour la justification complète (dbhub exclu en particulier pour ses limites d'intégration mcpo/Windows). Contenu ci-dessous conservé pour mémoire (contexte de l'essai MCP), sans actualité opérationnelle.

Serveur MCP PostgreSQL candidat, **en test** (poste individuel, identifiants
personnels) — comparé à `crystaldba/postgres-mcp` (déjà en place, `servers/mcp-postgres/`).
Voir `benchmark-techno.md`, section `mcp-postgres`,
pour l'alerte sur l'état de maintenance de `crystaldba` qui motive cette comparaison.

## Statut (24/07/2026) : test en cours, comparaison pas encore tranchée — voir décision d'abandon ci-dessus (03/08/2026)

Les deux serveurs (`mcp-postgres` et `mcp-dbhub`) restent actifs en parallèle pour comparaison et sont comparés avec un outil python.

## Pourquoi `stdio` + `mcpo`, pas le HTTP natif de dbhub

dbhub supporte aussi un transport HTTP natif (`--transport http`, endpoint `/mcp`), qui
correspondrait au type **MCP (Streamable HTTP)** natif d'Open WebUI, sans passer par `mcpo`. Non
retenu ici : ce mode natif n'est connectable que côté **Admin Settings** → **External Tools**
(chemin "Global", confirmé sur docs.openwebui.com le 24/07/2026) — pas de chemin "Direct"
personnel pour du MCP natif, seulement pour de l'OpenAPI. Or ce montage par poste
suppose que chaque chargé d'études connecte son **propre** serveur MCP avec son **propre**
compte Postgres, via **Réglages** personnels → **Intégrations** → **Gérer les serveurs d'outils** — donc
le chemin "Direct", qui n'existe que pour l'OpenAPI. D'où le choix de faire tourner dbhub en
`--transport stdio`, exposé en OpenAPI par `mcpo` — exactement le même montage que
`mcp-qgis`/`mcp-postgres`.

## Montage technique

- dbhub tourne via **`npx`** (`npx --yes @bytebase/dbhub@latest --transport stdio ...`), lancé
  en sous-processus par `mcpo` — nécessite **Node.js ≥ 22.5** sur le poste (voir "Dépendance
  runtime" ci-dessous). Une variante Docker (`docker run --rm -i bytebase/dbhub ...`) a été
  testée le 24/07/2026 mais abandonnée : sous Git Bash (MINGW64), la traduction automatique de
  chemins mangle les arguments `--volume`/`--config` de `docker run` (transforme `src:dst` en
  liste `;` façon `PATH` Windows) — `npx` n'a pas ce problème, et reste plus proche du pattern
  `uv`/`uvx` des autres serveurs MCP du projet.
- `mcpo --port 8003 --api-key ...` — port choisi pour ne pas entrer en conflit avec `mcp-qgis`
  (8001) et `mcp-postgres` (8002).
- Connexion côté Open WebUI : **Réglages** personnels → **Intégrations** → **Gérer les serveurs
  d'outils** → Type **OpenAPI** → URL `http://localhost:8003` → Auth **Bearer**, même clé que
  `--api-key` (`MCPO_API_KEY_DBHUB`) — identique au montage `mcp-postgres`.

## Dépendance runtime : Node.js, à peser dans la comparaison

`dbhub` exige Node.js ≥ 22.5 sur **chaque poste** où il tourne (un poste par chargé
d'études) — contrairement à `crystaldba/postgres-mcp`, qui réutilise `uv`/
`uvx` déjà exigé pour `mcp-qgis` et n'ajoute donc rien. À 15 postes non-développeurs, c'est un
vrai coût de déploiement/support, pas un détail — voir `benchmark-techno.md`,
section `mcp-postgres`, "dépendance runtime par candidat". Point à trancher explicitement dans
la comparaison, pas seulement les fonctionnalités des deux serveurs.

## Mode lecture seule

`readonly`/`max_rows`/`query_timeout` de dbhub ne se règlent **qu'en TOML** (aucun flag CLI
équivalent, contrairement à `--access-mode=restricted` de `postgres-mcp`) — voir
`dbhub.toml.example` (même dossier), à copier en `dbhub.toml` (gitignoré, cf. `.gitignore`).
Le `dsn` y pointe sur `${DATABASE_URI}`, lu directement depuis l'environnement du processus
(chargé depuis le `.env` racine par `start.ps1`/`start.sh`).

**Pourquoi garder ce garde-fou alors que chaque compte est déjà personnel** : les comptes
Postgres personnels ne sont pas forcément tous en lecture seule côté base — `readonly = true`
reste une défense en profondeur, cohérente avec le mode restreint déjà retenu pour
`mcp-postgres` (voir `servers/mcp-postgres/README.md`).

## Pas à pas du test

1. **Prérequis** : Node.js ≥ 22.5 (`node -v` — à installer, cf. "Dépendance runtime"
   ci-dessus) ; `uv`/`uvx` (déjà en place pour les autres serveurs) ; `DATABASE_URI` et
   `MCPO_API_KEY_DBHUB` dans le `.env` racine (voir `config/.env.example`).
2. Copier `dbhub.toml.example` → `dbhub.toml` (même dossier).
3. Lancer : `./servers/mcp-dbhub/start.ps1` (ou `start.sh`).
4. Connecter côté Open WebUI comme décrit ci-dessus ("Montage technique").
5. Dans un chat : activer l'outil, tester `search_objects` (lister les tables) puis
   `execute_sql` avec un `SELECT` ; tenter volontairement un `UPDATE`/`INSERT` pour confirmer
   que `readonly` le bloque.
6. **Comparer** avec `mcp-postgres` (fiabilité, pertinence des réponses, facilité de connexion)
   et reporter le résultat dans `benchmark-techno.md`.

## Prérequis restants avant de trancher la comparaison

- Résultat du test ci-dessus (fiabilité réelle, pas seulement la config).
- Vérification du rôle PostgreSQL personnel utilisé (droits réels du compte, pas seulement le
  garde-fou applicatif) — même point de vigilance que pour `mcp-postgres`.
