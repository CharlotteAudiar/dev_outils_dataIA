# Lance le serveur MCP QGIS et l'expose à Open WebUI en OpenAPI, via mcpo.
#
# Script de référence : c'est celui-ci qui est distribué et lancé sur les postes,
# via start-mcp-qgis.bat (dossier parent). Les fichiers servers/mcp-qgis/start.ps1
# et start.sh du dépôt sont d'anciennes copies, à ne plus considérer comme la source.
#
# PowerShell plutôt que bash (constat du 24/07/2026) : sur les postes, `bash` résolvait
# vers WSL, qui ne traduit pas les chemins de lecteurs réseau mappés.
#
# Prérequis côté QGIS : plugin "QGIS MCP" installé, et "Run MCP" activé dans le menu
# Extensions > QGIS MCP avant de lancer ce script. Procédure complète pour l'utilisateur :
# kit-demarrage-openwebui.pdf, section QGIS.
#
# ATTENTION, la clé --api-key est écrite en deux endroits qui doivent rester identiques :
# ici, et dans outils-serveurs/serveur-mcp-qgis.json (champ "key") que l'utilisateur importe
# dans Open WebUI. Changer l'une sans l'autre casse la connexion sans message explicite.
# Clé en clair assumée (décision du 03/08/2026) : la connexion mcpo <-> Open WebUI reste
# toujours locale au poste (http://localhost:8001, jamais host.docker.internal, puisque
# l'appel part du navigateur de l'utilisateur), donc pas d'exposition réseau.
#
# NE PAS retirer les versions figées ci-dessous : mcpo déclare mcp>=1.17.0 sans borne haute,
# et mcp 2.0.0 a renommé streamablehttp_client en streamable_http_client, que mcpo importe
# encore. Sans ce pin, toute installation fraîche échoue sur ImportError, même sur un poste
# neuf. À revoir seulement si mcpo annonce le support de mcp 2.x.

$ErrorActionPreference = "Stop"

uvx --with "mcp==1.29.0" mcpo@0.0.20 --port 8001 --api-key "mdp_qgis" -- `
    uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
