# Mathematician Caveman Chain-Of-Thoughts go brrrrrt

> why use many token when few token do trick

A benchmark testing compressed chain-of-thought prompting strategies against standard and thinking LLM modes on GSM8K.

## What is this?

This project benchmarks the hypothesis that forcing an LLM to reason in compressed "caveman" language — minimal English
fragments + mathematical symbols (→ ∵ ∴ ✓ ✗) — produces equivalent or better reasoning accuracy with significantly fewer
output tokens.

Key findings on GSM8K (n=1319, `qwen3-235b-a22b-2507`, no-thinking mode):

| Strategy                | Accuracy   | Completion tokens | vs. Default | Speedup   |
|-------------------------|------------|-------------------|-------------|-----------|
| Default CoT             | 95.07%     | 299,405           | —           | ×1        |
| No Prompt               | 94.84%     | 292,249           | −2.4%       | ×1.04     |
| Minimalist Math Caveman | **95.45%** | 215,689           | −28.0%      | ×1.33     |
| Math Caveman            | 95.30%     | 136,631           | −54.4%      | ×2.09     |
| **Caveman**             | **95.45%** | **117,104**       | **−60.9%**  | **×2.03** |
| One-Shot (↯ cliff)      | 78.62%     | 85,276            | −71.5%      | —         |

The cliff is sharp: Caveman at −61% tokens maintains full accuracy; One-Shot at −72% collapses 16.8pp.

See [article.md](article.md) for full results including the thinking model comparison.

## Quick Start

```bash
git clone https://github.com/VincentChalnot/mathematician-caveman-cot
cd mathematician-caveman-cot
# Create .env with your model identifiers and API key:
# MODEL=openrouter/qwen/qwen3-235b-a22b-2507
# THINKING_MODEL=openrouter/qwen/qwen3-235b-a22b-thinking-2507
# OPENAI_API_KEY=sk-or-...
docker compose up
```

## Configuration

Edit `config.yaml` to adjust benchmark options and task prompts:

```yaml
gsm8k_prompt: |

  Final line always: '#### [number only]'

options:
  num_samples: 2000
  concurrency: 20
  benchmark: gsm8k

tasks:
  - name: My Prompt
    output_name: my_prompt
    prompt: "Your system prompt here."
```

The `gsm8k_prompt` string is appended to every task prompt. API credentials are loaded from `.env` via `python-dotenv`.
Required env vars: `MODEL`, `THINKING_MODEL`.

Each task runs twice in parallel: once with `MODEL` (saved under `results/no_thinking/`) and once with
`THINKING_MODEL` (saved under `results/thinking/`).

## Prompts

All prompts are defined inline in `config.yaml`. The four caveman variants tested:

**Caveman** — general-purpose compressed style:

```
Respond terse like smart caveman. All technical substance stay. Only fluff die.
Drop: articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging.
Fragments OK. Short synonyms (big not extensive, fix not "implement a solution for"). Technical terms exact. Code blocks unchanged. Errors quoted exact.
Pattern: [thing] [action] [reason]. [next step].

Not: "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by..."
Yes: "Bug in auth middleware. Token expiry check use < not <=. Fix:"

Drop caveman only for: security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread. Resume caveman after.

Code blocks: write normal. "stop caveman" or "normal mode": revert.
```

**Math Caveman** — with explicit symbol legend:

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
```

**Minimalist Math Caveman** — condensed 3-line version:

```
You mathematician caveman: No filler. Fragments. No prose. Short synonyms. Reasoning symbols ∵, →, ↔, ∈, ∉, ✓, ✗
Technical terms exact. Code blocks unchanged. Errors quoted exact.
Reason: <r> 1.[step] 2.[step] → [conclusion] </r>
```

## Results

Results are saved to `results/[variant]/[output_name].json` — one JSON file per task per variant, with per-sample
predictions, accuracy, latency, and token counts.

Run `python compare.py` to aggregate all JSON files into `results.csv`.

## Reproducibility note

OpenRouter routes requests across multiple providers. Even at temperature=0, non-determinism is observed between runs
due to provider-level sampling differences. n=1319 (full GSM8K test set) is sufficient to make provider variance
negligible relative to condition differences.

## Requirements

- Docker + Docker Compose
- OpenRouter API key (or compatible OpenAI-API endpoint)

## License

GPLv3. See [LICENSE](LICENSE) for details.
