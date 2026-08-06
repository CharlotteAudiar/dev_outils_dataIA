:::: {.bloc-titre}
::: {.typologie}
Benchmark modèles v0
:::

# Données et outils IA

::: {.sous-titre}
Étude et expérimentations
:::
::::

**Référence** : 2026-HP-INT-001

Comparaison des modèles mis à disposition par l'API cloud Mistral, RAGaRenn (Eskemm Numérique) et les services OVH Cloud endpoints.

## Mistral AI

Sources : [docs.mistral.ai/models/overview](https://docs.mistral.ai/models/overview), juillet 2026.

### LLM généralistes

| Modèle | ID API `-latest` | Paramètres | Poids (réf. open-weight)¹ | Function calling | Usage principal |
|---|---|---|---|---|---|
| **Mistral Large 3** | `mistral-large-latest` | 675B total / 41B actifs (MoE) | ~1,35 To (BF16) / ~675 Go (FP8) | Oui | Tâches complexes, meilleur raisonnement brut, multimodal |
| **Mistral Medium 3.5** | `mistral-medium-latest` | — (non communiqué) | — | Oui | Frontier multimodal, optimisé agentique + code |
| **Mistral Small 4** | `mistral-small-latest` | 119B total, 128 experts, ~6B actifs (MoE) | ~238 Go (BF16) / ~119 Go (FP8) | Oui | Hybride instruct + raisonnement + code, rapide et économique |
| Ministral 3 (3B/8B/14B) | `ministral-3b-latest`, `ministral-8b-latest`, etc. | 3 à 14B, denses | ~6 à ~28 Go (BF16) selon la taille | Oui | Vision + texte, déploiement local/edge, latence minimale |

¹ Ces modèles sont consommés ici via l'API cloud managée Mistral (précision d'inférence réelle non communiquée) ; le poids indiqué est une référence théorique basée sur le nombre de paramètres publiés, utile si tu envisages un jour de les auto-héberger, pas pour dimensionner l'infra ragarenn/OVH. Mistral Large 3 est publié en open-weight sur Hugging Face ([mistralai/Mistral-Large-3-675B-Instruct-2512](https://huggingface.co/mistralai/Mistral-Large-3-675B-Instruct-2512)), Mistral Small 4 confirmé ~119B total ([couverture presse citant VentureBeat/Mistral AI](https://venturebeat.com/technology/mistrals-small-4-consolidates-reasoning-vision-and-coding-into-one-model-at)).

