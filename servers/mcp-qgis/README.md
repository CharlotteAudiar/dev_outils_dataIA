# mcp-qgis

Serveur MCP donnant accès aux fonctions QGIS (couches, projets, traitements géospatiaux).
Neutre : servable à n'importe quel client MCP (Claude Desktop/Cowork, Cursor, etc.).

## Décision (20/07/2026)

Usage **hybride** retenu : les chargés d'études continuent à manipuler QGIS Desktop à la main, avec la possibilité de solliciter l'IA sur la session en cours (même projet ouvert, mêmes couches) via Open WebUI.

Plugin retenu : **QGIS MCP** (Nicolas Karasiak, [nkarasiak/qgis-mcp](https://github.com/nkarasiak/qgis-mcp)).

- Plugin QGIS Desktop : ouvre un serveur socket TCP local dans le processus QGIS déjà lancé par l'agent — agit directement sur le projet ouvert à l'écran (pas une instance QGIS séparée/headless), compatible avec le mode hybride.
- 100+ outils MCP : gestion des couches, édition d'entités, algorithmes de traitement, rendu, mise en page.
- Installé et à jour en v0.7.0 sur le poste de Charlotte (confirmé le 20/07/2026).

## Montage technique (3 pièces)

1. **Plugin QGIS MCP** (poste de chaque agent) — serveur socket côté QGIS. Dans le panneau QGIS MCP, cocher *"Start MCP server automatically when QGIS opens"* pour éviter un démarrage manuel à chaque session ; laisser décoché *"Always pull latest server from GitHub"* (sauf mise à jour volontaire).
2. **Serveur MCP** (`qgis-mcp-server`) — traduit MCP vers le socket TCP du plugin. Lancé via `uv`/`uvx` (voir `docs/guides.md` pour l'installation d'`uv`), transport `stdio` par défaut.
3. **`mcpo`** ([open-webui/mcpo](https://github.com/open-webui/mcpo)) — proxy qui encapsule `qgis-mcp-server` (transport `stdio`) et l'expose en API **OpenAPI** classique. C'est la pièce qui permet la connexion à Open WebUI, **dans tous les cas de déploiement** (poste local comme instance mutualisée) — voir "Pourquoi `mcpo` et pas le MCP natif" ci-dessous.

**Commande de lancement (poste de l'agent)** — packagée dans `start.sh` (même dossier, variable `MCPO_API_KEY_QGIS` à définir, voir `config/.env.example`) :
```
uvx mcpo --port 8001 --api-key "<une-clé-au-choix>" -- uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
```

**Connexion côté Open WebUI** : Admin Settings → External Tools (admin) ou, pour un utilisateur non-admin sur une instance mutualisée (cf. plus bas), **Settings personnels → onglet "Integrations" (FR : "Intégrations") → "Manage Tool Servers" (FR : "Gérer les serveurs d'outils")** — pas l'onglet "Connections"/"Connexions", qui lui sert aux endpoints de modèles (OpenAI-compatible), pas aux serveurs d'outils. → **Type : OpenAPI**, **URL : `http://host.docker.internal:8001`** (Open WebUI tourne dans Docker ; `host.docker.internal` désigne le poste hôte) ou `http://localhost:8001` si Open WebUI tourne hors Docker, **Auth : Bearer**, avec la même clé que `--api-key`.

## Pourquoi `mcpo` et pas le support MCP natif d'Open WebUI

Justification technique valable pour tous les serveurs MCP métier du projet (pas spécifique à QGIS) : voir `docs/architecture/decision-framework.md`, section "Connexion des serveurs MCP à Open WebUI : pourquoi `mcpo`".

## Prérequis côté Open WebUI

Paramétrage générique (droits/permissions Open WebUI), pas spécifique à QGIS : voir `docs/guides.md`, section "Paramétrer les droits Open WebUI (instance mutualisée)".

## Checklist de déploiement — statut pour `mcp-qgis`

Modèle générique de la checklist, applicable à tout serveur MCP : `docs/guides.md`, section "Checklist de déploiement d'un nouveau serveur MCP (instance mutualisée)".

✅ **Validé le 20/07/2026** — testé sur l'instance locale de Charlotte avec un compte non-admin dédié : connexion `mcpo` ajoutée via *Intégrations → Gérer les serveurs d'outils*, outil réellement invoqué en conversation (le modèle a renvoyé les infos des couches du projet QGIS ouvert). La combinaison des deux réglages admin (toggle global + permission de groupe) fonctionne comme attendu. Note : l'[issue #15006](https://github.com/open-webui/open-webui/issues/15006) initialement citée ici comme "bug signalé" a été retirée par son auteur (fausse alerte, confusion avec les connexions directes aux modèles) — cohérent avec ce test qui n'a rencontré aucun blocage. Confirmé également : la section *Intégrations → Gérer les serveurs d'outils* est bien visible (non grisée) pour un compte non-admin une fois la permission "Serveur d'outils directs" activée pour son groupe — pas de blocage constaté à ce stade. Reste à vérifier : ce test s'est fait sur un seul poste (même machine que l'admin) ; le scénario multi-poste réel (chaque agent avec son propre `mcpo` local) n'a pas encore été testé.

## Points de vigilance avant déploiement

- **`execute_code` (observé le 20/07/2026, testé par Charlotte)** : cet outil (catégorie "System") accepte du code Python/PyQGIS arbitraire en paramètre, contrairement aux ~101 autres outils qui ont des paramètres contraints (`layer_id`, `expression`, etc.). Le modèle l'utilise spontanément en solution de repli quand un outil structuré échoue (observé sur un algorithme `execute_processing` mal paramétré par le modèle lui-même). Ce n'est pas un contournement du MCP — `execute_code` est un outil MCP comme les autres, transmis par la même chaîne (`mcpo` → `qgis-mcp-server` → plugin) — mais sa portée fonctionnelle est bien plus large (accès quasi illimité à ce que le processus QGIS peut faire) et sa traçabilité plus faible (un bloc de code est moins facile à auditer qu'un appel structuré). **À trancher avant un déploiement à plusieurs chargés d'études** : le désactiver (via la "Function Name Filter List" d'Open WebUI, cf. `docs.openwebui.com/features/extensibility/mcp`) ou l'autoriser en connaissance de cause.
- Vérifier que le serveur MCP `qgis-mcp` reste agnostique du client (pas de dépendance spécifique à un LLM donné).
- Sécuriser le service local (écoute sur `127.0.0.1` uniquement pour `qgis-mcp-server`, clé API obligatoire sur `mcpo` puisqu'il est, lui, atteint depuis le navigateur).
- Prévoir un message d'erreur clair si l'agent n'a pas lancé la chaîne locale (plugin + `qgis-mcp-server` + `mcpo`) — pas de blocage silencieux.
- Déploiement/maintenance à industrialiser sur plusieurs postes (cohérent avec le pilote 2-3 postes déjà envisagé dans l'architecture cible).

## Hors périmètre

Pour des traitements géospatiaux standardisés/batch (sans besoin d'interaction avec la session ouverte) : QGIS Server (API WMS/WFS/WPS) appelé par un Tool côté serveur — alternative secondaire, nécessiterait une brique d'infrastructure séparée à évaluer.

- `src/` — code source
- `tests/` — tests
