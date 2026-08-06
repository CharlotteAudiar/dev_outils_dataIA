:::: {.bloc-titre}
::: {.typologie}
Expérimentations
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


Documentation des expérimentations menées sur les instances Open WebUI installées sur Merlin et le PC de Charlotte.

Afin de ne pas surcharger la mémoire d'Open WebUI sur Merlin, les expérimentations seront menées sur le prototype local. Elles peuvent s'appuyer sur les expérimentations menées par les chargés d'études sur l'instance Merlin.


## Installation d'Open WebUI

Framework retenu : voir `docs/architecture/decisions.md`. Ce guide décrit le premier déploiement, en local sur un poste Windows, avant l'hébergement partagé sur Merlin (ci-dessous).

**Prérequis**

- **Docker Desktop** installé et lancé. Téléchargement : https://www.docker.com/products/docker-desktop/
  - À l'installation, choisir le backend **WSL2** si proposé (recommandé sur Windows).
  - Après installation, un redémarrage du poste est parfois demandé.
- Une connexion internet (pour télécharger l'image Open WebUI la première fois).

**Étape 1 — Vérifier que Docker fonctionne**

Ouvrir un terminal (PowerShell ou bash : les commandes `docker` sont identiques dans les deux) et taper :

```bash
docker --version # vérif n° de version
docker ps # liste application docker (docker doit être lancé)
```

**Étape 2 — Installer et lancer Open WebUI**
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

**Étape 3 — Créer le compte admin**

Ouvrir `http://localhost:3000` dans un navigateur. Le premier compte créé devient automatiquement administrateur. Choisir un email/mot de passe (peuvent être différents de ceux du poste).

**Étape 4 — Vérifier la version**

Le fichier JSON disponible à l'adresse http://localhost:3000/api/config indique dans les premiers champs la version d'Open WebUI installée.

Le numéro de version est aussi indiqué dans le menu "A propos" du panneau "Réglages", accessible en cliquant sur la bulle "Profil" (en haut à droite ou en bas à gauche).

**Étape 5 — Lancer Open WebUI une fois installé**

```bash
docker start open-webui # Open WebUI lancé en arrière-plan
```

## Interroger la base de données

## Utiliser QGIS

**`execute_code` (observé le 20/07/2026, testé par Charlotte)** : cet outil (catégorie "System") accepte du code Python/PyQGIS arbitraire en paramètre, contrairement aux ~101 autres outils qui ont des paramètres contraints (`layer_id`, `expression`, etc.). Le modèle l'utilise spontanément en solution de repli quand un outil structuré échoue (observé sur un algorithme `execute_processing` mal paramétré par le modèle lui-même). Ce n'est pas un contournement du MCP — `execute_code` est un outil MCP comme les autres, transmis par la même chaîne (`mcpo` → `qgis-mcp-server` → plugin) — mais sa portée fonctionnelle est bien plus large (accès quasi illimité à ce que le processus QGIS peut faire) et sa traçabilité plus faible (un bloc de code est moins facile à auditer qu'un appel structuré).
Deux mécanismes de filtrage existent, tous deux réels et documentés en amont mais non retranchés ici :
  - la **Function Name Filter List** d'Open WebUI, documentée pour les connexions MCP natives (streamable-http) — non confirmée pour une connexion OpenAPI comme la nôtre via `mcpo` (cf. `docs.openwebui.com/features/extensibility/mcp`) ;
  - le mode **`mcpo --config` + `disabledTools`**, qui filtre en amont d'Open WebUI (cf. `docs/architecture/decisions.md`, section "Mode `--config` de `mcpo`") — **testé le 21/07/2026** via `servers/mcp-qgis/mcpo-config.json`, puis **annulé le 22/07/2026** (retour au mode inline, une instance `mcpo` = un serveur = un port ; fichier supprimé). Capacité disponible et documentée par `mcpo` lui-même, mais non adoptée pour l'instant.