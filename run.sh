#!/bin/bash

set -e

export $(cat .env | xargs);

MODEL=$MODEL
THINKING_MODEL=$THINKING_MODEL
OPTIONS="-n 30 -c 10"

GSM8K_PROMPT="

Final line always: '#### [number only]'"

DEFAULT_PROMPT="You are solving a grade-school math problem. Reason step by step."

ONESHOT_PROMPT="Give only the final answer. No explanation. No steps. One line."

CAVEMAN_PROMPT="Respond terse like smart caveman. All technical substance stay. Only fluff die.
Drop: articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging.
Fragments OK. Short synonyms (big not extensive, fix not \"implement a solution for\"). Technical terms exact. Code blocks unchanged. Errors quoted exact.
Pattern: [thing] [action] [reason]. [next step].

Not: \"Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by...\"
Yes: \"Bug in auth middleware. Token expiry check use < not <=. Fix:\"

Drop caveman only for: security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread. Resume caveman after.

Code blocks: write normal. \"stop caveman\" or \"normal mode\": revert."

MATH_CAVEMAN_PROMPT="You mathematician caveman: No filler. Fragments. No prose. Short synonyms.
Technical terms exact. Code blocks unchanged. Errors quoted exact.

Math symbols compress reasoning:
∵ = because | ∴ = therefore | → = leads to | ↔ = equiv
≈ = approx | ≠ = differs | ∈ = is case of | ∉ = not applicable
✓ = valid | ✗ = rejected | ⚠ = edge case | ? = uncertain
⊕ = combine | > / < = better/worse than | (...)

<r> 1.[eq/step] 2.[eq/step] → [result] </r>

Drop caveman only for: security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread. Resume caveman after."

MINIMALIST_MATH_CAVEMAN_PROMPT="You mathematician caveman: No filler. Fragments. No prose. Short synonyms. Reasoning symbols ∵, →, ↔, ∈, ∉, ✓, ✗
Technical terms exact. Code blocks unchanged. Errors quoted exact.
Reason: <r> 1.[step] 2.[step] → [conclusion] </r>"

# NO PROMPT
echo "LAUNCHING TASKS: NO PROMPT"
P=$GSM8K_PROMPT
litebench run gsm8k -m $MODEL --system-prompt "$P" $OPTIONS --json-out results/no_thinking/no_prompt.json
litebench run gsm8k -m $THINKING_MODEL --system-prompt "$P" $OPTIONS --json-out results/thinking/no_prompt.json

# ONESHOT PROMPT
echo "LAUNCHING TASKS: ONESHOT PROMPT"
P=$ONESHOT_PROMPT$GSM8K_PROMPT
litebench run gsm8k -m $MODEL --system-prompt "$P" $OPTIONS --json-out results/no_thinking/oneshot_prompt.json
litebench run gsm8k -m $THINKING_MODEL --system-prompt "$P" $OPTIONS --json-out results/thinking/oneshot_prompt.json

# DEFAULT PROMPT
echo "LAUNCHING TASKS: DEFAULT PROMPT"
P=$DEFAULT_PROMPT$GSM8K_PROMPT
litebench run gsm8k -m $MODEL --system-prompt "$P" $OPTIONS --json-out results/no_thinking/default_prompt.json
litebench run gsm8k -m $THINKING_MODEL --system-prompt "$P" $OPTIONS --json-out results/thinking/default_prompt.json

# DEFAULT CAVEMAN
echo "LAUNCHING TASKS: DEFAULT CAVEMAN PROMPT"
P=$CAVEMAN_PROMPT$GSM8K_PROMPT
litebench run gsm8k -m $MODEL --system-prompt "$P" $OPTIONS --json-out results/no_thinking/caveman.json
litebench run gsm8k -m $THINKING_MODEL --system-prompt "$P" $OPTIONS --json-out results/thinking/caveman.json

# MATH CAVEMAN
echo "LAUNCHING TASKS: MATH CAVEMAN PROMPT"
P=$MATH_CAVEMAN_PROMPT$GSM8K_PROMPT
litebench run gsm8k -m $MODEL --system-prompt "$P" $OPTIONS --json-out results/no_thinking/math_caveman.json
litebench run gsm8k -m $THINKING_MODEL --system-prompt "$P" $OPTIONS --json-out results/thinking/math_caveman.json

# MINIMALIST MATH CAVEMAN
echo "LAUNCHING TASKS: MINIMALIST MATH CAVEMAN PROMPT"
P=$MINIMALIST_MATH_CAVEMAN_PROMPT$GSM8K_PROMPT
litebench run gsm8k -m $MODEL --system-prompt "$P" $OPTIONS --json-out results/no_thinking/minimalist_math_caveman.json
litebench run gsm8k -m $THINKING_MODEL --system-prompt "$P" $OPTIONS --json-out results/thinking/minimalist_math_caveman.json
