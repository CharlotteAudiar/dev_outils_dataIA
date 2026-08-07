## Dispositifs d'extension et contraintes de déploiement

### Quatre dispositifs
L'ajout de fonctionnalités dans Open WebUI peut se faire via quatre dispositifs :

- **Fonctionnalités par défaut** : trois fonctionnalités – recherche web, génération d'images et interpréteur de code – peuvent/doivent être paramétrés via le back-office ; 
- **Outils** : scripts python pouvant être configurés globalement ou individuellement (ou configurés globalement et paramétrés individuellement) ;
- **Serveurs externes** (MCP notamment) : peuvent être configurés globalement (côté admin) ou localement (côté utilisateur) ;
- **Fonctions** : permettent notamment de configurer des pipelines complètes ou de filtrer/modifier automatiquement les requêtes et réponses.    

Les  fonctions servent à modifier le pipeline de chat lui-même (filtrage automatique des requêtes/réponses, création de nouveaux modèles...). Les besoins prioritaires du projet (BDD, Excel, QGIS) pouvant déjà être couverts par les serveurs externes et les outils, ce dispositif n'a pas été étudié dans le détail.

Deux fonctionnalités par défaut entrent dans le champs de l'étude, la recherche sur le web et l'interpréteur de code. Elles font appel à des moteurs dédiés, qui doivent être paramétrés par un administrateur dans l'espace « Réglages » du panneau d'administration. Elles n'ont pas encore été étudiées dans le détail car elles ne répondent pas aux besoins prioritaires du projet.

Pour répondre aux besoins identifiés, il s'agira ainsi de choisir entre un outil, un serveur externe partagé ou un serveur externe local.

| **Dispositif** | **Configurateur** | **Origine des appels** | **Type de connexion** |
| --- | --- | ---- | --------- |
| Outil | Admin ou user | Serveur | *Aucune (logique interne au code)* | 
| Serveur global | Admin | Serveur | OpenAPI ou StreamableHTTP (MCP natif) |
| Serveur local | User | Navigateur | OpenAPI | 

### À savoir sur les serveurs

#### Processus local

Concernant les serveurs, si le besoin est d'utiliser un logiciel ouvert sur le PC utilisateur (QGIS, Excel...), le serveur doit dans tous les cas tourner sur le même poste, car serveur et logiciel ne peuvent communiquer que par une connexion locale (socket localhost, automation COM/OLE...). Cela implique, pour l'utilisateur, de lancer le serveur sur son PC à chaque fois qu'il veut utiliser un logiciel avec Open WebUI.

Dans ce cas de figure, un serveur peut être configuré localement ou globalement. S'il est configuré localement, l'opération devra être répétée sur tous les postes. S'il est configuré globalement, un administrateur aura deux possibilités : configurer autant de serveurs que d'utilisateurs (avec contrôle d'accès), afin de correspondre à chaque connexion locale, ou mettre en place un proxy/routeur permettant d'ajouter un id dans la requête, afin de rediriger la réponse vers le PC correspondant à cet id, ce qui demande un développement particulier.

Si le serveur est configuré globalement, le poste de l'utilisateur doit toutefois être joignable depuis le serveur où tourne Open WebUI (problématiques de stabilité d'adresse, de pare-feu...). Cela n'a pas été vérifié.

#### OpenAPI vs StreamableHTTP

Dans le cas d'un serveur configuré globalement, le choix entre un paramétrage OpenAPI ou MCP natif (StreamableHTTP uniquement, pas de connexion stdio possible dans Open WebUI) dépendra de la manière dont le MCP a été conçu. Par exemple, actuellement, les MCP construits avec la librairie python FastMCP restreignent par défaut leurs connexions à l'IP locale (localhost/127.0.0.1), sauf configuration explicite du développeur. Pour ces serveurs, il faudra utiliser le paramétrage OpenAPI, ainsi que le logiciel en ligne de commande mcpo, qui sert de proxy entre le serveur MCP (en stdio) et Open WebUI, et expose lui-même une adresse et un port configurables. Ces restrictions de FastMCP pourraient toutefois évoluer dans des versions futures.

Dans la version actuelle d'Open WebUI, la configuration locale d'un serveur est forcément OpenAPI. Elle nécessite donc l'utilisation de mcpo. 

#### Options MCPO
Exposer un serveur MCP en OpenAPI nécessite l'utilisation du proxy mcpo. Celui-ci peut être utilisé avec une commande inline (un serveur MCP par instance), ou avec `--config <fichier.json>` pour lire un fichier au format « mcpServers » (celui de Claude Desktop, Cursor, Cline...), permettant de déclarer plusieurs serveurs MCP à la fois, chacun exposé sous sa propre route par une seule instance mcpo. 

Deux options supplémentaires viennent avec ce mode : `disabledTools` (liste d'outils à exclure de ce qui est exposé, par serveur) et `--hot-reload` (recharge automatique si le fichier de config change, sans redémarrer mcpo).

Il faut également noter que mcpo accepte des requêtes venant de n'importe quel site web ouvert dans un navigateur, pas seulement d'Open WebUI. La clé API du processus, configurée manuellement, devra donc être suffisamment sécurisée. 

#### Modes d'installation et de lancement
Plusieurs stratégies sont possibles pour installer et lancer un MCP, selon où le serveur doit ou peut tourner, ses dépendances et les contraintes du pôle Données.

**Installation permanente** : 
Installation du serveur via `pip` ou `uv tool`. Avantages : version figée et traçable. Inconvénients : mise à jour manuelle. Si `pip` est choisi, il sera préférable de lancer le serveur dans un environnement (venv).

**Installation temporaire** : 
Installation dans le cache persistant de uv via `uvx`.  Avantages : vérification mise à jour à chaque lancement et téléchargement nouvelle version si elle existe. Inconvénients : version non traçable.

De la même manière, **mcpo** peut être installé de manière permanente via `pip` ou `uv tool` ou dans le cache persistant de uv via `uvx`. La version de mcpo à installer et celle du SDK MCP doivent être surveillées : au 3 août, la dernière version de mcpo n'avait pas encore implémenté la nouvelle version du SDK MCP (2.0.0).

Dans le cas d'un MCP devant tourner sur un PC utilisateur, le lancement peut se faire via une ligne de commande. Un geste manuel qui pourrait être remplacé par une tâche planifiée au démarrage/à l'ouverture de session ou par un service Windows (par exemple NSSM/WinSW encapsulant la commande `uvx`).

Dans ce projet, une installation temporaire via `uvx` a été choisie.

#### Docker et localhost

Enfin, si OpenWebUI est installé dans Docker, il faut noter que l'adresse http://localhost pointe vers son conteneur. Dans le cas d'un serveur configuré globalement, l'appel est lancé depuis le conteneur (et non pas du navigateur). Si le serveur où se trouve Docker doit être joint, il faudra utiliser l'adresse http://host.docker.internal. 

### À savoir sur les outils
Qu'il soit installé par un utilisateur ou un administrateur, un outil (script python) tourne toujours côté serveur, pas côté navigateur. Il ne peut donc pas être utilisé pour interagir avec un logiciel tournant sur le PC utilisateur.

Open WebUI intégre un mécanisme, les valves, consistant à permettre la configuration de certains paramètres d'outils partagés par les utilisateurs (par exemple des id et mots de passe).

Un outil n'étant pas isolé, son code s'exécute avec les mêmes accès que le processus Open WebUI (réseau, identifiants, fichiers), ceux du conteneur Docker s'il y en a un, ceux du serveur entier sinon. Le risque dépend donc de ce que fait chaque outil, sans protection propre à Open WebUI.

### Serveur vs Outils