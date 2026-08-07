# Créer un Tool Open WebUI

Ce qu'il faut savoir pour écrire un Tool Open WebUI natif sans repartir de zéro. Le seul exemple en service à ce jour est l'outil d'exploration de la base (`fonctionnalites/exploration-bd/exploration-bd.py`), cité ici comme illustration.

Contenu vérifié le 24/07/2026 sur Open WebUI 0.10.2 : à relire à chaque montée de version.

## Avant d'écrire : ce qu'un Tool engage

Un Tool exécute du code Python arbitraire **directement sur le serveur qui héberge Open WebUI**. Donner à quelqu'un le droit de créer ou d'importer un Tool équivaut à lui donner un accès shell au serveur. Deux conséquences : restreindre le droit de création (**Espaces de travail**) aux personnes de confiance, et relire intégralement le code de tout Tool avant de l'importer, le sien comme celui d'un tiers.

## Anatomie d'un Tool

Un Tool est un unique fichier Python, collé tel quel dans Open WebUI (**Espaces de travail** → **Outils** → **New Tool**). Il a deux parties : un docstring d'en-tête qui porte les métadonnées, et une classe obligatoirement nommée `Tools`.

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
        # Config réglée par l'admin uniquement (Espaces de travail > Outils > réglages de l'outil).
        # Optionnel : à omettre si rien n'a besoin d'être partagé entre tous les utilisateurs.
        pass

    class UserValves(BaseModel):
        # Config que CHAQUE utilisateur renseigne dans ses propres réglages personnels
        # (Réglages > Outils). C'est ici qu'on met des identifiants individuels
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

## Règles

**Docstring d'en-tête** : `title`, `author`, `description`, `version`, `requirements` ; en option `author_url`, `git_url`, `required_open_webui_version`, `licence`. Depuis la version 0.9.6, Open WebUI préremplit le nom et la description à la création du Tool, sans écraser une valeur déjà saisie à la main.

**`requirements:`** déclenche l'installation pip automatique des packages listés, dès la sauvegarde du Tool dans Open WebUI : rien à installer à la main sur le serveur.

**Chaque méthode publique de `Tools` devient un outil distinct**, que le modèle sélectionne individuellement. Trois contraintes sur ces méthodes :

- **Type hints obligatoires** sur les paramètres et la valeur de retour : Open WebUI s'en sert pour générer le schéma JSON envoyé au modèle. Sans eux, l'outil fonctionne beaucoup moins fiablement.
- **La docstring est lue par le modèle** : description générale, puis une ligne `:param nom: ...` par paramètre. À soigner comme une partie du prompt, pas comme un commentaire pour soi.
- **Le retour doit être une chaîne de caractères**, jamais un objet Python brut ni un dictionnaire.

**Préférer `async def`** : la documentation officielle le recommande pour la compatibilité avec les versions à venir, le backend basculant progressivement vers une exécution entièrement asynchrone. Une bibliothèque bloquante doit alors être isolée — méthode publique en `async def` qui délègue le travail à une méthode privée synchrone exécutée via `asyncio.to_thread(...)`, pour ne pas geler la boucle asyncio d'Open WebUI pendant un accès réseau.

