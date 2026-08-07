# postgres-explorer

Tool Open WebUI natif pour explorer une base Postgres avec les identifiants personnels de chaque
utilisateur — sans serveur MCP, sans `mcpo`, sans Node.js. Voir `../README.md` pour la
méthodologie générale de construction d'un Tool Open WebUI.

## Pourquoi (contexte, 24/07/2026)

Testé en alternative à `servers/mcp-postgres/` (crystaldba) et `servers/mcp-dbhub/` (bytebase),
après un blocage sur `mcp-dbhub` : `mcpo` n'arrivait pas à spawner correctement `npx`/`node` sur
Windows (fragilité `cmd.exe`/`.cmd`/héritage de handles, cf. historique de la session
`mcp-dbhub`). Ça a amené à se demander si un serveur MCP était réellement nécessaire pour ce cas
d'usage.

Argument déterminant : **les garde-fous contre l'écriture sont déjà portés par Postgres**, pas par
l'outil qui envoie le SQL — chaque utilisateur n'a de droits d'écriture que sur son propre schéma
sandbox personnel. Ce que les MCP dédiés (`crystaldba`, `dbhub`, ou le Toolbox Google) ajoutent
au-delà de cette protection déjà existante, ce sont surtout des outils de confort (introspection
de schéma prête à l'emploi, analyse de plans d'exécution pour `crystaldba`) — pas de la sécurité
supplémentaire dans ce contexte précis. D'où l'idée de tester un Tool natif, plus simple à faire
tourner (aucun processus externe, aucune supervision à mettre en place).

**Statut (03/08/2026)** : testé et fonctionnel chez Charlotte. Préféré aux MCP.

## Fonctions exposées

- `list_tables()` — liste les tables du schéma `public`.
- `describe_table(table_name)` — colonnes d'une table (nom, type, nullable).
- `execute_query(sql)` — exécute une requête SQL quelconque et retourne jusqu'à 200 lignes de
  résultat. Aucun filtrage/validation du SQL côté outil (voir "Pourquoi" ci-dessus) — les droits
  réels sont ceux du compte Postgres de l'utilisateur.

## Pourquoi `psycopg2-binary`

`psycopg2` est la bibliothèque Python la plus utilisée pour parler à une base PostgreSQL : ouvrir une connexion (`psycopg2.connect(host=..., user=..., password=..., ...)`), envoyer des requêtes SQL (`cur.execute(sql)`), récupérer les résultats (`cur.fetchall()`/`fetchmany()`). C'est l'équivalent, côté Postgres, de ce qu'un driver JDBC est pour Java ou un driver ODBC pour Excel et Power BI.

Deux variantes existent sur PyPI. `psycopg2` nécessite de compiler des dépendances C (`libpq`) sur la machine qui l'installe ; `psycopg2-binary` est précompilée. C'est cette seconde qui est déclarée dans la ligne `requirements:` du docstring, l'installation étant faite automatiquement par Open WebUI dans son conteneur. La documentation officielle déconseille `-binary` en production à grande échelle, au profit d'une compilation maîtrisée de `libpq` : non pertinent ici, avec un compte personnel et une faible volumétrie. Documentation : [psycopg.org/docs](https://www.psycopg.org/docs/).

`psycopg2.extras.RealDictCursor`, utilisé dans `execute_query`, fait que chaque ligne de résultat est retournée comme un dictionnaire `{nom_colonne: valeur}` plutôt qu'un tuple positionnel — plus pratique pour reconstruire un texte avec les en-têtes de colonnes.

Les méthodes exposées sont en `async def` mais délèguent le travail Postgres à des méthodes privées synchrones via `asyncio.to_thread(...)`, `psycopg2` étant une bibliothèque bloquante.

## Installation dans Open WebUI

1. **Espaces de travail** → **Outils** → **New Tool** → coller le contenu de `tool.py` → sauvegarder.
   `psycopg2-binary` s'installe automatiquement (ligne `requirements:` du docstring d'en-tête).
2. Chaque utilisateur renseigne ses identifiants personnels dans **Réglages** personnels → **Outils** →
   "Explorateur Postgres (sandbox Audiar)" :
   - `pg_user` / `pg_password` : compte Postgres personnel (obligatoire).
   - `pg_host` / `pg_port` / `pg_database` : pré-remplis pour `perceval2.audiar.net:5432/sandbox`,
     modifiables si besoin d'une autre cible.
3. Activer l'outil sur le modèle utilisé (fiche du modèle → onglet **Outils**).

## Limites connues

- Pas de limite de lignes en écriture ni de timeout de requête configurés côté outil (seul
  `connect_timeout=5` sur la connexion) — à durcir si besoin réapparaît une fois l'usage réel
  observé.
- Pas d'introspection de clés étrangères/index (seulement colonnes via `describe_table`) — à
  enrichir si le besoin s'en fait sentir, sur le même principe qu'une requête `information_schema`
  supplémentaire.
