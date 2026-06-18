# Can You Make an LLM Reason Better by Forcing It to Think Like a Caveman?

*A benchmark on GSM8K with Qwen3-235B exploring compressed chain-of-thought prompting*

***

When we talk about making LLMs more efficient, the conversation usually goes in one direction: bigger models, more
compute, fancier training. But what if the bottleneck isn't the model — it's the language?

This article documents a simple experiment: what happens when you instruct a model to reason in compressed, minimal
language — "caveman English" mixed with mathematical symbols — instead of the verbose prose it defaults to?

***

## Background: Thinking Is Not Language

Recent work in cognitive science has reinforced a position that linguists and philosophers have debated for decades: *
*thought is not reducible to language**. Language is a projection system — a way of externalizing and communicating
internal representations. It's optimized for human-to-human transmission, which means it carries enormous redundancy by
design. Politeness markers, discourse connectors, hedging phrases — all of this exists to reduce miscommunication
between biological agents operating in ambiguous social contexts.

A large language model is a neural network operating in a very high-dimensional vector space. It doesn't "think in
words" — it computes over token embeddings, and tokens are merely the projection interface between that internal
computation and the outside world. This distinction matters: when a model outputs *"Let's think step by step. First, we
need to consider..."*, it isn't necessarily reasoning better. It may simply be producing the surface form that
correlates with correct reasoning in its training data.

This is the core hypothesis we wanted to test.

***

## Prior Work

**Chain-of-Thought prompting** (Wei et al., 2022) showed that instructing models to "think step by step" significantly
improves performance on reasoning tasks. The effect is well-documented and robust.

**Chain of Draft** (MIT/Anthropic, 2024) pushed this further: ultra-minimal CoT, keeping only essential reasoning steps,
achieved 97% of full CoT performance with 7.6× fewer tokens.

**Caveman Prompting** emerged in the open-source community around April 2026 as a technique for compressing LLM
*output* — removing filler words, keeping high-value tokens, using symbols like `→`, `∴`, `∈`. Reports of 40–60% output
token reduction with minimal quality degradation circulated on Reddit and LinkedIn.

What nobody had combined, to our knowledge: **caveman-style compression applied specifically to the reasoning chain**,
not just the final output — and benchmarked rigorously against a baseline.

***

## The Experiment

### Setup

- **Models**: `qwen/qwen3-235b-a22b-2507` (instruct, no extended thinking) and
  `qwen/qwen3-235b-a22b-thinking-2507` (extended thinking)
- **Benchmark**: GSM8K (grade school math, 1319 questions, full test set)
- **Framework**: LiteBench, OpenRouter API
- **Conditions**: 6 system prompt variants, each run on both model variants

### Prompts

All prompts are defined in `config.yaml`. A universal suffix is appended to every prompt via the `gsm8k_prompt` field:

```
Final line always: '#### [number only]'
```

**No Prompt** (minimalist baseline — format instruction only):

```
Final line always: '#### [number only]'
```

**One-Shot** (answer compression — no reasoning):

```
Give only the final answer. No explanation. No steps. One line.
Final line always: '#### [number only]'
```

**Default** (standard CoT):

```
You are solving a grade-school math problem. Reason step by step.
Final line always: '#### [number only]'
```

**Caveman** (general compressed style, from JuliusBrussee/caveman):

```
Respond terse like smart caveman. All technical substance stay. Only fluff die.
Drop: articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging.
Fragments OK. Short synonyms (big not extensive, fix not "implement a solution for"). Technical terms exact. Code blocks unchanged. Errors quoted exact.
Pattern: [thing] [action] [reason]. [next step].

Not: "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by..."
Yes: "Bug in auth middleware. Token expiry check use < not <=. Fix:"

Drop caveman only for: security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread. Resume caveman after.

Code blocks: write normal. "stop caveman" or "normal mode": revert.
Final line always: '#### [number only]'
```

**Math Caveman** (compressed with explicit symbol legend):

