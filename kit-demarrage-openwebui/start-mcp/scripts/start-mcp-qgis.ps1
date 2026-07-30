# Lance mcp-qgis exposé via mcpo (proxy MCP -> OpenAPI)
# Équivalent PowerShell de start.sh (même dossier) : pour postes Windows utilisateurs,
# sans dépendance à bash/WSL/Git Bash (cf. échange du 24/07/2026 : `bash` resolvait vers WSL,
# qui ne traduit pas les chemins de lecteurs réseau mappés).

## Prérequis : plugin "QGIS MCP" démarré dans QGIS Desktop (voir README.md, même dossier)

$ErrorActionPreference = "Stop"

uvx --with "mcp==1.29.0" mcpo@0.0.20 --port 8001 --api-key "mdp_qgis" -- `
    uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
