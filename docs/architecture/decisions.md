:::: {.bloc-titre}
::: {.typologie}
Décisions d'architecture v0
:::

# Données & outils IA

::: {.sous-titre}
Étude et expérimentations
:::
::::

**Référence** : 2026-HP-INT-001

Décisions techniques (ADR) retenues pour le projet et justifications. Le détail de la recherche comparative qui a nourri ces décisions se trouve dans `benchmark-techno.md` (même dossier).

## Vue d'ensemble

### Principes
Plusieurs principes ont été suivis dans les choix des technologies. Côté fonctionnel, l'analyse a révélé des usages multiples dans l'exploitation des données, associant la plupart du temps plusieurs outils, en particulier QGIS et Excel. Les données peuvent provenir de la base de données de l'Audiar (bdsig), de ses ressources partagées (Z: et K:) ou directement de la source (web, producteur).

Comme indiqué dans l'**analyse technique**, plusieurs critères ont été formulés par le pôle Données pour sélectionner la solution d'orchestration : 

- open source et gratuits ;
- maintenance minimale ; 
- pouvant regrouper le maximum de fonctionnalités au vu des cas d'usages ;
- IA agnostique (n'importe quel fournisseur API peut être utilisé) ;
- gestion des utilisateurs possibles ;
- connexion possibles à des MCP ;
- fiabilité (documentation, pérennité de la technologie)

Plusieurs autres éléments – opportunités ou contraintes –, ont aussi influencé les choix de technologie et les scénarios de développement :

- possibilité de déployer un outil sur un serveur local (Merlin) ;
- compétences en javascript en développement ;
- démarche de montée en compétences en python pour le traitement de données ;
- accès à l'API de RAGaRenn et possibilité de se tourner vers OVH Cloud.
- catalogage de bdsig non terminé ; 
- chantier d'intégrations de données en cours (pôles environnement et habitat-démographie notamment).


::: {.lie}
### Récapitulatif des décisions

Le détail sur les cas d'usages (CU) peut être consulté dans l'analyse fonctionnelle.

| Composant | Cas d'usage | Outil retenu | Statut (03/08/2026) | Détail |
|-----|----|------|------|--------|
| Solution d'orchestration | CU1 à CU7 | **Open WebUI** | Prototype local et Merlin créés  | Section « Solution d'orchestration » ci-dessous |
| Accès base de données | CU1, CU2 et CU4 | outil python | Monté sur Merlin, à optimiser | outils-openwebui/explorateur-postgres/README.md |
| Utilisation QGIS | CU5 | MCP local [nkarasiak/qgis-mcp](https://github.com/nkarasiak/qgis-mcp) | Configuré sur Merlin, en test | `docs/guides.md`, section « MCP QGIS (serveur externe) » |
| Utilisation Excel | CU3 et CU4 | MCP [haris-musa/excel-mcp-server](https://github.com/haris-musa/excel-mcp-server) | À monter sur prototype local  |  |
| Recherche web | CU4 | Brave, SearXNG et Tavily benchmarkés | À l'étude | `benchmark-techno.md` |
:::


## Solution d'orchestration

### Solution prête à l'emploi vs framework

Deux approches possibles pour construire l'outil : une solution prête à l'emploi (peu ou pas de code, cf. benchmark-techno.md section « Solutions prêtes à l'emploi »), ou un framework à assembler soi-même (LangGraph, CrewAI... cf. même fichier, section « Frameworks »), à l'image de l'application de transcription développée par le pôle Données.

**Décision** : 

Solution prête à l'emploi. 

**Justification** : 

Le critère « maintenance minimale » a pesé plus lourd que la flexibilité d'un framework, qui fait porter au pôle Données la maintenance dans la durée de tout ce qu'une solution prête à l'emploi peut fournir : gestion des utilisateurs/droits, mémoire/persistance, traçabilité, interface. Construire cela soi-même avec LangGraph (l'un des framework les plus pertinents du comparatif) reviendrait à réimplémenter une partie d'Open WebUI.

### Chat/RAG vs mode projet
Les solutions prêtes à l'emploi benchmarkées (cf. `benchmark-techno.md`, même dossier) se répartissent en deux catégories, selon leur orientation : chat/RAG documentaire (AnythingLLM, Open WebUI, LibreChat, Jan, GPT4All) d'un côté, agent autonome/mode projet (Goose, VS Code + Cline, Eigent, Open Cowork, OpenWork, OpenHands) de l'autre. Aucun outil benchmarké n'offre de possibilité sérieuse permettant de combiner ces deux approches.

**Décision** : 

Orientation chat/RAG.

**Justification** :

- **Cadrage fonctionnel** : un agent conversationnel avec appel d'outils suffit pour les quatre cas d'usage priorisés (connaissance du catalogue, extraction depuis une table en base,manipulation Excel assistée, géomatique/QGIS) ; seuls les cas 8 et 9 (actualisation d'une chaîne de traitement, conception méthodo), hors périmètre du développement actuel, nécessitent un mode projet (accès autonome à un dossier de travail complet).
- **Profil utilisateur** : les candidats « mode projet » sont pour la plupart pensés pour un profil développeur (VS Code + Cline suppose un éditeur de code ; OpenHands vise des équipes d'ingénierie logicielle) ou restent jeunes et peu documentés (Eigent, pré-v1.0 ; Open Cowork, organisation anonyme et communauté encore petite) ; ils sont moins adaptés à des chargés d'études non-développeurs que les candidats chat/RAG.
- **Maintenance minimale/fiabilité** : plusieurs candidats « mode projet » sont encore jeunes (pré-v1.0, petites équipes) ou dépendent d'un moteur tiers (OpenWork/OpenCode) ; un profil de risque plus élevé que les leaders établis du chat/RAG (Open WebUI, LibreChat), cohérent avec le critère « maintenance minimale » déjà retenu pour écarter les frameworks (cf. section précédente).

Ce choix n'exclut pas le besoin de mode projet identifié pour les cas d'usage 8 et 9 (et potentiellement 7). Le développement d'un prototype pour ces usages sera à évaluer dans un second temps, notamment la piste VS Code + Cline.

### Open WebUI, AnythingLLM ou LibreChat

**Décision** : 

Open WebUI (https://openwebui.com/)

**Justification** :

La comparaison a d'abord porté sur les trois solutions chat/rag identifiées : Open WebUI, AnythingLLM, LibreChat (cf. `benchmark-techno.md`). Jan et GPT4All ont été écartés car ce sont des applications desktop sans aucun mode serveur/self-hosted documenté, qui impliqueraient une installation et une maintenance individuelles sur chaque poste.

Les trois candidats répondent à plusieurs critères :

- **Souveraineté** : self-hosted, compatible Ollama et tout endpoint API OpenAI pour les trois — cohérent avec la contrainte de sobriété/souveraineté des données.
- **Connexion MCP** : nativement pour AnythingLLM et LibreChat, via le proxy `mcpo` pour Open WebUI (cf. section « Connexion des serveurs MCP » plus bas).
- **Gestion des utilisateurs** : les trois proposent une forme de multi-utilisateurs.

Ils se différencient selon quatre principaux critères :

- **Multi-utilisateurs et droits (maturité)** : Open WebUI à égalité avec LibreChat (RBAC/SSO matures), nettement devant AnythingLLM (rôles basiques, self-hosted Docker uniquement).
- **Effort de déploiement** : Open WebUI à égalité avec AnythingLLM (un seul conteneur Docker), tous deux plus légers que LibreChat (MongoDB + Redis + MeiliSearch + pgvector).
- **MCP local par utilisateur** : mécanisme « Direct Tool Servers », permettant de répondre au besoin d'utiliser QGIS en mode hybride sur le poste de chaque utilisateur. Mécanisme absent chez AnythingLLM et LibreChat.
- **Extensibilité** : les trois candidats permettent d'ajouter des outils/skills sur mesure au-delà du MCP ; Tools/pipelines en Python pour Open WebUI, skills en JavaScript pour AnythingLLM, actions en JavaScript/TypeScript pour LibreChat. L'objectif du projet portant sur l'exploitation des données, et Python faisant référence dans ce domaine, Open WebUI parait plus opportun.

**Point de vigilance** :

La licence Open WebUI n'est plus certifiée OSI (Open Source Initiative) depuis la v0.6.6 (BSD 3-Clause + clause de marque), passant de "open source" à "source disponible". Cela ne restreint pas l'usage mais un resserrement du modèle économique du projet (soutenabilité, monétisation possible) est à surveiller. Des discussions de fork ont déjà eu lieu dans la communauté à ce sujet, aucun fork dominant et pérenne ne s'est imposé à ce jour.


## Dispositifs d'extension et contraintes de déploiement

### Quatre dispositifs
L'ajout de fonctionnalités dans Open WebUI peut se faire via quatre dispositifs :

- **Fonctionnalités par défaut** : trois fonctionnalités – recherche web, génération d'images et interpréteur de code – peuvent/doivent être paramétrés via le back-office ; 
- **Outils** : scripts python pouvant être configurés globalement ou individuellement (ou configurés globalement et paramétrés individuellement) ;
- **Serveurs externes** (MCP notamment) : peuvent être configurés globalement (côté admin) ou localement (côté utilisateur) ;
- **Fonctions** : permettent notamment de configurer des pipelines complètes ou de filtrer/modifier automatiquement les requêtes et réponses.    

Les  fonctions servent à modifier le pipeline de chat lui-même (filtrage automatique des requêtes/réponses, création de nouveaux modèles...). Les besoins prioritaires du projet (BDD, Excel, QGIS) pouvant déjà être couverts par les serveurs externes et les outils, ce dispositif n'a pas été étudié dans le détail.

Deux fonctionnalités par défaut entrent dans le champs de l'étude, la recherche sur le web et l'interpréteur de code. Elles font appel à des moteurs dédiés, qui doivent être paramétrés par un administrateur dans l'espace « Réglages » du panneau d'administration. Elles n'ont pas encore été étudiées dans le détail car elles ne répondent pas aux besoins prioritaires du projet.

Pour répondre aux besoins identifiés, il s'agira ainsi de choisir entre un outil, un serveur externe partagé ou un serveur externe local.

| **Dispositif** | **Configurateur** | **Origine des appels** | **Type de connexion** |
| --- | --- | ---- | --------- |
| Outil | Admin ou user | Serveur | *Aucune (logique interne au code)* | 
| Serveur global | Admin | Serveur | OpenAPI ou StreamableHTTP (MCP natif) |
| Serveur local | User | Navigateur | OpenAPI | 

### À savoir sur les serveurs

#### Processus local

Concernant les serveurs, si le besoin est d'utiliser un logiciel ouvert sur le PC utilisateur (QGIS, Excel...), le serveur doit dans tous les cas tourner sur le même poste, car serveur et logiciel ne peuvent communiquer que par une connexion locale (socket localhost, automation COM/OLE...). Cela implique, pour l'utilisateur, de lancer le serveur sur son PC à chaque fois qu'il veut utiliser un logiciel avec Open WebUI.

Dans ce cas de figure, un serveur peut être configuré localement ou globalement. S'il est configuré localement, l'opération devra être répétée sur tous les postes. S'il est configuré globalement, un administrateur aura deux possibilités : configurer autant de serveurs que d'utilisateurs (avec contrôle d'accès), afin de correspondre à chaque connexion locale, ou mettre en place un proxy/routeur permettant d'ajouter un id dans la requête, afin de rediriger la réponse vers le PC correspondant à cet id, ce qui demande un développement particulier.

Si le serveur est configuré globalement, le poste de l'utilisateur doit toutefois être joignable depuis le serveur où tourne Open WebUI (problématiques de stabilité d'adresse, de pare-feu...). Cela n'a pas été vérifié.

#### OpenAPI vs StreamableHTTP

Dans le cas d'un serveur configuré globalement, le choix entre un paramétrage OpenAPI ou MCP natif (StreamableHTTP uniquement, pas de connexion stdio possible dans Open WebUI) dépendra de la manière dont le MCP a été conçu. Par exemple, actuellement, les MCP construits avec la librairie python FastMCP restreignent par défaut leurs connexions à l'IP locale (localhost/127.0.0.1), sauf configuration explicite du développeur. Pour ces serveurs, il faudra utiliser le paramétrage OpenAPI, ainsi que le logiciel en ligne de commande mcpo, qui sert de proxy entre le serveur MCP (en stdio) et Open WebUI, et expose lui-même une adresse et un port configurables. Ces restrictions de FastMCP pourraient toutefois évoluer dans des versions futures.

Dans la version actuelle d'Open WebUI, la configuration locale d'un serveur est forcément OpenAPI. Elle nécessite donc l'utilisation de mcpo. 

#### Options MCPO
Exposer un serveur MCP en OpenAPI nécessite l'utilisation du proxy mcpo. Celui-ci peut être utilisé avec une commande inline (un serveur MCP par instance), ou avec `--config <fichier.json>` pour lire un fichier au format « mcpServers » (celui de Claude Desktop, Cursor, Cline...), permettant de déclarer plusieurs serveurs MCP à la fois, chacun exposé sous sa propre route par une seule instance mcpo. 

Deux options supplémentaires viennent avec ce mode : `disabledTools` (liste d'outils à exclure de ce qui est exposé, par serveur) et `--hot-reload` (recharge automatique si le fichier de config change, sans redémarrer mcpo).

Il faut également noter que mcpo accepte des requêtes venant de n'importe quel site web ouvert dans un navigateur, pas seulement d'Open WebUI. La clé API du processus, configurée manuellement, devra donc être suffisamment sécurisée. 

#### Modes d'installation et de lancement
Plusieurs stratégies sont possibles pour installer et lancer un MCP, selon où le serveur doit ou peut tourner, ses dépendances et les contraintes du pôle Données.

**Installation permanente** : 
Installation du serveur via `pip` ou `uv tool`. Avantages : version figée et traçable. Inconvénients : mise à jour manuelle. Si `pip` est choisi, il sera préférable de lancer le serveur dans un environnement (venv).

**Installation temporaire** : 
Installation dans le cache persistant de uv via `uvx`.  Avantages : vérification mise à jour à chaque lancement et téléchargement nouvelle version si elle existe. Inconvénients : version non traçable.

De la même manière, **mcpo** peut être installé de manière permanente via `pip` ou `uv tool` ou dans le cache persistant de uv via `uvx`. La version de mcpo à installer et celle du SDK MCP doivent être surveillées : au 3 août, la dernière version de mcpo n'avait pas encore implémenté la nouvelle version du SDK MCP (2.0.0).

Dans le cas d'un MCP devant tourner sur un PC utilisateur, le lancement peut se faire via une ligne de commande. Un geste manuel qui pourrait être remplacé par une tâche planifiée au démarrage/à l'ouverture de session ou par un service Windows (par exemple NSSM/WinSW encapsulant la commande `uvx`).

Dans ce projet, une installation temporaire via `uvx` a été choisie.

#### Docker et localhost

Enfin, si OpenWebUI est installé dans Docker, il faut noter que l'adresse http://localhost pointe vers son conteneur. Dans le cas d'un serveur configuré globalement, l'appel est lancé depuis le conteneur (et non pas du navigateur). Si le serveur où se trouve Docker doit être joint, il faudra utiliser l'adresse http://host.docker.internal. 

### À savoir sur les outils
Qu'il soit installé par un utilisateur ou un administrateur, un outil (script python) tourne toujours côté serveur, pas côté navigateur. Il ne peut donc pas être utilisé pour interagir avec un logiciel tournant sur le PC utilisateur.

Open WebUI intégre un mécanisme, les valves, consistant à permettre la configuration de certains paramètres d'outils partagés par les utilisateurs (par exemple des id et mots de passe).

Un outil n'étant pas isolé, son code s'exécute avec les mêmes accès que le processus Open WebUI (réseau, identifiants, fichiers), ceux du conteneur Docker s'il y en a un, ceux du serveur entier sinon. Le risque dépend donc de ce que fait chaque outil, sans protection propre à Open WebUI.


## Briques fonctionnelles
Cette section rend compte des dispositifs sélectionnés par chaque besoin. Si un serveur est choisi, le type de configuration, le mode d'installation et de lancement et les versions utilisées seront précisés.

### Accès à la base de données

**Cas d'usage** : 

CU1 (connaissance des données Audiar), CU2 (extraction de données en base) et CU4 (édition de tables, enrichissement et classifications)

**Décision** : 

Outil / connexion à sandbox avec compte utilisateur. Documentation dans `outils-openwebui/explorateur-postgres/README.md`. 

**Justification** :

Deux bases étaient candidates : bdsig (en lecture seule) et sandbox (accès en écriture dans son schéma individuel). Plusieurs approches ont été envisagées : 

- serveur MCP configuré globalement avec compte IA / bdsig
- serveur MCP configuré globalement avec compte utilisateur / bdsig ou sandbox
- serveur MCP configuré localement avec compte utilisateur / bdsig ou sandbox
- outil avec compte IA / bdsig
- outil avec compte utilisateur / bdsig ou sandbox

Utiliser un compte créé spécifiquement pour l'IA a l'avantage de sécuriser la base de données, aucun accès en écriture n'étant théoriquement accordé à ce compte. Cependant, ce compte n'existe pas à ce jour, et il restreignerait l'usage des chargés d'études : ils ne pourraient pas écrire dans leur espace sandbox, leur demandant d'importer manuellement les données résultant de leurs requêtes dans cet espace individuel, si les traitements qu'ils mènent sont multiples. Un accès à la base sandbox, avec compte utilisateur, a donc été privilégié, en considérant qu'il permet l'accès à l'ensemble des tables de bdsig (tables distantes via FWD). 

Deux MCP benchmarkés (cf `benchmark-techno.md`) ont été testés, crystaldba et dbhub. Ils proposent des avantages différents : crystaldba intégre des outils d'introspection de schéma et d'analyse de performance ; dbhub propose des options de sécurité (limitations d'usage et chiffrement des connexions réseau TLS/tunnel SSH).

Ils ont tout deux été exclus, le premier car il n'est plus maintenu depuis plusieurs mois, avec des tickets ouverts qui s'accumulent ; le second car, outre une dépendance à Node.js, il a montré des limites dans son intégration mcpo/Windows (diverses erreurs de connexions rencontrées, sans résolution). Aussi, ils n'ont pas de plus-value par rapport à un outil en python : celui-ci peut si besoin intégrer introspection de schéma et chiffrement des connexions, les chargés d'études n'ont pas besoin d'analyse de performance, et la sécurité de la base est portée par les droits définis dans Postgres. 

Par ailleurs, utiliser un serveur configuré globalement obligerait à stocker tous les mots de passe individuels dans une configuration gérée par l'administrateur, et une configuration locale doit être répétée chez tous les utilisateurs. Tandis qu'un outil, avec son mécanisme de valves (voir ci-dessus la section « Extensibilité Open WebUI et contraintes »), doit être configuré une seule fois par l'administrateur. Les utilisateurs n'auront qu'à renseigner, une seule fois, leur id et mot de passe dans les paramètres de l'outil. 

**Limites** :

Quel que soit le dispositif utilisé, plusieurs risques ou limites exposés dans les analyses fonctionnelle et technique doivent être prises en compte : 
- risque d'erreurs SQL silencieuses (jointure, filtre...) : point d'attention à ajouter dans les guides d'utilisation ;
- base de données pas encore documentée : tests sur tables cibles (bse éco, base logement, MOS/Cosia) avec une documentation à créer.

### Utilisation de QGIS


**Cas d'usage** : 

CU5 (géomatique et cartographie)

**Décision** : 

MCP QGIS [nkarasiak/qgis-mcp](https://github.com/nkarasiak/qgis-mcp). Documentation dans `docs/guides.md`, section « MCP QGIS (serveur externe) ». 

**Justification** :

Vu les usages actuels – avec QGIS comme principal logiciel – et les besoins identifiés, la comparaison a porté sur des dispositifs permettant d'utiliser QGIS en session ouverte, afin de permettre un usage hybride, à la fois manuel et IA. Deux MCP benchmarkés offrent cette possibilité. Le MCP nkarasiak/qgis-mcp a été retenu pour ses capacités étendues (plus de 100 outils contre environ 15 pour l'implémentation d'origine jjsantos01/qgis_mcp).


### Utilisation d'Excel
**Cas d'usage** : 

CU3 (manipulation Excel et traitements de données assistés)

**Décision** :

**Justification** :

Un usage hybride étant attendu (utilisation de l'IA s'ajoute à l'utilisation des outils) et le contrôle des résultats produits étant un enjeu important, la comparaison a notamment porté sur la capacité des outils à interagir en direct dans les documents ouverts par les utilisateurs. 

À cet égard, il faut noter que : 
- sous Windows, un fichier `.xlsx` ouvert dans Excel est verrouillé en écriture pour les autres processus ; une tentative d'écriture par openpyxl (ou toute bibliothèque équivalente manipulant le fichier directement) échoue avec `PermissionError` (`WinError 32`) tant que le fichier reste ouvert. Ainsi, les MCP de `haris-musa` et `guillehr2` ne peuvent pas offrir de mode hybride par construction, seule une lecture seule (`read_only=True`) reste possible fichier ouvert, jamais l'écriture.
- ce fonctionnement n'est possible qu'avec le MCP tournant sur la machine de l'utilisateur — approche COM/OLE (`sbroenne`, `negokaz` en mode "Live editing") —, pas de manière centralisée, qui ne permet que l'approche fichier (`haris-musa`, `negokaz` en mode normal, `guillehr2`).

Les fichiers Excel concernés sont des fichiers locaux, sur le poste Windows de chaque chargé d'études. La piste d'une co-édition via Microsoft Graph API (fichier en ligne, co-édition native Excel) est donc écartée d'emblée pour ce prototype.


### Recherche sur le web

**Cas d'usage** : 

CU4 (édition de tables, enrichissement et classifications) et usages hors projet

**Décision** :

**Justification** :

### Accès aux fichiers locaux

**Cas d'usage** :

**Décision** :

**Justification** :











