# Ressources pour écrire des Tools Open WebUI

Ce document rassemble ce dont tu as besoin pour construire toi-même de nouveaux Tools Open WebUI
natifs (comme `postgres-explorer/`), sans repartir de zéro à chaque fois. Vérifié/consulté le
24/07/2026.

## Sources officielles

- [Tools & Functions (Plugins) — vue d'ensemble](https://docs.openwebui.com/features/extensibility/plugin/)
  — distingue Tools (donnent des capacités au modèle, appelées pendant sa réponse) et Functions
  (modifient le comportement de la plateforme elle-même — pas notre cas ici).
- [Tools — présentation](https://docs.openwebui.com/features/extensibility/plugin/tools/)
- [Tool Development — page de référence](https://docs.openwebui.com/features/extensibility/plugin/tools/development/)
  — la page la plus utile : structure du fichier, arguments réservés, exemples.
- [Valves & UserValves](https://docs.openwebui.com/features/extensibility/plugin/development/valves/)
  — détail du mécanisme de configuration par admin (`Valves`) vs par utilisateur (`UserValves`).
- [Events (Event Emitters)](https://docs.openwebui.com/features/extensibility/plugin/development/events)
  — pour afficher des statuts/notifications dans le chat pendant l'exécution d'un outil (non
  utilisé dans `postgres-explorer`, utile si un outil devient plus long/complexe).
- [Reserved Arguments](https://docs.openwebui.com/features/extensibility/plugin/development/reserved-args)
  — liste complète des arguments spéciaux qu'Open WebUI peut injecter dans une méthode de Tool.
- [⚠️ Plugin Security Warning](https://docs.openwebui.com/features/extensibility/plugin/) (même
  page que la vue d'ensemble, encart en haut) — à lire avant de donner à quelqu'un le droit de
  créer/importer des Tools.

## Sources communautaires (pour s'inspirer, avec prudence)

- [openwebui.com/explore](https://openwebui.com/explore) — galerie officielle d'outils/prompts/
  modèles partagés par la communauté, avec bouton d'import direct.
- [openwebui.com/tools](https://open-webui.com/tools/) — section dédiée aux Tools.
- [github.com/Haervwe/open-webui-tools](https://github.com/Haervwe/open-webui-tools) — collection
  d'une quinzaine d'outils avec du code réel à lire comme exemples de patterns plus avancés.
- [github.com/gitjfmd/open-webui-tools](https://github.com/gitjfmd/open-webui-tools) — autre
  collection, plus modeste.

**Prudence** : un Tool exécute du code Python arbitraire côté serveur (voir "Règle de sécurité"
ci-dessous). Ne jamais importer un Tool communautaire sans en lire le code en entier d'abord.

## Règles d'écriture

- Un Tool = **un seul fichier Python**, collé tel quel dans Open WebUI. Le fichier a deux parties :
  un docstring d'en-tête (métadonnées) et une classe obligatoirement nommée `Tools`.
- **Docstring d'en-tête** : `title`, `author`, `description`, `version`, `requirements` (liste de
  packages pip séparés par des virgules, installés automatiquement à la sauvegarde), et
  optionnellement `author_url`, `git_url`, `required_open_webui_version`, `licence`.
- **Chaque méthode publique de `Tools` = un outil séparé**, proposé individuellement au modèle.
  Deux règles strictes sur ces méthodes :
  - **Type hints obligatoires** sur tous les paramètres et la valeur de retour — Open WebUI s'en
    sert pour générer le schéma JSON envoyé au modèle. Sans ça, l'outil fonctionne de façon
    beaucoup moins fiable.
  - **Docstring = ce que le modèle lit** pour savoir quand et comment appeler l'outil (description
    générale + une ligne `:param nom_du_param: ...` par paramètre). À soigner comme une partie du
    prompt, pas comme un simple commentaire pour toi.
- **Retour** : toujours une chaîne de caractères (pas un objet Python brut, pas un dict).
- **Préférer `async def`** à `def` pour les méthodes — la doc officielle recommande l'async pour
  la compatibilité avec les futures versions d'Open WebUI (le backend bascule progressivement vers
  de l'exécution entièrement asynchrone). `psycopg2` reste une bibliothèque bloquante : dans
  `postgres-explorer/tool.py`, les méthodes exposées sont `async def` mais délèguent le travail
  Postgres à des méthodes privées synchrones exécutées via `asyncio.to_thread(...)`, pour ne pas
  geler la boucle asyncio d'Open WebUI pendant l'accès réseau.
- **Arguments réservés**, à ajouter uniquement si besoin (jamais de description dessus dans le
  docstring, sinon ils seraient exposés au modèle) : `__user__` (infos utilisateur + `UserValves`
  dans `__user__["valves"]`), `__event_emitter__`/`__event_call__` (statuts/interactions dans le
  chat), `__metadata__`, `__messages__`, `__files__`, `__model__`, `__oauth_token__` (jeton OAuth
  de l'utilisateur, pour appeler une API tierce en son nom). Liste complète : page "Reserved
  Arguments" ci-dessus.

### Règle de sécurité (à ne pas sauter)

Un Tool exécute du code Python arbitraire **directement sur le serveur qui héberge Open WebUI**.
Donner à quelqu'un le droit de créer/importer un Tool équivaut à lui donner un accès shell au
serveur. Restreindre qui peut créer des Tools (Workspace) aux personnes de confiance, et relire le
code de tout Tool avant de l'importer — le sien ou celui d'un tiers.

## Valves et UserValves, en clair

Les deux servent à exposer des réglages configurables dans l'interface d'Open WebUI, sans toucher
au code :

- **`Valves`** : réglages **globaux**, modifiables uniquement par un admin (menu Workspace →
  Outils). Adapté à une config partagée par tout le monde (ex. une URL de service commune).
- **`UserValves`** : réglages **par utilisateur**, que chaque personne renseigne elle-même dans
  ses Réglages personnels → Outils. C'est le mécanisme utilisé dans `postgres-explorer` pour que
  chacun renseigne son propre compte Postgres, sans que ces identifiants transitent par un admin.

Techniquement, les deux sont des classes qui héritent de `pydantic.BaseModel`, avec un champ par
réglage défini via `Field(default=..., description="...")` — c'est cette description qui apparaît
comme texte d'aide dans le formulaire généré automatiquement par Open WebUI.

Pour lire la valeur d'un `UserValves` dans le code, utiliser l'accès par attribut :
`__user__["valves"].mon_champ` (ou `__user__.get("valves")` comme dans `postgres-explorer/tool.py`,
équivalent). **Ne jamais** faire `__user__["valves"]["mon_champ"]` (notation par clé) : ça renvoie
la valeur par défaut au lieu de la valeur réellement configurée par l'utilisateur, silencieusement.

**Champs sensibles (mots de passe, clés d'API)** : ajouter `json_schema_extra={"input": {"type":
"password"}}` au `Field` pour que le champ s'affiche masqué (points) dans l'interface au lieu
d'être en clair. Appliqué à `pg_password` dans `postgres-explorer/tool.py`.

## À quoi sert `psycopg2` (utilisé dans `postgres-explorer`)

`psycopg2` est la bibliothèque Python la plus utilisée pour parler à une base **PostgreSQL** :
ouvrir une connexion (`psycopg2.connect(host=..., user=..., password=..., ...)`), envoyer des
requêtes SQL (`cur.execute(sql)`), récupérer les résultats (`cur.fetchall()`/`fetchmany()`). C'est
l'équivalent, côté Postgres, de ce qu'un driver JDBC est pour Java ou un driver ODBC pour Excel/
Power BI.

Deux variantes existent sur PyPI :

- `psycopg2` : nécessite de compiler des dépendances C (`libpq`) sur la machine qui l'installe.
- `psycopg2-binary` : version précompilée, s'installe sans rien avoir à compiler — c'est celle
  utilisée dans `postgres-explorer/tool.py` (ligne `requirements:` du docstring), adaptée à ce
  contexte (installation automatique par Open WebUI, pas de contrôle fin nécessaire sur la version
  de `libpq`). La doc officielle de `psycopg2` déconseille `-binary` en production à grande échelle
  (préférence pour compiler soi-même la version exacte de `libpq`) — non pertinent pour l'usage
  actuel (compte personnel, faible volumétrie).
- Documentation officielle : [psycopg.org/docs](https://www.psycopg.org/docs/).

`psycopg2.extras.RealDictCursor` (utilisé dans `execute_query`) fait que chaque ligne de résultat
est retournée comme un dictionnaire `{nom_colonne: valeur}` plutôt qu'un simple tuple positionnel —
plus pratique pour reconstruire un texte avec les en-têtes de colonnes.

## Autres bibliothèques utiles pour de futurs Tools

- `requests` ou `httpx` (l'exemple officiel OAuth utilise `httpx`, en asynchrone) — pour un Tool
  qui appelle une API HTTP externe plutôt qu'une base de données.
- `pydantic` — déjà utilisé pour `Valves`/`UserValves`, réutilisable pour valider/structurer
  n'importe quelle donnée manipulée par un Tool.
- Pilotes équivalents à `psycopg2` pour d'autres bases si besoin un jour : `mysql-connector-python`
  (MySQL), `pyodbc` (SQL Server via ODBC).

## Lexique rapide

- **Frontmatter/docstring d'en-tête** : le bloc `"""..."""` tout en haut du fichier, lu par Open
  WebUI pour remplir automatiquement nom/description à la création du Tool (auto-fill depuis
  v0.9.6, sans écraser une valeur déjà saisie à la main).
- **`requirements:`** : déclenche une installation pip automatique des packages listés, dès la
  sauvegarde du Tool — rien à installer manuellement sur le serveur.
- **Native (Agentic) Mode vs Legacy Mode** : deux façons dont Open WebUI fait appeler les outils
  par le modèle. Legacy est obsolète et non supporté ; écrire les Tools pour Native (mode par
  défaut aujourd'hui) — pertinent surtout si un Tool utilise des `__event_emitter__` avancés, pas
  un sujet pour `postgres-explorer` qui se contente de retourner une chaîne de caractères.
