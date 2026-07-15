#!/usr/bin/env python3
"""Normalize **Test:** paths in OpenSpec specs from **Verify:** heuristics."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPECS = ROOT / "openspec" / "changes"


def infer_test(req: str, verify: str) -> str:
    req_id = req.split(":")[0].removeprefix("REQ-").lower()

    m = re.search(r"tests/chainsaw/[^\s`'\"]+", verify)
    if m:
        return m.group(0).rstrip(").,")

    m = re.search(r"hack/(?:smoke|demo|scorecard)/[^\s`'\"]+", verify)
    if m:
        return m.group(0).rstrip(").,")

    m = re.search(r"go test \S+", verify)
    if m:
        return m.group(0).replace(" ", "")

    if "tofu test" in verify:
        m = re.search(r"-filter=tests/(\S+)", verify)
        if m:
            return f"modules/labels/tests/{m.group(1)}.tftest.hcl"
        return f"modules/labels/tests/{req_id}.tftest.hcl"

    if "conftest" in verify or "task test:policy" in verify:
        return f"tests/policy/{req_id}.rego"

    if ".github/workflows/" in verify:
        m = re.search(r"\.github/workflows/[^\s`'\"]+", verify)
        if m:
            return f"tests/meta/{req_id}-workflow.yaml"

    if "manual review" in verify.lower():
        return f"tests/meta/{req_id}-checklist.md"

    if "task test:spec" in verify or "rg '**Verify:**'" in verify:
        return "hack/verify-spec-coverage.sh"

    if "task --list" in verify:
        return "tests/meta/task-targets.sh"

    if "task test:chainsaw" in verify or verify.strip().startswith("chainsaw test"):
        return "tests/chainsaw/chainsaw-test.yaml"

    if "task test:load" in verify or "k6 run" in verify:
        return "tests/load/marshal-threshold.js"

    if "task test:scorecard" in verify:
        return "hack/scorecard/capture.sh"

    if "task test:smoke:e1" in verify:
        return "tests/smoke/e1-exit.sh"

    if "task demo" in verify:
        return "hack/demo/mulligan.sh"

    if "envtest" in verify.lower() or "internal/controller" in verify:
        return f"internal/controller/{req_id}_test.go"

    return f"tests/smoke/{req_id}.sh"


def process_file(path: Path) -> None:
    text = path.read_text()
    parts = re.split(r"(^## REQ-[^\n]+)", text, flags=re.MULTILINE)
    if len(parts) < 2:
        return
    out = [parts[0]]
    for i in range(1, len(parts), 2):
        header = parts[i]
        body = parts[i + 1] if i + 1 < len(parts) else ""
        req = header.removeprefix("## ").strip()
        # Non-destructive: never overwrite an existing **Test:** — only backfill.
        if re.search(r"^\*\*Test:\*\* ", body, flags=re.MULTILINE):
            out.append(header + body)
            continue
        vm = re.search(r"^\*\*Verify:\*\* (.+)$", body, flags=re.MULTILINE)
        if not vm:
            out.append(header + body)
            continue
        verify = vm.group(1).strip()
        test_path = infer_test(req, verify)
        if re.search(r"^\*\*Then\*\* ", body, flags=re.MULTILINE):
            body = re.sub(
                r"(^\*\*Then\*\* .+$)",
                rf"\1\n**Test:** `{test_path}`",
                body,
                count=1,
                flags=re.MULTILINE,
            )
        else:
            body = f"\n**Test:** `{test_path}`\n" + body.lstrip("\n")
        out.append(header + body)
    path.write_text("".join(out))


def main() -> None:
    for spec in sorted(SPECS.glob("*/specs/*/*.md")):
        process_file(spec)
    print("Normalized Test paths in OpenSpec specs.")


if __name__ == "__main__":
    main()
