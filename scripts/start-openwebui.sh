#!/usr/bin/env bash
# Démarre le conteneur Open WebUI Audiar déjà créé (installation initiale : voir docs/guides.md,
# commande `docker run` à exécuter une seule fois).
set -euo pipefail

if docker ps -a --format '{{.Names}}' | grep -qx open-webui; then
  docker start open-webui
  echo "Open WebUI démarré : http://localhost:3000"
else
  echo "Conteneur 'open-webui' introuvable — installation initiale requise (voir docs/guides.md)." >&2
  exit 1
fi
