# Komodor Version Check

This folder contains a script to report the installed Komodor agent chart version across Kubernetes contexts.

## Script

- `komodor-version.sh`

## What the script does

For each context from `kubectl config get-contexts -o name`:

1. Queries workload `agent-komodor-agent` of kind `deployment` in namespace `komodor` by default.
2. Reads the version from label:
   - `helm.sh/chart`
3. Prints per-context results and a final summary.
4. Writes runtime logs to a timestamped log file.

## Output states

- `Version: <value>`: Komodor agent chart version label was found.
- `NOT-FOUND (Komodor agent not installed as <name> [<kind>])`: Target workload was not found in the target namespace.
- `NOT-FOUND (no helm.sh/chart version label)`: Target workload exists, but the version label is missing.
- `ERROR`: Kubernetes query failed for reasons other than not found.

## Prerequisites

- Bash shell
- `kubectl` installed and available in PATH
- Valid kubeconfig with accessible contexts
- RBAC permissions to:
  - get the target workload kind (default: deployments) in namespace `komodor`

## Usage

Run from repo root:

```bash
bash komodor/komodor-version.sh
```

Run from folder:

```bash
cd komodor
bash komodor-version.sh
```

Optional environment overrides:

```bash
KOMODOR_NAMESPACE=komodor KOMODOR_KIND=deployment KOMODOR_DEPLOYMENT=agent-komodor-agent KUBECTL_TIMEOUT=30s LOG_FILE=my-komodor-check.log bash komodor/komodor-version.sh
```

## Log file

Default log filename format:

- `YYYYMMDD-HHMM-komodor-versions.log`

The script truncates/creates the selected log file at startup.

## Notes

- The script currently checks all contexts in kubeconfig.
- The default namespace is `komodor`, but it can be overridden with `KOMODOR_NAMESPACE`.
- The default workload kind is `deployment`, but it can be overridden with `KOMODOR_KIND`.
- The default workload name is `agent-komodor-agent`, but it can be overridden with `KOMODOR_DEPLOYMENT`.
- The summary includes checked, installed, not-found, and error counts.
- The script exits non-zero when one or more context queries return an error.

#mmc-k8s
#k8s

