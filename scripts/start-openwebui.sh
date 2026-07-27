#!/usr/bin/env bash

# Démarre le conteneur Open WebUI Audiar (installation initiale : voir docs/guides.md)

set -euo pipefail

if docker ps -a --format '{{.Names}}' | grep -qx open-webui; then
  docker start open-webui
  echo "Open WebUI démarré : http://localhost:3000"
else
  echo "Conteneur 'open-webui' introuvable" >&2
  exit 1
fi