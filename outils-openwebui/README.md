# Outils Python natifs Open WebUI ("Tools")

Ce dossier regroupe des **Tools** Open WebUI natifs : du code Python exécuté directement par le
backend Open WebUI, sans passer par un serveur MCP ni par `mcpo`. À distinguer de `servers/`, qui
contient les serveurs MCP métier du projet (`mcp-qgis`, `mcp-postgres`, `mcp-dbhub`...).

**Pourquoi cette alternative existe** : pour certains cas d'usage, faire tourner un serveur MCP
dédié (processus externe, `mcpo`, port, supervision) est plus lourd que nécessaire. Open WebUI
permet d'écrire directement le code d'un outil, avec un mécanisme natif de configuration par
utilisateur (`UserValves`) qui couvre le même besoin de "compte/identifiants personnels" que le
montage `mcpo` + connexion "Direct" utilisé pour les MCP. Voir `postgres-explorer/README.md` pour
un exemple concret et le comparatif avec l'alternative MCP (`servers/mcp-postgres/`,
`servers/mcp-dbhub/`).

**Limite à garder en tête** : un Tool natif n'a aucun garde-fou intégré (pas de blocage des
requêtes destructrices, pas de limite de lignes, etc.) — à la différence d'un serveur MCP dédié
comme `crystaldba/postgres-mcp`. Il faut soit coder ces protections soi-même dans le Tool, soit
s'appuyer sur des garde-fous existant à un autre niveau (ex. droits restreints côté base de
données — c'est le cas retenu pour `postgres-explorer`, voir son README).

## Anatomie d'un Tool

Un Tool est un unique fichier Python, collé tel quel dans Open WebUI (**Espaces de travail** → **Outils** → **New Tool**). Structure attendue :

```python
"""
title: Nom affiché de l'outil
author: ...
version: 0.1.0
description: Description courte de l'outil.
requirements: nom-du-package-pip, autre-package
"""

from pydantic import BaseModel, Field


class Tools:
    class Valves(BaseModel):
        # Config réglée par l'admin uniquement (Workspace → Outils → réglages de l'outil).
        # Optionnel : à omettre si rien n'a besoin d'être partagé entre tous les utilisateurs.
        pass

    class UserValves(BaseModel):
        # Config que CHAQUE utilisateur renseigne dans ses propres réglages personnels
        # (Réglages personnels → Outils). C'est ici qu'on met des identifiants individuels
        # (ex. compte Postgres personnel) plutôt que dans Valves.
        mon_champ: str = Field(default="", description="Description affichée dans le formulaire")

    def __init__(self):
        pass  # self.valves = self.Valves() si une classe Valves est définie

    def ma_fonction(self, un_parametre: str, __user__: dict) -> str:
        """
        Description de ce que fait l'outil — c'est ce texte que le modèle voit pour décider
        quand appeler cette fonction. Documenter aussi chaque paramètre avec :param nom: ...
        :param un_parametre: à quoi sert ce paramètre.
        """
        uv = __user__.get("valves")  # instance de UserValves pour l'utilisateur courant
        # ... logique de l'outil, retourne une chaîne de caractères ...
        return "résultat"
```

Points importants, vérifiés en pratique le 24/07/2026 (`postgres-explorer`) :

- **`requirements:`** dans le docstring d'en-tête déclenche l'installation pip automatique des
  packages listés, dès la sauvegarde de l'outil dans Open WebUI — pas besoin d'installer quoi que
  ce soit à la main sur le serveur.
- **`__user__: dict`** est passé automatiquement par Open WebUI à l'appel — ne jamais lui mettre
  de description (elle serait exposée dans la spécification de fonction envoyée au modèle, ce
  qu'on veut éviter). `__user__["valves"]` (ou `__user__.get("valves")`) donne l'instance
  `UserValves` de l'utilisateur qui discute, uniquement si une classe `UserValves` est définie.
- Chaque méthode publique de la classe `Tools` devient un outil séparé, sélectionnable
  individuellement par le modèle. La docstring de la méthode = description envoyée au modèle ; à
  soigner comme le reste du prompt.
- Le retour de chaque fonction doit être une chaîne de caractères (pas un objet Python brut).

## Déploiement / test

1. **Espaces de travail** → **Outils** → **New Tool**, coller le script, sauvegarder (le nom/la description du
   docstring d'en-tête apparaissent dans la liste).
2. Si une classe `UserValves` est définie : chaque utilisateur va dans ses **Réglages** personnels →
   **Outils** → (nom de l'outil) pour renseigner ses propres valeurs (ex. identifiants personnels).
3. Activer l'outil sur le modèle utilisé : fiche du modèle → onglet **Outils** → cocher l'outil.
   Sans cette étape, l'outil existe mais n'est jamais proposé en conversation.
4. Debug : les `print()` dans le code apparaissent dans les logs serveur d'Open WebUI (pas dans le
   chat) ; toute chaîne retournée par une fonction est en revanche visible du modèle/utilisateur —
   utile pour renvoyer des messages d'erreur explicites plutôt que de lever une exception brute.

## Outils dans ce dossier

- `postgres-explorer/` — exploration d'une base Postgres (lecture/écriture selon les droits du
  compte personnel de l'utilisateur), alternative testée aux serveurs MCP `mcp-postgres`/
  `mcp-dbhub` pour le cas d'usage 1. Voir son README pour le détail et le statut de la comparaison.
