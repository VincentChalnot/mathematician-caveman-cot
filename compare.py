#!/usr/bin/env python3
import csv
import json
from datetime import datetime
from pathlib import Path

results_dir = Path("./results")
rows = []

for json_path in sorted(results_dir.rglob("*.json")):
    data = json.loads(json_path.read_text())
    s = data["summary"]
    started = datetime.fromisoformat(s["started_at"])
    finished = datetime.fromisoformat(s["finished_at"])
    total_duration = finished - started
    index = str(json_path.with_suffix(""))
    rows.append(
        {
            "index": index,
            "task": s["task"],
            "model": s["model"],
            "n_samples": s["n_samples"],
            "n_correct": s["n_correct"],
            "accuracy": s["accuracy"],
            "mean_latency_ms": s["mean_latency_ms"],
            "total_prompt_tokens": s["total_prompt_tokens"],
            "total_completion_tokens": s["total_completion_tokens"],
            "started_at": s["started_at"],
            "finished_at": s["finished_at"],
            "total_duration": str(total_duration),
        }
    )

out_path = Path("./results.csv")
with open(out_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)

print(f"Wrote {len(rows)} rows to {out_path.resolve()}")