**Arguments réservés**, à ajouter seulement si besoin : `__user__` (infos utilisateur, et instance `UserValves` dans `__user__["valves"]`), `__event_emitter__` et `__event_call__` (statuts et interactions dans le chat), `__metadata__`, `__messages__`, `__files__`, `__model__`, `__oauth_token__` (jeton OAuth de l'utilisateur, pour appeler une API tierce en son nom). **Ne jamais leur donner de description** dans la docstring : elle serait exposée dans la spécification de fonction envoyée au modèle.

**Écrire pour le mode Native (Agentic)**, mode par défaut aujourd'hui ; le mode Legacy est obsolète et non supporté. La distinction ne compte vraiment que pour un Tool qui utilise des `__event_emitter__` avancés.

## Valves et UserValves, en clair

Les deux servent à exposer des réglages configurables dans l'interface d'Open WebUI, sans toucher au code :

- **`Valves`** : réglages **globaux**, modifiables uniquement par un admin (**Espaces de travail** → **Outils**). Adapté à une configuration partagée par tout le monde, par exemple une URL de service commune.
- **`UserValves`** : réglages **par utilisateur**, que chaque personne renseigne elle-même dans ses **Réglages** personnels → **Outils**. C'est le mécanisme retenu pour l'outil d'exploration de la base, afin que chacun saisisse son propre compte Postgres sans que ces identifiants transitent par un administrateur.

Techniquement, les deux sont des classes qui héritent de `pydantic.BaseModel`, avec un champ par réglage défini via `Field(default=..., description="...")` — c'est cette description qui apparaît comme texte d'aide dans le formulaire généré automatiquement par Open WebUI.

Deux pièges vérifiés en pratique :

- **Lire un `UserValves` par attribut**, `__user__["valves"].mon_champ` (ou `__user__.get("valves")`, équivalent). **Jamais** par clé, `__user__["valves"]["mon_champ"]` : cette notation renvoie silencieusement la valeur par défaut au lieu de celle configurée par l'utilisateur.
- **Champs sensibles** (mots de passe, clés d'API) : ajouter `json_schema_extra={"input": {"type": "password"}}` au `Field` pour que le champ s'affiche masqué dans l'interface au lieu d'être en clair.

## Dépendances Python

`requirements:` installe les packages avec pip, dans le conteneur Open WebUI, où aucune chaîne de compilation n'est disponible. **Préférer donc les distributions précompilées** quand un package existe en deux variantes — typiquement `psycopg2-binary` plutôt que `psycopg2`, qui exige de compiler `libpq`.

- `requests` ou `httpx` (l'exemple officiel OAuth utilise `httpx`, en asynchrone) pour un Tool qui appelle une API HTTP externe plutôt qu'une base de données.
- `pydantic`, déjà utilisé pour `Valves` et `UserValves`, réutilisable pour valider ou structurer n'importe quelle donnée manipulée par un Tool.
- Pilotes pour d'autres bases si le besoin apparaît : `mysql-connector-python` (MySQL), `pyodbc` (SQL Server via ODBC).

## Sources officielles

- [Tools & Functions (Plugins) — vue d'ensemble](https://docs.openwebui.com/features/extensibility/plugin/) — distingue Tools (donnent des capacités au modèle, appelées pendant sa réponse) et Functions (modifient le comportement de la plateforme elle-même).
- [Tools — présentation](https://docs.openwebui.com/features/extensibility/plugin/tools/)
- [Tool Development — page de référence](https://docs.openwebui.com/features/extensibility/plugin/tools/development/) — la page la plus utile : structure du fichier, arguments réservés, exemples.
- [Valves & UserValves](https://docs.openwebui.com/features/extensibility/plugin/development/valves/) — détail du mécanisme de configuration par admin (`Valves`) contre par utilisateur (`UserValves`).
- [Events (Event Emitters)](https://docs.openwebui.com/features/extensibility/plugin/development/events) — pour afficher des statuts ou notifications dans le chat pendant l'exécution d'un outil.
- [Reserved Arguments](https://docs.openwebui.com/features/extensibility/plugin/development/reserved-args) — liste complète des arguments spéciaux qu'Open WebUI peut injecter dans une méthode de Tool.
- [Plugin Security Warning](https://docs.openwebui.com/features/extensibility/plugin/) — encart en haut de la vue d'ensemble, à lire avant d'accorder à quelqu'un le droit de créer ou d'importer des Tools.

## Sources communautaires (pour s'inspirer, avec prudence)

- [openwebui.com/explore](https://openwebui.com/explore) — galerie officielle d'outils, prompts et modèles partagés par la communauté, avec bouton d'import direct.
- [openwebui.com/tools](https://open-webui.com/tools/) — section dédiée aux Tools.
- [github.com/Haervwe/open-webui-tools](https://github.com/Haervwe/open-webui-tools) — une quinzaine d'outils avec du code réel à lire comme exemples de patterns plus avancés.
- [github.com/gitjfmd/open-webui-tools](https://github.com/gitjfmd/open-webui-tools) — autre collection, plus modeste.