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

**Statut (24/07/2026)** : testé et fonctionnel chez Charlotte. Comparaison avec les MCP dédiés
**pas encore tranchée** pour l'ensemble des cas d'usage — ce README documente uniquement la
construction et le fonctionnement de cet outil, pas une décision d'architecture actée (voir
`docs/architecture/decisions.md`/`benchmark-techno.md`, non modifiés par ce test).

## Fonctions exposées

- `list_tables()` — liste les tables du schéma `public`.
- `describe_table(table_name)` — colonnes d'une table (nom, type, nullable).
- `execute_query(sql)` — exécute une requête SQL quelconque et retourne jusqu'à 200 lignes de
  résultat. Aucun filtrage/validation du SQL côté outil (voir "Pourquoi" ci-dessus) — les droits
  réels sont ceux du compte Postgres de l'utilisateur.

## Installation dans Open WebUI

1. Workspace → Outils → New Tool → coller le contenu de `tool.py` → sauvegarder.
   `psycopg2-binary` s'installe automatiquement (ligne `requirements:` du docstring d'en-tête).
2. Chaque utilisateur renseigne ses identifiants personnels dans Réglages personnels → Outils →
   "Explorateur Postgres (sandbox Audiar)" :
   - `pg_user` / `pg_password` : compte Postgres personnel (obligatoire).
   - `pg_host` / `pg_port` / `pg_database` : pré-remplis pour `perceval2.audiar.net:5432/sandbox`,
     modifiables si besoin d'une autre cible.
3. Activer l'outil sur le modèle utilisé (fiche du modèle → onglet "Outils").

## Limites connues

- Pas de limite de lignes en écriture ni de timeout de requête configurés côté outil (seul
  `connect_timeout=5` sur la connexion) — à durcir si besoin réapparaît une fois l'usage réel
  observé.
- Pas d'introspection de clés étrangères/index (seulement colonnes via `describe_table`) — à
  enrichir si le besoin s'en fait sentir, sur le même principe qu'une requête `information_schema`
  supplémentaire.
