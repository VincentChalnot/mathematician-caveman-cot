# Document 3 : Document de référence interne

***

# Mathematician Caveman CoT — Document de référence

*Contexte, motivations, décisions, et tout ce qui ne rentre pas ailleurs*

***

## Genèse du projet

Ce projet est né d'une intuition simple : les LLMs produisent beaucoup de tokens de raisonnement qui ressemblent à de la
communication humaine — polis, structurés, verbeux — alors que le contexte d'exécution est entièrement
machine-to-machine. Personne ne lit ces tokens intermédiaires en production. Ils ont un coût. Est-ce qu'ils ont une
valeur proportionnelle à ce coût ?

La réponse, selon ce benchmark : **non, pas toujours**. Et la compression agressive du format de raisonnement peut même
légèrement améliorer les performances sur certains types de problèmes.

***

## Chronologie des décisions importantes

**Choix du modèle initial** : qwen3-235b-a22b-2507 (instruct) choisi pour ses performances mathématiques, son coût
raisonnable sur OpenRouter ($0.09/$0.10 par million de tokens), et ce qu'on croyait être un toggle
thinking/non-thinking. Erreur découverte en cours de route : la variante `-2507` est instruct-only, sans
thinking natif. Solution adoptée : utiliser deux identifiants de modèle distincts via les variables d'environnement
`MODEL` (instruct) et `THINKING_MODEL` (thinking), chacun tournant en parallèle sur toutes les conditions.

**Découverte du bug de parsing** : Sur les 10 premières questions, deux réponses marquées incorrectes par litebench
étaient en réalité correctes — le parser cherchait un entier isolé, les réponses caveman incluaient du contexte autour
du nombre. Solution : imposer `Final line always: '#### [number only]'` via le champ `gsm8k_prompt` global, appendé à
tous les prompts. Leçon : vérifier manuellement les premiers résultats avant de lancer des runs complets.

**Choix de la taille de sample** : n=20 → n=30 → n=1319 (full GSM8K). Les runs intermédiaires sur n=30 ont des IC trop
larges (±6pp) pour être interprétables. Pour les benchmarks de code, partir directement sur n=164 (HumanEval) ou n≥200 (
LiveCodeBench).

**Complexification des prompts** : Plusieurs tentatives d'améliorer les prompts caveman ont dégradé les résultats. La
version minimaliste en 3 lignes est la meilleure. Règle à retenir : **prompt engineering sur les modèles instruits =
moins est plus**.

***

## Les résultats du modèle thinking (n=1319, run complet)

Les résultats préliminaires à n=30 avaient conclu que le thinking natif sans prompt était la meilleure configuration et
que chaque prompt CoT ajouté dégradait l'accuracy. **Ces conclusions sont fausses** — elles étaient un artefact de la
variance à petit n (IC ±6pp).

Résultats réels n=1319 sur `qwen3-235b-a22b-thinking-2507` :

| Condition               | No-thinking | Thinking   | Δ           |
|-------------------------|-------------|------------|-------------|
| No Prompt               | 94.84%      | **83.70%** | −11.1pp ↓↓↓ |
| Default CoT             | 95.07%      | 88.40%     | −6.7pp ↓    |
| Caveman                 | 95.45%      | 86.66%     | −8.8pp ↓↓   |
| Math Caveman            | 95.30%      | 93.71%     | −1.6pp      |
| Minimalist Math Caveman | **95.45%**  | **94.54%** | −0.9pp      |
| One-Shot                | 78.62%      | **94.47%** | +15.9pp ↑↑↑ |

Interprétation révisée : Les prompts CoT verbeux (Default, Caveman) dégradent bien le modèle thinking — la conclusion de
n=30 était juste sur ce point. Mais les prompts minimaux (One-Shot, Minimalist Math Caveman) préservent presque
entièrement les performances. Et surtout : **l'absence totale de prompt système est le pire résultat** (83.70%),
résultat surprenant — le modèle thinking sans aucune instruction de cadrage sur la tâche dérive significativement. Le
One-Shot, qui est catastrophique pour le modèle non-thinking (78.62%), devient l'un des meilleures configurations pour
le thinking (94.47%).

Pour la ligne directrice : sur les modèles thinking, éviter les instructions CoT structurées, préférer un cadrage
minimal de la tâche.

