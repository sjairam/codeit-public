# codeit-public

Public scripts and small utilities for AWS, Kubernetes, and day-to-day ops work.

> **Auto-generated** — last scanned **2026-11-26 16:21:49 UTC**. Manual edits outside the marked block may be overwritten by the daily workflow.

<!-- README:AUTO-START -->

## Repository layout

| Path | Files | Description |
|------|------:|-------------|
| [`bin/`](bin/) | 9 | Runnable scripts and pre-built binaries |
| [`go/`](go/) | 4 | Go source and build notes |

## Tool inventory

Auto-generated from repository scan.

| Name | Path | Category | Type | Description |
|------|------|----------|------|-------------|
| `list-alb` | [`bin/aws/list-alb`](bin/aws/list-alb) | aws | binary | List Application Load Balancers (name, ARN, and count). |
| `list-secrets` | [`bin/aws/list-secrets`](bin/aws/list-secrets) | aws | script | 01 - initial - jairams 02 - Add AWS CLI check |
| `list-rds` | [`go/list-rds.go`](go/list-rds.go) | aws | go | List RDS instances filtered by database engine. |
| `get-kubectl` | [`bin/get-kubectl`](bin/get-kubectl) | kubernetes | script | Download and install kubectl for Linux or macOS. |
| `get-ns-secrets` | [`bin/get-ns-secrets`](bin/get-ns-secrets) | kubernetes | script | List Kubernetes namespaces and optionally export secrets to YAML. |
| `github-TOOLS` | [`bin/github-TOOLS`](bin/github-TOOLS) | kubernetes | script | Elapsed time: $elapsed_minutes minutes and $elapsed_seconds seconds |
| `delete-pods` | [`bin/kubernetes/delete-pods`](bin/kubernetes/delete-pods) | kubernetes | script | Delete all pods scheduled on a given Kubernetes node. |
| `export-GW` | [`bin/kubernetes/export-GW`](bin/kubernetes/export-GW) | kubernetes | binary | Export gateway configuration (pre-built binary). |
| `export-secrets` | [`bin/kubernetes/export-secrets`](bin/kubernetes/export-secrets) | kubernetes | script | Export Kubernetes secrets to per-namespace YAML files. |
| `gen-passwd` | [`bin/gen-passwd`](bin/gen-passwd) | general | binary | Interactive password generator with letters, symbols, and numbers. |

## Prerequisites

| Tool | Used for | Scripts |
|------|----------|---------|
| [AWS CLI v2](https://aws.amazon.com/cli/) | AWS scripts | `list-alb`, `list-rds`, `list-secrets` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Kubernetes scripts | `delete-pods`, `export-GW`, `export-secrets`, `get-kubectl`, `get-ns-secrets`, `github-TOOLS` |
| [Go](https://go.dev/) | Building binaries from `go/` | `gen-passwd`, `list-alb`, `list-rds` |
| `curl` | kubectl installer | `get-kubectl` |

Configure AWS credentials and a valid kubeconfig before running cloud scripts.

---

## AWS utilities

### `list-alb` — List Application Load Balancers (name, ARN, and count).

```bash
./bin/aws/list-alb  # see script help
Options:
-p profile   AWS CLI profile to use (optional)
-r region    AWS region to use (optional)
```

Path: [`bin/aws/list-alb`](bin/aws/list-alb) | Type: `binary` | Source: [`go/list-alb.go`](go/list-alb.go) | Pre-built binary (rebuild from Go source where available)

### `list-secrets` — 01 - initial - jairams 02 - Add AWS CLI check

```bash
./bin/aws/list-secrets
```

Path: [`bin/aws/list-secrets`](bin/aws/list-secrets) | Type: `script`

### `list-rds` — List RDS instances filtered by database engine.

```bash
=
```

Path: [`go/list-rds.go`](go/list-rds.go) | Type: `go`

---

## Kubernetes utilities

### `get-kubectl` — Download and install kubectl for Linux or macOS.

```bash
./bin/get-kubectl
```

Path: [`bin/get-kubectl`](bin/get-kubectl) | Type: `script` | Source: [`bin_SHELL/get-kubectl.sh`](bin_SHELL/get-kubectl.sh)

### `get-ns-secrets` — List Kubernetes namespaces and optionally export secrets to YAML.

```bash
./bin/get-ns-secrets
```

Path: [`bin/get-ns-secrets`](bin/get-ns-secrets) | Type: `script`

### `github-TOOLS` — Elapsed time: $elapsed_minutes minutes and $elapsed_seconds seconds

```bash
./bin/github-TOOLS
```

Path: [`bin/github-TOOLS`](bin/github-TOOLS) | Type: `script`

### `delete-pods` — Delete all pods scheduled on a given Kubernetes node.

```bash
./bin/kubernetes/delete-pods
```

Path: [`bin/kubernetes/delete-pods`](bin/kubernetes/delete-pods) | Type: `script` | Source: [`bin_SHELL/delete_pods.sh`](bin_SHELL/delete_pods.sh)

### `export-GW` — Export gateway configuration (pre-built binary).

```bash
./bin/kubernetes/export-GW
```

Path: [`bin/kubernetes/export-GW`](bin/kubernetes/export-GW) | Type: `binary` | Pre-built binary (rebuild from Go source where available)

### `export-secrets` — Export Kubernetes secrets to per-namespace YAML files.

```bash
./bin/kubernetes/export-secrets
```

Path: [`bin/kubernetes/export-secrets`](bin/kubernetes/export-secrets) | Type: `script`

---

## General utilities

### `gen-passwd` — Interactive password generator with letters, symbols, and numbers.

```bash
./bin/gen-passwd
```

Path: [`bin/gen-passwd`](bin/gen-passwd) | Type: `binary` | Source: [`go/gen-passwd.go`](go/gen-passwd.go) | Pre-built binary (rebuild from Go source where available)

---

## Building Go binaries

Pre-built binaries in `bin/` may target a specific platform. Rebuild for your OS/arch:

```bash
go build -o bin/gen-passwd go/gen-passwd.go
go build -o bin/aws/list-alb go/list-alb.go
go build -o bin/aws/list-rds go/list-rds.go
```

See [`go/BUILD.md`](go/BUILD.md) for additional notes.

## Usage tips

- Add `bin/`, `bin/aws/`, and `bin/kubernetes/` to your `PATH`, or symlink the tools you use.
- Treat secret exports and backup output as sensitive data.

<!-- README:AUTO-END -->
