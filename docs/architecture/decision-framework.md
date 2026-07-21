# Décisions d'architecture

Décisions techniques (ADR) retenues pour le projet. Le détail de la recherche comparative qui a nourri ces décisions se trouve dans `benchmark-frameworks.md` (même dossier) ; ce fichier-ci ne contient que les décisions elles-mêmes et leur justification.

## Vue d'ensemble

| Composant | Outil retenu | Statut (21/07/2026) | Détail |
|---|---|---|---|
| Framework d'orchestration | **Open WebUI** ("Open WebUI Audiar") | Instance à créer, à commencer en local sur le poste de Charlotte | Section "Framework d'orchestration" ci-dessous |
| Connexion des serveurs MCP | **mcpo** (proxy MCP → OpenAPI) | Choix arrêté | Section "Connexion des serveurs MCP à Open WebUI" ci-dessous |
| mcp-qgis | [nkarasiak/qgis-mcp](https://github.com/nkarasiak/qgis-mcp) | **Monté et validé**, y compris compte non-admin | `servers/mcp-qgis/README.md` |
| mcp-postgres | [crystaldba/postgres-mcp](https://github.com/crystaldba/postgres-mcp) | Prochain serveur à monter | `servers/mcp-postgres/README.md` |
| mcp-filesystem | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) | Reporté — pas de cas d'usage l'appelant dans le scope Open WebUI actuel | Section "Serveurs MCP retenus" ci-dessous |
| mcp-excel | [haris-musa/excel-mcp-server](https://github.com/haris-musa/excel-mcp-server) | Pas encore monté (dossier `servers/mcp-excel/` à créer) | Section "Serveurs MCP retenus" ci-dessous |
| Recherche web (fonction native Open WebUI) | **Pas encore tranché** — Brave, SearXNG et Tavily benchmarkés | Décision à prendre | `benchmark-frameworks.md`, section "Moteurs de recherche web candidats" |

## Framework d'orchestration : Open WebUI Audiar (instance à créer)

**Décision (20/07/2026)** : pour l'usage courant (catalogue, appels d'outils MCP dont QGIS en mode hybride — cf. `servers/mcp-qgis/README.md`), le framework retenu est **Open WebUI** ("Open WebUI Audiar" une fois l'instance créée et personnalisée). Aucune instance Open WebUI n'existe encore chez Audiar à ce stade — elle est à créer, en commençant par une installation locale sur le poste de Charlotte (prototype, voir `docs/guides.md`), avant d'envisager un hébergement partagé pour plusieurs chargés d'études. Comparé aux dix autres candidats évalués (voir `benchmark-frameworks.md`), justification par critère :

- **Effort de développement** : plus faible que les autres candidats du benchmark, mais pas nul — l'instance est à créer (voir `docs/guides.md`, pas-à-pas d'installation locale via Docker). Reste ensuite à connecter les serveurs MCP métier, via le proxy `mcpo` (MCP → OpenAPI) — voir `servers/mcp-qgis/README.md` pour le détail et la justification de ce choix. Contrairement à un développement sur-mesure (cf. `benchmark-frameworks.md`, section briques d'orchestration), il n'y a rien à coder : seulement à déployer et configurer des outils existants.
- **Documentation** : documentation officielle complète et à jour (docs.openwebui.com), section dédiée à l'extensibilité MCP (docs.openwebui.com/features/extensibility/mcp/), large communauté donc bon niveau de tutoriels/retours d'expérience tiers.
- **Facilité d'utilisation** : interface de chat déjà connue en interne par les chargés d'études (outil existant, pas un nouvel outil à apprendre) ; prise en main immédiate pour l'usage courant (chat/RAG). La configuration MCP/agentique reste du ressort de l'administrateur, transparente pour l'utilisateur final une fois en place.
- **Outils paramétrables** : compatibilité MCP native depuis la v0.6.31, ou via le proxy `mcpo` (MCP → OpenAPI) sur les versions antérieures ; pipelines/"functions" Python + large écosystème de plugins communautaires pour étendre au-delà du MCP.
- **Gestion mémoire** : historique des conversations persistant côté serveur + RAG documentaire intégré — pertinent pour le cas d'usage 1 (connaissance du catalogue Audiar).
- **Gouvernance multi-utilisateurs** : RBAC natif, groupes, SSO possible — un des points les plus mûrs du benchmark, nécessaire pour un déploiement à plusieurs chargés d'études (contrairement aux outils mono-utilisateur comme Goose ou VS Code + Cline).
- **Souveraineté** : self-hosted par construction, compatible Ollama et tout endpoint API OpenAI — cohérent avec la contrainte de sobriété/souveraineté des données (RAGaRenn/OVH Cloud).

**Point de vigilance conservé** : la licence "Open WebUI License" n'est plus certifiée OSI depuis la v0.6.6 (BSD 3-Clause + clause de marque) — à surveiller si l'agence a une politique stricte sur les licences ; des discussions de fork ont déjà eu lieu dans la communauté à ce sujet, sans qu'un fork dominant et pérenne ne se soit encore imposé à ce jour.

**Limite assumée** : le "mode projet" d'Open WebUI reste plus faible que des candidats comme Goose, Eigent ou Open Cowork (pas d'exécution autonome multi-étapes native, dépend du proxy `mcpo` pour l'agentique). Ce choix couvre l'usage courant (chat, catalogue, appels d'outils MCP dont QGIS en mode hybride) ; à réévaluer si un besoin d'agent autonome de type Cowork sur un dossier de travail complet devient prioritaire.

**Extensibilité Open WebUI (pipelines/"functions" Python) — non exploitée à ce stade** : Open WebUI permet d'étendre son comportement par du code Python custom (pipelines/functions), au-delà du MCP. Aucun besoin identifié à ce jour ne justifie d'écrire ce type de code — le prototype actuel se limite au déploiement/config de l'instance + connexion des serveurs MCP métier via `mcpo`. Si un besoin de personnalisation custom apparaît, y revenir à ce moment-là (pas de dossier réservé à l'avance dans le repo).

## Serveurs MCP retenus

Comparaison des implémentations candidates pour chaque serveur : voir `benchmark-frameworks.md`, section "Serveurs MCP candidats".

- **mcp-qgis** : [nkarasiak/qgis-mcp](https://github.com/nkarasiak/qgis-mcp) — retenu pour ses capacités étendues (100+ outils vs ~15 pour l'implémentation d'origine jjsantos01/qgis_mcp) et sa compatibilité avec le mode hybride (agit sur le projet QGIS ouvert à l'écran). Détail du montage technique complet : `servers/mcp-qgis/README.md`. **Statut (20/07/2026) : monté et validé**, y compris pour un compte non-admin.
- **mcp-postgres** : [crystaldba/postgres-mcp](https://github.com/crystaldba/postgres-mcp) ("Postgres MCP Pro") — retenu plutôt que l'ancienne implémentation de référence Anthropic (archivée, faille d'injection SQL documentée). Détail : `servers/mcp-postgres/README.md`. **Statut (20/07/2026) : prochain serveur à monter** — répond au cas d'usage 2 de l'analyse fonctionnelle ("extraction de données depuis une table en base", outils envisagés "Open WebUI + MCP BD").
- **mcp-filesystem** : implémentation de référence officielle [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) — la plus pérenne des candidates recensées (maintenue par le MCP steering group/Anthropic). Détail : `servers/mcp-filesystem/README.md`. **Statut (20/07/2026) : reporté, pas de priorité dans le scope Open WebUI actuel.** Aucun des 9 cas d'usage de `docs/sources/2026_analyse-fonctionnelle_V1.txt` n'appelle un accès fichiers générique via Open WebUI : le cas d'usage 3 (Excel) exclut explicitement Open WebUI pour ce type de tâche au profit d'un contrôle pas à pas (extension application, Claude Desktop) ; les cas d'usage 8/9 ("mode projet", accès à l'ensemble des fichiers) visent VS Code + Cline, Claude Desktop ou un outil type Cowork open source — pas Open WebUI, cohérent avec la "Limite assumée" ci-dessus sur le mode projet d'Open WebUI. `mcp-filesystem` n'a donc de sens que si un outil "mode projet" distinct d'Open WebUI est un jour retenu pour ce scope.
- **mcp-excel** : [haris-musa/excel-mcp-server](https://github.com/haris-musa/excel-mcp-server) — le plus populaire et actif des deux candidats évalués, ne nécessite pas Excel installé. Pas encore de dossier `servers/mcp-excel/` créé à ce stade (serveur pas encore mis en place). Même réserve que `mcp-filesystem` : le cas d'usage 3 (Excel) désigne une extension application ou Claude Desktop comme outils préférés à Open WebUI pour ce cas précis — à réévaluer selon l'outil finalement choisi pour ce cas d'usage.

## Connexion des serveurs MCP à Open WebUI : pourquoi `mcpo`

Chaque serveur MCP métier (`mcp-qgis`, `mcp-postgres`, futurs `mcp-filesystem`/`mcp-excel`) est exposé à Open WebUI via **`mcpo`** ([open-webui/mcpo](https://github.com/open-webui/mcpo), proxy MCP stdio → OpenAPI), ajouté ensuite comme connexion **OpenAPI** — jamais en MCP natif, malgré le support MCP natif d'Open WebUI depuis la v0.6.31. Deux raisons, documentées sur docs.openwebui.com/features/extensibility/mcp et vérifiées en conditions réelles le 20/07/2026 (sur `mcp-qgis`, premier serveur monté) :

1. **Admin-only et centralisé** : un serveur MCP natif ne peut être ajouté que par un administrateur (*Admin Settings → External Tools*), jamais par un utilisateur individuel. Sur une instance mutualisée entre plusieurs chargés d'études, une URL `localhost` configurée une fois par l'admin pointerait vers le poste de l'admin, pas vers celui de chaque agent — inutilisable pour un montage où l'outil tourne sur le poste de chaque utilisateur (ex. QGIS en mode hybride, cf. `servers/mcp-qgis/README.md`). Le mécanisme qui résout ce problème pour un déploiement à plusieurs utilisateurs — **"Direct Tool Servers"**, qui fait bien partir l'appel depuis le navigateur de chacun pour atteindre son propre `localhost` — n'existe que pour les serveurs **OpenAPI**, pas pour MCP natif. D'où le choix d'exposer chaque serveur MCP métier en OpenAPI via `mcpo`. Paramétrage des droits nécessaire côté Open WebUI pour activer ce mécanisme : voir `docs/guides.md`, section "Paramétrer les droits Open WebUI (instance mutualisée)".
2. **Protection anti-DNS-rebinding, même en local** : les serveurs MCP construits avec FastMCP (dont `qgis-mcp-server`) activent par défaut une vérification de l'en-tête HTTP `Host` de la requête entrante contre une liste blanche limitée à `localhost`/`127.0.0.1`. Comme Open WebUI tourne dans Docker, il doit appeler `http://host.docker.internal:<port>` pour atteindre le poste hôte — un `Host` qui n'est jamais dans cette liste blanche. Résultat observé (sur `qgis-mcp-server`) : `421 Misdirected Request`. Aucune variable d'environnement documentée par ce projet ne permet d'élargir cette liste blanche. Ce blocage touche donc aussi le cas d'un Open WebUI local (pas seulement l'instance mutualisée), et concerne potentiellement tout futur serveur MCP également construit avec FastMCP.

`mcpo` évite ce deuxième problème par construction : il lance le serveur MCP lui-même en sous-processus (transport `stdio`, pas de couche HTTP entre les deux), et expose sa propre API OpenAPI (FastAPI, sans cette vérification de `Host`).

## Lancement des serveurs MCP : pourquoi `uv`/`uvx` plutôt qu'un `pip install` classique

**Décision** : chaque serveur MCP métier (`qgis-mcp-server`, `postgres-mcp`) est lancé via `uvx` — jamais installé « en dur » dans un environnement Python dédié via `pip install`. Commandes exactes : `servers/mcp-qgis/README.md` et `servers/mcp-postgres/README.md` ; pas-à-pas d'installation d'`uv` sur le poste : `docs/guides.md`.

Justification (vérifiée le 20/07/2026 lors du montage de `mcp-qgis`, équivalent de `npx` côté écosystème JavaScript) :

- Pas de `venv` à créer/activer manuellement par un profil non-développeur à chaque session.
- Toujours la version exacte du dépôt GitHub visé (`--from git+https://...`), sans étape d'installation séparée à maintenir dans le temps.
- Cache stocké globalement (`%LOCALAPPDATA%\uv\cache` sous Windows) — rien ne pollue le dossier du projet.
- Téléchargement une seule fois (mise en cache), démarrages suivants rapides ; `--refresh-package` disponible pour forcer une revérification de la dernière version si besoin (non utilisé au quotidien).

## Point de vigilance : passage à l'échelle (15 utilisateurs) — supervision des processus `uv`/`mcpo`

**Pas encore tranché (identifié le 21/07/2026)**. Aujourd'hui, chaque serveur `mcpo`/`uvx` est lancé manuellement dans un terminal laissé ouvert sur le poste de Charlotte — acceptable pour un prototype à une personne, mais ça ne tiendra pas pour un déploiement à 15 chargés d'études non-développeurs. La réponse diffère selon deux familles de serveurs :

- **Serveurs liés à un poste individuel** (`mcp-qgis` aujourd'hui ; potentiellement de futurs `mcp-excel`/`mcp-filesystem` s'ils touchent des fichiers ou applications locales) : doivent tourner sur la machine de chaque agent, pas ailleurs. Le geste manuel actuel (ouvrir un terminal, coller la commande, le laisser ouvert) devra être remplacé par un lancement silencieux et automatique — piste à évaluer : tâche planifiée au démarrage/à l'ouverture de session Windows, ou véritable service Windows (ex. NSSM/WinSW encapsulant la commande `uvx`), avec redémarrage automatique en cas de plantage.
- **Serveurs centralisés** (`mcp-postgres`, qui n'a aucune raison de dépendre du poste d'un utilisateur en particulier puisqu'il interroge une base distante) : à déployer une seule fois, sur le même serveur que l'instance Open WebUI mutualisée à venir, géré comme un vrai service (conteneur Docker avec `--restart always`, ou service systemd/Windows) plutôt qu'en commande manuelle dans un terminal lié à un poste précis.

Cette question est une sous-partie de la décision d'hébergement partagé déjà anticipée plus haut ("commencer en local... avant d'envisager un hébergement partagé") — à trancher au moment de packager le déploiement pour plusieurs chargés d'études, pas avant. Aucun outil de supervision précis n'a été benchmarké à ce stade.
