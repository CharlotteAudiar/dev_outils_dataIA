# Métadonnées géographiques, GeoNetwork et normes ISO — état des lieux et pistes d'outillage

Document d'étude (non tranché) — à rattacher au cas d'usage « base non documentée » évoqué dans `docs/architecture/decisions.md` (« étude métadonnées geonetwork à étudier »).

Toutes les affirmations ci-dessous sont sourcées. Quand une page de documentation consultée ne permettait de vérifier qu'une partie d'un point, ce point est signalé comme non confirmé plutôt que déduit.

**Note de vérification (31/07/2026)** : ce document a fait l'objet d'une seconde passe dédiée à vérifier l'absence de version plus récente des normes/outils cités. Quatre points ressortent de cette vérification et sont détaillés aux endroits concernés :

1. GeoNetwork marque désormais **ISO 19110 comme « Deprecated - use ISO19115-3 »** dans sa propre documentation (§2.4) — sans que cela remette en cause la structure technique décrite au §2.1, toujours implémentée dans la version stable actuelle.
2. Il existe une **édition ISO 19115-3:2023** au niveau de la norme (ISO, référence 80874), plus récente que l'édition 2018 citée ici — mais le plugin de schéma effectivement utilisé par GeoNetwork (y compris en version 4.4.12, la plus récente vérifiée) reste nommé et versionné « 2018 » (§1.4).
3. La **directive INSPIRE est en cours de révision** (initiative « GreenData4All », proposition législative de la Commission européenne du 10/12/2025, COM(2025) 985 final) qui vise justement à simplifier les exigences techniques/d'interopérabilité, dont les métadonnées — le règlement (CE) 1205/2008 cité au §1.3 reste en vigueur à ce jour mais n'est pas figé (§1.3, encart de vigilance).
4. Les versions des outils listés en §4 ont été vérifiées à date (geoflow 1.2.1, OWSLib 0.36.0, pygeometa 0.21.1, Plume v1.2.1) ; aucun de ces outils n'a changé de nature depuis la première rédaction, mais le non-support d'ISO 19110 par pygeometa est désormais confirmé (et non plus seulement non confirmé).

---

## 1. Impératifs des métadonnées acceptées par GeoNetwork (normes ISO)

### 1.1 Les standards que GeoNetwork sait cataloguer

GeoNetwork n'impose pas un schéma unique : le choix du standard dépend du type de ressource à décrire.

- **Dublin Core** : pour les portails open data, publications, rapports.
- **ISO 19115 / 119 / 139** (profil **ISO 19115-3:2018** dans les versions récentes de GeoNetwork) : pour les ressources spatiales (jeux de données, services, cartes).
- **ISO 19110** : pour les tables d'attributs (catalogue d'entités).

