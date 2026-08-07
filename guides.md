:::: {.bloc-titre}
::: {.typologie}
Notice administrateur v0
:::

# Données & outils IA

::: {.sous-titre}
Installation Open WebUI et outils
:::

::: {.date}
ÉTÉ 2026
:::
::::

**Référence** : 2026-HP-INT-001


Guide d'installation et d'utilisation d'Open WebUI (v0.10.2) sur le serveur interne mutualisé Merlin. Il documente notamment la création et le paramétrage d'Open WebUI, ses fonctionnalités, la gestion des droits, la gestion de la mémoire.

Les différents choix opérés sont documentés dans `decisions.md`.

## Installer Open WebUI

**Prérequis**

- Docker Desktop installé et lancé
- Connexion internet pour télécharger l'image Open WebUI

**Étape 1 | Installer et lancer Open WebUI**

Dans le terminal :

```bash
docker run -d -p 8195:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```

Détail de la commande :

- `-d` : lance le conteneur en arrière-plan.
- `-p 8195:8080` : rend l'interface accessible sur `http://srv-gitlab.audiar.net:8195` (8080 = port dans le conteneur Docker).
- `-v open-webui:/app/backend/data` : les données (comptes, conversations, config) sont conservées même si le conteneur est recréé.
- `--restart always` : Open WebUI redémarre automatiquement avec Docker Desktop.

Le premier lancement télécharge l'image (plusieurs centaines de Mo, peut prendre quelques minutes).

**Étape 2 | Créer le compte admin**

