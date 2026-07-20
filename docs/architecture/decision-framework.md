# Décisions d'architecture

Décisions techniques (ADR) retenues pour le projet. Le détail de la recherche comparative qui a nourri ces décisions se trouve dans `benchmark-frameworks.md` (même dossier) ; ce fichier-ci ne contient que les décisions elles-mêmes et leur justification.

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

## Serveurs MCP retenus

Comparaison des implémentations candidates pour chaque serveur : voir `benchmark-frameworks.md`, section "Serveurs MCP candidats".

- **mcp-qgis** : [nkarasiak/qgis-mcp](https://github.com/nkarasiak/qgis-mcp) — retenu pour ses capacités étendues (100+ outils vs ~15 pour l'implémentation d'origine jjsantos01/qgis_mcp) et sa compatibilité avec le mode hybride (agit sur le projet QGIS ouvert à l'écran). Détail du montage technique complet : `servers/mcp-qgis/README.md`.
- **mcp-filesystem** : implémentation de référence officielle [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) — la plus pérenne des candidates recensées (maintenue par le MCP steering group/Anthropic). Détail : `servers/mcp-filesystem/README.md`.
- **mcp-postgres** : [crystaldba/postgres-mcp](https://github.com/crystaldba/postgres-mcp) ("Postgres MCP Pro") — retenu plutôt que l'ancienne implémentation de référence Anthropic (archivée, faille d'injection SQL documentée). Détail : `servers/mcp-postgres/README.md`.
- **mcp-excel** : [haris-musa/excel-mcp-server](https://github.com/haris-musa/excel-mcp-server) — le plus populaire et actif des deux candidats évalués, ne nécessite pas Excel installé. Pas encore de dossier `servers/mcp-excel/` créé à ce stade (serveur pas encore mis en place).