***

## Questions ouvertes non résolues

**Mécanisme exact de l'amélioration caveman-CoT** : est-ce que le caveman change réellement le raisonnement du modèle (
hypothèse forte) ou simplement sa projection en tokens (hypothèse faible) ? Les benchmarks ne permettent pas de
trancher. Nécessiterait une analyse d'activation ou des expériences d'interpretabilité mécaniste.

**Threshold de compression** : math-caveman (−54% tokens) et caveman (−61% tokens) sont statistiquement équivalents à
default (IC superposés). Où est la falaise ? Les résultats la localisent précisément : entre caveman à −61% (95.45%
accuracy) et one-shot à −72% (78.62% accuracy) — une chute de 16.8pp pour 10.6pp de tokens en moins supplémentaires. La
falaise est abrupte et se situe autour de −65% à −70% de tokens de complétion.

**Généralisation** : GSM8K = arithmétique scolaire. Le raisonnement sur du code est structurellement différent (parcours
d'arbre syntaxique, gestion d'état, etc.). La compression caveman va-t-elle aider, être neutre, ou dégrader ? C'est la
vraie question pour l'audience cible.

**Généralisation inter-modèles** : tous les résultats sont sur Qwen3-235B. DeepSeek V3.1, Llama 3.3 70B, et les modèles
Mistral ont des distributions de training data différentes. Le caveman peut avoir des effets très différents selon la
proportion de code vs prose dans le training data.

***

## Setup technique du projet

**Dépendances clés** :

- [LiteBench](https://github.com/VincentChalnot/LiteBench) — framework de benchmark, installé depuis le repo git
- OpenRouter — routing API vers Qwen3, DeepSeek, etc.
- Docker Compose — isolation de l'environnement, reproductibilité

**Variables d'environnement** (fichier `.env`, non versionné) :

- `MODEL` : identifiant du modèle non-thinking (ex. `openrouter/qwen/qwen3-235b-a22b-2507`)
- `THINKING_MODEL` : identifiant du modèle thinking (ex. `openrouter/qwen/qwen3-235b-a22b-thinking-2507`)
- `OPENAI_API_KEY` : clé OpenRouter

**Structure des résultats** : chaque run produit un fichier `results/[variant]/[output_name].json` avec la liste
complète des questions, réponses attendues, prédictions, et flag correct/incorrect. Exemples :
`results/no_thinking/caveman.json`, `results/thinking/minimalist_math_caveman.json`. Essentiel pour débugger les faux
positifs/négatifs du parser.

***

## Estimations de coût (run complet n=1319, 6 conditions × 2 variants)

Run no-thinking (6 conditions, `qwen3-235b-a22b-2507`) :

- Total prompt tokens : ~1,265,000 @ $0.09/M ≈ $0.11
- Total completion tokens : ~1,146,000 @ $0.10/M ≈ $0.11
- **Total no-thinking : ~$0.23**

Run thinking (6 conditions, `qwen3-235b-a22b-thinking-2507`) :

- Total prompt tokens : ~1,271,000 @ $0.09/M ≈ $0.11
- Total completion tokens (incl. thinking) : ~5,128,000 @ $0.10/M ≈ $0.51
- **Total thinking : ~$0.63**

**Total benchmark complet : ~$0.86**

Le thinking est ~2.7× plus cher que le no-thinking, principalement en raison du volume de tokens de raisonnement
interne (4 à 7× plus de completion tokens selon la condition).

***

## Références utiles

- [LiteBench](https://github.com/VincentChalnot/LiteBench)
- [Chain of Draft paper](https://arxiv.org/abs/2502.18600)
- [Caveman prompting — Reddit r/LLMDevs](https://www.reddit.com/r/LLMDevs/comments/1sepedh/)
- [JuliusBrussee/caveman repo](https://github.com/juliusbrussee/caveman)
- [qwen3-235b-a22b-2507 — OpenRouter](https://openrouter.ai/qwen/qwen3-235b-a22b-2507)
- [Qwen3-235B-A22B-Thinking-2507 — OpenRouter](https://openrouter.ai/qwen/qwen3-235b-a22b-thinking-2507)
- GSM8K dataset : Cobbe et al., 2021