Ouvrir [http://srv-gitlab.audiar.net:8195](http://srv-gitlab.audiar.net:8195) dans un navigateur. Le premier compte créé devient automatiquement administrateur (son compte ne pourra pas être supprimé ni son rôle modifié, voir ci-desous la section [Gestion des droits](#gestion-des-droits)). Choisir un email/mot de passe (peuvent être différents de ceux du poste).

**Étape 3 | Lancer Open WebUI**

```bash
docker start open-webui # Open WebUI lancé en arrière-plan
```

Les applications tournant en docker sur Merlin actuellement sont lancées via la commande  `docker compose` et des fichiers de configuration YAML `docker-compose.yml` et `docker-compose.dev.yml`. Ce n'est pas le mode qui a été utilisé pour lancer Open WebUI sur Merlin. Le mode de lancement devra si besoin être adapté.

**Étape 4 | Vérifier la version**

Le fichier JSON disponible à l'adresse [http://srv-gitlab.audiar.net:8195/api/config](http://srv-gitlab.audiar.net:8195/api/config) indique dans les premiers champs la version d'Open WebUI installée.

Le numéro de version est aussi indiqué dans le menu **A propos** du panneau **Réglages**, accessible en cliquant sur la bulle **Profil** (en bas à gauche).



**Plus tard | Mettre à jour Open WebUI**
  ```
  docker pull ghcr.io/open-webui/open-webui:main
  docker stop open-webui && docker rm open-webui
  ```
  puis relancer la commande de l'étape 1 (les données sont conservées grâce au volume `open-webui`).
  

## Paramétrer les connexions et les modèles

Les fournisseurs de modèles LLM par API — Mistral, RAGaRenn, OVHcloud AI Endpoints, catalogue comparé dans `benchmark-modeles.md` — se connectent via le protocole **OpenAI-compatible**, nativement supporté par Open WebUI.


### Configurer une connexion au modèle (API)

#### Endpoints et clé API

Deux informations sont nécessaires à la création d'une connexion : l'endpoint du fournisseur et la clé API.

##### RAGaRenn 

Endpoint : [https://ragarenn.eskemm-numerique.fr/test@audiar/api](https://ragarenn.eskemm-numerique.fr/test@audiar/api)

Au 06/08/2026, c'est la clé API de Charlotte de l'instance Open WebUI de RAGaRenn ([https://ragarenn.univ-rennes.fr/test@audiar/app](https://ragarenn.univ-rennes.fr/test@audiar/app)) configurée pour l'Audiar qui est utilisée. Elle est disponible via **Profil** → **Paramètres** → **Compte** → **Clés d'API** → **Token JWT** → **📋 Copier**.

Cette est renouvellée régulièrement (environ tous les 10 jours), et doit donc être mise à jour dans l'instance Merlin. 

##### Mistral 

Endpoint :  [https://api.mistral.ai/v1](https://api.mistral.ai/v1)

L'abonnement à l'API de Mistral est gérée par le pôle Données.

##### OVH Cloud  

Pas d'abonnement au 06/08/2026. 

#### Modèles disponibles

Pour connaître la liste des modèles disponibles dans les API, il est possible d'interroger l'API, par exemple en ligne de commandes. Exemples de scripts bash (à adapter dans Powershell) :

**RAGaRenn**
```bash
curl https://ragarenn.eskemm-numerique.fr/test@audiar/api/models \
  -H "Authorization: Bearer cle-API"
```

**Mistral**
```bash
curl https://api.mistral.ai/v1/models \
  -H "Authorization: Bearer cle-API"
```

#### Procédure

1. **Panneau d'administration** → **Réglages** → **Connexions** → **➕ Ajouter une connexion**.

2. Renseigner **URL** et **Auth** (Bearer = clé API) du fournisseur.

3. Open WebUI vérifie la connexion en appelant l'endpoint `/models` du fournisseur avec le Bearer token. 

4. Si besoin, préciser les id des modèles visés. Si ce n'est pas précisé, tous les modèles disponibles seront intégrés.

5. Pour faciliter la gestion des modèles une fois les connexions configurées, il est possible de renseigner un ID de préfixe. 

À l'étape 3, si l'appel  à l'endpoint échoue (403/400/401) sans que le fournisseur soit incompatible pour autant, ajouter manuellement les IDs de modèles dans **"Model IDs (Filter)"** de la connexion peut résoudre les problèmes de connexion (la connexion affiche un statut d'erreur mais le chat fonctionne).

### Paramétrage des modèles

Une fois les connexions configurées, les modèles peuvent être gérés via
**Panneau d'administration** → **Réglages** → **Modèles**. Il est possible d'indiquer quels modèles sont disponibles en activant/désactivant les boutons.

#### Réglages par défaut

**Panneau d'administration** → **Réglages** → **Modèles** → **Réglages** (bouton en haut à droite) → **Valeurs par défaut**.

La configuration des modèles comprend :

- **Réglages avancés** : permet de renseigner un certain nombre de paramètres des requêtes (nombre maximum de token, paramètres d'échantillonnage, efforts de raisonnement...)
- **Capacités** : permet de fixer ce que le modèle a le droit de faire ;
- **Fonctionnalités par défaut** : si cochées, elles sont automatiquement activées à chaque nouvelle conversation. Les trois fonctionnalités – recherche web, génération d'images et interpréteur de code – doivent être configurées ailleurs ;
- **Outils intégrés** : outils que le modèle peut appeler lui-même via des appels de fonction.

### Réglages par modèle
Via **Panneau d'administration** → **Réglages** → **Modèles** → **✏️**, la configuration d'un modèle peut être modifiée par rapport aux réglages par défaut et intégrer en plus un prompt système, des connaissances, des outils et des skills (voir section [Espace de travail][#espace-de-travail] ci-dessous). Leur nom d'affichage peut aussi être modifié. 

C'est uniquement depuis cet espace qu'il est possible de rendre les modèles accessibles à d'autres utilisateurs, avec deux possibilités :

  - configurer l'accès comme "public" ;
  - configurer l'accès comme "privé" et accorder des droits à des utilisateurs ou des groupes.

  Sources : 
- [Open WebUI](https://docs.openwebui.com/getting-started/quick-start/settings/)
- [Open WebUI](https://docs.openwebui.com/features/workspace/models/)

**Mode Arena**
Open WebUI intègre un outil de comparaison de modèles dit « Arena Model », qui apparaît dans les modèles disponibles. Il peut être activé/désactivé dans **Panneau d'administration** → **Réglages** → **Évaluations** → **Modèles d'arène**. Son fonctionnement n'a pas été étudié.

### Décompte des tokens consommés

Open WebUI propose, pour les administrateurs, un outil de suivi de l'utilisation des tokens, disponible via **Panneau d'administration** → **Analytique**. Pour cela, la capacité **Utilisation** des modèles doit être cochée (réglages par défaut et/ou réglages par modèle, voir ci-dessus).

Cette consommation de token est agrégée pour tous les utilisateurs, par groupe ou par utilisateur, et par période, avec un agrégat quotidien pour le plus détaillé. 

## Gestion des droits

La gestion des droits des utilisateurs et des groupes se gèrent à trois niveaux : 

- via **Panneau d'administration** → **Réglages** : gestion des accès des utilisateurs et des groupes aux modèles (voir plus haut la section [Paramétrage des modèles](#paramétrage-des-modèles) plus haut) et aux outils externes (serveurs OpenAPI ou serveurs MCP via proxy mcpo) configurés par les administrateurs ;
- via **Panneau d'administration** → **Utilisateurs** → **Groupes** : gestion des autorisations de tous les utilisateurs (Autorisations par défaut) et de celles des groupes (**Groupes** dans les réglages du groupe) ;
- via **Espaces de travail** : chaque outil, skill, prompt, connaissance et modèle (dans cet espace, un « modèle » associe un modèle d'IA et et un ensemble d'éléments : outils, skills, prompts, connaissances) : gestion de l'accès des utilisateurs et des groupes à ces éléments.

### Rôles disponibles

Trois rôles système, aussi utilisés comme valeurs de la colonne `Role` du CSV d'import (ci-dessous) :


| **Rôle** | **Mot clé** | **Description** |
|----|---|---------------|
| Administrateur | admin | Accès total : gestion des utilisateurs, groupes, config globale |
| Utilisateur | user | Soumis aux permissions RBAC (défauts + groupes), aucun accès implicite |              |
| En attente | pending | Aucun accès tant qu'un admin ne l'a pas approuvé manuellement — recommandé comme rôle par défaut sur une instance partagée (`DEFAULT_USER_ROLE=pending`)|

### Premier compte administrateur

La documentation officielle précise que le tout premier compte créé sur l'instance (« primary administrator ») a une protection : pas de bouton de suppression dans l'interface. Selon le code source (analyse IA, Claude Sonnet 5), le rôle du primary administrator est verrouillé sur **admin** de façon permanente, au niveau backend (403 `ACTION_PROHIBITED`) : il ne peut pas s'auto-rétrograder et aucun autre admin ne peut changer son rôle.

Les autres comptes admin (créés après le premier) n'ont pas cette protection : leur rôle reste librement modifiable par n'importe quel admin, y compris vers **user** ou **pending**.

### Gestion des utilisateurs et des groupes

Deux possibilités pour ajouter des utilisateurs : manuellement ou via un fichier csv, selon un modèle fixe (voir `plateforme/gabarits/user-import.example.csv`).

Concernant la création via un fichier csv, il faut noter qu'il ne permet pas une gestion globale : 

- si un utilisateur avec la même adresse email existe déjà, il n'est pas ajouté, et la configuration de l'utilisateur déjà enregistré ne change pas ;
- si un utilisateur existant n'est pas renseigné dans le csv, son compte n'est pas supprimé. 

Ce fichier doit par ailleurs faire l'objet d'une grande vigilance puisqu'il contient les mots de passe des utilisateurs.

Les autorisations des utilisateurs se gèrent via les groupes. Des utilisateurs peuvent être ajoutés seulement une fois le groupe créé.

## Espace de travail et dispositifs d'extension

### Espace de travail

L'espace de travail comprend cinq entrées : Modèles, Connaissances, Prompts, Skills et Outils.

**Modèles** : 

Préréglages combinant un modèle IA de base avec un prompt système, des connaissances, des outils et des skills, pour créer des « agents » spécialisés sans toucher au modèle sous-jacent.

Documentation : [https://docs.openwebui.com/features/workspace/models](https://docs.openwebui.com/features/workspace/models)

**Connaissances** : 

Bases documentaires (PDF, tableurs, code, texte) que le modèle interroge via RAG pour répondre en s'appuyant sur des documents précis. 

Documentation : [https://docs.openwebui.com/features/workspace/knowledge](https://docs.openwebui.com/features/workspace/knowledge)

**Prompts** : 

Instructions réutilisables enregistrées comme commandes slash (ex. /résumer), avec variables et formulaires, pour lancer en un clic une demande complexe déjà rédigée.

Documentation : [https://docs.openwebui.com/features/workspace/prompts/](https://docs.openwebui.com/features/workspace/prompts/)

**Skills** : 

Consignes de fond en markdown, attachables durablement à un modèle ou invocables ponctuellement, qui indiquent au modèle comment se comporter/raisonner sur un type de tâche.

Documentation : [https://docs.openwebui.com/features/workspace/skills/](https://docs.openwebui.com/features/workspace/skills/)

**Outils** : 

Scripts Python exécutés côté serveur qui donnent au modèle des capacités concrètes (recherche web, requêtes, génération d'image, etc.). Documentation : https://docs.openwebui.com/features/extensibility/plugin/tools

Pour ces quatre éléments, deux niveaux d'accès sont prévus : 

- droits d'utiliser ces fonctionnalités, d'en importer, d'en exporter et de les partager avec d'autres utilisateurs, paramétrés par les administrateurs (sauf la création de modèles, permise par défaut) ;
- droits sur les éléments : chaque nouvel élément créé est restreint par défaut à son utilisateur, des droits de lecture ou d'écriture doivent être accordés à des utilisateurs ou des groupes par un administrateur ou son créateur (si les droits de partage lui sont accordés).

### Dispositifs d'extension

#### Quatre dispositifs
L'ajout de fonctionnalités dans Open WebUI peut se faire via quatre dispositifs : 

- **Fonctionnalités par défaut** : trois fonctionnalités – recherche web, génération d'images et interpréteur de code – peuvent/doivent être paramétrés via le back-office ; 
- **Outils** : scripts python pouvant être configurés globalement ou individuellement (ou configurés globalement et paramétrés individuellement) ; modèle de script fourni à la création dans Open WebUI ;
- **Serveurs externes** (MCP notamment) : peuvent être configurés globalement (côté admin, partageables, OpenAPI ou StreamableHTTP, appel depuis le backend Open WebUI) ou localement (côté utilisateur, non partageables, OpenAPI uniquement, appel depuis le navigateur de l'utilisateur) ;
- **Fonctions** : permettent notamment de configurer des pipelines complètes ou de filtrer/modifier automatiquement les requêtes et réponses.

#### Des droits à gérer
Par défaut, les utilisateurs ont accès aux fonctionnalités par défaut (qui doivent être paramétrées), pas aux outils, serveurs externes locaux et fonctions. Ainsi, des droits doivent leur être accordés pour être créés, utilisés, importés et/ou exportés (voir la section [Gestion des droits](#gestion-des-droits) ci-dessus).

Pour permettre aux utilisateurs d'utiliser les outils, d'en importer et/ou d'en exporter, un administrateur doit, dans les réglages des autorisations par défaut ou des autorisatins des groupes, cocher au choix **Accès aux outils**, **Importer les outils** et **Exporter les outils**. Pour être utilisé par un autre utilisateur que son auteur, ce dernier ou un administrateur doit aussi, dans **Espace de travail** → **Outils** → **Page outil** → **Accès**, indiquer les permissions et leur type (lecture ou lecture/écriture).

Pour permettre aux utilisateurs d'installer et d'utiliser des serveurs externes locaux (voir la section [Gestion des droits](#gestion-des-droits) ci-dessus), un administrateur doit cocher **Serveur d'outils directs**, dans **Autorisations des fonctionnalités**. Un serveur local n'est pas partageable.

Seuls les administrateurs peuvent créer un serveur externe global. Pour être utilisés, des droits doivent être accordés dans les paramètres du serveur, via **Panneau d'administration** → **Réglages** → **Intégrations** → **External Tool Servers** → **Fenêtre serveur** → **Accès**.

#### Installer un serveur (à rédiger)

#### Installer un outil (à revoir)
1. **Espaces de travail** → **Outils** → **New Tool**, coller le script, sauvegarder (le nom/la description du
   docstring d'en-tête apparaissent dans la liste).
2. Si une classe `UserValves` est définie : chaque utilisateur va dans ses **Réglages** personnels →
   **Outils** → (nom de l'outil) pour renseigner ses propres valeurs (ex. identifiants personnels).
3. Activer l'outil sur le modèle utilisé : fiche du modèle → onglet **Outils** → cocher l'outil.
   Sans cette étape, l'outil existe mais n'est jamais proposé en conversation.
4. Debug : les `print()` dans le code apparaissent dans les logs serveur d'Open WebUI (pas dans le
   chat) ; toute chaîne retournée par une fonction est en revanche visible du modèle/utilisateur —
   utile pour renvoyer des messages d'erreur explicites plutôt que de lever une exception brute.

## Fonctionnalités installées

La configuration des fonctionnalités, l'installation des dépendances et le lancement des serveurs externes nécessitent des opérations sur les postes des utilisateurs. Les différents éléments nécessaires (scripts et fichiers json pour import des outils et serveurs) se trouvent dans le dossier `kit-demarrage-openwebui`.

### Exploration de la base de données (outil python)

*à rédiger*

### Utilisation QGIS (serveur externe)

#### Principes

Le MCP de QGIS ([nkarasiak/qgis-mcp](https://github.com/nkarasiak/qgis-mcp)) est configuré côté utilisateur, et le serveur lancé sur son poste, condition pour permettre son utilisation en direct.

Le serveur est téléchargé depuis son dépôt GitHub, lancé par l'utilisateur sur son PC, et exposé via `mcpo` (proxy MCP/OpenAPI).

Les commandes `git` et `mcpo` sont opérés via `uvx` (gestionnaire de paquets et installateur Python). Au 06/08/2026, la dernière version de mcpo n'ayant pas encore intégré certaines règles du SDK MCP, la version de `mcpo` et celle du SDK ont été fixées dans le script de lancement (voir `kit-demarrage-openwebui/start-mcp/scripts/start-mcp-qgis.ps1`).

#### Configuration et utilisation

**Étape 1 | Installer les dépendances**  
Installer git via PowerShell : 

```shell
winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements`
```

Installer uv via PowerShell : 

```shell
Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
```

Afin de faciliter leur installation, des programmes `.bat` ont été créés pour lancer les scripts PowerShell `.ps1` (un double-clic sur le `.bat` lance le script dans un terminal). Chaque script vérifie d'abord si le programme est installé et précise si le terminal doit être relancé.

Les deux .bat et .ps1 se trouvent dans `kit-demarrage-openwebui/install`

**Étape 2 | Installer l'extension dans QGIS**  
Installer l'extension **QGIS MCP** développée par Nicolas Karasiak. La fenêtre de configuration est destinée aux applications comme Claude desktop, elle peut être fermée. Cette extension ouvre un serveur socket TCP local dans le processus QGIS déjà lancé.

IMG/extension

Pour fonctionner, l'extension doit être active (**Extensions** → **QGIS MCP** → **MCP :9876** actif, ou outil actif dans la barre d'outils).

IMG/extension active

**Étape 3 | Configurer le serveur dans Open WebUI**  
Le serveur est configuré côté utilisateur, via **Profil** → **Réglages** → **Intégrations** → **Gérer les serveurs d'outils** → **➕ Ajouter une connexion**. Parmi les informations à renseigner, l'URL du serveur (`http://localhost:8001`) et un mot de passe (mdp_qgis). Deux informations à reporter dans la commande de lancement du MCP (`--port` et `--api-key`). 

IMG/config

Un fichier de configuration `.json` a été créé pour faciliter l'intégration dans Open WebUI (outil **Importer** dans les paramètres du serveur). Il se trouve dans `kit-demarrage-openwebui/outils-serveurs`.

**Étape 4 | Installer et lancer le serveur MCP**  
Enfin, le serveur, qui traduit MCP vers le socket TCP, doit être lancé. Pour le lancer via PowerShell : 

```shell
uvx --with "mcp==1.29.0" mcpo@0.0.20 --port 8001 --api-key "mdp_qgis" -- `
    uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
```

Afin de faciliter le lancement du MCP, un programme `.bat` a été créé pour lancer le script `.ps1`. Les fichiers se trouvent dans `kit-demarrage-openwebui/start-mcp`.

Le terminal doit rester ouvert pour permettre à l'IA d'accéder à la session QGIS.





### Recherche sur le web

*à rédiger*  

https://docs.openwebui.com/features/chat-conversations/web-search/providers/external/



## Gestion de la mémoire d'Open WebUI

### Généralités

Lorsqu'il est installé en Docker, Open WebUI stocke par défaut toute sa mémoire dans le système de fichiers `/app/backend/data` (chemin relatif `DATA_DIR=./data`), dans l'image Docker officielle. Une politique de sauvegarde du volume peut être mise en place.

**Trois familles de données** :

| **Famille** | **Emplacement** | **Exemples** |
|---|----|------|
| **Fichiers sur disque** | `DATA_DIR` (volume Docker) | fichiers uploadés/générés, base vectorielle, cache, base SQLite |
| **Base de données** | SQLite (par défaut) ou Postgres externe | utilisateurs, mots de passe, conversations, outils, prompts, connaissances (métadonnées), réglages admin |
| **Configuration** | Variables d'environnement et/ou base de données | tout réglage exposé dans Réglages admin (voir ci-dessous mécanisme "PersistentConfig") |


**Arborescence par défaut** :

```
/app/backend/data/
├── webui.db        # base SQLite (absent si DATABASE_URL pointe  
│                   # vers un Postgres externe) 
│                   # Plusieurs tables dont utilisateurs et conversations
├── uploads/        # fichiers utilisateurs : pièces jointes, imports, connaissances
│                   # et tout fichier généré par un Tool et attaché via l'API Files
├── vector_db/      # base vectorielle ChromaDB (par défaut) : embeddings 
│                   # des connaissances
├── cache/          # modèles téléchargés localement (embeddings, whisper...).
│                   # À exclure des sauvegardes, régénérable
└── audit.log       # journal d'audit, si activé
```

Si SQLite est utilisé, webui.db est à la fois le fichier sous DATA_DIR et toute la base de données : la distinction ne devient réelle qu'avec un Postgres externe, hébergé ailleurs.

### Base de données
Open WebUI intègre par défaut une base **SQLite** (`webui.db`). Si la variable `DATABASE_URL` est définie, Open WebUI utilise un **Postgres externe** à la place.

Les fichiers de migration Alembic fournis par Open WebUI ont permis d'identifier 16 familles de tables.

| **Table (famille)** | **Contenu** |
|--|---------|
| `user` | Profils : nom, email, rôle (admin/user/pending), image de profil |
| `auth` | Identifiants de connexion : mot de passe haché (bcrypt par défaut, 10 rounds ; argon2 possible selon `PASSWORD_HASH_ALGORITHM`). Jamais en clair, jamais dans un fichier ou un log. |
| `chat` (+ messages) | Conversations et leur contenu |
| `tag` | Tags appliqués aux conversations |
| `folder` | Organisation des conversations en dossiers |
| `channel` | Canaux/discussions de groupe (espace de discussion collectif, distinct des conversations 1:1) |
| `feedback` | Retours utilisateurs sur les réponses (pouces haut/bas), utilisés pour l'évaluation des modèles |
| `model` | Modèles « espace de travail » : presets (prompt système, paramètres, contrôle d'accès) |
| `tool` | Code Python des outils + les valves enregistrées par les utilisateurs |
| `function` | Filtres/pipelines |
| `prompt` | Prompts sauvegardés dans l'espace de travail |
| `knowledge` + `file` | Métadonnées des bases de "Connaissances" (RAG) et des fichiers associés. Le contenu brut des fichiers reste sur disque (`uploads/`), les embeddings dans `vector_db/` |
| `memory` | Fonctionnalité "Mémoires" : faits personnels retenus sur l'utilisateur à travers les conversations, distincte des connaissances. |
| `note` | Fonctionnalité "Notes" (éditeur de texte collaboratif, distinct du chat) |
| `config` | Réglages admin persistés. Voir mécanisme PersistentConfig ci-dessous |
| `group` | Groupes d'utilisateurs et permissions |

### Dossier uploads/ 

Le dossier `uploads/` ne bénéficie d'aucun nettoyage automatique et peut se retrouver saturé. Il peut être géré manuellement, via des scripts ou via des mécanismes internes aux outils si les fichiers sont générés par ces derniers.

Si les fichiers de `uploads/` doivent être partagés entre plusieurs instances Open WebUI, l'ajout d'un `STORAGE_PROVIDER` permet de créer une source commune unique dans un stockage cloud (GCS, Azure ou S3). Chaque instance l'interroge chaque fois qu'elle doit servir un fichier demandé et le copie dans son `uploads/` (si une version existe déjà, elle est remplacée).

Ainsi, dans la version actuelle d'Open WebUI, le dossier `uploads/` est forcément stocké localement.

### Embeddings et connaissances
`vector_db/` ne contient les embeddings que si la base vectorielle est locale (ChromaDB, réglage par défaut). Si `VECTOR_DB` est configuré vers une base externe (Qdrant, Milvus, pgvector...), ce dossier reste vide ou inutilisé.

Par défaut (RAG_EMBEDDING_ENGINE=""), l'embedding utilise un moteur local basé sur la bibliothèque sentence-transformers. Lors du premier lancement, Open WebUI télécharge depuis Hugging Face le modèle par défaut sentence-transformers/all-MiniLM-L6-v2, ensuite mis en cache dans le `cache/` de l'image Docker. Le modèle d'embedding installé peut être vérifié dans  `Panneau d'administration` → `Réglages` → `Documents` → `Modèle d'embedding`.

Les connaissances sont ainsi traitées de deux manières : les documents sources sont enregistrés dans `uploads/`, et les embeddings sont stockés dans une base vectorielle.

D'après plusieurs sources (bug report GitHub encore ouvert début 2026, analyse technique détaillée de mars 2026...), supprimer une connaissance dans l'interface d'Open WebUI ne supprime pas systématiquement :

- les fichiers correspondants dans `uploads/` (l'appel de suppression du stockage n'est pas déclenché par l'endpoint de suppression de la base de connaissances) ;
- leurs embeddings dans `vector_db/` (deux bugs distincts identifiés côté ChromaDB : une comparaison de noms de collection cassée, et un appel delete() utilisé à la place de delete_collection()).

Un outil tiers (prune-open-webui, dernière version le 21/04/2026) a été créé pour nettoyer ces résidus (fichiers orphelins, collections vectorielles orphelines, et même des lignes orphelines en base côté SQLite, qui n'applique pas ON DELETE CASCADE par défaut).

### Variables d'environnement vs réglages admin

Beaucoup de réglages, exposés comme variables d'environnement (au lancement du conteneur, `docker run -e` / `docker-compose`), ont aussi une existence en base de données, dans la table `config`. C'est le mécanisme **PersistentConfig**. 

Celui intègre un mécanisme de priorité : **valeur en base > variable d'environnement > valeur par défaut**. Dès qu'un administrateur modifie un réglage dans l'interface, Open WebUI écrit la nouvelle valeur dans la table `config`, qui prime définitivement sur la variable d'environnement correspondante, y compris après un redémarrage du conteneur avec une variable d'environnement différente. Pour repartir de la variable d'environnement, il faut d'abord effacer/réinitialiser le réglage correspondant côté interface (ou directement en base).

### Mécanisme de bind mount
Docker intègre un mécanisme de bind mount (montage lié), permettant d'accéder aux données d'un conteneur directement depuis l'hôte (Merlin), sans commande `docker`, ce qui peut faciliter sa gestion.

À l'installation, `-v open-webui:/app/backend/data` devient `-v /opt/open-webui/data:/app/backend/data` (`/opt/open-webui/data` est un exemple, le choix du répertoire est à définir).

Si Open WebUI est déjà installé sans bind mount, il faut opérer une migration (qui implique une coupure du service) : 

1. Récupérer l'emplacement réel du volume nommé actuel (docker volume inspect open-webui, champ Mountpoint).
2. Copier son contenu vers le nouveau dossier bind mount choisi (ex. /opt/open-webui/data). Soit `rsync` ou `cp` du contenu du Mountpoint vers là, soit passer par un conteneur temporaire qui monte les deux pour faire la copie.
3. Arrêter et supprimer le conteneur actuel (`docker stop open-webui && docker rm open-webui`). Le volume nommé survit à cette étape, mais ce n'est pas grave puisqu'on a déjà copié son contenu.
4. Relancer avec `-v /opt/open-webui/data:/app/backend/data` à la place de -`v open-webui:/app/backend/data`, même image, même nom de conteneur.


## Pour plus tard

### Fonctions
Une fonction modifie le comportement du backend Open WebUI lui-même : elle s'exécute côté serveur, indépendamment du function calling du modèle. Il en existe trois types :

- **Pipe** : crée une entrée "modèle" personnalisée qui apparaît dans le sélecteur de modèles, comme si c'était un LLM classique. Sert typiquement à brancher une API externe non supportée nativement, ou à construire un pipeline (RAG custom, agent multi-étapes) qui répond à la place d'un vrai modèle ;
- **Filter** : s'intercale sur le flux inlet (avant que la requête parte vers le modèle) et/ou outlet (après la réponse). Sert à modifier ou enrichir silencieusement les échanges (masquage de données sensibles, injection de contexte, logging, modération...) ;
- **Action** : ajoute un bouton personnalisé sous les messages du chat (ex. "traduire", "reformuler").


## Sources
- [OpenAI-Compatible / Open WebUI](https://docs.openwebui.com/getting-started/quick-start/connect-a-provider/starting-with-openai-compatible/)
[Roles / Open WebUI](https://docs.openwebui.com/features/authentication-access/rbac/roles/)
- [File Management](https://docs.openwebui.com/features/chat-conversations/data-controls/files/)
- [Backups / Open WebUI](https://docs.openwebui.com/tutorials/maintenance/backups/)
- [Environment Variable Configuration / Open WebUI](https://docs.openwebui.com/reference/env-configuration/)
- [PersistentConfig System | open-webui/open-webui | DeepWiki](https://deepwiki.com/open-webui/open-webui/12.2-persistentconfig-system)
- [Authentication Methods | open-webui/open-webui | DeepWiki](https://deepwiki.com/open-webui/open-webui/11.1-authentication-methods)
- [Reset Admin Password / Open WebUI](https://docs.openwebui.com/troubleshooting/password-reset/)
- [File Upload and Processing | open-webui/open-webui | DeepWiki](https://deepwiki.com/open-webui/open-webui/4.4-file-upload-and-processing)
- [Suppression connaissances-Issues](https://github.com/open-webui/open-webui/issues/10823) 
- [Suppression connaissances-Discussions](https://github.com/open-webui/open-webui/discussions/14077)
- [prune-open-webui](https://github.com/Classic298/prune-open-webui)
- [Téléchargement modèle embedding Hugging Face](https://github.com/open-webui/open-webui/discussions/9729)
- [Tables bases de données](https://github.com/open-webui/open-webui/tree/main/backend/open_webui/migrations/versions)