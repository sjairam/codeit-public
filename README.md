# codeit-public

Public scripts and small utilities for AWS, Kubernetes, shell configuration, and day-to-day ops work.

> **Auto-generated** — last scanned **2026-07-29 15:35:39 UTC**. Manual edits outside the marked block may be overwritten by the daily workflow.

<!-- README:AUTO-START -->

## Repository layout

| Path | Files | Description |
|------|------:|-------------|
| [`bin/`](bin/) | 12 | Runnable scripts and pre-built binaries |
| [`bin_SHELL/`](bin_SHELL/) | 8 | Editable shell script sources |
| [`go/`](go/) | 4 | Go source and build notes |
| [`zsh/`](zsh/) | 10 | Zsh configuration fragments and functions |

## Tool inventory

Auto-generated from repository scan.

| Name | Path | Category | Type | Description |
|------|------|----------|------|-------------|
| `aws-list` | [`bin/aws/aws-list`](bin/aws/aws-list) | aws | script | List running EC2 instances with ID, name, state, and private IP. |
| `cert-list` | [`bin/aws/cert-list`](bin/aws/cert-list) | aws | script | List ACM certificates with optional detail and expired-only filtering. |
| `list-alb` | [`bin/aws/list-alb`](bin/aws/list-alb) | aws | binary | List Application Load Balancers (name, ARN, and count). |
| `list-rds` | [`bin/aws/list-rds`](bin/aws/list-rds) | aws | binary | List RDS instances filtered by database engine. |
| `aws-list` | [`bin_SHELL/aws-list.sh`](bin_SHELL/aws-list.sh) | aws | shell | List running EC2 instances with ID, name, state, and private IP. |
| `cert-list` | [`bin_SHELL/cert-list.sh`](bin_SHELL/cert-list.sh) | aws | shell | List ACM certificates with optional detail and expired-only filtering. |
| `find_alb` | [`bin_SHELL/find_alb.sh`](bin_SHELL/find_alb.sh) | aws | shell | Find the ALB and target group registered to an EC2 instance ID. |
| `list-alb` | [`go/list-alb.go`](go/list-alb.go) | aws | go | List Application Load Balancers (name, ARN, and count). |
| `list-rds` | [`go/list-rds.go`](go/list-rds.go) | aws | go | List RDS instances filtered by database engine. |
| `get-kubectl` | [`bin/get-kubectl`](bin/get-kubectl) | kubernetes | script | Download and install kubectl for Linux or macOS. |
| `get-ns-secrets` | [`bin/get-ns-secrets`](bin/get-ns-secrets) | kubernetes | script | List Kubernetes namespaces and optionally export secrets to YAML. |
| `github-TOOLS` | [`bin/github-TOOLS`](bin/github-TOOLS) | kubernetes | script | Elapsed time: $elapsed_minutes minutes and $elapsed_seconds seconds |
| `delete-pods` | [`bin/kubernetes/delete-pods`](bin/kubernetes/delete-pods) | kubernetes | script | Delete all pods scheduled on a given Kubernetes node. |
| `export-GW` | [`bin/kubernetes/export-GW`](bin/kubernetes/export-GW) | kubernetes | binary | Export gateway configuration (pre-built binary). |
| `export-secrets` | [`bin/kubernetes/export-secrets`](bin/kubernetes/export-secrets) | kubernetes | script | Export Kubernetes secrets to per-namespace YAML files. |
| `delete_pods` | [`bin_SHELL/delete_pods.sh`](bin_SHELL/delete_pods.sh) | kubernetes | shell | Delete all pods that are scheduled on a specific node. |
| `get-kubectl` | [`bin_SHELL/get-kubectl.sh`](bin_SHELL/get-kubectl.sh) | kubernetes | shell | Download and install kubectl for Linux or macOS. |
| `get_versions_v12` | [`bin_SHELL/get_versions_v12.sh`](bin_SHELL/get_versions_v12.sh) | kubernetes | shell | Audit platform component versions across kubectl contexts. |
| `gen-passwd` | [`bin/gen-passwd`](bin/gen-passwd) | general | binary | Interactive password generator with letters, symbols, and numbers. |
| `biggest_files` | [`bin_SHELL/biggest_files.sh`](bin_SHELL/biggest_files.sh) | general | shell | Find the largest files in a directory. |
| `gen-passwd` | [`go/gen-passwd.go`](go/gen-passwd.go) | general | go | Interactive password generator with letters, symbols, and numbers. |
| `00-zshrc` | [`zsh/00-zshrc`](zsh/00-zshrc) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `10-zshrc-aliases` | [`zsh/10-zshrc-aliases`](zsh/10-zshrc-aliases) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `100-zshrc-newAWS-path` | [`zsh/100-zshrc-newAWS-path`](zsh/100-zshrc-newAWS-path) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `1000-zshrc` | [`zsh/1000-zshrc`](zsh/1000-zshrc) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `20-zshrc-path` | [`zsh/20-zshrc-path`](zsh/20-zshrc-path) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `30-zshrc-functions` | [`zsh/30-zshrc-functions`](zsh/30-zshrc-functions) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `40-zshrc-sshkeys` | [`zsh/40-zshrc-sshkeys`](zsh/40-zshrc-sshkeys) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `50-zshrc-istios` | [`zsh/50-zshrc-istios`](zsh/50-zshrc-istios) | shell | file | If you come from bash you might have to change your $PATH. export PATH=$HOME/... |
| `fino-time.zsh` | [`zsh/themes/fino-time.zsh`](zsh/themes/fino-time.zsh) | shell | zsh | fino-time.zsh-theme |
| `github-INFRA` | [`bin/github-INFRA`](bin/github-INFRA) | environment | script | Clones Harvard LTS *-INFRA Git repositories into a local APPS-INFRA folder. |
| `backup` | [`bin_SHELL/backup.sh`](bin_SHELL/backup.sh) | environment | shell | Backs up Documents, media, dotfiles, and config to an external USB volume. |

