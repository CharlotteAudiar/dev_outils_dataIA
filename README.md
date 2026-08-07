# Audiar IA Toolkit

Outil IA pour les chargés d'études de l'agence, construit sur **Open WebUI** (framework retenu, cf. `decisions.md`) : accès à la base de données, pilotage de QGIS, et les briques à venir. Référence de projet : 2026-HP-INT-001.

## Contenu

- `decisions.md` — journal des décisions : ce qui a été choisi, quand et pourquoi. Commence par son récapitulatif et son index.
- `guides.md` — notice administrateur : installation et paramétrage de l'instance mutualisée sur Merlin.
- `kit-demarrage-openwebui/` — notice utilisateur et scripts distribués aux chargés d'études.
- `plateforme/` — ce qui relève d'Open WebUI lui-même : mécanismes d'extension, création d'outils, paramétrage, expérimentations, gabarits d'import.
- `fonctionnalites/` — un dossier par besoin métier, chacun avec son état courant, son paramétrage et ses expérimentations.
- `ressources/` — skills, connaissances et prompts, partagés entre plusieurs fonctionnalités.
- `benchmark-techno.md`, `benchmark-modeles.md` — la recherche comparative derrière les décisions.
- `diagnostic/` — documents source du projet (analyse fonctionnelle, analyse technique).
- `img/` — copies d'écran de `guides.md`.
- `draft/` — brouillons, non versionné.

## Trois liens qui ne se devinent pas

**Où vit un script dépend de qui l'installe.** Un script que le chargé d'études lance lui-même vit dans `kit-demarrage-openwebui/`, qui est le canal de distribution ; un outil Python qu'un administrateur colle dans l'interface vit avec sa fonctionnalité, à la racine de son dossier.

**Le dépôt n'est pas le canal de distribution.** Le kit est copié sur `Z:\3.NUMERIQUE\PROJETS\2026_IA&BD_2026-HP-INT-001`, et c'est de là que les chargés d'études le récupèrent. Toute modification d'un script du kit doit être republiée sur `Z:`, faute de quoi les postes continuent de lancer l'ancienne version.

**Deux documents sont publiés en PDF** : `guides.md` pour les administrateurs, `kit-demarrage-openwebui/kit-demarrage-openwebui.md` pour les utilisateurs. Tout le reste est interne au dépôt.

## Par où commencer

1. Ce README.
2. `decisions.md`, section « Récapitulatif des décisions » — l'état des dispositifs par besoin, en un coup d'œil ; puis l'index si tu cherches une décision précise.
3. `guides.md` — installation et paramétrage pas-à-pas.
4. `fonctionnalites/<besoin>/README.md` — l'état courant de la brique qui t'intéresse.
5. `benchmark-techno.md` et `benchmark-modeles.md` — seulement pour la recherche comparative derrière une décision.

Voir `AGENTS.md` pour les conventions de développement et les commandes du projet.
