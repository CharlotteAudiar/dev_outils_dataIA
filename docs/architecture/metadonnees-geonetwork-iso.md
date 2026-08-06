# Métadonnées géographiques, GeoNetwork et normes ISO — état des lieux et pistes d'outillage

Document d'étude (non tranché) — rattaché au cas d'usage « base de données non documentée » évoqué dans `docs/architecture/decisions.md` (« bd pas encore documentée, étude métadonnées geonetwork à étudier »).

**Objet** : établir ce que GeoNetwork exige comme métadonnées, comment il représente précisément les tables et leurs attributs, et par quels moyens alimenter ces fiches depuis les tables de description du projet (ou l'inverse).

**Méthode et fiabilité des sources** : toutes les affirmations sont sourcées, avec une préférence pour les sources primaires (schémas XSD officiels ISO/TC 211, code source des outils, textes réglementaires) plutôt que pour la documentation de seconde main. Quand une source ne permet de vérifier qu'une partie d'un point, la limite est signalée explicitement à cet endroit plutôt que comblée par déduction. Les versions d'outils et l'état des normes ont été vérifiés fin juillet et début août 2026 ; les points susceptibles d'évoluer (révision INSPIRE en cours, statut « deprecated » d'ISO 19110, édition 2023 d'ISO 19115-3) sont signalés comme tels aux sections concernées.

---

## 1. Ce que GeoNetwork accepte comme métadonnées (normes ISO)

### 1.1 Les standards en présence, et l'édition réellement utilisée

GeoNetwork n'impose pas un schéma unique : le choix du standard dépend du type de ressource à décrire.

- **Dublin Core** : portails open data, publications, rapports.
- **ISO 19115 / 119 / 139**, dans le profil **ISO 19115-3:2018** pour les versions récentes : ressources spatiales (jeux de données, services, cartes).
- **ISO 19110** : tables d'attributs, sous forme de « catalogue d'entités » (voir §2).

Une **édition plus récente de la norme existe côté ISO — ISO 19115-3:2023** (référence ISO 80874), qui succède formellement à l'édition 2018. Mais le plugin de schéma effectivement embarqué par GeoNetwork (`metadata101/iso19115-3.2018`, désormais intégré au cœur du dépôt `core-geonetwork`) porte toujours le nom et le numéro « 2018 », et aucun plugin « iso19115-3.2023 » n'a été identifié dans les dépôts consultés. La version stable de GeoNetwork vérifiée est la 4.4.12. Autrement dit : **l'édition 2023 existe dans le corpus normatif, mais rien n'indique que GeoNetwork l'ait adoptée** — les exigences décrites ci-dessous restent celles d'une instance GeoNetwork standard, à réévaluer si une migration de schéma était annoncée.

Sources : [Describing information — GeoNetwork 4.2](https://docs.geonetwork-opensource.org/4.2/user-guide/describing-information/) ; [ISO 19115-3:2023 — ISO](https://www.iso.org/standard/80874.html) ; [GitHub metadata101/iso19115-3.2018](https://github.com/metadata101/iso19115-3.2018) ; [News — GeoNetwork opensource (versions)](https://geonetwork-opensource.org/news.html)

### 1.2 Le socle d'éléments obligatoires

Dans l'éditeur ISO 19115-3 de GeoNetwork, la vue « Simple » regroupe les champs à renseigner pour qu'une fiche soit valide et publiable : identifiant de métadonnées, contact, type de ressource, date, titre, résumé, catégorie thématique, point de contact de la métadonnée (organisme ou personne). Plusieurs guides utilisateurs convergents (guide FAO 2021, guide NAL/USDA) retiennent comme socle minimal : **titre, date de création ou publication, résumé, langue, catégorie thématique, échelle, fréquence de mise à jour, point de contact**.

Cette liste a une limite de fiabilité : la page de référence GeoNetwork sur ISO 19115-3:2018 est un index technique auto-généré (tous les éléments du schéma classés par espace de noms), **sans colonne « obligatoire/optionnel »** exploitable. La liste ci-dessus est donc une synthèse de guides, pas une lecture directe du schéma.

Cette limite est levée par une source primaire : l'ISO/TC 211 publie lui-même un **exemple XML minimal valide** pour le module `mdb` (Metadata Base, la brique racine d'ISO 19115-3), commenté pour expliquer *pourquoi* chaque élément y figure. C'est ce même espace de noms `mdb` 1.0 qu'utilise le plugin GeoNetwork — l'exemple est donc directement transposable.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mdb:MD_Metadata xmlns:mdb="http://standards.iso.org/iso/19115/-3/mdb/1.0"
    xmlns:cit="http://standards.iso.org/iso/19115/-3/cit/1.0"
    xmlns:mri="http://standards.iso.org/iso/19115/-3/mri/1.0"
    xmlns:gex="http://standards.iso.org/iso/19115/-3/gex/1.0"
    xmlns:lan="http://standards.iso.org/iso/19115/-3/lan/1.0"
    xmlns:gco="http://standards.iso.org/iso/19115/-3/gco/1.0">

    <!-- Point de contact de la métadonnée (obligatoire) -->
    <mdb:contact>
        <cit:CI_Responsibility>
            <cit:role>
                <cit:CI_RoleCode codeListValue="custodian">custodian</cit:CI_RoleCode>
            </cit:role>
            <cit:party>
                <cit:CI_Organisation>
                    <!-- nom (ou logo) obligatoire, règle Schematron -->
                    <cit:name><gco:CharacterString>Nom de l'organisme</gco:CharacterString></cit:name>
                </cit:CI_Organisation>
            </cit:party>
        </cit:CI_Responsibility>
    </mdb:contact>

    <!-- Date de la métadonnée (obligatoire) -->
    <mdb:dateInfo>
        <cit:CI_Date>
            <cit:date><gco:DateTime>2026-08-05T12:00:00</gco:DateTime></cit:date>
            <cit:dateType><cit:CI_DateTypeCode codeListValue="Creation"/></cit:dateType>
        </cit:CI_Date>
    </mdb:dateInfo>

    <mdb:identificationInfo>
        <mri:MD_DataIdentification>
            <!-- Titre + date de la ressource (obligatoires) -->
            <mri:citation>
                <cit:CI_Citation>
                    <cit:title><gco:CharacterString>Titre de la ressource</gco:CharacterString></cit:title>
                    <cit:date>
                        <!-- date de type "creation" obligatoire, règle Schematron -->
                        <cit:CI_Date>
                            <cit:date><gco:DateTime>2020-01-01T12:00:00</gco:DateTime></cit:date>
                            <cit:dateType><cit:CI_DateTypeCode codeListValue="publication"/></cit:dateType>
                        </cit:CI_Date>
                    </cit:date>
                </cit:CI_Citation>
            </mri:citation>

            <!-- Résumé (obligatoire) -->
            <mri:abstract><gco:CharacterString>Résumé de la ressource.</gco:CharacterString></mri:abstract>

            <!-- Catégorie thématique : obligatoire par défaut (scope = "dataset"), règle Schematron -->
            <mri:topicCategory><mri:MD_TopicCategoryCode>boundaries</mri:MD_TopicCategoryCode></mri:topicCategory>

            <!-- Emprise géographique : obligatoire par défaut (scope = "dataset"), règle Schematron -->
            <mri:extent>
                <gex:EX_Extent>
                    <gex:geographicElement>
                        <gex:EX_GeographicBoundingBox>
                            <gex:westBoundLongitude><gco:Decimal>-1.9</gco:Decimal></gex:westBoundLongitude>
                            <gex:eastBoundLongitude><gco:Decimal>-1.4</gco:Decimal></gex:eastBoundLongitude>
                            <gex:southBoundLatitude><gco:Decimal>48.0</gco:Decimal></gex:southBoundLatitude>
                            <gex:northBoundLatitude><gco:Decimal>48.3</gco:Decimal></gex:northBoundLatitude>
                        </gex:EX_GeographicBoundingBox>
                    </gex:geographicElement>
                </gex:EX_Extent>
            </mri:extent>

            <!-- Langue par défaut : obligatoire si la ressource contient du texte -->
            <mri:defaultLocale>
                <lan:PT_Locale>
                    <lan:language><lan:LanguageCode codeListValue="fra">French</lan:LanguageCode></lan:language>
                    <lan:characterEncoding><lan:MD_CharacterSetCode codeListValue="utf8">UTF-8</lan:MD_CharacterSetCode></lan:characterEncoding>
                </lan:PT_Locale>
            </mri:defaultLocale>
        </mri:MD_DataIdentification>
    </mdb:identificationInfo>
</mdb:MD_Metadata>
```

*(Squelette simplifié et traduit depuis l'exemple officiel ; les valeurs de codelists — `custodian`, `boundaries`, `fra` — sont des exemples à remplacer.)*

Ce squelette confirme et affine la liste des guides : le contact, la date de métadonnée, le titre, la date de citation, le résumé, la catégorie thématique et l'emprise géographique ne sont pas des « bonnes pratiques » mais des contraintes **imposées par des règles Schematron** du schéma officiel. Il apporte aussi une nuance que la documentation GeoNetwork ne donne pas : la catégorie thématique et l'emprise ne deviennent obligatoires que si la portée de la fiche (`MD_MetadataScope`) n'est pas précisée, car elle vaut alors « dataset » par défaut.

Sources : [AppendixD.1MinimalExample.xml — exemple officiel ISO/TC 211, module mdb 1.0](https://raw.githubusercontent.com/ISO-TC211/XML/master/standards.iso.org.annotated/iso/19115/-3/mdb/1.0/AppendixD.1MinimalExample.xml) ; [Metadata Base (MDB) 1.0 — page d'accès](https://meta.geo.census.gov/data/existing/XML-master/standards.iso.org/19115/-3/mdb/1.0/index.html) ; [How to Create and Publish Geospatial Metadata — FAO, 2021](https://openknowledge.fao.org/server/api/core/bitstreams/5cc37bd1-1185-4e24-b70d-266ce96813f4/content) ; [ISO 19115 Metadata Elements Content — NAL/USDA](https://geodata.nal.usda.gov/geonetwork/doc/geodata/NAL_UserGuide/19115_content/19115_content_main.html) ; [Metadata (iso19115-3.2018) — GeoNetwork 4.4](https://docs.geonetwork-opensource.org/4.4/annexes/standards/iso19115-3.2018/)

### 1.3 Si les fiches sont publiées sur un portail soumis à INSPIRE

Pour une diffusion sur un géoportail relevant de la directive INSPIRE (2007/2/CE), le règlement d'exécution **(CE) n° 1205/2008** impose un jeu d'éléments supplémentaires. Les « Technical Guidelines » qui en détaillent l'implémentation en ISO 19139 listent notamment :

| Élément | Élément XML (ISO 19139) | Cardinalité | Référence TG |
|---|---|---|---|
| Langue de la métadonnée | `gmd:language` | 1 | C.5 |
| Point de contact de la métadonnée | `gmd:contact` | 1..* | C.6 |
| Date de la métadonnée | `gmd:dateStamp` | 1 | C.7 |
| Titre de la ressource | `gmd:CI_Citation/title` | 1 | C.8 |
| Résumé de la ressource | `gmd:abstract` | 1 | C.9 |
| Organisme responsable de la ressource | — | 1..* | C.10 |
| Référence temporelle (publication/création/révision) | — | 1..* | C.11 |
| Limitations d'accès public | `gmd:resourceConstraints` | 1..* | C.17 |
| Conditions d'accès et d'utilisation | — | 1..* | C.18 |

D'autres éléments (emprise géographique, conformité/qualité, type de ressource, identifiant unique, mots-clés, résolution spatiale, langue de la ressource, catégorie thématique, système de référence) sont également couverts, mais le corps détaillé de ces sections n'a pas pu être vérifié intégralement (page très longue, lecture partielle). Pour une conformité stricte, se référer au texte du règlement et à l'annexe C complète.

**Ce cadre réglementaire n'est pas figé.** La Commission européenne a adopté le 10 décembre 2025 une proposition législative (initiative « GreenData4All », COM(2025) 985 final) visant explicitement à moderniser et simplifier la directive INSPIRE, notamment ses exigences techniques et d'interopérabilité — dont celles portant sur les métadonnées. Cette proposition entre dans la procédure législative ordinaire et n'est pas en vigueur : le règlement 1205/2008 et la liste ci-dessus restent la référence applicable. Mais un contrôle de l'avancement de cette révision est recommandé avant de figer un outillage qui en dépendrait fortement.

Sources : [Technical Guidance for INSPIRE dataset and service metadata (ISO/TS 19139) — INSPIRE-MIF](https://inspire-mif.github.io/technical-guidelines/metadata/metadata-iso19139/metadata-iso19139.html) ; [INSPIRE — EUR-Lex (synthèse)](https://eur-lex.europa.eu/EN/legal-content/summary/the-eu-s-infrastructure-for-spatial-information-inspire.html) ; [COM(2025) 985 final — EUR-Lex](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A52025PC0985) ; [Legislative Train — Revision of the INSPIRE Directive, Parlement européen](https://www.europarl.europa.eu/legislative-train/theme-a-european-green-deal/file-revision-of-the-inspire-directive) ; [Describing resources for the INSPIRE directive — GeoNetwork 3.12](https://docs.geonetwork-opensource.org/3.12/user-guide/describing-information/inspire-editing/)

---

## 2. Comment sont décrites les tables, leurs attributs et leurs valeurs codées (ISO 19110)

### 2.1 Un standard séparé — et un statut à connaître avant d'investir

GeoNetwork ne décrit pas la structure d'une table (colonnes, définitions, domaines de valeurs) dans la fiche ISO 19115 : cette information relève d'un **standard distinct, ISO 19110** (« méthodologie de catalogage des entités »), matérialisé par un **type de fiche à part**, le « catalogue d'entités » (feature catalogue), ensuite associé à la fiche de données.

Deux réserves à poser d'emblée, car elles conditionnent l'ampleur de l'investissement à consentir sur ce format :

- **GeoNetwork étiquette lui-même ce standard comme obsolète.** Sa documentation titre la page concernée « Geographic information -- Methodology for feature cataloguing (**Deprecated - use ISO19115-3**) ». Cette étiquette apparaît dans le titre et le fil d'Ariane, mais **aucune section de la documentation consultée n'en explique la raison ni ne décrit le mécanisme de remplacement** — en particulier, aucun équivalent « catalogue d'entités intégré nativement à la fiche ISO 19115-3 » n'a été trouvé.
- **Le schéma XML utilisé est lui aussi une version historique.** Le schéma `gfc` 1.1 décrit ci-dessous est signalé « Historical » (legacy) par l'ISO ; la version « Current » du catalogue d'entités est `fcc`/`gfc` v2.2.0. C'est bien la version historique que GeoNetwork implémente aujourd'hui ; la v2.2.0 n'a pas été étudiée ici car elle n'est pas utilisable en l'état dans GeoNetwork.

Malgré ces deux réserves, le format reste **techniquement implémenté et pleinement fonctionnel** dans la version stable actuelle (4.4.12) : l'éditeur ISO 19110 existe, un modèle est fourni par défaut, et l'import WFS natif (§2.4) cible toujours ce format. L'étiquette « Deprecated » indique une direction annoncée, pas un retrait effectif, et aucune alternative publiée ne la remplace à ce jour. Recommandation pratique : le considérer comme fiable pour un usage immédiat, mais **surveiller les versions majeures de GeoNetwork au-delà de la branche 4.4** avant d'investir massivement dans l'automatisation du format `gfc:`.

Sources : [Describing attributes table in a feature Catalog — GeoNetwork 4.0](https://www.geonetwork-opensource.org/manuals/4.0.x/en/user-guide/associating-resources/linking-feature-catalog.html) ; [Methodology for feature cataloguing (Deprecated - use ISO19115-3) — GeoNetwork 3.12](https://docs.geonetwork-opensource.org/3.12/annexes/standards/iso19110/) ; [ISO/TC 211 Implementation Schemas — ISO 19110](https://schemas.isotc211.org/19110/)

### 2.2 La structure XML du catalogue d'entités (`gfc:`)

Structure vérifiée directement dans le schéma XSD officiel (`featureCatalogue.xsd`, ISO/TC 211), et non seulement dans la documentation GeoNetwork. Les champs marqués (O) sont optionnels.

- **`gfc:FC_FeatureCatalogue`** — le catalogue lui-même, qui peut décrire une ou plusieurs tables. Porte un `uuid` propre, un `name`/`scope`, un `versionNumber`, une `versionDate`, un `producer` (partie responsable), et la liste des `featureType`.
- **`gfc:FC_FeatureType`** — **une table** (un type d'entité) :
  - `typeName` : nom de la table (identifiant unique dans le catalogue) ;
  - `definition` (O) : **description de la table** ;
  - `isAbstract` : booléen ;
  - `code` (O), `aliases` (O), `designation` (O), `definitionReference` (O), `constrainedBy` (O) ;
  - `carrierOfCharacteristics` : conteneur des attributs (et associations/opérations).
- **`gfc:FC_FeatureAttribute`** — **un attribut** (une colonne), rattaché à un `FC_FeatureType` via `carrierOfCharacteristics` :
  - `memberName` : nom de la colonne ;
  - `definition` (O) : **description de l'attribut** ;
  - `cardinality` : cardinalité ;
  - `valueType` (O) : type de donnée ;
  - `code` (O), `valueMeasurementUnit` (O), `designation` (O), `definitionReference` (O) ;
  - `listedValue` (O, répétable) : les valeurs codées admissibles. Le schéma précise que si cet élément est présent, il **restreint** le domaine du `valueType` ; s'il est absent, il n'y a pas de restriction.
- **`gfc:FC_ListedValue`** — **une valeur codée** du domaine d'un attribut. Exactement 5 éléments, en séquence fermée :
  - `label` : **seul champ obligatoire** — « libellé descriptif qui identifie de façon unique cette valeur » ;
  - `code` (O) : code numérique ou alphanumérique identifiant la valeur ;
  - `definition` (O) : définition de la valeur en langage naturel ;
  - `designation` (O) : voir la précision ci-dessous ;
  - `definitionReference` (O) : renvoi vers la source de la définition (`FC_DefinitionSource`, qui est une citation complète — donc potentiellement une URL/URI, une référence documentaire, etc.).

En synthèse : **nom et description d'une table** = `typeName`/`definition` d'un `FC_FeatureType` ; **nom et description d'un attribut** = `memberName`/`definition` d'un `FC_FeatureAttribute` ; **nomenclatures** = `FC_ListedValue` imbriqués dans l'attribut concerné.

**Sur le champ `designation`** — le XSD ne porte **aucune annotation de documentation** sur cet élément pour `FC_ListedValue` précisément (contrairement à `label`, `code`, `definition` et `definitionReference`, tous documentés) : son sens exact n'est donc pas garanti par une source directe pour ce cas. En revanche, le même champ est documenté de façon identique ailleurs dans le même fichier — sur `FC_FeatureType` (« designation of the feature type in a natural language »), sur `AbstractFC_PropertyType` dont hérite `FC_FeatureAttribute`, et sur `FC_InheritanceRelation`. Par analogie, `designation` désigne **un nom en langage naturel, distinct du `label`** : là où `label` porte une contrainte d'unicité (c'est un identifiant lisible), `designation` en est dépourvu et correspond plutôt à un nom d'usage, un synonyme ou une formulation plus naturelle. Cette lecture est une inférence par analogie ; à confirmer en ouvrant un enregistrement ISO 19110 dans l'éditeur GeoNetwork pour voir comment le champ y est libellé.

**Le schéma n'est pas extensible.** `FC_ListedValue_Type` est déclaré en `<sequence>` strict, **sans point d'extension générique** (pas de `xs:any`, pas d'attributs libres) : impossible de glisser un élément arbitraire et d'obtenir un XML valide. Tout ce qui dépasse ces cinq champs n'a pas sa place dans le XML — ce qui a des conséquences directes sur la conception des tables de nomenclature, traitées au §3.4.

Sources : [featureCatalogue.xsd — XSD officiel ISO/TC 211, gfc 1.1](https://raw.githubusercontent.com/ISO-TC211/XML/master/standards.iso.org.annotated/iso/19110/gfc/1.1/featureCatalogue.xsd) ; [ISO 19110 Feature cataloguing — GeoNetwork Enterprise 2023](https://docs.geocat.net/geonetwork-enterprise/2023/documentation/annexes/standards/iso19110/)

### 2.3 Rattachement du catalogue à la fiche de données

Le catalogue d'entités est une **fiche distincte**, reliée à la fiche de données via le panneau « Associated resources » de l'éditeur. Au niveau du modèle ISO 19115-3, le lien passe par la section « Content Information » (`mdb:contentInfo`), via les éléments `mrc:MD_FeatureCatalogueDescription` / `mrc:featureCatalogueCitation`, qui référencent la citation du `gfc:FC_FeatureCatalogue`.

**Limite de vérification** : le mécanisme exact (quel identifiant est repris de quel côté) n'a pas pu être confirmé texte à l'appui — la documentation ISO 19110 décrit la structure interne du catalogue, pas son raccordement à la fiche ISO 19115. Les noms d'éléments cités proviennent de l'index du schéma ISO 19115-3:2018. À confirmer par un export XML d'une fiche GeoNetwork réelle avant d'en dépendre pour un développement.

Sources : [Describing attributes table in a feature Catalog — GeoNetwork 4.0](https://www.geonetwork-opensource.org/manuals/4.0.x/en/user-guide/associating-resources/linking-feature-catalog.html) ; [Metadata (iso19115-3.2018) — GeoNetwork 4.4](https://docs.geonetwork-opensource.org/4.4/annexes/standards/iso19115-3.2018/)

### 2.4 Un import automatisé déjà fourni par GeoNetwork

GeoNetwork embarque une **feuille de style XSLT** pour importer un document WFS `DescribeFeatureType` et générer une fiche ISO 19110 à partir de la structure d'un service WFS. Le mécanisme va « structure de service → XML ISO 19110 », pas « table Postgres → XML », mais il établit qu'un flux de génération semi-automatique est un usage prévu et outillé.

Le fichier a été localisé et vérifié dans le code source : `OGCWFSDescribeFeatureType-to-ISO19110.xsl`, qui inclut la logique de transformation `OGCWFS-to-ISO19110.xsl` (dossier `web/src/main/webapp/xsl/conversion/import/`). À noter que la page wiki Trac souvent citée à ce sujet est une fiche de proposition de fonctionnalité de 2009 : elle atteste que la fonctionnalité a été actée, mais ne donne pas accès au fichier lui-même.

Sources : [OGCWFSDescribeFeatureType-to-ISO19110.xsl — core-geonetwork (fichier source)](https://raw.githubusercontent.com/geonetwork/core-geonetwork/4.0.x/web/src/main/webapp/xsl/conversion/import/OGCWFSDescribeFeatureType-to-ISO19110.xsl) ; [Iso19110Support — wiki GeoNetwork (proposition 2009)](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support)

---

## 3. Alimenter le XML depuis les tables de description (et inversement)

### 3.1 Point de départ : ce dont le projet dispose

Le tool `openwebui-tools/postgres-explorer/tool.py` interroge déjà `information_schema.tables` (liste des tables) et `information_schema.columns` (nom, type, nullabilité), mais **ne récupère aucune description** — son README signale lui-même cette limite, à combler « sur le même principe qu'une requête `information_schema` supplémentaire ». Il n'introspecte pas non plus les clés étrangères.

PostgreSQL dispose pourtant nativement d'un mécanisme de description : `COMMENT ON TABLE` et `COMMENT ON COLUMN`, stockés dans le catalogue système `pg_description` et lisibles via `obj_description()` (table) et `col_description()` (colonne).

Contexte à garder en tête pour tout ce qui suit : **la base concernée n'est pas documentée** et ne comporte pas de tables de nomenclature préexistantes. C'est le point de départ du cas d'usage, pas un détail — il détermine ce qui peut être automatisé et ce qui relève d'une saisie humaine.

Sources : [PostgreSQL — COMMENT](https://www.postgresql.org/docs/current/sql-comment.html) ; [List PostgreSQL Object Comments with SQL](https://www.postgresscripts.com/post/list-postgresql-object-comments/)

### 3.2 Les trois niveaux à documenter, et où ils vivent

ISO 19110 impose une structure à trois niveaux — description de la table, description des attributs, modalités des attributs — quel que soit l'outil employé. Mais chaque outil matérialise ces niveaux différemment.

**Correspondance de principe entre Postgres et ISO 19110 :**

| Donnée Postgres | Élément ISO 19110 |
|---|---|
| Nom de la table | `gfc:typeName` |
| `obj_description()` de la table | `gfc:definition` du `FC_FeatureType` |
| Nom de la colonne | `gfc:memberName` |
| `col_description()` de la colonne | `gfc:definition` du `FC_FeatureAttribute` |
| Type de donnée (`data_type`) | `gfc:valueType` |
| Table de nomenclature associée | `gfc:listedValue` / `FC_ListedValue` |

**Côté geoflow : trois objets tabulaires distincts.** Contrairement à ce que suggère la présentation habituelle (« une table d'entités »), générer un catalogue ISO 19110 complet suppose au minimum trois objets, chacun avec sa structure de colonnes propre. Vérifié dans le code source R du package, pas seulement dans sa documentation :

- **`entities`** : une ligne par jeu de données/table, pour les métadonnées ISO 19115 (titre, résumé, contact, dates — cf. §1.2).
- **`dictionary`** : **une seule table à plat, une ligne par attribut** (et non deux tables « types » et « attributs »). La classe `geoflow_featuretype` ne porte qu'un identifiant et une liste de membres ; c'est `geoflow_featuremember` qui porte le contenu, et sa méthode `asDataFrame()` fixe les colonnes attendues : `FeatureType` (identifiant de la table, répété sur chaque ligne d'attribut — c'est ce qui les regroupe), `MemberCode`, `MemberName`, `MemberType`, `MinOccurs`, `MaxOccurs`, `Definition`, `DefinitionSource`, `MeasurementUnit`, `RegisterId`, `RegisterScript`. **Aucune colonne n'y porte la description de la table elle-même** : reste non confirmé si et comment cette description est reprise depuis `entities` lors de la génération XML — à vérifier avant de s'appuyer dessus.
- **`registers`** (un par nomenclature) : c'est ici, et seulement ici, que vivent les **modalités d'un attribut**, futurs `FC_ListedValue`. La classe `geoflow_register` impose une structure stricte, contrôlée par une fonction `check()` : exactement les 4 colonnes `code`, `uri`, `label`, `definition`, sous peine d'erreur. Chaque ligne de `dictionary` désigne son registre via `RegisterId`.

**Côté Postgres : deux niveaux gratuits, un à construire.** La répartition n'est pas symétrique à geoflow :

- **Table et attributs** : aucune table dédiée nécessaire. Une fois les `COMMENT ON` renseignés, tout est interrogeable via `information_schema` + `obj_description()`/`col_description()` — ce sont des vues du catalogue système. La contrepartie est que remplir ces commentaires reste, ici, un travail de documentation manuelle puisque rien n'existe encore.
- **Valeurs codées** : **une table dédiée est nécessaire dans tous les cas**, Postgres n'ayant pas d'équivalent natif à un registre `code`/`label`/`definition`. Dans une base déjà normalisée, les tables de nomenclature existantes joueraient ce rôle, et le lien attribut → nomenclature pourrait être découvert automatiquement par introspection des clés étrangères (`information_schema.key_column_usage`) — un avantage sur geoflow, où ce lien est saisi à la main. **Ce n'est pas le cas ici** : les modalités ne sont nulle part dans la base, ni en table de référence, ni en `ENUM` documenté (et le catalogue `pg_enum` ne stocke qu'une étiquette par valeur, sans champ de définition — insuffisant pour `FC_ListedValue`). L'apport de Postgres se limite donc à **amorcer** le travail : un `SELECT DISTINCT` donne les codes réellement présents dans les données, mais libellés et définitions restent à saisir par quelqu'un qui connaît la donnée. Ce n'est pas un désavantage face à geoflow : ses `registers` sont eux aussi renseignés à part, jamais découverts automatiquement.

Sources : [geoflow — doc/metadata.md](https://github.com/r-geoflow/geoflow/blob/master/doc/metadata.md) ; [geoflow_dictionary.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_dictionary.R) ; [geoflow_featuretype.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_featuretype.R) ; [geoflow_featuremember.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_featuremember.R) ; [geoflow_register.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_register.R) ; [PostgreSQL — key_column_usage](https://www.postgresql.org/docs/current/infoschema-key-column-usage.html) ; [PostgreSQL — Enumerated Types](https://www.postgresql.org/docs/current/datatype-enum.html)

### 3.3 Générer le XML : deux voies

**1. Directement depuis Postgres.** La mise en forme XML n'exige pas nécessairement un outil externe : PostgreSQL fournit nativement `xmlelement`, `xmlattributes`, `xmlagg`, `xmlforest`, `xmlconcat`, qui permettent de construire du XML bien formé avec espaces de noms depuis une requête SQL. Deux limites concrètes :

- Les fonctions de mapping « toutes faites » (`table_to_xml`, `query_to_xml`) ne produisent qu'un XML générique `<table><row><colonne>valeur</colonne></row></table>` — **elles ne savent pas produire la structure imbriquée `FC_FeatureType` > `FC_FeatureAttribute` > `FC_ListedValue`**. Il faut assembler les éléments à la main et imbriquer les niveaux avec `xmlagg` dans des sous-requêtes, ce qui revient à écrire un gabarit — en SQL plutôt que dans un autre langage.
- Ces fonctions supposent un PostgreSQL compilé avec `--with-libxml` : le cas des paquets standards, mais pas une garantie universelle.

En pratique, dès que la structure cible a plusieurs niveaux d'imbrication, écrire ce gabarit en SQL pur n'est pas plus simple qu'en Python ou en XSLT. Aucun outil clé en main combinant Postgres et ISO 19110 n'a été identifié : cette voie reste à écrire spécifiquement, comme extension ciblée du tool existant.

**2. Via un orchestrateur de métadonnées.** **geoflow** (package R) prend en entrée les trois objets tabulaires décrits au §3.2 et produit un catalogue ISO 19110, avec publication vers GeoNetwork via son module `geonapi`. C'est l'outil le plus proche du besoin parmi ceux recensés au §4.

Sources : [PostgreSQL — XML Functions](https://www.postgresql.org/docs/current/functions-xml.html) ; [GitHub r-geoflow/geoflow](https://github.com/r-geoflow/geoflow)

### 3.4 Concevoir la table de nomenclature : plus riche que `FC_ListedValue`

Le cas se pose dès que la table de nomenclature à créer porte plus d'informations que les cinq champs de `FC_ListedValue` (§2.2). Trois recommandations.

**La table est la source de vérité, le XML n'est qu'un export.** C'est cohérent avec ce que fait geoflow lui-même, qui réduit un registre à 4 colonnes pour l'exporter sans prétendre que cette forme réduite soit le modèle définitif. Traiter la table comme référence et le XML ISO 19110 comme une vue projetée, régénérée à chaque publication, évite de brider le modèle de données à la structure la plus pauvre de ses consommateurs — d'autant que cette structure est elle-même étiquetée « Deprecated » (§2.1).

**Le surplus n'a pas de place dans le XML — sauf via `definitionReference`.** Le schéma étant fermé (§2.2), les champs supplémentaires restent dans la table sans équivalent XML. Le seul point d'accueil un peu extensible est `definitionReference`, qui pointe vers une citation complète et peut donc porter une URL, une référence documentaire et une version.

**Ne pas nommer les colonnes `gfc:label`, `gfc:code`, `gfc:definition`.** Trois raisons : (a) le `:` n'est pas un caractère d'identifiant SQL standard — il faudrait citer chaque nom (`"gfc:label"`) dans toutes les requêtes ; (b) nommer une colonne d'après un espace de noms XML cible fige la table sur ce seul export, alors que la recommandation ci-dessus va dans le sens inverse ; (c) le statut « Deprecated » d'ISO 19110 rend ce couplage d'autant plus fragile. Préférer des noms neutres en français courant — `code`, `libelle`, `definition`, `designation`, `source_definition` — et faire porter la correspondance vers le vocabulaire `gfc:` par la couche d'export (vue SQL avec alias, feuille de mapping dans le script, configuration d'un registre geoflow).

### 3.5 Exemple travaillé : `siret` et `code_naf` sur une table « entreprises »

Cet exemple distingue la documentation d'un **attribut** (`FC_FeatureAttribute`) de celle d'une **valeur codée** (`FC_ListedValue`) — une confusion facile.

**`siret` — un attribut sans liste de valeurs.** Un SIRET est un identifiant unique par établissement (14 chiffres : SIREN + NIC), pas une valeur catégorielle : il n'y a rien à énumérer, donc aucun `FC_ListedValue`.

| Champ (`FC_FeatureAttribute`) | Valeur |
|---|---|
| `memberName` | `siret` |
| `definition` | Numéro d'identification de l'établissement, composé de 14 chiffres (SIREN de l'entreprise + NIC de l'établissement), attribué par l'Insee via le répertoire Sirene. |
| `designation` | Numéro SIRET de l'établissement |
| `valueType` | texte, 14 caractères |
| `listedValue` | sans objet |
| `definitionReference` | [Numéro Siret — définition officielle, Insee](https://www.insee.fr/fr/metadonnees/definition/c1841) |

**`code_naf` — un attribut à valeurs codées.** Le code NAF (ou code APE) classe l'activité principale d'un établissement selon la Nomenclature d'Activités Française : cas typique de `FC_ListedValue`.

| Champ (`FC_FeatureAttribute`) | Valeur |
|---|---|
| `memberName` | `code_naf` |
| `definition` | Code identifiant l'activité principale exercée (APE) de l'établissement, selon la Nomenclature d'Activités Française (NAF) de l'Insee. |
| `designation` | Code APE / NAF de l'établissement |
| `valueType` | texte, 5 caractères (4 chiffres + 1 lettre) |
| `listedValue` | oui — registre `nomenclature_naf` |

Une ligne du registre associé (`FC_ListedValue`) :

| Champ (`FC_ListedValue`) | Valeur |
|---|---|
| `code` | `62.01Z` |
| `libelle` (`gfc:label`) | Programmation informatique |
| `definition` | Développement, adaptation, test et prise en charge de logiciels ; conception de programmes sur la base des instructions des utilisateurs. |
| `designation` | *(discrétionnaire — l'Insee ne fournit pas de désignation distincte du libellé officiel ; à renseigner seulement si un nom d'usage local est utile)* |
| `source_definition` (`definitionReference`) | [nafr2-62.01Z — Insee](https://www.insee.fr/fr/metadonnees/nafr2/sousClasse/62.01Z), nomenclature NAF rév. 2 (2008) |

**Pourquoi `source_definition` doit porter une version.** Ce code appartient à la nomenclature **NAF rév. 2 (2008)**, en vigueur. Mais l'Insee a adopté une révision, **NAF 2025** (décembre 2023, approuvée par Eurostat en mai 2024), qui remplacera NAF rév. 2 au **1er janvier 2027** — avec mise à jour automatique du code APE de tous les établissements actifs du répertoire Sirene, sans démarche de leur part. Un même établissement pourra donc porter un code différent pour la même activité réelle. Documenter `code: 62.01Z / libelle: Programmation informatique` sans dater la nomenclature rendrait la ligne ambiguë dès 2027 : `source_definition` doit porter l'identification de la nomenclature **et sa version**, pas seulement une URL.

Sources : [Numéro Siret — Insee](https://www.insee.fr/fr/metadonnees/definition/c1841) ; [nafr2-62.01Z — Insee](https://www.insee.fr/fr/metadonnees/nafr2/sousClasse/62.01Z) ; [Vers une nouvelle nomenclature : la NAF 2025 — Insee](https://www.insee.fr/fr/information/8181066) ; [NAF 2025 — Insee](https://www.insee.fr/fr/information/8617910) ; [NAF rév. 2 — Insee](https://www.insee.fr/fr/information/2120875)

### 3.6 Le sens inverse : du XML vers les tables

Pour récupérer un catalogue ISO 19110 existant — moissonné depuis un autre GeoNetwork régional ou national — et le reverser dans une table Postgres ou un tableur :

1. **Avec une bibliothèque qui connaît le schéma**, pour éviter de réécrire le mapping : **OWSLib** (Python) construit un objet `MD_Metadata` depuis une fiche ISO 19139, lit les éléments `FC_FeatureCatalogue`, et fournit un utilitaire (`get_featurecatalogue_uuid()`) pour retrouver l'UUID du catalogue associé à une fiche.
2. **Par un parcours générique** (XSLT vers CSV, ou script Python `lxml`/`ElementTree` parcourant `FC_FeatureType` puis `FC_FeatureAttribute`), pour un contrôle total du mapping vers le schéma cible.

Source : [GitHub geopython/OWSLib](https://github.com/geopython/OWSLib) (usage de `MD_Metadata`/`FC_FeatureCatalogue` documenté dans le module `owslib.iso`)

### 3.7 Ce qui reste à trancher

Pistes d'analyse, pas décisions :

- **Source de vérité des descriptions** : Postgres (`COMMENT ON`), une table/tableur dédié, ou les deux avec synchronisation. Dépend de qui doit pouvoir éditer les descriptions.
- **Voie de génération du XML** : script interne ciblé ou orchestrateur externe (geoflow). Dépend de la volumétrie de tables à documenter et de l'appétence pour une dépendance R.
- **Confirmations techniques à obtenir avant développement** : le mécanisme de rattachement catalogue ↔ fiche de données (§2.3), et la reprise de la description de table par geoflow depuis `entities` (§3.2).

---

## 4. Outils recensés

| Outil | Sens | Ce qu'il fait | Source |
|---|---|---|---|
| **GeoNetwork natif** — import WFS `DescribeFeatureType` | Service WFS → XML ISO 19110 | Feuille XSLT fournie en standard, génère une fiche ISO 19110 depuis la structure d'un service WFS | [fichier source vérifié](https://raw.githubusercontent.com/geonetwork/core-geonetwork/4.0.x/web/src/main/webapp/xsl/conversion/import/OGCWFSDescribeFeatureType-to-ISO19110.xsl) |
| **GeoNetwork natif** — « Apply XSLT » | XML → XML | Applique une feuille de style personnalisée ou prédéfinie sur une fiche | [wiki Iso19110Support](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support) |
| **GeoNetwork API** | Publication | API REST pour créer/mettre à jour des fiches (dont catalogues ISO 19110) une fois le XML généré ; version stable vérifiée 4.4.12 | [API GeoNetwork](https://docs.geonetwork-opensource.org/4.4/api/) |
| **geoflow** (R, v1.2.1 vérifiée 05/2026) | Tables (CSV/Excel/Sheet/BD) → XML ISO 19110, + publication via `geonapi` | Orchestrateur ISO 19115/19119/19110/19139 ; attend les trois objets du §3.2 ; activement maintenu (CRAN 1.0.0 le 09/10/2025, 1.2.1 sur GitHub en 05/2026) | [GitHub](https://github.com/r-geoflow/geoflow) ; [CRAN](https://cran.r-project.org/package=geoflow) |
| **pygeometa** (Python, v0.21.1 vérifiée 04/2026) | YAML (MCF) → XML ISO 19139 | Génère des fiches depuis un YAML structuré. **Ne supporte pas ISO 19110** — confirmé par le catalogue des schémas (iso19139, iso19139-2, iso19139-hnap, dcat, ogcapi-records, schema.org, stac, wmo-*, csvw, openaire, local) | [répertoire des schémas](https://github.com/geopython/pygeometa/tree/master/pygeometa/schemas) |
| **OWSLib** (Python, v0.36.0 vérifiée 06/2026) | XML ISO 19139/19110 → objets Python | Parse `MD_Metadata` et `FC_FeatureCatalogue` ; retrouve l'UUID du catalogue lié ; activement maintenu | [GitHub](https://github.com/geopython/OWSLib) |
| **Script sur mesure** (Python `lxml`, ou XSLT) | XML ↔ table, deux sens | Parcours explicite de `FC_FeatureType`/`FC_FeatureAttribute`/`FC_ListedValue` ; contrôle total, à écrire | — (approche, pas un outil packagé) |
| **PostgreSQL natif** (`COMMENT ON`, `xmlelement`/`xmlagg`) | Table ↔ description, et génération XML | Stocke/lit les descriptions dans le catalogue système ; sait produire du XML imbriqué en SQL, au prix d'un gabarit à écrire (§3.3) | [COMMENT](https://www.postgresql.org/docs/current/sql-comment.html) ; [XML Functions](https://www.postgresql.org/docs/current/functions-xml.html) |
| **PLUME** (QGIS + `PlumePg`, v1.2.1 vérifiée 07/2026) | Table Postgres ↔ fiche, **en RDF/GeoDCAT-AP** | Plugin QGIS de saisie de métadonnées pour tables/vues PostgreSQL ; stocke en JSON-LD dans les commentaires, profil GeoDCAT-AP 2.0. **Aucun export ISO 19139/gfc identifié** : nécessiterait une conversion pour alimenter GeoNetwork | [GitHub](https://github.com/MTES-MCT/metadata-postgresql) ; [doc v1.2.1](https://mtes-mct.github.io/metadata-postgresql/usage/metadonnees_communes.html) |

---

## Sources consultées

**Schémas et normes (sources primaires ISO/TC 211)**

- [featureCatalogue.xsd — XSD officiel gfc 1.1 (ISO 19110)](https://raw.githubusercontent.com/ISO-TC211/XML/master/standards.iso.org.annotated/iso/19110/gfc/1.1/featureCatalogue.xsd)
- [AppendixD.1MinimalExample.xml — exemple minimal officiel, module mdb 1.0 (ISO 19115-3)](https://raw.githubusercontent.com/ISO-TC211/XML/master/standards.iso.org.annotated/iso/19115/-3/mdb/1.0/AppendixD.1MinimalExample.xml)
- [Metadata Base (MDB) 1.0 — page d'accès aux schémas](https://meta.geo.census.gov/data/existing/XML-master/standards.iso.org/19115/-3/mdb/1.0/index.html)
- [ISO/TC 211 Implementation Schemas — ISO 19110](https://schemas.isotc211.org/19110/)
- [ISO 19115-3:2023 — ISO](https://www.iso.org/standard/80874.html)

**Documentation GeoNetwork**

- [Describing information — GeoNetwork 4.2](https://docs.geonetwork-opensource.org/4.2/user-guide/describing-information/)
- [Metadata (iso19115-3.2018) — GeoNetwork 4.4](https://docs.geonetwork-opensource.org/4.4/annexes/standards/iso19115-3.2018/)
- [Methodology for feature cataloguing (Deprecated - use ISO19115-3) — GeoNetwork 3.12](https://docs.geonetwork-opensource.org/3.12/annexes/standards/iso19110/)
- [ISO 19110 Feature cataloguing — GeoNetwork Enterprise 2023](https://docs.geocat.net/geonetwork-enterprise/2023/documentation/annexes/standards/iso19110/)
- [Describing attributes table in a feature Catalog — GeoNetwork 4.0](https://www.geonetwork-opensource.org/manuals/4.0.x/en/user-guide/associating-resources/linking-feature-catalog.html)
- [Describing resources for the INSPIRE directive — GeoNetwork 3.12](https://docs.geonetwork-opensource.org/3.12/user-guide/describing-information/inspire-editing/)
- [API GeoNetwork 4.4](https://docs.geonetwork-opensource.org/4.4/api/) ; [News / historique des versions](https://geonetwork-opensource.org/news.html)
- [Iso19110Support — wiki Trac (proposition 2009)](https://trac.osgeo.org/geonetwork/wiki/Iso19110Support)
- [OGCWFSDescribeFeatureType-to-ISO19110.xsl — code source](https://raw.githubusercontent.com/geonetwork/core-geonetwork/4.0.x/web/src/main/webapp/xsl/conversion/import/OGCWFSDescribeFeatureType-to-ISO19110.xsl)
- [GitHub metadata101/iso19115-3.2018](https://github.com/metadata101/iso19115-3.2018)

**Guides de saisie**

- [How to Create and Publish Geospatial Metadata — FAO, 2021](https://openknowledge.fao.org/server/api/core/bitstreams/5cc37bd1-1185-4e24-b70d-266ce96813f4/content)
- [ISO 19115 Metadata Elements Content — NAL/USDA](https://geodata.nal.usda.gov/geonetwork/doc/geodata/NAL_UserGuide/19115_content/19115_content_main.html)

**INSPIRE et cadre réglementaire**

- [Technical Guidance for INSPIRE metadata (ISO/TS 19139) — INSPIRE-MIF](https://inspire-mif.github.io/technical-guidelines/metadata/metadata-iso19139/metadata-iso19139.html)
- [INSPIRE — EUR-Lex (synthèse)](https://eur-lex.europa.eu/EN/legal-content/summary/the-eu-s-infrastructure-for-spatial-information-inspire.html)
- [COM(2025) 985 final — révision INSPIRE / GreenData4All](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A52025PC0985)
- [Legislative Train — Revision of the INSPIRE Directive](https://www.europarl.europa.eu/legislative-train/theme-a-european-green-deal/file-revision-of-the-inspire-directive)

**Outils (documentation et code source)**

- [GitHub r-geoflow/geoflow](https://github.com/r-geoflow/geoflow) ; [CRAN geoflow](https://cran.r-project.org/package=geoflow) ; [doc/metadata.md](https://github.com/r-geoflow/geoflow/blob/master/doc/metadata.md)
- Code source geoflow vérifié : [geoflow_dictionary.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_dictionary.R), [geoflow_featuretype.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_featuretype.R), [geoflow_featuremember.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_featuremember.R), [geoflow_register.R](https://raw.githubusercontent.com/r-geoflow/geoflow/master/R/geoflow_register.R)
- [GitHub geopython/pygeometa](https://github.com/geopython/pygeometa) ; [répertoire des schémas supportés](https://github.com/geopython/pygeometa/tree/master/pygeometa/schemas)
- [GitHub geopython/OWSLib](https://github.com/geopython/OWSLib)
- [GitHub MTES-MCT/metadata-postgresql (PLUME)](https://github.com/MTES-MCT/metadata-postgresql) ; [doc Plume v1.2.1](https://mtes-mct.github.io/metadata-postgresql/usage/metadonnees_communes.html) ; [fiche SPOTE](https://spote.developpement-durable.gouv.fr/offre/plume-metadonnees-d-un-patrimoine-postgresql)

**PostgreSQL**

- [COMMENT](https://www.postgresql.org/docs/current/sql-comment.html) ; [XML Functions](https://www.postgresql.org/docs/current/functions-xml.html) ; [key_column_usage](https://www.postgresql.org/docs/current/infoschema-key-column-usage.html) ; [Enumerated Types](https://www.postgresql.org/docs/current/datatype-enum.html)
- [List PostgreSQL Object Comments with SQL](https://www.postgresscripts.com/post/list-postgresql-object-comments/)

**Nomenclatures Insee (exemple du §3.5)**

- [Numéro Siret — définition](https://www.insee.fr/fr/metadonnees/definition/c1841)
- [nafr2-62.01Z Programmation informatique](https://www.insee.fr/fr/metadonnees/nafr2/sousClasse/62.01Z)
- [NAF rév. 2](https://www.insee.fr/fr/information/2120875) ; [NAF 2025](https://www.insee.fr/fr/information/8617910) ; [Vers une nouvelle nomenclature : la NAF 2025](https://www.insee.fr/fr/information/8181066)
- [Catégories juridiques (nomenclature Sirene)](https://www.insee.fr/fr/information/2028129)
