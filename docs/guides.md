# Guides

Guides d'installation, d'usage et d'onboarding.

## Installer Open WebUI en local (prototype, poste de travail)

Framework retenu : voir `docs/architecture/decision-framework.md`. L'instance "Open WebUI Audiar" n'existe pas encore. Ce guide décrit son premier déploiement, en local sur un poste Windows, avant d'envisager un hébergement partagé.

### Prérequis

- **Docker Desktop** installé et lancé (icône de la baleine visible dans la barre des tâches Windows). Téléchargement : https://www.docker.com/products/docker-desktop/
  - À l'installation, choisir le backend **WSL2** si proposé (recommandé sur Windows).
  - Après installation, un redémarrage du poste est parfois demandé.
- Une connexion internet (pour télécharger l'image Open WebUI la première fois).

### Étape 1 — Vérifier que Docker fonctionne

Ouvrir un terminal (PowerShell, ou Git Bash intégré à VS Code — les commandes `docker` sont identiques dans les deux) et taper :

```bash
docker --version # vérif n° de version
docker ps # liste application docker (docker doit être lancé)
```

### Étape 2 — Installer et lancer Open WebUI

Dans le même terminal :

```bash
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```

Détail de la commande :
- `-d` : lance le conteneur en arrière-plan.
- `-p 3000:8080` : rend l'interface accessible sur `http://localhost:3000` (8080 = port dans le conteneur Docker).
- `-v open-webui:/app/backend/data` : les données (comptes, conversations, config) sont conservées même si le conteneur est recréé.
- `--restart always` : Open WebUI redémarre automatiquement avec Docker Desktop.

Le premier lancement télécharge l'image (plusieurs centaines de Mo, peut prendre quelques minutes).

### Étape 3 — Créer le compte admin

Ouvrir `http://localhost:3000` dans un navigateur. Le premier compte créé devient automatiquement administrateur. Choisir un email/mot de passe (peuvent être différents de ceux du poste).

### Étape 4 — Vérifier la version

Le fichier JSON disponible à l'adresse http://localhost:3000/api/config indique dans les premiers champs la version d'Open WebUI installée.

Le numéro de version est aussi indiqué dans le menu "A propos" du panneau "Réglages", accessible en cliquant sur la bulle "Profil" (en haut à droite ou en bas à gauche).

### Étape 5 — Lancer Open web UI une fois installé

```bash
docker start open-webui # open webui lancé en arrière-plan
```


## Configurer les serveurs MCP

Plusieurs serveurs MCP métier doivent être installaés : QGIS, PostgreSQL, filesystem, Excel en particulier.

### Principe général

Chaque serveur MCP est exposé via **`mcpo`** (proxy MCP → OpenAPI, [open-webui/mcpo](https://github.com/open-webui/mcpo)), puis ajouté dans Open WebUI comme connexion **OpenAPI** (pas MCP natif). Raison de ce choix, valable pour tous les serveurs métier du projet : voir `docs/architecture/decision-framework.md`, section "Connexion des serveurs MCP à Open WebUI : pourquoi `mcpo`".

### Où configurer les serveurs

**Réglages** (icône de profil, en haut à droite) → **Intégrations** (menu de gauche) → section **"External Tool Servers"** (Serveurs d'outils externes).

C'est là qu'on ajoute chaque connexion. Un bouton **"+"** permet d'en créer une nouvelle. Type à choisir : **OpenAPI**, avec l'URL de `mcpo` et une clé Bearer.

### mcp-filesystem

Priorité plus basse que `mcp-qgis` (voir ci-dessous) — pas encore mis en place. Même principe attendu (serveur exposé via `mcpo`, connexion OpenAPI côté Open WebUI) ; pas-à-pas à écrire une fois ce serveur configuré à son tour.

## Paramétrer les droits Open WebUI (instance mutualisée)

Prérequis générique, valable pour tout serveur MCP métier exposé via `mcpo` — pas spécifique à un serveur en particulier (justification technique complète : `docs/architecture/decision-framework.md`, section "Connexion des serveurs MCP à Open WebUI : pourquoi `mcpo`").

- Version Open WebUI ≥ 0.6.31 pas nécessaire pour ce montage (on utilise OpenAPI, pas le MCP natif) — utile seulement si un autre outil MCP natif est ajouté par ailleurs.
- Instance mutualisée : deux réglages distincts nécessaires côté admin, tous deux désactivés par défaut —
  1. **Toggle global** : *Admin Panel → Settings → Connections → "Direct Connections"* → ON (sans lui, personne — même un admin — n'a accès aux connexions directes). En français : *Panneau d'administration → Réglages → Connexions → « Direct connexions »*.
  2. **Permission par utilisateur/groupe** : *Admin Panel → Users → Groups → Default permissions (ou un groupe dédié) → Features → "Direct Tool Servers"* → ON. En français : *Panneau d'administration → Utilisateurs → Groupes → « Modifier les autorisations par défaut » → section « Autorisations des fonctionnalités » → toggle « Serveur d'outils directs »* (confirmé sur l'instance de Charlotte le 20/07/2026 — désactivé par défaut).

## Checklist de déploiement d'un nouveau serveur MCP (instance mutualisée)

Modèle générique à appliquer avant de proposer un nouveau serveur MCP aux chargés d'études (au-delà de `mcp-qgis`, déjà appliqué et validé — statut détaillé dans `servers/mcp-qgis/README.md`) :

1. Packager sur chaque poste le lancement conjoint de la chaîne locale complète (ex. pour QGIS : plugin QGIS MCP démarré automatiquement à l'ouverture de QGIS → `mcpo`, qui lance lui-même le serveur MCP) — idéalement un script unique, pas plusieurs manipulations manuelles par un profil non-développeur.
2. Vérifier que le navigateur (onglet Open WebUI) peut effectivement atteindre `http://localhost:<port>` de `mcpo` sans blocage CORS/mixed-content (Open WebUI en HTTPS appelant un `localhost` en HTTP peut être bloqué par certains navigateurs — à tester en conditions réelles).
3. Chaque chargé d'études ajoute lui-même l'URL de son `mcpo` local dans *Settings → Integrations → Manage Tool Servers* (FR : *Réglages → Intégrations → Gérer les serveurs d'outils*) — paramètre personnel, pas partageable entre postes.

Statut d'application de cette checklist par serveur : documenté dans le README du serveur concerné (`servers/mcp-<nom>/README.md`).

## Configurer mcp-qgis (premier serveur MCP mis en place)

Priorité retenue par Charlotte le 20/07/2026 : QGIS avant les autres serveurs. Décision et montage technique complets : voir `servers/mcp-qgis/README.md`. Ici, le pas-à-pas concret suivi sur le poste de Charlotte.

### Prérequis

- QGIS Desktop installé (testé avec la version 3.40.15 "Bratislava" — nécessite ≥ 3.28).
- Plugin **QGIS MCP** installé depuis QGIS (`Extensions` → `Gérer et installer les extensions` → rechercher "QGIS MCP") — installé et à jour en v0.7.0.
- **`uv`** (gestionnaire de paquets/outils Python moderne) installé sur le poste — voir Étape 1.

### Étape 1 — Installer `uv`

Dans Git Bash :

```
uv --version
```

Si la commande n'est pas reconnue (`bash: uv: command not found`), l'installer via pip :

```
pip install uv
```

VS Code affiche parfois une notification proposant de créer un environnement virtuel Python pour isoler l'installation — pas nécessaire ici, `uv` est un outil en ligne de commande global, pas une dépendance de projet. On peut fermer la notification ("Don't show again").

Une fois installé, si `uv --version` ne fonctionne toujours pas immédiatement, fermer et rouvrir le terminal (le PATH n'est pas toujours actualisé dans la session en cours).

**Pourquoi `uv`/`uvx` plutôt qu'un `pip install` classique du serveur MCP ?**
`uvx` (comme `npx` en JavaScript) exécute un outil dans un environnement isolé et mis en cache, sans l'installer "en dur" dans le projet ni dans le Python global du poste :
- Pas de `venv` à créer/activer manuellement à chaque fois.
- Toujours la version exacte du dépôt GitHub visé (`--from git+https://...`), sans étape d'installation séparée à maintenir.
- Le cache est stocké globalement (`%LOCALAPPDATA%\uv\cache` sous Windows), pas dans le dossier du projet — rien ne pollue `dev_outils_dataIA`.
- Le téléchargement ne se fait qu'une fois (mise en cache) ; les lancements suivants réutilisent le cache et démarrent vite. Pour forcer une re-vérification de la dernière version sur GitHub, ajouter `--refresh-package qgis-mcp` à la commande (plus lent, dépend du réseau) — pas nécessaire au quotidien.

C'est la méthode d'installation documentée par le projet `qgis-mcp` lui-même.

### Étape 2 — Configurer et démarrer le plugin côté QGIS

Dans QGIS, ouvrir le panneau **QGIS MCP** et cliquer sur l'icône de configuration (**"Setup & Configurator"**). Deux cases à cocher pertinentes (ignorer le dropdown "Client" et le bouton "Apply Config" — prévus pour des clients CLI comme Claude Code/Cursor, pas pour Open WebUI) :

- **"Start MCP server automatically when QGIS opens"** → cocher. Démarre automatiquement le socket du plugin à chaque ouverture de QGIS (évite de cliquer "Start Server" manuellement à chaque session).
- **"Always pull latest server from GitHub"** → laisser décoché. Équivalent de l'option `--refresh-package` : forcerait une revérification GitHub à chaque lancement (plus lent). À cocher seulement si on veut explicitement forcer une mise à jour.

Fermer cette fenêtre, puis dans le panneau QGIS MCP principal, cliquer sur **"Start Server"** pour démarrer le socket dès maintenant (le démarrage automatique ne s'appliquera qu'au prochain lancement de QGIS).

### Étape 3 — Lancer le serveur MCP via `mcpo`

`qgis-mcp-server` est exposé via **`mcpo`** (proxy MCP → OpenAPI, [open-webui/mcpo](https://github.com/open-webui/mcpo)) plutôt qu'en connexion MCP native directe — raison détaillée dans `docs/architecture/decision-framework.md` (section "Connexion des serveurs MCP à Open WebUI : pourquoi `mcpo`"). `mcpo` lance lui-même `qgis-mcp-server` en sous-processus (transport `stdio`) et expose une API OpenAPI classique.

Créer un fichier `.env` à la racine du repo (non versionné, voir `.gitignore`) à partir de `config/.env.example`, en renseignant au moins `MCPO_API_KEY_QGIS` (la clé à réutiliser côté Open WebUI, authentification Bearer). Puis, dans Git Bash, lancer le script packagé plutôt que la commande brute :

```
./servers/mcp-qgis/start.sh
```

`start.sh` charge automatiquement ce `.env` (variables exportées via `set -a`/`source`/`set +a`) avant de lancer `uvx mcpo --port 8001 --api-key "$MCPO_API_KEY_QGIS" -- uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server` — port `8001` choisi arbitrairement, tout ce qui suit `--` étant la commande du serveur MCP que `mcpo` doit lancer lui-même.

Laisser ce terminal ouvert tant que la connexion QGIS doit rester disponible dans Open WebUI (cf. point de vigilance sur la supervision des processus à l'échelle, `docs/architecture/decision-framework.md`).

### Étape 4 — Reconfigurer la connexion dans Open WebUI

1. Réglages → Intégrations → External Tool Servers → supprimer ou modifier la connexion `mcp-qgis` existante.
2. Nouvelle configuration :
   - **Type** : `OpenAPI` (pas MCP)
   - **URL** : `http://host.docker.internal:8001`
   - **Auth** : `Bearer`, avec la même clé que `--api-key`
3. Enregistrer, puis tester dans une conversation (activer l'outil, demander un `ping`).

### Dépannage courant

- **Page inaccessible sur `localhost:3000`** : vérifier que le conteneur tourne avec `docker ps` (il doit apparaître dans la liste). Sinon, consulter les logs avec `docker logs open-webui`.
- **Port 3000 déjà utilisé** : remplacer `3000:8080` par un autre port libre, ex. `3001:8080`, et utiliser `http://localhost:3001`.
- **Mettre à jour Open WebUI plus tard** :
  ```
  docker pull ghcr.io/open-webui/open-webui:main
  docker stop open-webui && docker rm open-webui
  ```
  puis relancer la commande de l'Étape 2 (les données sont conservées grâce au volume `open-webui`).