Source : [Describing information — GeoNetwork opensource 4.2](https://docs.geonetwork-opensource.org/4.2/user-guide/describing-information/)

### 1.2 Éléments considérés comme obligatoires côté éditeur GeoNetwork

Dans l'éditeur ISO 19115-3, la vue « Simple » regroupe les champs qui doivent systématiquement être renseignés pour qu'une fiche soit valide et publiable : identifiant de métadonnées, contact, type de ressource, date, titre, résumé, catégorie thématique, ainsi que le point de contact de la métadonnée (organisme ou personne).

Une synthèse convergente de plusieurs guides (notamment le guide FAO 2021 et le guide utilisateur NAL/USDA) retient comme socle minimal : **titre, date de création ou publication, résumé, langue, catégorie thématique (topic category), échelle, fréquence de mise à jour, point de contact de la métadonnée**. Le titre, la date et le résumé sont décrits comme des champs qui doivent être complétés pour que la fiche valide le schéma ; un nom d'organisme ou de personne doit également être renseigné pour le point de contact.

Sources :
- [How to Create and Publish Geospatial Metadata — FAO, 2021 (PDF)](https://openknowledge.fao.org/server/api/core/bitstreams/5cc37bd1-1185-4e24-b70d-266ce96813f4/content)
- [ISO 19115 Metadata Elements Content — NAL/USDA GeoNetwork](https://geodata.nal.usda.gov/geonetwork/doc/geodata/NAL_UserGuide/19115_content/19115_content_main.html)
- [Geographic information -- Metadata (iso19115-3.2018) — GeoNetwork opensource 4.4](https://docs.geonetwork-opensource.org/4.4/annexes/standards/iso19115-3.2018/)

**Point de vigilance** : la page de référence GeoNetwork sur ISO 19115-3:2018 est un index technique auto-généré (liste de tous les éléments du schéma, classés par espace de noms) et ne porte pas de colonne « obligatoire/optionnel » exploitable telle quelle. La liste ci-dessus est donc une synthèse de plusieurs guides utilisateurs, pas une lecture directe du XSD. Pour un besoin de conformité stricte, la référence à consulter est le schéma XSD du profil réellement déployé (`iso19115-3.2018` ou un profil dérivé/national).

### 1.3 Cas particulier : publication sur un portail soumis à INSPIRE

Si les fiches doivent être diffusées sur un géoportail relevant de la directive européenne INSPIRE (2007/2/EC), un jeu d'éléments supplémentaires est imposé par le règlement d'exécution **(CE) n° 1205/2008**. Les « Technical Guidelines » qui en détaillent l'implémentation en ISO 19139 listent notamment, avec leur cardinalité :

| Élément | Élément XML (ISO 19139) | Cardinalité | Référence TG |
|---|---|---|---|
| Langue de la métadonnée | `gmd:language` | 1 | TG Requirement C.5 |
| Point de contact de la métadonnée | `gmd:contact` | 1..* | TG Requirement C.6 |
| Date de la métadonnée | `gmd:dateStamp` | 1 | TG Requirement C.7 |
| Titre de la ressource | `gmd:CI_Citation/title` | 1 | TG Requirement C.8 |
| Résumé de la ressource | `gmd:abstract` | 1 | TG Requirement C.9 |
| Organisme responsable de la ressource | — | 1..* | TG Requirement C.10 |
| Référence temporelle (une des dates : publication/création/révision) | — | 1..* | TG Requirement C.11 |
| Limitations d'accès public | `gmd:resourceConstraints` | 1..* | TG Requirement C.17 |
| Conditions d'accès et d'utilisation | — | 1..* | TG Requirement C.18 |

D'autres éléments (emprise géographique, conformité/qualité, type de ressource, identifiant unique, mots-clés, résolution spatiale, langue de la ressource, catégorie thématique, système de référence...) sont également couverts par les Technical Guidelines, mais le corps détaillé de ces sections n'a pas pu être intégralement vérifié dans la lecture effectuée (page très longue, lecture partielle). Pour une conformité INSPIRE certaine, se référer directement au texte du règlement et à l'annexe C complète des Technical Guidelines.

Sources :
- [Technical Guidance for the implementation of INSPIRE dataset and service metadata based on ISO/TS 19139:2007 — INSPIRE-MIF](https://inspire-mif.github.io/technical-guidelines/metadata/metadata-iso19139/metadata-iso19139.html)
- [The EU's infrastructure for spatial information (INSPIRE) — EUR-Lex](https://eur-lex.europa.eu/EN/legal-content/summary/the-eu-s-infrastructure-for-spatial-information-inspire.html)
- [Describing resources for the INSPIRE directive — GeoNetwork opensource 3.12](https://docs.geonetwork-opensource.org/3.12/user-guide/describing-information/inspire-editing/)

> **Mise à jour (vérifiée le 31/07/2026) — la directive INSPIRE est en cours de révision.** La Commission européenne a adopté le 10 décembre 2025 une proposition législative (initiative « GreenData4All », [COM(2025) 985 final](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A52025PC0985)) visant explicitement à moderniser et simplifier la directive INSPIRE, notamment ses exigences techniques et d'interopérabilité — dont celles qui portent sur les métadonnées. Cette proposition entre dans la procédure législative ordinaire (Parlement/Conseil) et n'est donc pas encore en vigueur : le règlement (CE) 1205/2008 et la liste d'éléments obligatoires ci-dessus restent la référence applicable à ce jour. Mais ils ne doivent pas être considérés comme figés pour un développement à moyen terme — un contrôle de l'état d'avancement de cette révision est recommandé avant de figer un outillage dépendant fortement de ce règlement. Source complémentaire : [Legislative Train Schedule — Revision of the INSPIRE Directive (GreenData4All), Parlement européen](https://www.europarl.europa.eu/legislative-train/theme-a-european-green-deal/file-revision-of-the-inspire-directive)

### 1.4 Édition de la norme ISO 19115-3 : 2018 vs 2023

Une édition plus récente de la norme existe au niveau du corpus ISO : **ISO 19115-3:2023** (« Geographic information — Metadata — Part 3: XML schema implementation for fundamental concepts »), référencée par l'ISO sous le numéro 80874. Elle succède formellement à l'édition 2018 utilisée dans ce document. Vérification faite : le plugin de schéma effectivement embarqué par GeoNetwork (`metadata101/iso19115-3.2018`, désormais intégré au cœur du dépôt `core-geonetwork`) porte encore explicitement le nom et le numéro « 2018 » dans sa documentation et son URL, et aucun plugin « iso19115-3.2023 » n'a été identifié dans les dépôts GeoNetwork consultés. Autrement dit : **l'édition 2023 existe côté norme, mais rien dans les sources consultées n'indique que GeoNetwork l'ait déjà adoptée** — les impératifs décrits au §1.2 restent donc d'actualité pour une instance GeoNetwork standard, à réévaluer si une migration de schéma était annoncée.

Sources :
- [ISO 19115-3:2023 — ISO](https://www.iso.org/standard/80874.html)
- [GitHub — metadata101/iso19115-3.2018](https://github.com/metadata101/iso19115-3.2018)

---

## 2. Comment GeoNetwork traite précisément les tables, leur description, et les attributs et leur description

GeoNetwork ne décrit pas la structure d'une table (liste de colonnes, définitions, domaines de valeurs) dans la fiche ISO 19115 elle-même : cette information relève d'un **standard séparé, ISO 19110** (« méthodologie de catalogage des entités »), matérialisé dans GeoNetwork par un **type de fiche distinct**, le « catalogue d'entités » (feature catalogue), qui peut ensuite être associé à la fiche de données.

Source : [Describing attributes table in a feature Catalog — GeoNetwork opensource 4.0](https://www.geonetwork-opensource.org/manuals/4.0.x/en/user-guide/associating-resources/linking-feature-catalog.html) ; [Iso19110Support — GeoNetwork opensource wiki](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support)

### 2.1 La structure XML du catalogue d'entités (`gfc:` = namespace ISO 19110)

D'après la documentation GeoCat/GeoNetwork Enterprise sur ISO 19110, la hiérarchie est la suivante :

- **`gfc:FC_FeatureCatalogue`** — le catalogue lui-même (un catalogue peut décrire une ou plusieurs tables). Porte un identifiant propre (`uuid`), un `name`/`scope`, un `versionNumber`, une `versionDate`, un `producer` (`gmd:CI_ResponsibleParty`) et une liste de `featureType`.
- **`gfc:FC_FeatureType`** — **une table** (un type d'entité). Champs :
  - `gfc:typeName` : nom de la table.
  - `gfc:definition` : **description de la table**.
  - `gfc:isAbstract` : indicateur booléen.
  - `gfc:carrierOfCharacteristics` : conteneur qui référence les attributs (et associations/opérations) de cette table.
- **`gfc:FC_FeatureAttribute`** — **un attribut** (une colonne), rattaché à un `FC_FeatureType` via `carrierOfCharacteristics`. Champs :
  - `gfc:memberName` : nom de la colonne (ex. `VALUE`).
  - `gfc:definition` : **description de l'attribut**.
  - `gfc:cardinality` : cardinalité (`gco:MultiplicityRange` avec bornes basse/haute).
  - `gfc:valueType` : type de donnée (ex. `INTEGER`).
  - `gfc:valueMeasurementUnit` : unité, le cas échéant.
  - `gfc:listedValue` : liste répétable de valeurs codées.
- **`gfc:FC_ListedValue`** — une valeur codée du domaine de valeurs d'un attribut. Champs : `gfc:label` (libellé), `gfc:code` (code), `gfc:definition` (définition de la valeur).

Autrement dit : **le nom et la description d'une table correspondent à `typeName`/`definition` d'un `FC_FeatureType`**, et **le nom et la description de chaque attribut correspondent à `memberName`/`definition` d'un `FC_FeatureAttribute`** rattaché à ce type. Les listes de valeurs (nomenclatures) sont portées par des `FC_ListedValue` imbriqués dans l'attribut concerné.

Source : [ISO 19110 Feature cataloguing — GeoNetwork Enterprise 2023](https://docs.geocat.net/geonetwork-enterprise/2023/documentation/annexes/standards/iso19110/)

### 2.2 Rattachement du catalogue d'entités à la fiche de données

Le catalogue d'entités est une **fiche à part** dans GeoNetwork, reliée à la fiche de données via le panneau « Associated resources » de l'éditeur. Au niveau du modèle ISO 19115-3, le lien passe par la section « Content Information » (`mdb:contentInfo`), et plus précisément par les éléments `mrc:MD_FeatureCatalogueDescription` / `mrc:featureCatalogueCitation` (espace de noms `mrc:`, ISO 19115-3), qui référencent la citation du catalogue `gfc:FC_FeatureCatalogue`.

**Point de vigilance** : ce mécanisme de rattachement exact (quel identifiant est repris de quel côté) n'a pas pu être vérifié texte à l'appui dans la page ISO 19110 elle-même — celle-ci ne documente que la structure interne du catalogue, pas son raccordement à la fiche ISO 19115. Le nom des éléments (`mrc:MD_FeatureCatalogueDescription`, `mrc:featureCatalogueCitation`) provient de l'index du schéma ISO 19115-3:2018 (cf. §1.2) ; à confirmer par un exemple concret (export XML d'une fiche GeoNetwork existante) avant d'en dépendre pour un développement.

Sources :
- [Describing attributes table in a feature Catalog — GeoNetwork opensource 4.0](https://www.geonetwork-opensource.org/manuals/4.0.x/en/user-guide/associating-resources/linking-feature-catalog.html)
- [Geographic information -- Metadata (iso19115-3.2018) — GeoNetwork opensource 4.4](https://docs.geonetwork-opensource.org/4.4/annexes/standards/iso19115-3.2018/)

### 2.3 Import automatisé déjà prévu par GeoNetwork

GeoNetwork fournit une **feuille de style XSLT native** pour importer un document WFS `DescribeFeatureType` et générer automatiquement une fiche ISO 19110 (un catalogue d'entités) à partir de la structure d'un service WFS. C'est un mécanisme allant « structure de service → XML ISO 19110 », pas « table Postgres → XML » directement, mais il montre qu'un flux de génération semi-automatique est un usage prévu et outillé côté GeoNetwork.

Source : [Iso19110Support — GeoNetwork opensource wiki](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support)

### 2.4 Mise à jour (vérifiée le 31/07/2026) : ISO 19110 marqué comme obsolète par GeoNetwork lui-même

La documentation GeoNetwork actuelle titre elle-même la page consacrée à ce standard : **« Geographic information -- Methodology for feature cataloguing (Deprecated - use ISO19115-3) »**. Cette étiquette apparaît dans le titre de page et le fil d'Ariane, mais **aucune section de la documentation consultée n'en explique la raison ni ne décrit le mécanisme de remplacement** (en particulier, aucune occurrence de `mrc:MD_FeatureCatalogue` ou d'un équivalent « catalogue d'entités intégré nativement à la fiche ISO 19115-3 » n'a été trouvée dans les pages consultées).

Conséquences pratiques pour ce document :
- La structure `gfc:FC_FeatureCatalogue` / `FC_FeatureType` / `FC_FeatureAttribute` / `FC_ListedValue` décrite au §2.1 reste **techniquement implémentée et fonctionnelle** dans la version stable actuelle de GeoNetwork (4.4.12) : l'éditeur ISO 19110 continue d'exister, un modèle est fourni par défaut, et l'import WFS (§2.3) cible toujours ce format.
- L'étiquette « Deprecated » indique une **direction annoncée**, pas un retrait effectif : à ce jour, aucune alternative documentée et publiée ne remplace le catalogue d'entités séparé par un mécanisme intégré à la fiche ISO 19115-3.
- Pour un développement à moyen/long terme, il est recommandé de **surveiller les prochaines versions majeures de GeoNetwork** (au-delà de la branche 4.4) avant d'investir massivement dans l'automatisation du format `gfc:` actuel, tout en le considérant comme fiable pour un usage immédiat.

Source : [Geographic information -- Methodology for feature cataloguing (Deprecated - use ISO19115-3) — GeoNetwork opensource 3.12](https://docs.geonetwork-opensource.org/3.12/annexes/standards/iso19110/)

---

## 3. Exploiter les tables décrivant vos données pour éditer un XML de métadonnées (et inversement)

### 3.1 Constat de départ : ce que le projet a déjà

Le tool `openwebui-tools/postgres-explorer/tool.py` interroge déjà `information_schema.columns` (nom de colonne, type, nullabilité) et `information_schema.tables` (liste des tables), mais **ne récupère aucun commentaire/description** — le README du tool le signale lui-même comme limite à combler « sur le même principe qu'une requête `information_schema` supplémentaire ». Or PostgreSQL dispose nativement d'un mécanisme de description : `COMMENT ON TABLE ...` et `COMMENT ON COLUMN ...`, stockés dans le catalogue système `pg_description` et exposables via les fonctions `obj_description()` (niveau table) et `col_description()` (niveau colonne).

Sources :
- [PostgreSQL Documentation — COMMENT](https://www.postgresql.org/docs/current/sql-comment.html)
- [List PostgreSQL Object Comments with SQL](https://www.postgresscripts.com/post/list-postgresql-object-comments/)

### 3.2 Sens « table → XML »

Si les descriptions de tables et d'attributs vivent (ou sont recopiées) dans Postgres via `COMMENT ON`, la correspondance avec la structure ISO 19110 vue au §2.1 est directe :

| Donnée Postgres | Élément ISO 19110 |
|---|---|
| Nom de la table | `gfc:typeName` |
| `obj_description()` de la table | `gfc:definition` du `FC_FeatureType` |
| Nom de la colonne | `gfc:memberName` |
| `col_description()` de la colonne | `gfc:definition` du `FC_FeatureAttribute` |
| Type de donnée (`data_type`) | `gfc:valueType` |
| Table de nomenclature associée (si elle existe) | `gfc:listedValue` / `FC_ListedValue` |

Deux approches d'implémentation possibles, à ne pas confondre :

1. **Générer le XML directement depuis Postgres** (requête `information_schema` + `col_description()`/`obj_description()`, puis mise en forme XML ou passage par un gabarit). C'est une extension raisonnable et ciblée du tool existant, mais elle reste à écrire spécifiquement — aucun outil « clé en main » de ce type précis n'a été identifié dans les sources consultées.
2. **Passer par un orchestrateur de métadonnées existant**, en particulier **geoflow** (package R), qui prend explicitement en entrée une table d'entités (CSV, Excel, Google Sheet, ou source base de données) et produit un catalogue d'entités ISO 19110, avec publication possible vers GeoNetwork via son module `geonapi`. C'est l'outil le plus proche, dans les sources trouvées, du besoin « table de description → XML ISO 19110 ».

Source : [geoflow — Orchestrate Geospatial (Meta)Data Management Workflows (GitHub, r-geoflow/geoflow)](https://github.com/r-geoflow/geoflow) ; [geoflow — doc/metadata.md](https://github.com/r-geoflow/geoflow/blob/master/doc/metadata.md)

### 3.3 Sens « XML → table »

Pour le sens inverse (récupérer un catalogue ISO 19110 existant — par exemple moissonné depuis un autre GeoNetwork régional ou national — et le reverser dans une table Postgres ou un tableur de suivi), deux logiques sont possibles :

1. **Parser le XML avec une bibliothèque qui connaît le schéma** (évite de réinventer le mapping) : la bibliothèque Python **OWSLib** sait construire un objet `MD_Metadata` à partir d'une fiche ISO 19139, et propose également la lecture d'éléments `FC_FeatureCatalogue`, avec une fonction utilitaire (`get_featurecatalogue_uuid()`) pour retrouver l'UUID du catalogue associé à une fiche de métadonnées.
2. **Parser le XML de façon générique** (XSLT vers CSV, ou script Python avec `lxml`/`ElementTree` parcourant `gfc:FC_FeatureType` puis `gfc:FC_FeatureAttribute`), pour un contrôle total du mapping vers le schéma de table cible.

Source : [OWSLib — geopython/OWSLib (GitHub)](https://github.com/geopython/OWSLib) ; usage de `MD_Metadata`/`FC_FeatureCatalogue` documenté dans le code source du module `owslib.iso`.

### 3.4 Ce qui reste à trancher

Ce point est une piste d'analyse, pas une décision : il reste à choisir (a) si la source de vérité des descriptions doit être Postgres (`COMMENT ON`), un tableur/table dédiée, ou les deux avec synchronisation, et (b) si la génération XML passe par un script interne ciblé ou par un orchestrateur externe (geoflow). Ce choix dépend de la volumétrie de tables à documenter et de qui doit pouvoir éditer les descriptions (cf. `[[project_mcp_dbhub_test]]` et la question plus large de l'architecture d'espaces de travail, non tranchée).

---

## 4. Outils possibles pour passer du XML à la table de description des attributs (et inversement)

| Outil | Sens principal | Ce qu'il fait précisément | Source |
|---|---|---|---|
| **GeoNetwork (natif)** — import WFS DescribeFeatureType | Service WFS → XML ISO 19110 | Feuille de style XSLT fournie en standard pour générer une fiche ISO 19110 à partir de la structure d'un service WFS | [Iso19110Support (wiki)](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support) |
| **GeoNetwork (natif)** — « Apply XSLT » | XML → XML (transformation sur mesure) | Mécanisme intégré à l'éditeur pour appliquer une feuille de style personnalisée ou prédéfinie sur une fiche | [Iso19110Support (wiki)](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support) |
| **geoflow** (R, `r-geoflow/geoflow`, v1.2.1 vérifiée 05/2026) | Table (CSV/Excel/Google Sheet/BD) → XML ISO 19110, avec publication GeoNetwork via `geonapi` | Orchestrateur de métadonnées ISO 19115/19119/19110/19139 ; gère les entités sous forme de table, une ligne = une entité ; activement maintenu (dernière release CRAN 1.0.0 le 09/10/2025, puis 1.2.1 sur GitHub en 05/2026) | [GitHub r-geoflow/geoflow](https://github.com/r-geoflow/geoflow) ; [CRAN geoflow](https://cran.r-project.org/package=geoflow) |
| **pygeometa** (Python, `geopython/pygeometa`, v0.21.1 vérifiée 04/2026) | Fichier YAML (Metadata Control File) → XML ISO 19139 | Génère des fiches de métadonnées ISO 19139 (et autres schémas) depuis un YAML structuré ; **le catalogue des schémas supportés (iso19139, iso19139-2, iso19139-hnap, dcat, ogcapi-records, schema.org, stac, wmo-cmp/wcmp2/wigos, csvw, openaire, local) ne comprend pas ISO 19110 — confirmé au 31/07/2026, pas seulement supposé** | [GitHub geopython/pygeometa — répertoire des schémas](https://github.com/geopython/pygeometa/tree/master/pygeometa/schemas) |
| **OWSLib** (Python, `geopython/OWSLib`, v0.36.0 vérifiée 06/2026) | XML ISO 19139/19110 → objets Python | Parse `MD_Metadata` et `FC_FeatureCatalogue` ; utilitaire pour retrouver l'UUID du catalogue lié à une fiche ; activement maintenu | [GitHub geopython/OWSLib](https://github.com/geopython/OWSLib) |
| **Script sur mesure** (Python `lxml`/`ElementTree`, ou XSLT) | XML ↔ CSV/table, dans les deux sens | Parcours explicite de `FC_FeatureType`/`FC_FeatureAttribute`/`FC_ListedValue` ; contrôle total du mapping, à écrire spécifiquement | — (approche générique, pas un outil packagé) |
| **PostgreSQL natif** (`COMMENT ON`, `col_description()`, `obj_description()`) | Table ↔ description (source, côté base) | Stocke/lit les descriptions de tables et colonnes directement dans le catalogue système Postgres, sans dépendance externe | [PostgreSQL Doc — COMMENT](https://www.postgresql.org/docs/current/sql-comment.html) |
| **PLUME** (QGIS + extension PostgreSQL `PlumePg`, `MTES-MCT/metadata-postgresql`, v1.2.1 vérifiée 07/2026) | Table Postgres ↔ fiche de métadonnées, mais **format RDF/GeoDCAT-AP**, pas ISO 19139/gfc | Plugin QGIS de saisie de métadonnées pour tables/vues PostgreSQL ; stocke en JSON-LD dans les commentaires PostgreSQL, profil GeoDCAT-AP 2.0/DCAT v2 (vocabulaire `geodcat:` confirmé dans la doc v1.2.1) — **toujours aucune fonction d'export ISO 19139/gfc identifiée à ce jour ; nécessite une conversion pour alimenter un GeoNetwork en ISO 19115/19110** | [GitHub MTES-MCT/metadata-postgresql](https://github.com/MTES-MCT/metadata-postgresql) ; [Documentation Plume v1.2.1 — Métadonnées communes](https://mtes-mct.github.io/metadata-postgresql/usage/metadonnees_communes.html) |
| **GeoNetwork API** | Publication automatisée | API REST pour créer/mettre à jour des fiches (dont des catalogues ISO 19110) une fois le XML généré, en complément d'un des outils ci-dessus ; version GeoNetwork stable vérifiée : 4.4.12 | [GeoNetwork opensource — API](https://docs.geonetwork-opensource.org/4.4/api/) ; [News — GeoNetwork opensource](https://geonetwork-opensource.org/news.html) |

---

## Sources consultées

- [Describing information — GeoNetwork opensource 4.2](https://docs.geonetwork-opensource.org/4.2/user-guide/describing-information/)
- [Geographic information -- Metadata (iso19115-3.2018) — GeoNetwork opensource 4.4](https://docs.geonetwork-opensource.org/4.4/annexes/standards/iso19115-3.2018/)
- [ISO 19110 Feature cataloguing — GeoNetwork Enterprise 2023](https://docs.geocat.net/geonetwork-enterprise/2023/documentation/annexes/standards/iso19110/)
- [Describing attributes table in a feature Catalog — GeoNetwork opensource 4.0](https://www.geonetwork-opensource.org/manuals/4.0.x/en/user-guide/associating-resources/linking-feature-catalog.html)
- [Iso19110Support — GeoNetwork opensource wiki (Trac)](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support)
- [Describing resources for the INSPIRE directive — GeoNetwork opensource 3.12](https://docs.geonetwork-opensource.org/3.12/user-guide/describing-information/inspire-editing/)
- [Technical Guidance for the implementation of INSPIRE dataset and service metadata based on ISO/TS 19139:2007 — INSPIRE-MIF](https://inspire-mif.github.io/technical-guidelines/metadata/metadata-iso19139/metadata-iso19139.html)
- [The EU's infrastructure for spatial information (INSPIRE) — EUR-Lex](https://eur-lex.europa.eu/EN/legal-content/summary/the-eu-s-infrastructure-for-spatial-information-inspire.html)
- [How to Create and Publish Geospatial Metadata — FAO, 2021 (PDF)](https://openknowledge.fao.org/server/api/core/bitstreams/5cc37bd1-1185-4e24-b70d-266ce96813f4/content)
- [ISO 19115 Metadata Elements Content — NAL/USDA GeoNetwork](https://geodata.nal.usda.gov/geonetwork/doc/geodata/NAL_UserGuide/19115_content/19115_content_main.html)
- [GitHub — r-geoflow/geoflow](https://github.com/r-geoflow/geoflow)
- [geoflow — doc/metadata.md](https://github.com/r-geoflow/geoflow/blob/master/doc/metadata.md)
- [GitHub — geopython/pygeometa](https://github.com/geopython/pygeometa)
- [GitHub — geopython/OWSLib](https://github.com/geopython/OWSLib)
- [PostgreSQL Documentation — COMMENT](https://www.postgresql.org/docs/current/sql-comment.html)
- [List PostgreSQL Object Comments with SQL](https://www.postgresscripts.com/post/list-postgresql-object-comments/)
- [GitHub — MTES-MCT/metadata-postgresql (PLUME)](https://github.com/MTES-MCT/metadata-postgresql)
- [Plume : métadonnées d'un patrimoine PostgreSQL — fiche SPOTE](https://spote.developpement-durable.gouv.fr/offre/plume-metadonnees-d-un-patrimoine-postgresql)
- [Documentation Plume v1.2.1 — Métadonnées communes](https://mtes-mct.github.io/metadata-postgresql/usage/metadonnees_communes.html)
- [GeoNetwork opensource — API](https://docs.geonetwork-opensource.org/4.4/api/)

### Sources ajoutées lors de la vérification du 31/07/2026

- [Geographic information -- Methodology for feature cataloguing (Deprecated - use ISO19115-3) — GeoNetwork opensource 3.12](https://docs.geonetwork-opensource.org/3.12/annexes/standards/iso19110/)
- [ISO 19115-3:2023 — ISO](https://www.iso.org/standard/80874.html)
- [GitHub — metadata101/iso19115-3.2018](https://github.com/metadata101/iso19115-3.2018)
- [COM(2025) 985 final — proposition de révision de la directive INSPIRE (GreenData4All) — EUR-Lex](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A52025PC0985)
- [Legislative Train Schedule — Revision of the INSPIRE Directive (GreenData4All), Parlement européen](https://www.europarl.europa.eu/legislative-train/theme-a-european-green-deal/file-revision-of-the-inspire-directive)
- [News — GeoNetwork opensource (historique des versions)](https://geonetwork-opensource.org/news.html)
- [GitHub geopython/pygeometa — répertoire des schémas supportés](https://github.com/geopython/pygeometa/tree/master/pygeometa/schemas)
- [CRAN — package geoflow](https://cran.r-project.org/package=geoflow)
