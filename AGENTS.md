# AGENTS.md — instructions de dev pour l'outil IA Audiar

Source de vérité des instructions de développement (stack, conventions, structure).
Lu nativement par Cursor. `CLAUDE.md` importe ce fichier pour Claude Code.

## Stack

- Framework d'orchestration : **Open WebUI** (instance « Open WebUI Audiar » sur Merlin — décision et justification dans `decisions.md`)
- Dispositifs d'extension : outils Python natifs exécutés par le backend, et serveurs MCP exposés en OpenAPI via le proxy `mcpo`. Le choix entre les deux se fait par besoin, et se trace dans `decisions.md` (mécanismes : `plateforme/mecanismes-extension.md`).
- Langage(s) : Python pour les outils natifs, PowerShell pour les scripts distribués aux postes.

## Structure du repo

- `decisions.md` — journal des décisions au format ADR, à la racine. Récapitulatif (état par besoin) et index chronologique en tête.
- `guides.md` — notice administrateur, publiée en PDF.
- `kit-demarrage-openwebui/` — notice utilisateur publiée en PDF, plus les scripts et fichiers de configuration distribués aux postes.
- `plateforme/` — ce qui relève d'Open WebUI lui-même : `mecanismes-extension.md` (référence, se périme avec les versions), `creation-outils.md` (mode d'emploi), `parametrage.md` (état de la configuration), `experimentations.md`, `gabarits/`.
- `fonctionnalites/<besoin>/` — un dossier par besoin métier : `README.md` (état courant), `parametrage.md`, `experimentations.md`, le script s'il est installé par un administrateur, et `old/` pour les dispositifs écartés.
- `ressources/` — `skills/`, `connaissances/`, `prompts/` : les artefacts importés dans Open WebUI, partagés entre fonctionnalités.
- `benchmark-techno.md`, `benchmark-modeles.md` — recherche comparative citée par `decisions.md`.
- `diagnostic/` — documents source primaires (analyse fonctionnelle CU1-CU9, analyse technique).
- `img/` — copies d'écran de `guides.md`. Celles du kit restent dans le kit, qui doit rester autonome.
- `draft/` — scratchpad non versionné : ce qui se stabilise est déplacé vers son emplacement définitif puis retiré d'ici.

## Conventions

- **Où vit un fichier suit qui l'installe** : script lancé par un chargé d'études → `kit-demarrage-openwebui/` ; outil collé dans l'interface par un administrateur → à la racine du dossier de sa fonctionnalité. Pas de sous-dossier `scripts/` pour un seul fichier.
- **`decisions.md` fonctionne en journal** : on n'édite jamais une entrée retenue. Une décision qui change donne une nouvelle entrée qui remplace la précédente, avec un renvoi entre les deux. Le prochain numéro disponible : `grep -o "D-[0-9]\+" decisions.md | sort -u | tail -1`
- **Branches** : si le commit touche `fonctionnalites/*/` (scripts) ou `kit-demarrage-openwebui/`, il passe par une branche nommée `<fonctionnalite>-<sujet>` ; sinon il va directement sur `main`. `main` doit toujours contenir ce qui est réellement installé.
- **Version installée** : tout script porte en en-tête sa version et la date de son installation dans Open WebUI. C'est le seul moyen de savoir si le dépôt reflète ce qui tourne.
- `CLAUDE.local.md` (gitignoré) : notes personnelles, jamais partagées.
- Les vrais fichiers de configuration ne sont jamais commités, seules leurs versions `.example` le sont (`dbhub.toml.example`, `user-import.example.csv`). Les motifs de `.gitignore` ne doivent **pas** être ancrés sur un chemin : un fichier déplacé cesserait d'être ignoré sans que rien ne le signale.
- Transport stdio = un client à la fois ; passer en HTTP streamable si plusieurs outils doivent interroger le même serveur simultanément.
- Tout lancement `uvx mcpo` doit épingler `mcpo@<version>` **et** sa dépendance `mcp` via `--with "mcp==<version>"` — jamais `uvx mcpo` nu. Raison : `mcpo` déclare `mcp>=1.17.0` sans plafond, et `mcp` 2.0.0 a renommé une fonction que `mcpo` importe, cassant toute résolution fraîche (détail en tête de `kit-demarrage-openwebui/start-mcp/scripts/start-mcp-qgis.ps1`).
- Jamais de tiret cadratin (`—`) dans un script (`.ps1`/`.sh`/`.bat`), y compris en commentaire — préférer `:` ou `-`. Raison : sans BOM, Windows PowerShell 5.1 peut lire un `.ps1` UTF-8 avec le mauvais encodage système ; un `—` placé dans une chaîne de caractères peut alors être mal interprété comme un guillemet fermant et faire planter le script avec une erreur de type "terminateur manquant" (constaté sur `kit-demarrage-openwebui/install/scripts/install-uv.ps1`, 29/07/2026). Les `.ps1` du kit portent un BOM UTF-8 ; le `.bat` n'en porte pas, `cmd.exe` le refuserait.

## Conventions typographiques (documentation)

Deux formes seulement, alignées sur les guides de style Google et Microsoft — accents graves pour ce qu'on tape ou qu'on ouvre, gras pour ce sur quoi on clique.

| Élément | Forme | Exemple |
|---|---|---|
| Chemins, fichiers, dossiers | accents graves | `decisions.md`, `%LOCALAPPDATA%\uv\cache` |
| Commandes, options, code inline | accents graves | `docker start open-webui`, `--api-key` |
| Variables d'environnement, noms de tables | accents graves | `DATABASE_URL`, `config` |
| Menus, boutons, onglets, libellés d'interface | gras | **Panneau d'administration** → **Réglages** → **Connexions** |

- Jamais de chemin en gras ni entre crochets : hors police code, l'antislash est un caractère d'échappement Markdown (`C:\Users\clm` rendu hors code donne `C:Usersclm`) et les crochets sont la syntaxe de lien, ce qui casse silencieusement au rendu Pandoc.
- Pas de gras cumulé avec les accents graves : la police code suffit.
- Chaînes de navigation : séparateur `→`, chaque libellé en gras séparément, jamais le gras sur toute la chaîne.
- Libellés d'interface en français (langue de l'instance), l'anglais entre parenthèses seulement quand il aide à retrouver la documentation officielle.

## Commandes

- Lancer Open WebUI (déjà installé) : `docker start open-webui` (installation initiale : `guides.md`)
- Lancer mcp-qgis sur un poste : `kit-demarrage-openwebui/start-mcp/start-mcp-qgis.bat`, après avoir activé **Run MCP** dans QGIS. La clé `--api-key` est écrite à la fois dans `start-mcp/scripts/start-mcp-qgis.ps1` et dans `outils-serveurs/serveur-mcp-qgis.json` : les deux doivent rester identiques.
- Accès Postgres : aucun serveur à lancer — outil Python natif, `fonctionnalites/exploration-bd/exploration-bd.py`, identifiants renseignés par chaque utilisateur dans ses réglages personnels.
- Logs Open WebUI : `docker logs open-webui` (`-f` pour suivre en direct, `--tail 100` pour les 100 dernières lignes)
- Pas de lint/tests à ce stade : le repo assemble des outils existants — aucun code applicatif propre au projet, hors l'outil d'exploration de la base.

## Note de style pour ce fichier

Rester court et actionnable (commandes exactes, conventions qui diffèrent des défauts du langage) — pas de pavé théorique.
