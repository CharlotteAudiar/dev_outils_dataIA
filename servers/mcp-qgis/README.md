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

**Commande de lancement (poste de l'agent)** :
```
uvx mcpo --port 8001 --api-key "<une-clé-au-choix>" -- uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
```

**Connexion côté Open WebUI** : Admin Settings → External Tools (ou Settings → Tools en "Direct Tool Server" pour un utilisateur non-admin sur une instance mutualisée, cf. plus bas) → **Type : OpenAPI**, **URL : `http://host.docker.internal:8001`** (Open WebUI tourne dans Docker ; `host.docker.internal` désigne le poste hôte) ou `http://localhost:8001` si Open WebUI tourne hors Docker, **Auth : Bearer**, avec la même clé que `--api-key`.

## Pourquoi `mcpo` et pas le support MCP natif d'Open WebUI

Deux caractéristiques du support MCP natif d'Open WebUI (documentées sur [docs.openwebui.com/features/extensibility/mcp](https://docs.openwebui.com/features/extensibility/mcp), vérifiées en conditions réelles le 20/07/2026) le rendent inadapté à ce montage :

1. **Admin-only et centralisé** : un serveur MCP ne peut être ajouté que par un administrateur (*Admin Settings → External Tools*), jamais par un utilisateur individuel. Sur une instance mutualisée entre plusieurs chargés d'études, une URL `localhost` configurée une fois par l'admin pointerait vers le poste de l'admin, pas vers celui de chaque agent — inutilisable pour le mode hybride visé (QGIS tourne sur le poste de chaque chargé d'études, pas sur un serveur central).
   Le mécanisme qui résout ce problème pour un déploiement à plusieurs utilisateurs — **"Direct Tool Servers"**, qui fait bien partir l'appel depuis le navigateur de chacun pour atteindre son propre `localhost` — n'existe que pour les serveurs **OpenAPI**, pas pour MCP. D'où le choix d'exposer `qgis-mcp-server` en OpenAPI (via `mcpo`) plutôt qu'en MCP natif.
2. **Protection anti-DNS-rebinding, même en local** : `qgis-mcp-server` (via FastMCP, la bibliothèque qu'il utilise) active par défaut une vérification de l'en-tête HTTP `Host` de la requête entrante contre une liste blanche limitée à `localhost`/`127.0.0.1`. Comme Open WebUI tourne dans Docker, il doit appeler `http://host.docker.internal:8000` pour atteindre le poste hôte — un `Host` qui n'est jamais dans cette liste blanche, quel que soit le poste. Résultat observé : `421 Misdirected Request`. Aucune variable d'environnement documentée par `qgis-mcp` ne permet d'élargir cette liste blanche. Ce blocage touche donc **aussi le cas d'un Open WebUI local** (pas seulement l'instance mutualisée).

`mcpo` évite ce deuxième problème par construction : il lance `qgis-mcp-server` lui-même en sous-processus (transport `stdio`, pas de couche HTTP entre les deux), et expose sa propre API OpenAPI (FastAPI, sans cette vérification de `Host`).

## Prérequis côté Open WebUI

- Version ≥ 0.6.31 pas nécessaire pour ce montage (on utilise OpenAPI, pas le MCP natif) — utile seulement si un autre outil MCP natif est ajouté par ailleurs.
- Instance mutualisée : activer l'option *"Direct Tool Servers"* (désactivée par défaut) par utilisateur/groupe dans les paramètres admin.

## Checklist avant de proposer l'usage aux chargés d'études (instance mutualisée)

1. Vérifier sur l'instance Audiar réelle que l'option *"Direct Tool Servers"* est bien activable et fonctionne pour un compte non-admin — un bug a été signalé sur ce point dans certaines versions d'Open WebUI ([issue #15006](https://github.com/open-webui/open-webui/issues/15006), "permission not working for non-admin users") : à tester avant tout déploiement, pas à supposer fonctionnel.
2. Packager sur chaque poste le lancement conjoint de : plugin QGIS MCP (démarrage auto à l'ouverture de QGIS) → `mcpo` (qui lance lui-même `qgis-mcp-server`) — idéalement un script unique, pas plusieurs manipulations manuelles par un profil non-développeur.
3. Vérifier que le navigateur (onglet Open WebUI) peut effectivement atteindre `http://localhost:<port>` de `mcpo` sans blocage CORS/mixed-content (Open WebUI en HTTPS appelant un `localhost` en HTTP peut être bloqué par certains navigateurs — à tester en conditions réelles).
4. Chaque chargé d'études ajoute lui-même l'URL de son `mcpo` local dans *Settings → Tools* (paramètre personnel, pas partageable entre postes).

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
