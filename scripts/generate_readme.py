#!/usr/bin/env python3
"""Scan the repository and regenerate README.md from discovered scripts and tools."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parent.parent
README_PATH = ROOT / "README.md"

SCAN_DIRS = ("bin", "go", "cribl", "komodor", "kyverno")
SKIP_NAMES = {".DS_Store", ".gitkeep"}
SKIP_SUFFIXES = {".pyc"}

SKIP_SCAN_FILES = {"BUILD.md", "functions.txt", "README.md"}

ENV_SPECIFIC = {"backup.sh", "github-INFRA"}

ENV_DESCRIPTIONS = {
    "backup.sh": "Backs up Documents, media, dotfiles, and config to an external USB volume.",
    "backup": "Backs up Documents, media, dotfiles, and config to an external USB volume.",
    "github-INFRA": "Clones Harvard LTS *-INFRA Git repositories into a local APPS-INFRA folder.",
}

TOOL_DESCRIPTIONS = {
    "aws-list": "List running EC2 instances with ID, name, state, and private IP.",
    "biggest_files": "Find the largest files in a directory.",
    "cert-list": "List ACM certificates with optional detail and expired-only filtering.",
    "cribl-version": "Report the installed Cribl Edge DaemonSet version across all kube contexts.",
    "delete-pods": "Delete all pods scheduled on a given Kubernetes node.",
    "export-secrets": "Export Kubernetes secrets to per-namespace YAML files.",
    "export-GW": "Export gateway configuration (pre-built binary).",
    "find_alb": "Find the ALB and target group registered to an EC2 instance ID.",
    "get-kubectl": "Download and install kubectl for Linux or macOS.",
    "get-ns-secrets": "List Kubernetes namespaces and optionally export secrets to YAML.",
    "gen-passwd": "Interactive password generator with letters, symbols, and numbers.",
    "get_versions_v12": "Audit platform component versions across kubectl contexts.",
    "komodor-version": "Report the installed Komodor agent chart version across all kube contexts.",
    "kyverno-versions": "Report installed Kyverno component versions across all kube contexts.",
    "list-alb": "List Application Load Balancers (name, ARN, and count).",
    "list-rds": "List RDS instances filtered by database engine.",
}

CATEGORY_ORDER = (
    "aws",
    "cribl",
    "komodor",
    "kubernetes",
    "kyverno",
    "general",
    "environment",
)

CATEGORY_TITLES = {
    "aws": "AWS utilities",
    "cribl": "Cribl utilities",
    "komodor": "Komodor utilities",
    "kyverno": "Kyverno utilities",
    "kubernetes": "Kubernetes utilities",
    "general": "General utilities",
    "environment": "Environment-specific scripts",
}

PATH_CATEGORY_HINTS = {
    "bin/aws": "aws",
    "bin/kubernetes": "kubernetes",
    "bin/komodor": "komodor",
    "cribl": "cribl",
    "komodor": "komodor",
    "kyvero": "kyverno",
}

NAME_CATEGORY_HINTS = {
    "aws-list": "aws",
    "cert-list": "aws",
    "find_alb": "aws",
    "list-alb": "aws",
    "list-rds": "aws",
    "delete-pods": "kubernetes",
    "delete_pods": "kubernetes",
    "export-secrets": "kubernetes",
    "export-gw": "kubernetes",
    "get-kubectl": "kubernetes",
    "get-ns-secrets": "kubernetes",
    "get_versions": "kubernetes",
    "gen-passwd": "general",
    "biggest_files": "general",
    "backup": "environment",
    "github-infra": "environment",
    "cribl-version": "cribl",
    "komodor-version": "komodor",
    "kyverno-versions": "kyverno",
}


@dataclass
class Tool:
    path: Path
    rel_path: str
    name: str
    kind: str
    category: str
    description: str = ""
    usage_lines: list[str] = field(default_factory=list)
    source_path: str | None = None
    is_binary: bool = False


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def is_probably_binary(path: Path) -> bool:
    try:
        with path.open("rb") as fh:
            chunk = fh.read(8192)
        if b"\0" in chunk:
            return True
    except OSError:
        return False
    return False


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def first_comment_description(text: str) -> str:
    lines = text.splitlines()
    start = 0
    if lines and lines[0].startswith("#!"):
        start = 1

    skip_prefixes = (
        "v0.",
        "v1.",
        "v2.",
        "v03",
        "v04",
        "version",
        "disable the aws cli",
        "export aws_pager",
        "colors for output",
        "logging configuration",
    )
    skip_patterns = (
        re.compile(r"^v?\d+\.\d+", re.I),
        re.compile(r"\\033\["),
        re.compile(r"^(red|green|yellow|blue|nc)='", re.I),
    )

    collected: list[str] = []
    for line in lines[start : start + 40]:
        stripped = line.strip()
        if not stripped:
            if collected:
                break
            continue
        if stripped.startswith("#"):
            body = stripped.lstrip("#").strip()
            lower = body.lower()
            if any(lower.startswith(prefix) for prefix in skip_prefixes):
                continue
            if any(
                token in lower
                for token in (
                    "alternate screen",
                    "aws_pager",
                    "usage function",
                    "check for aws cli",
                    "check for aws credentials",
                    "check for",
                    "parse arguments",
                    "get script name",
                )
            ):
                continue
            if any(pattern.search(body) for pattern in skip_patterns):
                continue
            if lower.startswith("usage"):
                break
            if body.startswith("=") or body.startswith("-"):
                continue
            if lower.startswith(("options:", "arguments:", "examples:", "flags:")):
                continue
            collected.append(body)
        elif collected:
            break

    if not collected:
        return ""

    desc = " ".join(collected[:2]).strip()
    desc = re.sub(r"\s+", " ", desc)
    # Drop trailing "Usage:" fragments occasionally captured from inline comments.
    desc = re.split(r"\s+Usage:?\s*", desc, maxsplit=1)[0].strip()
    return desc[:240]


def score_description_candidate(text: str) -> int:
    lower = text.lower()
    score = min(len(text), 120)
    positive = (
        "list",
        "export",
        "delete",
        "install",
        "generate",
        "find",
        "fetch",
        "report",
        "backup",
        "clone",
        "search",
        "password",
        "certificate",
        "instance",
        "namespace",
        "secret",
        "version",
    )
    negative = (
        "error",
        "check for",
        "credentials",
        "usage:",
        "-->",
        "==>>",
        "going to",
        "creating",
        "determine log",
        "fix:",
        "hint:",
    )
    for word in positive:
        if word in lower:
            score += 20
    for word in negative:
        if word in lower:
            score -= 40
    return score


def fallback_description(path: Path, text: str) -> str:
    """Infer a short description when header comments are sparse."""
    if path.suffix == ".go":
        match = re.search(r"DESCRIPTION:\s*\n\s*(.+)", text)
        if match:
            return match.group(1).strip()[:240]
        match = re.search(r"What it does:\s*\n((?:\s*- .+\n?)+)", text)
        if match:
            bullets = [
                line.strip().lstrip("- ").strip()
                for line in match.group(1).splitlines()
                if line.strip().startswith("-")
            ]
            if bullets:
                return bullets[0][:240]
        match = re.search(r'fmt\.Println\("([^"]{12,})"\)', text)
        if match:
            return match.group(1).strip()[:240]

    usage_match = re.search(
        r"Get version information from[^\n]+|"
        r"Downloads and installs kubectl[^\n]+|"
        r"produce a list of Kubernetes namespaces[^\n]+|"
        r"export Kubernetes secrets[^\n]+|"
        r"Finds a specific ALB[^\n]+|"
        r"Lists AWS Certificate Manager[^\n]+|"
        r"Lists running EC2[^\n]+|"
        r"Delete all pods[^\n]+",
        text,
        re.I,
    )
    if usage_match:
        return usage_match.group(0).strip()[:240]

    candidates: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        for pattern in (
            r'echo\s+"([^"]{12,})"',
            r'echo\s+"([^"]{12,})"\s*>\s*&2',
        ):
            echo_match = re.match(pattern, stripped)
            if echo_match:
                candidates.append(echo_match.group(1))

    if candidates:
        best = max(candidates, key=score_description_candidate)
        if score_description_candidate(best) > 0:
            return best[:240]

    return humanize_name(display_name(path))


def extract_usage_lines(text: str, limit: int = 6) -> list[str]:
    patterns = [
        r"Usage:\s*\n((?:[ \t]+[^\n]+\n?)+)",
        r"usage\(\)\s*\{[^}]*?(?:cat <<EOF|echo)\s*\n((?:[^\n]+\n)+?)(?:EOF|\")",
        r"printUsage\([^)]*\)\s*\{[^}]*?`([^`]+)`",
        r"func usage\(\)[^{]*\{[^\"]*\"([^\"]+)\"",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, re.MULTILINE | re.DOTALL)
        if match:
            block = match.group(1)
            lines = []
            for raw in block.splitlines():
                line = raw.strip()
                if not line or line.startswith("#"):
                    continue
                line = line.replace("$0", "./" + Path("tool").name)
                lines.append(line)
                if len(lines) >= limit:
                    break
            if lines:
                return lines
    return []


def infer_category(path: Path, text: str) -> str:
    rel_posix = rel(path)
    lower_name = path.name.lower()

    if path.name in ENV_SPECIFIC or lower_name in NAME_CATEGORY_HINTS and NAME_CATEGORY_HINTS[lower_name.replace(".sh", "")] == "environment":
        if "backup" in lower_name or "github-infra" in lower_name:
            return "environment"

    for prefix, category in PATH_CATEGORY_HINTS.items():
        if rel_posix.startswith(prefix + "/") or rel_posix == prefix:
            return category

    for key, category in NAME_CATEGORY_HINTS.items():
        if key in lower_name:
            return category

    lower_text = text.lower()
    aws_score = sum(1 for kw in ("aws ", " ec2", "acm", "elbv2", "rds", "amazon") if kw in lower_text)
    k8s_score = sum(1 for kw in ("kubectl", "kubernetes", "namespace", " pods", "kube-") if kw in lower_text)
    if aws_score > k8s_score and aws_score > 0:
        return "aws"
    if k8s_score > 0:
        return "kubernetes"
    if path.suffix == ".go":
        return "aws" if any(x in lower_name for x in ("alb", "rds", "aws")) else "general"
    return "general"


def detect_kind(path: Path, binary: bool) -> str:
    if binary:
        return "binary"
    if path.suffix == ".go":
        return "go"
    if path.suffix == ".sh":
        return "shell"
    if path.suffix == ".zsh":
        return "zsh"
    text = read_text(path)
    if text.startswith("#!"):
        return "script"
    if path.suffix == ".txt":
        return "text"
    return "file"


def normalized_stem(path: Path) -> str:
    name = path.name
    for suffix in (".sh", ".go"):
        if name.endswith(suffix):
            name = name[: -len(suffix)]
    return name.replace("-", "_").lower()


def find_shell_source(tool_path: Path) -> str | None:
    stem = tool_path.name.replace("-", "_")
    candidates = [
        ROOT / "bin_SHELL" / f"{tool_path.name}.sh",
        ROOT / "bin_SHELL" / f"{stem}.sh",
        ROOT / "bin_SHELL" / tool_path.name,
    ]
    for candidate in candidates:
        if candidate.exists() and candidate.is_file():
            return rel(candidate)
    return None


def find_bin_deployable(stem: str) -> str | None:
    """Return relative bin/ path if a deployable exists for a bin_SHELL stem."""
    normalized = stem.replace("-", "_").lower()
    for path in (ROOT / "bin").rglob("*"):
        if not path.is_file() or path.name in SKIP_NAMES:
            continue
        if normalized_stem(path) == normalized:
            return rel(path)
    return None


def enrich_from_source(tool: Tool, source_rel: str | None) -> None:
    if not source_rel:
        return
    source_path = ROOT / source_rel
    if not source_path.exists():
        return
    source_text = read_text(source_path)
    source_desc = fallback_description(source_path, source_text)
    if first_comment_description(source_text):
        comment_desc = first_comment_description(source_text)
        if score_description_candidate(comment_desc) > score_description_candidate(source_desc):
            source_desc = comment_desc
    source_usage = extract_usage_lines(source_text)
    if source_desc:
        tool.description = source_desc
    if source_usage:
        tool.usage_lines = source_usage


def scan_tools() -> list[Tool]:
    tools: list[Tool] = []

    for scan_dir in SCAN_DIRS:
        base = ROOT / scan_dir
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            if path.name in SKIP_NAMES or path.suffix in SKIP_SUFFIXES:
                continue
            if path.name in SKIP_SCAN_FILES:
                continue

            binary = is_probably_binary(path)
            text = "" if binary else read_text(path)
            category = infer_category(path, text)
            description = first_comment_description(text)
            usage_lines = extract_usage_lines(text)

            if not description or description.lower() == humanize_name(path.stem).lower():
                description = fallback_description(path, text)

            source = None
            if rel(path).startswith("bin/"):
                source = find_shell_source(path)
                if not source and binary:
                    go_candidate = ROOT / "go" / f"{path.stem}.go"
                    if go_candidate.exists():
                        source = rel(go_candidate)
            elif path.suffix == ".go":
                source = rel(path)

            tool = Tool(
                path=path,
                rel_path=rel(path),
                name=display_name(path),
                kind=detect_kind(path, binary),
                category=category,
                description=description,
                usage_lines=usage_lines,
                source_path=source if source != rel(path) else None,
                is_binary=binary,
            )
            enrich_from_source(tool, tool.source_path)
            apply_description_overrides(tool)
            tools.append(tool)

    return tools


def apply_description_overrides(tool: Tool) -> None:
    if tool.name in TOOL_DESCRIPTIONS:
        tool.description = TOOL_DESCRIPTIONS[tool.name]
    elif tool.path.name in ENV_DESCRIPTIONS:
        tool.description = ENV_DESCRIPTIONS[tool.path.name]


def tools_for_sections(tools: list[Tool]) -> list[Tool]:
    """Drop duplicates so bin/ deployables win over Go sources and vendor source dirs."""
    go_binary_stems = {
        normalized_stem(t.path)
        for t in tools
        if t.rel_path.startswith("bin/") and t.is_binary
    }

    # Track (subdir_name, filename) pairs that exist under bin/ so we can suppress
    # the matching source-directory copy (e.g. bin/komodor/x.sh beats komodor/x.sh).
    bin_subdir_files = {
        (t.path.parent.name, t.path.name)
        for t in tools
        if t.rel_path.startswith("bin/") and t.path.parent.name != "bin"
    }

    section_tools: list[Tool] = []
    for tool in tools:
        stem = normalized_stem(tool.path)
        if tool.rel_path.startswith("go/") and tool.path.suffix == ".go" and stem in go_binary_stems:
            continue
        if tool.path.name in SKIP_SCAN_FILES:
            continue
        # Skip source-dir scripts that have a deployable copy under bin/<subdir>/
        if (
            not tool.rel_path.startswith("bin/")
            and (tool.path.parent.name, tool.path.name) in bin_subdir_files
        ):
            continue
        section_tools.append(tool)

    return section_tools


def humanize_name(name: str) -> str:
    cleaned = name.replace("_", " ").replace("-", " ")
    return cleaned[:1].upper() + cleaned[1:]


def display_name(path: Path) -> str:
    name = path.name
    if name.endswith(".sh"):
        name = name[:-3]
    if name.endswith(".go"):
        name = name[:-3]
    return name


def scan_tree_summary() -> list[tuple[str, int, str]]:
    summaries: list[tuple[str, int, str]] = []
    descriptions = {
        "bin": "Runnable scripts and pre-built binaries",
        "go": "Go source and build notes",
        "cribl": "Cribl Edge scripts",
        "komodor": "Komodor agent scripts",
        "kyvero": "Kyverno policy engine scripts",
    }
    for scan_dir in SCAN_DIRS:
        base = ROOT / scan_dir
        if not base.exists():
            continue
        count = sum(1 for p in base.rglob("*") if p.is_file() and p.name not in SKIP_NAMES)
        summaries.append((scan_dir + "/", count, descriptions.get(scan_dir, "")))
    return summaries


def derive_prerequisites(tools: Iterable[Tool]) -> list[tuple[str, str, str]]:
    names = {t.name.lower() for t in tools}
    rel_paths = {t.rel_path.lower() for t in tools}
    prereqs: list[tuple[str, str, str]] = []

    aws_tools = [t.name for t in tools if t.category == "aws"]
    k8s_tools = [t.name for t in tools if t.category == "kubernetes"]
    go_tools = [t.name for t in tools if t.kind == "go" or t.rel_path.startswith("go/")]

    if aws_tools:
        prereqs.append(
            (
                "[AWS CLI v2](https://aws.amazon.com/cli/)",
                "AWS scripts",
                ", ".join(f"`{n}`" for n in sorted(set(aws_tools))),
            )
        )
    if k8s_tools:
        prereqs.append(
            (
                "[kubectl](https://kubernetes.io/docs/tasks/tools/)",
                "Kubernetes scripts",
                ", ".join(f"`{n}`" for n in sorted(set(k8s_tools))),
            )
        )
    if go_tools or any(t.is_binary for t in tools if t.rel_path.startswith("bin/")):
        prereqs.append(
            (
                "[Go](https://go.dev/)",
                "Building binaries from `go/`",
                ", ".join(f"`{n}`" for n in sorted(set(go_tools))) or "see Go build section",
            )
        )
    if any("get-kubectl" in n for n in names):
        prereqs.append(("`curl`", "kubectl installer", "`get-kubectl`"))
    if any("cert-list" in p for p in rel_paths):
        prereqs.append(("`python3` (optional)", "ACM expiry parsing on macOS", "`cert-list`"))

    return prereqs


def example_invocation(tool: Tool) -> str:
    path = f"./{tool.rel_path}"
    if tool.usage_lines:
        line = tool.usage_lines[0]
        if line.lower().startswith("usage:"):
            return f"{path}  # see script help"
        return line.replace("./tool", path).replace("$PROG_NAME", path)
    if tool.category == "shell":
        return f"source ./{tool.rel_path}"
    if tool.kind == "go":
        return f"go run {tool.rel_path}"
    if tool.kind == "binary":
        return path
    return path


def render_tool_section(tool: Tool) -> list[str]:
    lines = [f"### `{tool.name}` — {tool.description}", ""]

    if tool.kind != "text":
        lines.append("```bash")
        lines.append(example_invocation(tool))
        if tool.usage_lines and len(tool.usage_lines) > 1:
            for usage in tool.usage_lines[1:4]:
                lines.append(usage.replace("./tool", f"./{tool.rel_path}"))
        lines.append("```")
        lines.append("")

    meta = []
    meta.append(f"Path: [`{tool.rel_path}`]({tool.rel_path})")
    meta.append(f"Type: `{tool.kind}`")
    if tool.source_path:
        meta.append(f"Source: [`{tool.source_path}`]({tool.source_path})")
    if tool.is_binary:
        meta.append("Pre-built binary (rebuild from Go source where available)")

    lines.append(" | ".join(meta))
    lines.append("")
    return lines


def render_inventory(tools: list[Tool]) -> list[str]:
    lines = [
        "## Tool inventory",
        "",
        "Auto-generated from repository scan.",
        "",
        "| Name | Path | Category | Type | Description |",
        "|------|------|----------|------|-------------|",
    ]
    for tool in sorted(tools, key=lambda t: (CATEGORY_ORDER.index(t.category) if t.category in CATEGORY_ORDER else 99, t.rel_path)):
        desc = tool.description.replace("|", "\\|")
        if len(desc) > 80:
            desc = desc[:77] + "..."
        lines.append(
            f"| `{tool.name}` | [`{tool.rel_path}`]({tool.rel_path}) | {tool.category} | {tool.kind} | {desc} |"
        )
    lines.append("")
    return lines


def render_go_build(tools: list[Tool]) -> list[str]:
    go_files = sorted(p for p in (ROOT / "go").glob("*.go") if p.is_file()) if (ROOT / "go").exists() else []
    if not go_files:
        return []

    lines = [
        "## Building Go binaries",
        "",
        "Pre-built binaries in `bin/` may target a specific platform. Rebuild for your OS/arch:",
        "",
        "```bash",
    ]
    for go_file in go_files:
        stem = go_file.stem
        if "alb" in stem or "rds" in stem:
            out = f"bin/aws/{stem}"
        else:
            out = f"bin/{stem}"
        lines.append(f"go build -o {out} {rel(go_file)}")
    lines.append("```")
    lines.append("")
    if (ROOT / "go" / "BUILD.md").exists():
        lines.append("See [`go/BUILD.md`](go/BUILD.md) for additional notes.")
        lines.append("")
    return lines


def generate_readme(tools: list[Tool]) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    tree = scan_tree_summary()
    prereqs = derive_prerequisites(tools)

    lines: list[str] = [
        "# codeit-public",
        "",
        "Public scripts and small utilities for AWS, Kubernetes, and day-to-day ops work.",
        "",
        "> **Auto-generated** — last scanned **" + now + "**. "
        "Manual edits outside the marked block may be overwritten by the daily workflow.",
        "",
        "<!-- README:AUTO-START -->",
        "",
        "## Repository layout",
        "",
        "| Path | Files | Description |",
        "|------|------:|-------------|",
    ]

    for path, count, description in tree:
        lines.append(f"| [`{path}`]({path}) | {count} | {description} |")

    section_tools = tools_for_sections(tools)

    lines.extend(["", *render_inventory(section_tools)])

    if prereqs:
        lines.extend(["## Prerequisites", ""])
        lines.append("| Tool | Used for | Scripts |")
        lines.append("|------|----------|---------|")
        for tool_name, used_for, scripts in prereqs:
            lines.append(f"| {tool_name} | {used_for} | {scripts} |")
        lines.extend(
            [
                "",
                "Configure AWS credentials and a valid kubeconfig before running cloud scripts.",
                "",
                "---",
                "",
            ]
        )
    grouped: dict[str, list[Tool]] = {cat: [] for cat in CATEGORY_ORDER}
    for tool in section_tools:
        if tool.category not in grouped:
            grouped[tool.category] = []
        grouped[tool.category].append(tool)

    for category in CATEGORY_ORDER:
        cat_tools = sorted(grouped.get(category, []), key=lambda t: t.rel_path)
        if not cat_tools:
            continue
        lines.extend([f"## {CATEGORY_TITLES[category]}", ""])
        for tool in cat_tools:
            lines.extend(render_tool_section(tool))
        lines.append("---")
        lines.append("")

    lines.extend(render_go_build(tools))

    lines.extend(
        [
            "## Usage tips",
            "",
            "- Add `bin/`, `bin/aws/`, and `bin/kubernetes/` to your `PATH`, or symlink the tools you use.",
            "- Treat secret exports and backup output as sensitive data.",
            "",
            "<!-- README:AUTO-END -->",
            "",
        ]
    )

    return "\n".join(lines)


def main() -> int:
    tools = scan_tools()
    if not tools:
        print("No tools found during scan.", file=sys.stderr)
        return 1

    readme = generate_readme(tools)
    README_PATH.write_text(readme, encoding="utf-8")
    print(f"Wrote {README_PATH} ({len(tools)} tools scanned)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