```
You mathematician caveman: No filler. Fragments. No prose. Short synonyms.
Technical terms exact. Code blocks unchanged. Errors quoted exact.

Math symbols compress reasoning:
∵ = because | ∴ = therefore | → = leads to | ↔ = equiv
≈ = approx | ≠ = differs | ∈ = is case of | ∉ = not applicable
✓ = valid | ✗ = rejected | ⚠ = edge case | ? = uncertain
⊕ = combine | > / < = better/worse than | (...)

<r> 1.[eq/step] 2.[eq/step] → [result] </r>

Drop caveman only for: security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread. Resume caveman after.

Final line always: '#### [number only]'
```

**Minimalist Math Caveman** (condensed 3-line version):

```
You mathematician caveman: No filler. Fragments. No prose. Short synonyms. Reasoning symbols ∵, →, ↔, ∈, ∉, ✓, ✗
Technical terms exact. Code blocks unchanged. Errors quoted exact.
Reason: <r> 1.[step] 2.[step] → [conclusion] </r>
Final line always: '#### [number only]'
```

***

## Results

### Instruct model (`qwen3-235b-a22b-2507`)

| Condition               | Accuracy   | IC 95%          | Completion tokens | vs. Default | Speedup   |
|-------------------------|------------|-----------------|-------------------|-------------|-----------|
| Default CoT             | 95.07%     | [93.8–96.1]     | 299,405           | —           | ×1        |
| No Prompt               | 94.84%     | [93.5–95.9]     | 292,249           | −2.4%       | ×1.04     |
| Minimalist Math Caveman | **95.75%** | [94.5–96.7]     | 213,108           | −28.8%      | ×1.37     |
| Math Caveman            | 95.30%     | [94.0–96.3]     | 136,631           | −54.4%      | ×2.09     |
| **Caveman**             | **95.45%** | **[94.2–96.4]** | **117,104**       | **−60.9%**  | **×2.03** |
| One-Shot (↯)            | 78.62%     | [76.3–80.7]     | 85,276            | −71.5%      | —         |

*Confidence intervals: Wilson method, z=1.96. Speedup based on mean per-request latency.*

### Key findings

**1. Caveman and Minimalist Math Caveman preserve — and marginally improve — accuracy** (95.45% and 95.75% respectively,
vs. 95.07% for Default). All three caveman variants fall within overlapping CIs of Default, meaning accuracy is
statistically
preserved, not degraded.

**2. Token efficiency is large and real.** Caveman uses 60.9% fewer completion tokens than Default at equivalent
accuracy. Math Caveman uses 54.4% fewer. These are deterministic counts, unaffected by sampling variance.

**3. The efficiency curve is monotonic up to a hard drop.** From Default to Minimalist Math Caveman to Math Caveman to
Caveman, each step reduces tokens while maintaining accuracy. One-Shot is not a further point on this continuum — it
removes reasoning entirely, a qualitatively different intervention. The result is a 10.6pp additional token reduction
(−61% → −72%) that causes a 16.8pp accuracy drop (95.45% → 78.62%). Two distinct regimes, separated by a sharp boundary.

**4. No Prompt ≈ Default in accuracy, but with no token savings.** Removing the CoT instruction costs nothing in
accuracy but also gains nothing in efficiency — the model produces nearly the same token volume regardless.

***

## Why Does Caveman-CoT Help?

We propose two non-exclusive mechanisms:

**The redundancy hypothesis**: Natural language prose carries communicative redundancy that is irrelevant for automated
reasoning. Caveman format strips this redundancy while preserving the logical structure. The model's underlying
computation may not change — only the projection into tokens is constrained. (This is an assumption: autoregressive
models propagate information through their token sequence, so forcing a different surface form could in principle alter
attention patterns across subsequent steps. We cannot rule this out from benchmark results alone.)

**The anchoring hypothesis**: Mathematical symbols (→, ∴, ∈) are semantically dense — one token expressing a logical
relation that prose would require 5–10 tokens to express. They may act as stronger semantic anchors for subsequent
reasoning steps, reducing the probability of drift in long chains.

