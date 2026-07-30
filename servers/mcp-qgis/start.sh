#!/usr/bin/env bash

# Lance mcp-qgis exposé via mcpo (proxy MCP -> OpenAPI)

## Prérequis : plugin "QGIS MCP" démarré dans QGIS Desktop (voir README.md, même dossier)

set -euo pipefail

uvx --with "mcp==1.29.0" mcpo@0.0.20 --port 8001 --api-key "mdp_qgis" -- \
  uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
