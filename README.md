# codeit-public

Public scripts and small utilities for AWS, Kubernetes, and day-to-day ops work. Most shell scripts live in `bin_SHELL/` as editable sources; runnable copies and compiled Go binaries are in `bin/`.

## Repository layout

| Path | Description |
|------|-------------|
| [`bin/`](bin/) | Runnable scripts and pre-built Go binaries (add to your `PATH` or invoke directly) |
| [`bin_SHELL/`](bin_SHELL/) | Shell script sources — edit here, then copy or symlink into `bin/` as needed |
| [`go/`](go/) | Go source for AWS helpers and a password generator; see [`go/BUILD.md`](go/BUILD.md) for build commands |

## Prerequisites

| Tool | Used by |
|------|---------|
| [AWS CLI v2](https://aws.amazon.com/cli/) | AWS scripts (`aws-list`, `cert-list`, `find_alb`, `list-alb`, `list-rds`) |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Kubernetes scripts (`delete_pods`, `get-ns-secrets`, `get_versions_v12`, `get-kubectl`) |
| [Go](https://go.dev/) | Building binaries from `go/`; `list-rds` checks for Go at runtime |
| `curl` | `get-kubectl` |
| `python3` (optional) | `cert-list` — robust ACM expiry parsing on macOS |

Configure AWS credentials (`aws configure` or environment variables) and a valid kubeconfig before running the cloud scripts.

---

## AWS utilities

### `aws-list` — List running EC2 instances

Lists running EC2 instances with Instance ID, Name tag, state, and private IP.

```bash
./bin/aws/aws-list              # default region from AWS config
./bin/aws/aws-list -r us-east-1
```

Source: [`bin_SHELL/aws-list.sh`](bin_SHELL/aws-list.sh)

### `cert-list` — List ACM certificates

Lists AWS Certificate Manager certificates with optional detail and expired-only filtering.

```bash
./bin/aws/cert-list
./bin/aws/cert-list -r us-east-1 -d          # detailed view
./bin/aws/cert-list -r us-east-1 -e          # expired only
```

Source: [`bin_SHELL/cert-list.sh`](bin_SHELL/cert-list.sh)

### `find_alb` — Find ALB for an EC2 instance

Given an EC2 instance ID, finds the Application Load Balancer and target group that instance is registered to.

```bash
./bin_SHELL/find_alb.sh i-0123456789abcdef0
```

### `list-alb` — List Application Load Balancers

Go wrapper around `aws elbv2 describe-load-balancers`. Filters to ALBs (type `application`) and prints name, ARN, and count.

```bash
./bin/aws/list-alb
./bin/aws/list-alb -p my-profile -r us-east-1
```

Source: [`go/list-alb.go`](go/list-alb.go) — rebuild with:

```bash
go build -o bin/aws/list-alb go/list-alb.go
```

### `list-rds` — List RDS instances by engine

Lists RDS instances filtered by database engine.

```bash
./bin/aws/list-rds postgres
./bin/aws/list-rds mysql
./bin/aws/list-rds oracle-ee
```

Source: [`go/list-rds.go`](go/list-rds.go) — rebuild with:

```bash
go build -o bin/aws/list-rds go/list-rds.go
```

---

## Kubernetes utilities

### `get-kubectl` — Install kubectl

Downloads and installs kubectl for Linux or macOS (`amd64` / `arm64`). Installs to `/usr/local/bin` (uses `sudo` when needed).

```bash
./bin/get-kubectl              # latest stable
./bin/get-kubectl v1.32.0
./bin/get-kubectl 1.32.0       # v prefix added automatically
```

Source: [`bin_SHELL/get-kubectl.sh`](bin_SHELL/get-kubectl.sh)

### `delete_pods` — Delete pods on a node

Deletes all pods scheduled on a given Kubernetes node.

```bash
./bin_SHELL/delete_pods.sh NODE_NAME
./bin_SHELL/delete_pods.sh NODE_NAME --fast   # force delete, zero grace period
```

Source: [`bin_SHELL/delete_pods.sh`](bin_SHELL/delete_pods.sh)

### `get-ns-secrets` — List namespaces and export secrets

Lists non-system Kubernetes namespaces (excluding Rancher `cattle-*`, `u-*`, `p-*` prefixes by default). Can output as lines, CSV, or a bash array assignment. Optionally dumps all secrets to a YAML file.

```bash
./bin/get-ns-secrets
./bin/get-ns-secrets --format csv
./bin/get-ns-secrets --format array --array-name MYNS
./bin/get-ns-secrets --save-secrets ./backups
./bin/get-ns-secrets --no-exclude-system
```

### `get_versions_v12` — Platform version audit

Reports versions of cluster platform components across all kubectl contexts (or a single context). Checks namespaces such as ArgoCD, Cribl, Datadog, Komodor, and NFS/EFS CSI drivers in `kube-system`. Supports tabular output and file logging.

```bash
./bin_SHELL/get_versions_v12.sh           # all contexts, default namespaces
./bin_SHELL/get_versions_v12.sh -t        # table view
./bin_SHELL/get_versions_v12.sh -c prod   # single context
./bin_SHELL/get_versions_v12.sh -n argocd # single namespace
```

Edit `NAMESPACES_TO_CHECK_LIST` at the top of the script to add or remove namespaces.

Source: [`bin_SHELL/get_versions_v12.sh`](bin_SHELL/get_versions_v12.sh)

---

## General utilities

### `biggest_files` — Find largest files in a directory

```bash
./bin_SHELL/biggest_files.sh /path/to/dir
./bin_SHELL/biggest_files.sh /path/to/dir 50   # top 50 files
```

Source: [`bin_SHELL/biggest_files.sh`](bin_SHELL/biggest_files.sh)

### `gen-passwd` — Interactive password generator

Prompts for counts of letters, symbols, and numbers, then generates a shuffled password.

```bash
./bin/gen-passwd
go run go/gen-passwd.go
```

Source: [`go/gen-passwd.go`](go/gen-passwd.go) — rebuild with:

```bash
go build -o bin/gen-passwd go/gen-passwd.go
```

---

## Environment-specific scripts

These scripts contain hard-coded local paths and are included for reference. Review and edit before use on your machine.

| Script | Purpose |
|--------|---------|
| [`bin_SHELL/backup.sh`](bin_SHELL/backup.sh) | Backs up Documents, Pictures, Movies, Desktop, and dotfiles (`~/.kube`, `~/.ssh`, `~/.aws`, etc.) to an external USB volume |
| [`bin/github-INFRA`](bin/github-INFRA) | Clones Harvard LTS `*-INFRA` Git repositories into `~/GITHUB/harvard/APPS-INFRA` |

---

## Building Go binaries

Pre-built binaries in `bin/` target **macOS arm64**. To rebuild for your platform:

```bash
go build -o bin/aws/list-alb  go/list-alb.go
go build -o bin/aws/list-rds  go/list-rds.go
go build -o bin/gen-passwd    go/gen-passwd.go
```

See [`go/BUILD.md`](go/BUILD.md) for additional notes.

## Usage tips

- Add `bin/` and `bin/aws/` to your `PATH`, or create symlinks to the tools you use regularly.
- Shell sources in `bin_SHELL/` are the canonical versions for editing; some `bin/` copies may include small runtime tweaks (for example, `AWS_PAGER=""` in `bin/aws/aws-list`).
- Scripts that touch secrets (`get-ns-secrets`, `backup.sh`) should be run with care — treat exported YAML and backup directories as sensitive.
