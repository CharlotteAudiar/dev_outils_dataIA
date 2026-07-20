# Guides

Guides d'installation, d'usage et d'onboarding.

## Installer Open WebUI en local (prototype, poste de travail)

Framework retenu : voir `docs/architecture/decision-framework.md`. L'instance "Open WebUI Audiar" n'existe pas encore — ce guide décrit son premier déploiement, en local sur un poste Windows, avant d'envisager un hébergement partagé.

### Prérequis

- **Docker Desktop** installé et lancé (icône de la baleine visible dans la barre des tâches Windows). Téléchargement : https://www.docker.com/products/docker-desktop/
  - À l'installation, choisir le backend **WSL2** si proposé (recommandé sur Windows).
  - Après installation, un redémarrage du poste est parfois demandé.
- Une connexion internet (pour télécharger l'image Open WebUI la première fois).

### Étape 1 — Vérifier que Docker fonctionne

Ouvrir un terminal (PowerShell, ou Git Bash intégré à VS Code — les commandes `docker` sont identiques dans les deux) et taper :

```
docker --version
docker ps
```

- `docker --version` doit afficher un numéro de version (ex. `Docker version 27.x.x`).
- `docker ps` doit afficher un tableau vide (colonnes CONTAINER ID, IMAGE, ...) sans message d'erreur. Un message d'erreur du type "Cannot connect to the Docker daemon" signifie que Docker Desktop n'est pas lancé — l'ouvrir depuis le menu Démarrer et réessayer.

### Étape 2 — Lancer Open WebUI

Dans le même terminal :

```
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```

Détail de la commande :
- `-d` : lance le conteneur en arrière-plan.
- `-p 3000:8080` : rend l'interface accessible sur `http://localhost:3000`.
- `-v open-webui:/app/backend/data` : les données (comptes, conversations, config) sont conservées même si le conteneur est recréé.
- `--restart always` : Open WebUI redémarre automatiquement avec Docker Desktop.

Le premier lancement télécharge l'image (plusieurs centaines de Mo) — peut prendre quelques minutes.

### Étape 3 — Créer le compte admin

Ouvrir `http://localhost:3000` dans un navigateur. Le premier compte créé devient automatiquement administrateur. Choisir un email/mot de passe (peuvent être différents de ceux du poste).

### Étape 4 — Vérifier la version

Deux méthodes (équivalentes) :

**Méthode 1 — via l'API (rapide)** :
Ouvrir dans le navigateur : `http://localhost:3000/api/config`

Tu vas voir un JSON avec :
```json
{
  "version": "0.10.2",
  ...
}
```

Noter le numéro — utile pour savoir si l'installation est à jour et pour vérifier la compatibilité d'éventuelles futures fonctionnalités.

**Méthode 2 — via l'interface** :
Icône de profil (en haut à droite) → **Réglages** → onglet **Général** → voir la ligne "Version".

## Configurer les serveurs MCP

Une fois Open WebUI installé, on peut connecter les serveurs MCP métier (QGIS, PostgreSQL, filesystem...).

### Principe général

Chaque serveur MCP est exposé via **`mcpo`** (proxy MCP → OpenAPI, [open-webui/mcpo](https://github.com/open-webui/mcpo)), puis ajouté dans Open WebUI comme connexion **OpenAPI** (pas MCP natif). Raison de ce choix, valable pour tous les serveurs métier du projet : voir `servers/mcp-qgis/README.md`, section "Pourquoi `mcpo` et pas le support MCP natif d'Open WebUI".

### Où configurer les serveurs

**Réglages** (icône de profil, en haut à droite) → **Intégrations** (menu de gauche) → section **"External Tool Servers"** (Serveurs d'outils externes).

C'est là qu'on ajoute chaque connexion. Un bouton **"+"** permet d'en créer une nouvelle. Type à choisir : **OpenAPI**, avec l'URL de `mcpo` et une clé Bearer.

### mcp-filesystem

Priorité plus basse que `mcp-qgis` (voir ci-dessous) — pas encore mis en place. Même principe attendu (serveur exposé via `mcpo`, connexion OpenAPI côté Open WebUI) ; pas-à-pas à écrire une fois ce serveur configuré à son tour.

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

`qgis-mcp-server` est exposé via **`mcpo`** (proxy MCP → OpenAPI, [open-webui/mcpo](https://github.com/open-webui/mcpo)) plutôt qu'en connexion MCP native directe — raison détaillée dans `servers/mcp-qgis/README.md` ("Pourquoi `mcpo` et pas le support MCP natif d'Open WebUI"). `mcpo` lance lui-même `qgis-mcp-server` en sous-processus (transport `stdio`) et expose une API OpenAPI classique.

Dans Git Bash :

```
uvx mcpo --port 8001 --api-key "choisis-une-cle-ici" -- uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
```

- `--port 8001` : port d'écoute de `mcpo` (choisi arbitrairement).
- `--api-key "..."` : clé à réutiliser côté Open WebUI (authentification Bearer).
- Tout ce qui suit `--` est la commande du serveur MCP que `mcpo` doit lancer lui-même.

Laisser ce terminal ouvert tant que la connexion QGIS doit rester disponible dans Open WebUI.

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
