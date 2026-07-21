# Comparatif des modèles LLM disponibles

Référence pour la configuration des connexions API dans Open WebUI (whitelist "ID des modèles"). Deux sources couvertes : l'API cloud Mistral, et l'instance auto-hébergée RAGaRenn (Eskemm Numérique).

# Partie 1 — Mistral AI (cloud)

Sources : [docs.mistral.ai/models/overview](https://docs.mistral.ai/models/overview), juillet 2026.

## Modèles généralistes (frontier)

| Modèle | ID API `-latest` | Paramètres | Function calling | Usage principal |
|---|---|---|---|---|
| **Mistral Large 3** | `mistral-large-latest` | 675B total / 41B actifs (MoE) | Oui | Tâches complexes, meilleur raisonnement brut, multimodal |
| **Mistral Medium 3.5** | `mistral-medium-latest` | — | Oui | Frontier multimodal, optimisé agentique + code |
| **Mistral Small 4** | `mistral-small-latest` | 128 experts, ~6B actifs (MoE) | Oui | Hybride instruct + raisonnement + code, rapide et économique |
| Ministral 3 (3B/8B/14B) | `ministral-3b-latest`, `ministral-8b-latest`, etc. | 3 à 14B, denses | Oui | Vision + texte, déploiement local/edge, latence minimale |

Function calling confirmé via les fiches modèles officielles Mistral, qui listent "Function Calling" (`/v1/chat/completions`, `/v1/conversations`) comme fonctionnalité de la plateforme — ex. [fiche Codestral](https://docs.mistral.ai/models/model-cards/codestral-25-08), cohérente avec le reste de la gamme texte-à-texte.

## Modèles spécialisés code

| Modèle | ID API | Function calling | Usage principal |
|---|---|---|---|
| **Codestral** | `codestral-latest` | Oui | Complétion de code, FIM (fill-in-the-middle) |
| **Codestral Embed** | `codestral-embed` (pas de `-latest`) | N/A (embedding) | Embeddings sémantiques de code (recherche, RAG sur repo) |
| **Devstral 2** | `devstral-latest` | Oui | Agents de code autonomes, résolution de tâches d'ingénierie logicielle (frontier) |

Source function calling Codestral : [fiche modèle officielle](https://docs.mistral.ai/models/model-cards/codestral-25-08), section "Features" → Function Calling listé explicitement.

## Embeddings, OCR, audio

| Modèle | ID API | Function calling | Usage |
|---|---|---|---|
| Mistral Embed | `mistral-embed` | N/A (embedding) | Embeddings texte généralistes |
| OCR 4 | via API dédiée | N/A (OCR) | OCR avec bounding boxes, structure de document |
| Voxtral (Small / Mini / TTS) | dédiés | N/A (audio) | Transcription audio, synthèse vocale multilingue |

## Modèles "Labs" (expérimentaux)

| Modèle | ID API | Function calling | Usage |
|---|---|---|---|
| Leanstral 1.5 | `labs-leanstral-1-5-1` | Non confirmé | Preuves formelles en Lean 4 — usage très niche, à exclure sauf besoin spécifique |

À exclure de la whitelist sauf besoin identifié : tout ce qui commence par `labs-` (expérimental, non garanti stable).

## Recommandation pour ta whitelist Open WebUI

```
mistral-large-latest      # tâches complexes / raisonnement lourd
mistral-medium-latest     # bon compromis qualité/coût, agentique
mistral-small-latest      # rapide, hybride raisonnement+code, usage courant
codestral-latest          # complétion/génération de code
devstral-latest           # agents de code autonomes
mistral-embed             # embeddings texte (RAG sur ton catalogue)
codestral-embed           # embeddings code (si RAG sur repo de code)
```

Pas de `-latest` pour les embeddings : leur nom est déjà stable et versionné manuellement par Mistral (`mistral-embed`, `codestral-embed`).

## Point de vigilance

Les alias `-latest` pointent vers la version la plus récente de chaque famille et **changent sans préavis** quand Mistral sort une mise à jour (ex: Small 3 → Small 4). Bon compromis ergonomie/stabilité pour un prototype, mais à figer sur un ID daté (ex: `mistral-small-2503`) si un jour tu passes en production et veux un comportement reproductible.

# Partie 2 — RAGaRenn (Eskemm Numérique)

Source : appel direct à `https://ragarenn.eskemm-numerique.fr/test@audiar/api/models`, juillet 2026. Contrairement à l'API Mistral, RAGaRenn expose un catalogue **auto-hébergé et hétérogène** : plusieurs pipelines de serving (Ollama direct, préfixe `ilaas/`, chemins HuggingFace complets, quantifications) exposent souvent **le même modèle sous 3-4 noms différents**, sans convention `-latest` fiable. Le nettoyage se fait donc manuellement, alias par alias.

## Modèles de langage générique

| Famille | ID canonique recommandé | Function calling | Doublons observés | Notes |
|---|---|---|---|---|
| Mistral Small 3.2 (24B) | `mistral-small:latest` | Oui | `mistralai/Mistral-Small-3.2-24B-Instruct-2506`, `mistral-small-3.2-24b`, `mistral-small`, `small`, `ilaas/mistral-small-3.2-24b` | Vision + citations activées |
| Mistral Small 4 (119B, pipeline ilaas) | `ilaas/mistral-small-4-119b` | Oui | — | Variante plus grosse, distincte de Small 3.2 ci-dessus |
| Mistral NeMo | `mistral-nemo:latest` | Oui | — | Modèle plus ancien (12B) |
| Codestral | `codestral:latest` | Oui | — | Spécialisé code — accès restreint à un groupe |
| Llama 3.3 (70B) | `llama-3.3-70b` | Oui | `llama-3.3`, `llama-large`, `RedHatAI/Llama-3.3-70B-Instruct-FP8-dynamic` (quantifié FP8), `ilaas/llama-3.3-70b` | |
| Llama 3.1 (8B) | `llama-3.1-8b` | Oui | `llama-3.1`, `llama-small`, `meta-llama/Llama-3.1-8B-Instruct`, `ilaas/llama-3.1-8b` | |
| GPT-OSS (120B) | `gpt-oss-120b` | Oui | `gpt-oss`, `gpt`, `ilaas/gpt-oss-120b` | Open-weight OpenAI |
| DeepSeek Coder (33B) | `deepseek-coder:33b` | Non confirmé | — | Spécialisé code — accès restreint à un groupe ; version 2024, pas de support natif documenté |
| DeepSeek R1 (70B) | `deepseek-r1:70b` | Instable | — | Raisonnement — accès restreint à 2 groupes ; support function calling ajouté en mai 2025 sur la version officielle R1-0528, mais rapporté comme instable et souvent absent des tags Ollama (voir source) |
| Gemma 4 (31B) | `gemma-4-31b` | Oui | `gemma-4`, `RedHatAI/gemma-4-31B-it-NVFP4` (quantifié), `ilaas/gemma-4-31b` | |
| Qwen 3.6 (35B) | `ilaas/qwen-3.6-35b-instruct` | Oui | — | |
| Phi-4 (14B) | `phi4:14b-q8_0` | Limité | — | Quantifié Q8 ; support natif faible, à utiliser plutôt comme moteur de raisonnement encapsulé par ta propre logique d'agent (voir source) |
| Lucie (7B) | `ParisNeo/Lucie-7B-Instruct-v1.1:latest` | Non confirmé | — | LLM souverain français (LINAGORA / OpenLLM-France) — pas de function calling documenté |
| Salamandra (7B) | `cas/salamandra-7b-instruct:latest` | Non | — | Multilingue (BSC) — une variante dédiée `salamandra-7b-instruct-tools` existe séparément avec function calling, mais n'est pas celle déployée ici |
| LLaVA | `llava:latest` | Non | — | Multimodal image + texte, pas conçu pour l'appel de fonctions structuré |
| Non identifié | `small-til` | Inconnu | — | Alias sans métadonnées (`info`/`meta` absents dans la réponse API) — ne pas whitelister sans confirmation de ce qu'il pointe réellement |

Sources function calling (au-delà des cas déjà confirmés côté Mistral en partie 1) :
- Llama 3.x tool calling : [Llama API — Tool Calling](https://llama.developer.meta.com/docs/features/tool-calling)
- Gemma 4 tool use : voir [Annexe — Arena](#annexe--arena-la-source-de-benchmark-citée), source citée sur les capacités Gemma 4
- Qwen3 function calling : [Qwen Docs — Function Calling](https://qwen.readthedocs.io/en/latest/framework/function_call.html)
- Phi-4 support limité : [Microsoft Community Hub — Function Calling with Small Language Models](https://techcommunity.microsoft.com/blog/educatordeveloperblog/function-calling-with-small-language-models/4472720)
- DeepSeek R1 function calling instable : [DeepSeek API Docs — Tool Calls](https://api-docs.deepseek.com/guides/tool_calls/) et [issue GitHub ollama/ollama #10935](https://github.com/ollama/ollama/issues/10935)
- Salamandra variante tools séparée : [BSC-LT/salamandra-7b-instruct-tools sur Hugging Face](https://huggingface.co/BSC-LT/salamandra-7b-instruct-tools)

## Outils RAG (pas des modèles de chat)

| Modèle | ID | Function calling | Usage |
|---|---|---|---|
| BGE-M3 | `emb/bge-m3` | N/A (embedding) | Embeddings multilingues |
| BGE Reranker v2 M3 | `rank/bge-reranker-v2-m3` | N/A (reranking) | Reranking de résultats de recherche |

## À exclure de la whitelist

- `arena-model` : fonctionnalité Open WebUI (vote A/B anonyme entre modèles), pas un modèle réel.
- Tous les alias en doublon listés dans la colonne "Doublons observés" une fois l'ID canonique choisi.
- `codestral:latest`, `deepseek-coder:33b`, `deepseek-r1:70b` : accès restreint par groupe — vérifier que le compte `test@audiar` a les droits avant de whitelister, sinon échec silencieux à l'usage.

## Recommandation whitelist RAGaRenn

```
mistral-small:latest                     # généraliste courant
llama-3.3-70b                            # généraliste plus costaud
gemma-4-31b                              # généraliste très efficace, bon rapport perf/taille
gpt-oss-120b                             # alternative open-weight
codestral:latest                         # code (si droits d'accès confirmés)
deepseek-r1:70b                          # raisonnement (si droits d'accès confirmés)
ParisNeo/Lucie-7B-Instruct-v1.1:latest   # LLM souverain FR, cas d'usage sensibles
emb/bge-m3                               # embeddings RAG
rank/bge-reranker-v2-m3                  # reranking RAG
```

**Pourquoi ajouter Gemma 4 (31B) :** ta remarque était juste — je l'avais omis par un tri mécanique (un représentant par famille pour dédupliquer), sans évaluer la qualité de chaque famille. Détail et sources vérifiées : voir [Annexe — Arena, la source de benchmark citée](#annexe--arena-la-source-de-benchmark-citée) ci-dessous. En résumé : gemma-4-31b est classé #50 au général sur le classement Arena (score 1451, au 19/07/2026), soit environ 8ᵉ parmi les modèles à licence ouverte — un bon ratio performance/taille pour un modèle de 31B, donc moins gourmand en ressources qu'un modèle plus gros pour un niveau de qualité comparable. Licence Apache 2.0, contexte 262K. Bon candidat pour un usage courant à la place ou en complément de Mistral Small.

**Correctif :** mon message précédent citait "#3 des modèles ouverts" — ce chiffre venait d'un blog secondaire non vérifié sur la source primaire. Voir le correctif détaillé en annexe.

## Annexe — Arena, la source de benchmark citée

**Qu'est-ce qu'Arena :** plateforme de classement de LLM par vote humain en aveugle, anciennement LMArena / LMSYS Chatbot Arena (créée par des chercheurs de UC Berkeley), rebaptisée "Arena" le 28 janvier 2026 et opérée par Arena Intelligence. Un utilisateur soumet un prompt, deux modèles anonymes répondent, l'utilisateur vote pour la meilleure réponse ; les votes alimentent un système de notation Bradley-Terry (apparenté à l'Elo utilisé aux échecs).

**Échelle (au 19/07/2026) :** 7 399 550 votes cumulés sur 376 modèles.

**Limite méthodologique à connaître :** un score Elo/Bradley-Terry mesure une préférence perçue par des votants humains, pas une exactitude factuelle mesurée par un test. Le classement a aussi fait l'objet de critiques sur des biais possibles liés à un accès préférentiel de certains fournisseurs au système de test avant publication (cf. papier académique cité ci-dessous).

**Données vérifiées le 19/07/2026 sur `gemma-4-31b` (source primaire, consultée directement) :**
- Rang général : #50 / 376
- Score : 1451 (± 8)
- Votes : 5 879
- Licence : Apache 2.0
- Contexte : 262,1K tokens
- Prix : 0,14 $ / 0,40 $ par Mtoken (entrée/sortie)
- Rang parmi les seuls modèles à licence ouverte : ~8ᵉ (derrière glm-5.1, glm-5.2, mimo-v2.5-pro, kimi-k2.6, deepseek-v4-pro, glm-5, deepseek-v4-pro-thinking)

**Sources :**
- Classement en direct (texte) : [arena.ai/leaderboard/text](https://arena.ai/leaderboard/text)
- Explication de la méthodologie Elo/Bradley-Terry : [BenchLM.ai — Arena Elo Explained](https://benchlm.ai/blog/posts/chatbot-arena-elo-explained)
- Critique académique de la méthodologie : Singh et al., *"The Leaderboard Illusion"*, arXiv:2504.20879 — [arxiv.org/pdf/2504.20879](https://arxiv.org/pdf/2504.20879)
- Historique et rebranding LMArena → Arena : [Local AI Master — LMArena Leaderboard 2026](https://localaimaster.com/blog/lmarena-chatbot-arena-leaderboard)

# Partie 3 — OVHcloud AI Endpoints

Source : [catalogue OVHcloud AI Endpoints](https://www.ovhcloud.com/fr/public-cloud/ai-endpoints/catalog/), juillet 2026 — 24 modèles au catalogue. Contrairement à RAGaRenn, ce catalogue est **propre par construction** : un modèle = une entrée, pas d'alias ni de doublon. Le problème ici n'est pas le nettoyage, mais l'arbitrage coût/performance (facturation au token, affichée directement dans le catalogue).

## LLM généralistes et raisonnement

| Modèle | Paramètres | Contexte | Function calling | Prix entrée/sortie (€/Mtoken) | Licence | Notes |
|---|---|---|---|---|---|---|
| Meta-Llama-3_3-70B-Instruct | 70B | 131K | Oui | 0,67 / 0,67 | Llama 3.3 Community | |
| Mistral-Nemo-Instruct-2407 | 12,2B | 118K | Oui | 0,13 / 0,13 | Apache 2.0 | |
| Mistral-7B-Instruct-v0.3 | 7B | 127K | Oui | 0,10 / 0,10 | Apache 2.0 | |
| Qwen3-32B | 32,8B | 32K | Oui | 0,08 / 0,23 | Apache 2.0 | Reasoning |
| gpt-oss-120b | 117B | 131K | Oui | 0,08 / 0,40 | Apache 2.0 | Reasoning |
| gpt-oss-20b | 21B | 131K | Oui | 0,04 / 0,15 | Apache 2.0 | Reasoning, le plus économique de la gamme raisonnement |

## Modèles visuels / multimodaux

| Modèle | Paramètres | Contexte | Function calling | Prix entrée/sortie (€/Mtoken) | Licence | Notes |
|---|---|---|---|---|---|---|
| Qwen3.5-397B-A17B | 397B (MoE, 17B actifs) | 262K | Oui | 0,60 / 3,60 | Apache 2.0 | Le plus gros du catalogue, reasoning + multimodal |
| Qwen3.6-27B | 27B | 262K | Oui | 0,40 / 2,70 | Apache 2.0 | Reasoning + multimodal |
| Qwen2.5-VL-72B-Instruct | 72B | 32K | Non | 0,91 / 0,91 | Qwen | Multimodal, pas de reasoning ni function calling listés au catalogue |
| Qwen3.5-9B | 9,7B | 262K | Oui | 0,10 / 0,15 | Apache 2.0 | Le plus économique des modèles visuels |
| Mistral-Small-3.2-24B-Instruct-2506 | 24B | 128K | Oui | 0,09 / 0,28 | Apache 2.0 | Équivalent du modèle vu chez RAGaRenn — ici sous son nom HF complet, sans doublon |

## Code

| Modèle | Paramètres | Contexte | Function calling | Prix entrée/sortie (€/Mtoken) | Licence | Notes |
|---|---|---|---|---|---|---|
| Qwen3-Coder-30B-A3B-Instruct | 30B (MoE, 3B actifs) | 256K | Oui | 0,06 / 0,22 | Apache 2.0 | Code Assistant |

Pas de Codestral ni Devstral chez OVH — seule alternative code dédiée : Qwen3-Coder.

## Embeddings et modération

| Modèle | Paramètres | Function calling | Prix (€/Mtoken entrée) | Licence | Usage |
|---|---|---|---|---|---|
| bge-m3 | 0,567B | N/A (embedding) | 0,01 | MIT | Embeddings multilingues (identique à RAGaRenn) |
| bge-multilingual-gemma2 | 0,567B | N/A (embedding) | 0,01 | Gemma | Embeddings multilingues, variante Gemma |
| Qwen3-Embedding-8B | 7,6B | N/A (embedding) | 0,10 | Apache 2.0 | Embeddings, plus gros modèle → meilleure qualité sémantique |
| Qwen3Guard-Gen-8B | 8B | Non | Gratuit (bêta) | Apache 2.0 | Modération de contenu |
| Qwen3Guard-Gen-0.6B | 0,6B | Non | Gratuit (bêta) | Apache 2.0 | Modération de contenu, version légère |

## Audio et image

| Modèle | Type | Function calling | Prix | Licence |
|---|---|---|---|---|
| whisper-large-v3 | Speech-to-text | N/A (audio) | 0,00004083€/seconde | Apache 2.0 |
| whisper-large-v3-turbo | Speech-to-text | N/A (audio) | 0,00001278€/seconde | Apache 2.0 |
| nvr-tts-fr, en-us, de-de, es-es, it-it | Text-to-speech | N/A (audio) | Gratuit | Riva license |
| stable-diffusion-xl-base-v10 | Génération d'image | N/A (image) | Gratuit | OpenRail++ |

Toutes les valeurs "Oui/Non" de cette partie 3 sont reprises directement du champ "Support" du [catalogue OVHcloud](https://www.ovhcloud.com/fr/public-cloud/ai-endpoints/catalog/) (juillet 2026) — source déjà citée en introduction de cette partie.

## Comparaison avec Mistral Cloud et RAGaRenn

- Pas de Mistral Large, Medium, Magistral ni Devstral chez OVH : le catalogue est centré open-weight (Qwen, Llama, GPT-OSS, Mistral small/nemo/7B).
- Mistral-Small-3.2-24B est le point commun avec RAGaRenn — même modèle, mais chez OVH facturé au token et sans les doublons d'alias observés côté RAGaRenn.
- OVH est le seul des trois à afficher un **prix par token dans le catalogue** — utile pour arbitrer par cas d'usage plutôt que par simple préférence de qualité.

## Recommandation whitelist OVH AI Endpoints

```
Meta-Llama-3_3-70B-Instruct              # généraliste solide
Mistral-Small-3.2-24B-Instruct-2506      # généraliste économique, multimodal
gpt-oss-120b                             # raisonnement, bon rapport qualité/prix
Qwen3-Coder-30B-A3B-Instruct             # code
bge-m3                                   # embeddings RAG (cohérent avec RAGaRenn)
whisper-large-v3-turbo                   # speech-to-text si besoin, moins cher que la v3 standard
```

À vérifier avant de whitelister : l'ID exact attendu par l'API (`/v1/models` une fois la clé configurée) peut différer légèrement de l'intitulé affiché dans le catalogue (casse, tirets).
