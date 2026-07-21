# mcp-filesystem

Serveur MCP pour la lecture/modification de fichiers (catalogue, documents de travail).
Neutre : servable à n'importe quel client MCP.

## Statut (2026-07-21) : reporté, pas de priorité dans le scope Open WebUI actuel

Aucun des 9 cas d'usage de `docs/sources/2026_analyse-fonctionnelle_V1.txt` n'appelle un accès fichiers générique via Open WebUI (voir `docs/architecture/decision-framework.md` pour le détail). N'a de sens que si un outil "mode projet" distinct d'Open WebUI est un jour retenu pour ce scope.

Candidat identifié si besoin : implémentation de référence officielle [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) — un paquet existant à installer, pas du code à écrire ici (voir `docs/architecture/benchmark-frameworks.md` pour le comparatif).
