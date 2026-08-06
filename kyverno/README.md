# Kyverno Version Check

This folder contains a script to report installed Kyverno component versions across Kubernetes contexts.

## Script

- `kyverno-versions.sh`

## What the script does

For each context from `kubectl config get-contexts -o name`:

1. Queries namespace `kyverno` by default.
2. Selects Deployments by label selector `app.kubernetes.io/part-of=kyverno`.
3. Determines each component version using this order:
   - `app.kubernetes.io/version`
   - `helm.sh/chart`
   - first container image tag
4. Prints per-context results and a final summary.
5. Writes runtime logs to a timestamped log file.

## Output states

- `Components:` followed by one line per component (`- <deployment>: <version>`): One or more Kyverno components were found and versioned.
- `NOT-FOUND (namespace/components not found)`: Namespace does not exist or query target is missing.
- `NOT-FOUND (no deployments matched selector)`: Namespace exists, but no matching Kyverno Deployments were found.
- `NOT-FOUND (components returned but versions unavailable)`: Components were returned but no version could be derived.
- `ERROR`: Kubernetes query failed for reasons other than not found.

## Prerequisites

- Bash shell
- `kubectl` installed and available in PATH
- Valid kubeconfig with accessible contexts
- RBAC permissions to:
  - get deployments in namespace `kyverno`

## Usage

Run from repo root:

```bash
bash kyvero/kyverno-versions.sh
```

Run from folder:

```bash
cd kyvero
bash kyverno-versions.sh
```

Optional environment overrides:

```bash
KYVERNO_NAMESPACE=kyverno KYVERNO_LABEL_SELECTOR='app.kubernetes.io/part-of=kyverno' KUBECTL_TIMEOUT=30s LOG_FILE=my-kyverno-check.log bash kyvero/kyverno-versions.sh
```

## Log file

Default log filename format:

- `YYYYMMDD-HHMM-kyverno-versions.log`

The script truncates/creates the selected log file at startup.

## Notes

- The script currently checks all contexts in kubeconfig.
- The default namespace is `kyverno`, but it can be overridden with `KYVERNO_NAMESPACE`.
- The default selector is `app.kubernetes.io/part-of=kyverno`, but it can be overridden with `KYVERNO_LABEL_SELECTOR`.
- The summary includes checked, with-components, not-found, and error counts.
- The script exits non-zero when one or more context queries return an error.


#mmc-k8s
#k8s

