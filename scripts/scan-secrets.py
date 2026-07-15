#!/usr/bin/env python3
"""Reject obvious credentials before homelab documentation is committed."""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

PATTERNS = (
    ("private-key", re.compile(r"BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY")),
    ("url-userinfo", re.compile(r"https?://[^\s/:]+:[^\s/@]+@")),
    ("auth-header", re.compile(r"(?i)(?:authorization\s*:\s*(?:basic|bearer)|x-api-key\s*:)\s*[A-Za-z0-9._~+/=-]{12,}")),
    ("github-token", re.compile(r"\bgh[opusr]_[A-Za-z0-9_]{20,}\b")),
    ("api-token", re.compile(r"\b(?:sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16})\b")),
    ("secret-assignment", re.compile(
        r"(?i)\b(?:password|passwd|secret|token|api[ _-]?key|private[ _-]?key)\s*[:=]\s*[`\"']?([^\s`\"']+)"
    )),
)
PLACEHOLDERS = {"***", "<redacted>", "redacted", "changeme", "local", "none"}


def tracked_paths() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        check=True,
        text=True,
        capture_output=True,
    )
    return [Path(line) for line in result.stdout.splitlines() if line]


def main() -> int:
    findings: list[tuple[Path, int, str]] = []
    for path in tracked_paths():
        if not path.is_file() or path.suffix.lower() not in {".md", ".yaml", ".yml", ".sh", ".py", ".json", ".toml", ".env"}:
            continue
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for number, line in enumerate(lines, 1):
            for name, pattern in PATTERNS:
                match = pattern.search(line)
                if not match:
                    continue
                value = match.group(1).strip("`\"'") if match.lastindex else ""
                if name == "secret-assignment":
                    if value.lower() in PLACEHOLDERS or value.startswith(("$", "<", "{{")) or len(value) < 8:
                        continue
                    if value == "root@pam!prometheus":
                        continue
                findings.append((path, number, name))
    if findings:
        for path, number, name in findings:
            print(f"{path}:{number}: {name}")
        print(f"secret scan failed: {len(findings)} finding(s)", file=sys.stderr)
        return 1
    print("secret scan passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