Both mechanisms point to a unifying principle: **what's important is not to guide the reasoning process but to
constrain how that process projects into tokens**. This framing applies differently depending on model type. For
instruct
models, reasoning and token projection are coupled — the caveman prompt constrains the format of the reasoning chain
itself. For thinking models, they are already separated: internal reasoning runs in hidden token space, and the system
prompt applies only to the visible output. This is why verbose CoT instructions degrade thinking models — they attempt
to guide a reasoning process that has already been internalized, while doing nothing productive with the token
projection. The thinking model results, discussed below, provide the cleaner evidence for this principle.

We cannot distinguish the two hypotheses from benchmark results alone. This is an open question for future
interpretability work.

***

## The Thinking Model Results

The instruct results raise a natural question: does the same logic hold when the model has its own built-in reasoning
process? The same 6 conditions were run on `qwen3-235b-a22b-thinking-2507` (n=1319, full dataset):

| Condition               | No-thinking | IC 95%      | Thinking   | IC 95%          |
|-------------------------|-------------|-------------|------------|-----------------|
| No Prompt               | 94.84%      | [93.5–95.9] | 83.70%     | [81.6–85.6] ↓↓↓ |
| Default CoT             | 95.07%      | [93.8–96.1] | 88.40%     | [86.6–90.0] ↓   |
| Caveman                 | 95.45%      | [94.2–96.4] | 86.66%     | [84.7–88.4] ↓↓  |
| Math Caveman            | 95.30%      | [94.0–96.3] | **93.71%** | [92.3–94.9]     |
| Minimalist Math Caveman | **95.75%**  | [94.5–96.7] | **94.54%** | [93.2–95.6]     |
| One-Shot                | 78.62%      | [76.3–80.7] | **94.47%** | [93.1–95.6] ↑↑↑ |

Several results stand out:

**Verbose CoT prompts significantly degrade the thinking model.** Default CoT drops 6.7pp. Classic Caveman — the most
instruction-heavy prompt — drops 8.8pp. This is consistent with the hypothesis that the thinking model has already
internalized a reasoning structure during training; external CoT instructions create competing signals.

**Minimalist prompts preserve thinking model performance.** Math Caveman (93.71%) and Minimalist Math Caveman (94.54%)
are near-parity with the no-thinking best (95.75%). The gap between thinking and no-thinking effectively closes when the
reasoning instruction is compact.

**No prompt at all is the worst configuration for the thinking model** (83.70%), despite being close to default for the
instruct model. Without any task framing, the thinking model appears to drift — the absence of even a minimal system
prompt is more disruptive for the thinking variant than for the instruct variant.

**One-Shot inverts completely**: catastrophically bad for the instruct model (78.62%) but one of the best results for
the thinking model (94.47%). The thinking model's internal reasoning compensates for the absence of explicit
chain-of-thought instructions, making brevity an asset rather than a liability.

***

## Limitations

- GSM8K is an arithmetic reasoning benchmark. Results may not generalize to code generation, logical reasoning, or
  open-ended tasks. Code benchmarks (LiveCodeBench, HumanEval+) are the natural next step.
- OpenRouter routes requests across multiple providers. Non-determinism is observed between runs due to provider-level
  sampling differences. n=1319 is sufficient to make provider variance negligible relative to condition differences, but
  results should be interpreted within Wilson CIs.
- n=1319 is a single run per condition. Multi-run averaging would further strengthen the conclusions.
- We test one model family. Generalization to other architectures (DeepSeek, Llama, Mistral) is untested.

***

## Conclusion

For arithmetic-style reasoning tasks: a caveman or minimalist math caveman prompt on a non-thinking instruct model
offers the best cost-performance tradeoff — equivalent accuracy to standard CoT with 55–61% fewer tokens and ~2× lower
latency. For thinking models, avoid detailed reasoning instructions and prefer concise task framing. Having no system
prompt at all is the worst configuration for both efficiency and performance.
