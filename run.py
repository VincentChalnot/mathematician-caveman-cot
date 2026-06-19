#!/usr/bin/env python3
import datetime
import os
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed

import yaml
from dotenv import load_dotenv


def sanitize_model_name(name: str) -> str:
    """Replace all non-alphanumeric characters with underscores."""
    return re.sub(r"[^a-zA-Z0-9-]", "_", name)


def load_config(path="config.yaml"):
    with open(path) as f:
        return yaml.safe_load(f)


def run_task(task, variant, model_name, benchmark, num_samples,
             concurrency, gsm8k_prompt):
    label = task["name"]
    output_name = task["output_name"]
    prompt = task["prompt"]
    system_prompt = (prompt + gsm8k_prompt) if prompt else gsm8k_prompt

    sanitized_model_name = sanitize_model_name(model_name)
    current_datetime = datetime.datetime.now().strftime("%Y-%m-%dT%H%M%S")
    out_path = f"results/{sanitized_model_name}/{output_name}/{current_datetime}.json"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    cmd = [
        "litebench", "run", benchmark,
        "-m", model_name,
        "--system-prompt", system_prompt,
        "-n", str(num_samples),
        "-c", str(concurrency),
        "--json-out", out_path,
    ]
    print(f"  Running [{variant}] {label}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    return label, variant, result


def main():
    load_dotenv()

    config = load_config()

    model = os.environ["MODEL"]
    thinking_model = os.environ["THINKING_MODEL"]

    opts = config["options"]
    gsm8k_prompt = config["gsm8k_prompt"]
    benchmark = opts["benchmark"]
    num_samples = opts["num_samples"]
    concurrency = opts["concurrency"]

    print(f"RUNNING BENCHMARK: {benchmark} with {num_samples} samples, concurrency={concurrency}")
    print(f"No thinking model: {model}")
    print(f"Thinking model: {thinking_model}")

    futures = {}
    with ThreadPoolExecutor(max_workers=12) as executor:
        for task in config["tasks"]:
            for variant, m in [("no_thinking", model), ("thinking", thinking_model)]:
                future = executor.submit(
                    run_task, task, variant,
                    m, benchmark, num_samples, concurrency, gsm8k_prompt,
                )
                futures[future] = (task["name"], variant)

        for future in as_completed(futures):
            label, variant, result = future.result()
            status = "OK" if result.returncode == 0 else f"FAIL ({result.returncode})"
            print(f"\n[{status}] {label} [{variant}]")
            if result.stdout.strip():
                print(result.stdout.strip())
            if result.stderr.strip():
                print(result.stderr.strip())


if __name__ == "__main__":
    main()
