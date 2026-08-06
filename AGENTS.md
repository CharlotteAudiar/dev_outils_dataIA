# AGENTS.md — instructions de dev pour l'outil IA Audiar

Source de vérité des instructions de développement (stack, conventions, structure).
Lu nativement par Cursor. `CLAUDE.md` importe ce fichier pour Claude Code.

## Stack

- Framework d'orchestration : **Open WebUI** (instance "Open WebUI Audiar" — décision et justification dans `docs/architecture/decisions.md`)
- Serveurs MCP métier : QGIS, filesystem, Excel (voir `servers/`), exposés à Open WebUI via le proxy `mcpo` (MCP → OpenAPI). PostgreSQL n'est plus un serveur MCP depuis le 03/08/2026 : accès via un outil Python natif Open WebUI (`outils-openwebui/explorateur-postgres/`) — `servers/mcp-postgres/` et `servers/mcp-dbhub/` sont conservés pour mémoire mais abandonnés.
- Langage(s) : à définir

## Structure du repo

- `servers/mcp-*/` — un serveur MCP par dossier, isolé, sans logique spécifique à un client : `README.md` (décision, montage technique) + `start.sh` (commande `mcpo` validée), quand le serveur est actif
- `openwebui-tools/<nom>/` — alternative aux serveurs MCP : Tool Python natif Open WebUI (exécuté directement par le backend, pas de process externe/`mcpo`), quand un serveur MCP dédié est disproportionné pour le besoin. Voir `openwebui-tools/README.md` pour la structure attendue et le comparatif avec `servers/`.
- `config/` — `.env.example` (variables d'environnement attendues, sans valeurs réelles)
- `scripts/` — scripts transverses, pas spécifiques à un serveur (ex. `start-openwebui.sh` pour l'instance elle-même)
- `docs/architecture/` — décisions techniques (ADR) + recherche comparative
- `docs/sources/` — documents source primaires (ex. analyse fonctionnelle CU1-CU9), versionnés car cités par `docs/architecture/`
- `docs/specs.md` — specs fonctionnelles pour les chargés d'études (utilisateurs finaux, pas les devs)
- `docs/guides.md` — installation, usage, onboarding
- `docs/knowledge.md` — synthèses à uploader dans les Projects Claude Desktop/Cowork des chargés d'études
- `docs/benchmark-modeles.md` — comparatif des fournisseurs de modèles LLM par API (Mistral, RAGaRenn, OVHcloud...)
- `draft/` — scratchpad non structuré (notes, essais de scripts), pas une convention durable : le contenu qui se stabilise est déplacé vers son emplacement définitif (`servers/`, `openwebui-tools/`, `docs/`) puis retiré d'ici

## Conventions

- `CLAUDE.local.md` (gitignoré) : notes personnelles — chemins locaux, remarques en cours, journal de progression — jamais partagées.
- Un serveur MCP = un dossier sous `servers/`, ses propres dépendances, son propre `README.md` + `start.sh`.
- Serveur MCP (`servers/`) vs Tool natif Open WebUI (`openwebui-tools/`) : MCP par défaut (réutilisable hors Open WebUI, garde-fous portés par le serveur lui-même) ; Tool natif si le process externe + `mcpo` est disproportionné pour le besoin, à condition d'assumer ses propres garde-fous (voir `openwebui-tools/README.md`).
- Les vrais fichiers de config (`.env`, `CLAUDE.local.md`) ne sont jamais commités : seules leurs versions `.example` le sont (voir `.gitignore`).
- Transport stdio = un client à la fois ; passer en HTTP streamable si plusieurs outils doivent interroger le même serveur simultanément.
- Tout lancement `uvx mcpo` doit épingler `mcpo@<version>` **et** sa dépendance `mcp` via `--with "mcp==<version>"` — jamais `uvx mcpo` nu. Raison : `mcpo` déclare `mcp>=1.17.0` sans plafond, et `mcp` 2.0.0 a renommé une fonction que `mcpo` importe, cassant toute résolution fraîche (détail : `docs/guides.md`, section "Dépannage" sous mcp-qgis).
- Jamais de tiret cadratin (`—`) dans un script (`.ps1`/`.sh`/`.bat`), y compris en commentaire — préférer `:` ou `-`. Raison : sans BOM, Windows PowerShell 5.1 peut lire un `.ps1` UTF-8 avec le mauvais encodage système ; un `—` placé dans une chaîne de caractères peut alors être mal interprété comme un guillemet fermant et faire planter le script avec une erreur de type "terminateur manquant", loin de la vraie cause (constaté sur `kit-demarrage-openwebui/install-uv.ps1`, 29/07/2026).

## Conventions typographiques (documentation)

Deux formes seulement, alignées sur les guides de style Google et Microsoft — accents graves pour ce qu'on tape ou qu'on ouvre, gras pour ce sur quoi on clique.

| Élément | Forme | Exemple |
|---|---|---|
| Chemins, fichiers, dossiers | accents graves | `docs/architecture/decisions.md`, `%LOCALAPPDATA%\uv\cache` |
| Commandes, options, code inline | accents graves | `docker start open-webui`, `--api-key` |
| Variables d'environnement, noms de tables | accents graves | `DATABASE_URL`, `config` |
| Menus, boutons, onglets, libellés d'interface | gras | **Panneau d'administration** → **Réglages** → **Connexions** |

- Jamais de chemin en gras ni entre crochets : hors police code, l'antislash est un caractère d'échappement Markdown (`C:\Users\clm` rendu hors code donne `C:Usersclm`) et les crochets sont la syntaxe de lien, ce qui casse silencieusement au rendu Pandoc.
- Pas de gras cumulé avec les accents graves : la police code suffit.
- Chaînes de navigation : séparateur `→`, chaque libellé en gras séparément, jamais le gras sur toute la chaîne.
- Libellés d'interface en français (langue de l'instance), l'anglais entre parenthèses seulement quand il aide à retrouver la documentation officielle.

## Commandes

- Lancer Open WebUI (déjà installé) : `./scripts/start-openwebui.sh` (installation initiale : `docs/guides.md`)
- Lancer mcp-qgis : `./servers/mcp-qgis/start.sh` (clé `--api-key` en dur dans le script, à éditer localement + plugin QGIS MCP démarré côté QGIS Desktop)
- Accès Postgres : plus de serveur MCP à lancer — outil Python natif Open WebUI, voir `outils-openwebui/explorateur-postgres/README.md` (identifiants renseignés par chaque utilisateur dans ses réglages personnels)
- `servers/mcp-postgres/` et `servers/mcp-dbhub/` : **abandonnés** (03/08/2026), conservés pour mémoire — ne plus les lancer
- Logs Open WebUI : `docker logs open-webui` (`-f` pour suivre en direct, `--tail 100` pour les 100 dernières lignes)
- Pas de lint/tests à ce stade : le repo assemble des outils existants (Open WebUI, serveurs MCP tiers) — aucun code applicatif propre au projet pour l'instant.

## Note de style pour ce fichier

Rester court et actionnable (commandes exactes, conventions qui diffèrent des défauts du langage) — pas de pavé théorique.