Function calling confirmé via les fiches modèles officielles Mistral, qui listent "Function Calling" (`/v1/chat/completions`, `/v1/conversations`) comme fonctionnalité de la plateforme — ex. [fiche Codestral](https://docs.mistral.ai/models/model-cards/codestral-25-08), cohérente avec le reste de la gamme texte-à-texte.

### LLM spécialisés code

| Modèle | ID API | Paramètres | Function calling | Usage principal |
|---|---|---|---|---|
| **Codestral** | `codestral-latest` | ~22B (dense) | Oui | Complétion de code, FIM (fill-in-the-middle) |
| **Codestral Embed** | `codestral-embed` (pas de `-latest`) | Non communiqué | N/A (embedding) | Embeddings sémantiques de code (recherche, RAG sur repo) |
| **Devstral 2** | `devstral-latest` | Non communiqué | Oui | Agents de code autonomes, résolution de tâches d'ingénierie logicielle (frontier) |

Source function calling Codestral : [fiche modèle officielle](https://docs.mistral.ai/models/model-cards/codestral-25-08), section "Features" → Function Calling listé explicitement.

### Embeddings, OCR, audio

| Modèle | ID API | Function calling | Usage |
|---|---|---|---|
| Mistral Embed | `mistral-embed` | N/A (embedding) | Embeddings texte généralistes |
| OCR 4 | via API dédiée | N/A (OCR) | OCR avec bounding boxes, structure de document |
| Voxtral (Small / Mini / TTS) | dédiés | N/A (audio) | Transcription audio, synthèse vocale multilingue |

### Modèles "Labs" (expérimentaux)

| Modèle | ID API | Function calling | Usage |
|---|---|---|---|
| Leanstral 1.5 | `labs-leanstral-1-5-1` | Non confirmé | Preuves formelles en Lean 4 — usage très niche, à exclure sauf besoin spécifique |

À exclure des recommandations sauf besoin identifié : tout ce qui commence par `labs-` (expérimental, non garanti stable).

### Recommandations modèles Mistral

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

### Point de vigilance

Les alias `-latest` pointent vers la version la plus récente de chaque famille et **changent sans préavis** quand Mistral sort une mise à jour (ex: Small 3 → Small 4). Bon compromis ergonomie/stabilité pour un prototype, mais à figer sur un ID daté (ex: `mistral-small-2503`) si un jour tu passes en production et veux un comportement reproductible.

## RAGaRenn (Eskemm Numérique)

Source : appel direct à `https://ragarenn.eskemm-numerique.fr/test@audiar/api/models`, juillet 2026. Contrairement à l'API Mistral, RAGaRenn expose un catalogue **auto-hébergé et hétérogène** : plusieurs pipelines de serving (Ollama direct, préfixe `ilaas/`, chemins HuggingFace complets, quantifications) exposent souvent **le même modèle sous 3-4 noms différents**, sans convention `-latest` fiable. Le nettoyage se fait donc manuellement, alias par alias.

### LLM généralistes

| Famille | ID canonique recommandé | Paramètres | Poids (disque)² | Function calling | Doublons observés | Notes |
|---|---|---|---|---|---|---|
| Mistral Small 3.2 (24B) | `mistral-small:latest` | 24B (dense) | ~24 Go (FP8/Q8) à ~48 Go (BF16) — quantification servie non précisée par l'alias | Oui | `mistralai/Mistral-Small-3.2-24B-Instruct-2506`, `mistral-small-3.2-24b`, `mistral-small`, `small`, `ilaas/mistral-small-3.2-24b` | Vision + citations activées |
| Mistral Small 4 (119B, pipeline ilaas) | `ilaas/mistral-small-4-119b` | 119B total / ~6B actifs (MoE, 128 experts) | ~119 Go (FP8) à ~238 Go (BF16) — non précisé | Oui | — | Variante plus grosse, distincte de Small 3.2 ci-dessus |
| Mistral NeMo | `mistral-nemo:latest` | 12,2B (dense) | ~12 Go (FP8/Q8) à ~24 Go (BF16) | Oui | — | Modèle plus ancien (12B) |
| Llama 3.3 (70B) | `llama-3.3-70b` | 70,6B (dense) | ~70 Go (FP8, cf. variante RedHatAI ci-contre) à ~141 Go (BF16) — l'alias `llama-3.3-70b` seul ne précise pas sa quantification | Oui | `llama-3.3`, `llama-large`, `RedHatAI/Llama-3.3-70B-Instruct-FP8-dynamic` (quantifié FP8), `ilaas/llama-3.3-70b` | |
| Llama 3.1 (8B) | `llama-3.1-8b` | 8,03B (dense) | ~8 Go (FP8/Q8) à ~16 Go (BF16) | Oui | `llama-3.1`, `llama-small`, `meta-llama/Llama-3.1-8B-Instruct`, `ilaas/llama-3.1-8b` | |
| GPT-OSS (120B) | `gpt-oss-120b` | 117B total / 5,1B actifs (MoE, MXFP4 natif) | ~65 Go (MXFP4, format natif publié par OpenAI) — nécessite un GPU ~80 Go d'après la fiche officielle | Oui | `gpt-oss`, `gpt`, `ilaas/gpt-oss-120b` | Open-weight OpenAI ; voir note function calling/positionnement ci-dessous |
| DeepSeek R1 (70B) | `deepseek-r1:70b` | 71B (dense — distillation de Llama 3.3 70B) | ~35-40 Go (Q4, quantification par défaut Ollama la plus courante) à ~142 Go (BF16) | Instable | — | Raisonnement — accès restreint à 2 groupes ; support function calling ajouté en mai 2025 sur la version officielle R1-0528, mais rapporté comme instable et souvent absent des tags Ollama (voir source) |
| Gemma 4 (31B, dense) | `gemma-4-31b` | 30,7B (dense) | ~31 Go (FP8/Q8) à ~61 Go (BF16) ; variante NVFP4 (RedHatAI) plus légère, ~15-18 Go | Oui | `RedHatAI/gemma-4-31B-it-NVFP4` (quantifié), `ilaas/gemma-4-31b` | Les deux alias incluent explicitement "31b/31B" dans le nom — doublon fiable |
| Gemma 4 — alias ambigu | `gemma-4` | Inconnu — 30,7B (dense, si variante 31B) ou 25,2B total/3,8B actifs (si variante 26B-A4B MoE) | Dépend de la variante réelle — à vérifier avant usage | Inconnu | — | **Pas un doublon confirmé de la ligne ci-dessus.** Alias sans métadonnées (`info` absent), sans indication de taille. Gemma 4 existe en au moins deux tailles publiées : 31B dense et 26B-A4B (MoE, ~4B actifs) — voir [gemma-4-26b-a4b sur le classement Arena](#annexe--arena-la-source-de-benchmark-citée). `gemma-4` pourrait pointer vers l'une ou l'autre. À vérifier avant recommandations (par ex. en interrogeant le endpoint avec ce seul ID et en comparant la taille de réponse/latence) |
| Qwen 3.6 (35B) | `ilaas/qwen-3.6-35b-instruct` | 35B total / 3B actifs (MoE, 256 experts, 8 routés + 1 partagé) | ~70-75 Go (BF16) — quantifications plus légères (INT4/AWQ) probablement possibles mais non confirmées sur ragarenn | Oui | — | |
| Phi-4 (14B) | `phi4:14b-q8_0` | 14,7B (dense) | ~15 Go (Q8, confirmé par le suffixe `-q8_0` de l'alias) | Limité | — | Quantifié Q8 ; support natif faible, à utiliser plutôt comme moteur de raisonnement encapsulé par ta propre logique d'agent (voir source) |
| Lucie (7B) | `ParisNeo/Lucie-7B-Instruct-v1.1:latest` | ~7B (dense, entraîné from scratch) | ~14 Go (BF16) — quantification non précisée par l'alias `:latest` | Non confirmé | — | LLM souverain français (LINAGORA / OpenLLM-France) — pas de function calling documenté |
| Salamandra (7B) | `cas/salamandra-7b-instruct:latest` | 7,77B (dense) | ~15,5 Go (BF16) — non précisé | Non | — | Multilingue (BSC) — une variante dédiée `salamandra-7b-instruct-tools` existe séparément avec function calling, mais n'est pas celle déployée ici |
| LLaVA | `llava:latest` | Probablement 7B (dense) — alias `:latest` correspond par défaut à la version 7B chez la plupart des distributions Ollama, mais LLaVA existe aussi en 13B/34B, non confirmé ici | ~14 Go (BF16, si 7B) — à vérifier comme pour `gemma-4` | Non | — | Multimodal image + texte, pas conçu pour l'appel de fonctions structuré |
| Non identifié | `small-til` | Inconnu | Inconnu | Inconnu | — | Alias sans métadonnées (`info`/`meta` absents dans la réponse API) — ne pas recommander sans confirmation de ce qu'il pointe réellement |

² Poids = taille estimée du fichier de poids sur disque à la précision indiquée (calcul : nombre de paramètres × octets/paramètre — BF16 ≈ 2 octets, FP8/Q8 ≈ 1 octet, Q4/NVFP4/MXFP4 ≈ 0,5-0,6 octet, hors overhead mineur des tenseurs annexes). Quand l'alias ne précise pas la quantification réellement servie (pas de suffixe type `-q8_0`, `-NVFP4`, `FP8-dynamic`), une fourchette est donnée plutôt qu'un chiffre unique — à confirmer auprès de ragarenn si le dimensionnement GPU devient un enjeu concret pour le choix final. Sources chiffres de paramètres non déjà citées ailleurs dans ce document : [Gemma 4 model card — Google AI for Developers](https://ai.google.dev/gemma/docs/core/model_card_4), [Qwen3.6-35B-A3B — apxml specs](https://apxml.com/models/qwen36-35b-a3b), [gpt-oss-120b/20b model card](https://arxiv.org/html/2508.10925v1) et [annonce OpenAI](https://openai.com/index/introducing-gpt-oss/), [DeepSeek-R1-Distill-Llama-70B — Hugging Face](https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Llama-70B).

### LLM spécialisés code

| Famille | ID canonique recommandé | Paramètres | Poids (disque) | Function calling | Doublons observés | Notes |
|---|---|---|---|---|---|---|
| Codestral | `codestral:latest` | ~22B (dense) | ~22 Go (FP8/Q8) à ~44 Go (BF16) — non précisé | Oui | — | Accès restreint à un groupe |
| DeepSeek Coder (33B) | `deepseek-coder:33b` | 33,3B (dense) | ~33 Go (Q8) à ~67 Go (BF16) — alias sans suffixe de quantification | Non confirmé | — | Accès restreint à un groupe ; version 2024, pas de support natif documenté |

Sources function calling (au-delà des cas déjà confirmés côté Mistral en partie 1) :
- Llama 3.x tool calling : [Llama API — Tool Calling](https://llama.developer.meta.com/docs/features/tool-calling)
- Gemma 4 tool use : voir [Annexe — Arena](#annexe--arena-la-source-de-benchmark-citée), source citée sur les capacités Gemma 4
- Qwen3 function calling : [Qwen Docs — Function Calling](https://qwen.readthedocs.io/en/latest/framework/function_call.html)
- Phi-4 support limité : [Microsoft Community Hub — Function Calling with Small Language Models](https://techcommunity.microsoft.com/blog/educatordeveloperblog/function-calling-with-small-language-models/4472720)
- DeepSeek R1 function calling instable : [DeepSeek API Docs — Tool Calls](https://api-docs.deepseek.com/guides/tool_calls/) et [issue GitHub ollama/ollama #10935](https://github.com/ollama/ollama/issues/10935)
- Salamandra variante tools séparée : [BSC-LT/salamandra-7b-instruct-tools sur Hugging Face](https://huggingface.co/BSC-LT/salamandra-7b-instruct-tools)

### Embeddings

| Modèle | ID | Paramètres | Poids (disque) | Function calling | Usage |
|---|---|---|---|---|---|
| BGE-M3 | `emb/bge-m3` | 568M (dense) | ~1,1 Go (BF16) | N/A (embedding) | Embeddings multilingues |
| BGE Reranker v2 M3 | `rank/bge-reranker-v2-m3` | 568M (dense, même base que BGE-M3) | ~1,1 Go (BF16) | N/A (reranking) | Reranking de résultats de recherche |


### Modèles exclus
- `arena-model` : fonctionnalité Open WebUI (vote A/B anonyme entre modèles), pas un modèle réel.
- Tous les alias en doublon listés dans la colonne "Doublons observés" une fois l'ID canonique choisi.
- `codestral:latest`, `deepseek-coder:33b`, `deepseek-r1:70b` : accès restreint par groupe — vérifier que le compte `test@audiar` a les droits avant de recommander, sinon échec silencieux à l'usage.



### Recommandation modèles RAGaRenn

```
mistral-small:latest                     # généraliste courant
llama-3.3-70b                            # généraliste plus costaud
gemma-4-31b                              # généraliste très efficace, bon rapport perf/taille
gpt-oss-120b                             # alternative de raisonnement à deepseek-r1:70b (accès non restreint, pas d'instabilité connue à ce jour)
codestral:latest                         # code (si droits d'accès confirmés)
deepseek-r1:70b                          # raisonnement (si droits d'accès confirmés)
ParisNeo/Lucie-7B-Instruct-v1.1:latest   # LLM souverain FR, cas d'usage sensibles
emb/bge-m3                               # embeddings RAG
rank/bge-reranker-v2-m3                  # reranking RAG
```






## OVHcloud AI

Source : [catalogue OVHcloud AI Endpoints](https://www.ovhcloud.com/fr/public-cloud/ai-endpoints/catalog/), juillet 2026 — 24 modèles au catalogue. Contrairement à RAGaRenn, ce catalogue est **propre par construction** : un modèle = une entrée, pas d'alias ni de doublon. Le problème ici n'est pas le nettoyage, mais l'arbitrage coût/performance (facturation au token, affichée directement dans le catalogue).

### LLM généralistes

| Modèle | Paramètres | Poids (réf. BF16)³ | Contexte | Function calling | Prix entrée/sortie (€/Mtoken) | Licence | Notes |
|---|---|---|---|---|---|---|---|
| Meta-Llama-3_3-70B-Instruct | 70B | ~140 Go | 131K | Oui | 0,67 / 0,67 | Llama 3.3 Community | |
| Mistral-Nemo-Instruct-2407 | 12,2B | ~24 Go | 118K | Oui | 0,13 / 0,13 | Apache 2.0 | |
| Mistral-7B-Instruct-v0.3 | 7B | ~14 Go | 127K | Oui | 0,10 / 0,10 | Apache 2.0 | |
| Qwen3-32B | 32,8B | ~66 Go | 32K | Oui | 0,08 / 0,23 | Apache 2.0 | Reasoning |
| gpt-oss-120b | 117B (5,1B actifs, MoE) | ~65 Go (MXFP4 natif) | 131K | Oui | 0,08 / 0,40 | Apache 2.0 | Reasoning |
| gpt-oss-20b | 21B (3,6B actifs, MoE) | ~16 Go (MXFP4 natif) | 131K | Oui | 0,04 / 0,15 | Apache 2.0 | Reasoning, le plus économique de la gamme raisonnement |

### LLM spécialisés Code

| Modèle | Paramètres | Poids (réf. BF16)³ | Contexte | Function calling | Prix entrée/sortie (€/Mtoken) | Licence | Notes |
|---|---|---|---|---|---|---|---|
| Qwen3-Coder-30B-A3B-Instruct | 30B (MoE, 3B actifs) | ~60 Go | 256K | Oui | 0,06 / 0,22 | Apache 2.0 | Code Assistant |

Pas de Codestral ni Devstral chez OVH — seule alternative code dédiée : Qwen3-Coder.


### Modèles visuels / multimodaux

| Modèle | Paramètres | Poids (réf. BF16)³ | Contexte | Function calling | Prix entrée/sortie (€/Mtoken) | Licence | Notes |
|---|---|---|---|---|---|---|---|
| Qwen3.5-397B-A17B | 397B (MoE, 17B actifs) | ~794 Go | 262K | Oui | 0,60 / 3,60 | Apache 2.0 | Le plus gros du catalogue, reasoning + multimodal |
| Qwen3.6-27B | 27B | ~54 Go | 262K | Oui | 0,40 / 2,70 | Apache 2.0 | Reasoning + multimodal |
| Qwen2.5-VL-72B-Instruct | 72B | ~144 Go | 32K | Non | 0,91 / 0,91 | Qwen | Multimodal, pas de reasoning ni function calling listés au catalogue |
| Qwen3.5-9B | 9,7B | ~19 Go | 262K | Oui | 0,10 / 0,15 | Apache 2.0 | Le plus économique des modèles visuels |
| Mistral-Small-3.2-24B-Instruct-2506 | 24B | ~48 Go | 128K | Oui | 0,09 / 0,28 | Apache 2.0 | Équivalent du modèle vu chez RAGaRenn — ici sous son nom HF complet, sans doublon |


### Embeddings et modération

| Modèle | Paramètres | Poids (réf. BF16)³ | Function calling | Prix (€/Mtoken entrée) | Licence | Usage |
|---|---|---|---|---|---|---|
| bge-m3 | 0,567B | ~1,1 Go | N/A (embedding) | 0,01 | MIT | Embeddings multilingues (identique à RAGaRenn) |
| bge-multilingual-gemma2 | 0,567B ⚠️ | ~1,1 Go ⚠️ | N/A (embedding) | 0,01 | Gemma | Embeddings multilingues, variante Gemma — **⚠️ incohérence relevée dans le catalogue OVHcloud lui-même** : ce modèle est documenté publiquement (BAAI/Hugging Face) comme construit sur la base Gemma-2-9B (~9,24B paramètres), pas 0,567B. Le chiffre 0,567B affiché sur la fiche OVHcloud est identique à celui de bge-m3 juste au-dessus — probable erreur de copier-coller côté OVHcloud, pas une transcription fautive de ta part. Poids réel si 9,24B : ~18,5 Go (BF16). À confirmer directement auprès d'OVHcloud avant d'arbitrer sur ce modèle. |
| Qwen3-Embedding-8B | 7,6B | ~15,2 Go | N/A (embedding) | 0,10 | Apache 2.0 | Embeddings, plus gros modèle → meilleure qualité sémantique |
| Qwen3Guard-Gen-8B | 8B | ~16 Go | Non | Gratuit (bêta) | Apache 2.0 | Modération de contenu |
| Qwen3Guard-Gen-0.6B | 0,6B | ~1,2 Go | Non | Gratuit (bêta) | Apache 2.0 | Modération de contenu, version légère |

³ Poids théorique = paramètres × 2 octets (BF16), à titre de référence : OVHcloud facture au token via une API managée et ne communique pas la précision d'inférence réellement utilisée côté serveur (probablement optimisée/quantifiée sur son infra, donc potentiellement plus légère en pratique). GPT-OSS fait exception : poids donné à sa précision native MXFP4 publiée par OpenAI, plus représentative que la référence BF16 théorique pour ce modèle.

### Audio et image

| Modèle | Type | Function calling | Prix | Licence |
|---|---|---|---|---|
| whisper-large-v3 | Speech-to-text | N/A (audio) | 0,00004083€/seconde | Apache 2.0 |
| whisper-large-v3-turbo | Speech-to-text | N/A (audio) | 0,00001278€/seconde | Apache 2.0 |
| nvr-tts-fr, en-us, de-de, es-es, it-it | Text-to-speech | N/A (audio) | Gratuit | Riva license |
| stable-diffusion-xl-base-v10 | Génération d'image | N/A (image) | Gratuit | OpenRail++ |

Toutes les valeurs "Oui/Non" de cette partie 3 sont reprises directement du champ "Support" du [catalogue OVHcloud](https://www.ovhcloud.com/fr/public-cloud/ai-endpoints/catalog/) (juillet 2026), source déjà citée en introduction de cette partie.

### Recommandations OVH

```
Meta-Llama-3_3-70B-Instruct              # généraliste solide
Mistral-Small-3.2-24B-Instruct-2506      # généraliste économique, multimodal
gpt-oss-120b                             # raisonnement, bon rapport qualité/prix
Qwen3-Coder-30B-A3B-Instruct             # code
bge-m3                                   # embeddings RAG (cohérent avec RAGaRenn)
whisper-large-v3-turbo                   # speech-to-text si besoin, moins cher que la v3 standard
```


## Outils de comparaison des modèles

### Arena

**Qu'est-ce qu'Arena :** plateforme de classement de LLM par vote humain en aveugle, anciennement LMArena / LMSYS Chatbot Arena (créée par des chercheurs de UC Berkeley), rebaptisée "Arena" le 28 janvier 2026 et opérée par Arena Intelligence. Un utilisateur soumet un prompt, deux modèles anonymes répondent, l'utilisateur vote pour la meilleure réponse ; les votes alimentent un système de notation Bradley-Terry (apparenté à l'Elo utilisé aux échecs).

**Échelle (au 19/07/2026) :** 7 399 550 votes cumulés sur 376 modèles.

**Limite méthodologique :** un score Elo/Bradley-Terry mesure une préférence perçue par des votants humains, pas une exactitude factuelle mesurée par un test. Le classement a aussi fait l'objet de critiques sur des biais possibles liés à un accès préférentiel de certains fournisseurs au système de test avant publication (cf. papier académique cité ci-dessous).

**Sources :**
- Classement en direct (texte) : [arena.ai/leaderboard/text](https://arena.ai/leaderboard/text)
- Explication de la méthodologie Elo/Bradley-Terry : [BenchLM.ai — Arena Elo Explained](https://benchlm.ai/blog/posts/chatbot-arena-elo-explained)
- Critique académique de la méthodologie : Singh et al., *"The Leaderboard Illusion"*, arXiv:2504.20879 — [arxiv.org/pdf/2504.20879](https://arxiv.org/pdf/2504.20879)
- Historique et rebranding LMArena → Arena : [Local AI Master — LMArena Leaderboard 2026](https://localaimaster.com/blog/lmarena-chatbot-arena-leaderboard)