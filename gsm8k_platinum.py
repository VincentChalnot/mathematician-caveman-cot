from __future__ import annotations

from collections.abc import Iterable

from datasets import load_dataset

from litebench.core.models import Sample
from litebench.tasks.gsm8k import GSM8KTask

def _gold(answer: str) -> str:
    """GSM8K stores the final number after a ``####`` marker at the end of the answer."""
    if "####" in answer:
        return answer.split("####")[-1].strip().replace(",", "")
    return answer.strip().replace(",", "")

class GSM8KPlatinumTask(GSM8KTask):
    name = "gsm8k_platinum"
    description = "Fixes the answers from the original GSM8K dataset."

    def load_samples(self, n: int | None = None, split: str = "test") -> Iterable[Sample]:
        ds = load_dataset("madrylab/gsm8k-platinum", "main", split=split, streaming=True)
        taken = 0
        for i, row in enumerate(ds):
            if n is not None and taken >= n:
                break
            yield Sample(
                id=f"gsm8k-{i}",
                input=row["question"],
                target=_gold(row["answer"]),
            )
            taken += 1
