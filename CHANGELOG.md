# Changelog

Toutes les évolutions notables du projet sont documentées ici.

## [Non publié]

- Initialisation de l'arborescence du projet.
- Correction de `docs/architecture.md` : l'instance Open WebUI n'existait pas déjà en interne (hypothèse initiale erronée) ; décision de framework inchangée, mais l'instance reste à créer.
- Ajout du guide d'installation locale d'Open WebUI (Docker) dans `docs/guides.md`.
- Installation locale réussie d'Open WebUI 0.10.2 sur le poste de Charlotte (Docker Desktop AMD64 + WSL2).
- Vérification version via API JSON (`/api/config`) — support MCP natif disponible ✓
- Localisation section MCP dans Open WebUI : Réglages → Intégrations → "External Tool Servers".
- Mise à jour `docs/guides.md` avec instructions de vérification de version et accès aux paramètres MCP.
- Connexion Mistral (API compatible OpenAI) opérationnelle dans Open WebUI local (62 modèles chargés).
- Découverte importante (confirmée via docs.openwebui.com) : le support MCP natif d'Open WebUI est Streamable HTTP uniquement (pas stdio/SSE), et la configuration MCP est admin-only (pas de "User Tool Server" par utilisateur pour MCP — uniquement pour OpenAPI). Correction apportée à `docs/architecture.md` et `config/mcp-servers.yaml` (commande `qgis-mcp-server` via `uvx`, transport `streamable-http`).
- `uv` installé sur le poste de Charlotte (via `pip install uv`). Plugin QGIS MCP configuré (démarrage auto avec QGIS).
- Testé et abandonné : connexion MCP native directe (`streamable-http`) entre Open WebUI (Docker) et `qgis-mcp-server` — bloquée par la protection anti-DNS-rebinding du serveur (erreur 421, `Host: host.docker.internal` refusé). Solution retenue : passer par `mcpo` (proxy MCP → OpenAPI) dans tous les cas, local ou mutualisé — pas seulement pour l'instance mutualisée comme supposé initialement. Voir `servers/mcp-qgis/README.md`, "Correction n°2".