## Prerequisites

| Tool | Used for | Scripts |
|------|----------|---------|
| [AWS CLI v2](https://aws.amazon.com/cli/) | AWS scripts | `aws-list`, `cert-list`, `find_alb`, `list-alb`, `list-rds` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Kubernetes scripts | `delete-pods`, `delete_pods`, `export-GW`, `export-secrets`, `get-kubectl`, `get-ns-secrets`, `get_versions_v12`, `github-TOOLS` |
| [Go](https://go.dev/) | Building binaries from `go/` | `gen-passwd`, `list-alb`, `list-rds` |
| `curl` | kubectl installer | `get-kubectl` |
| `python3` (optional) | ACM expiry parsing on macOS | `cert-list` |

Configure AWS credentials and a valid kubeconfig before running cloud scripts.

---

## AWS utilities

### `aws-list` — List running EC2 instances with ID, name, state, and private IP.

```bash
./bin/aws/aws-list
```

Path: [`bin/aws/aws-list`](bin/aws/aws-list) | Type: `script` | Source: [`bin_SHELL/aws-list.sh`](bin_SHELL/aws-list.sh)

### `cert-list` — List ACM certificates with optional detail and expired-only filtering.

```bash
./bin/aws/cert-list
```

Path: [`bin/aws/cert-list`](bin/aws/cert-list) | Type: `script` | Source: [`bin_SHELL/cert-list.sh`](bin_SHELL/cert-list.sh)

### `list-alb` — List Application Load Balancers (name, ARN, and count).

```bash
./bin/aws/list-alb  # see script help
Options:
-p profile   AWS CLI profile to use (optional)
-r region    AWS region to use (optional)
```

Path: [`bin/aws/list-alb`](bin/aws/list-alb) | Type: `binary` | Source: [`go/list-alb.go`](go/list-alb.go) | Pre-built binary (rebuild from Go source where available)

### `list-rds` — List RDS instances filtered by database engine.

```bash
=
```

Path: [`bin/aws/list-rds`](bin/aws/list-rds) | Type: `binary` | Source: [`go/list-rds.go`](go/list-rds.go) | Pre-built binary (rebuild from Go source where available)

### `find_alb` — Find the ALB and target group registered to an EC2 instance ID.

```bash
./bin_SHELL/find_alb.sh
```

Path: [`bin_SHELL/find_alb.sh`](bin_SHELL/find_alb.sh) | Type: `shell`

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

### `get_versions_v12` — Audit platform component versions across kubectl contexts.

```bash
./bin_SHELL/get_versions_v12.sh
```

Path: [`bin_SHELL/get_versions_v12.sh`](bin_SHELL/get_versions_v12.sh) | Type: `shell`

---

## General utilities

### `gen-passwd` — Interactive password generator with letters, symbols, and numbers.

```bash
./bin/gen-passwd
```

Path: [`bin/gen-passwd`](bin/gen-passwd) | Type: `binary` | Source: [`go/gen-passwd.go`](go/gen-passwd.go) | Pre-built binary (rebuild from Go source where available)

### `biggest_files` — Find the largest files in a directory.

```bash
./bin_SHELL/biggest_files.sh
```

Path: [`bin_SHELL/biggest_files.sh`](bin_SHELL/biggest_files.sh) | Type: `shell`

---

## Environment-specific scripts

### `github-INFRA` — Clones Harvard LTS *-INFRA Git repositories into a local APPS-INFRA folder.

```bash
./bin/github-INFRA
```

Path: [`bin/github-INFRA`](bin/github-INFRA) | Type: `script`

### `backup` — Backs up Documents, media, dotfiles, and config to an external USB volume.

```bash
./bin_SHELL/backup.sh
```

Path: [`bin_SHELL/backup.sh`](bin_SHELL/backup.sh) | Type: `shell`

---

## Shell configuration (`zsh/`)

Modular Zsh setup files (aliases, PATH, functions, SSH keys, Istio helpers).

| File | Type | Notes |
|------|------|-------|
| [`zsh/00-zshrc`](zsh/00-zshrc) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/10-zshrc-aliases`](zsh/10-zshrc-aliases) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/100-zshrc-newAWS-path`](zsh/100-zshrc-newAWS-path) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/1000-zshrc`](zsh/1000-zshrc) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/20-zshrc-path`](zsh/20-zshrc-path) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/30-zshrc-functions`](zsh/30-zshrc-functions) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/40-zshrc-sshkeys`](zsh/40-zshrc-sshkeys) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/50-zshrc-istios`](zsh/50-zshrc-istios) | file | If you come from bash you might have to change your $PATH... |
| [`zsh/themes/fino-time.zsh`](zsh/themes/fino-time.zsh) | zsh | fino-time.zsh-theme |

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
- Edit shell sources in `bin_SHELL/` first, then copy or sync into `bin/`.
- Treat secret exports and backup output as sensitive data.

<!-- README:AUTO-END -->
