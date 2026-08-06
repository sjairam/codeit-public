# Cribl Version Check

This folder contains a script to report the installed Cribl Edge version across Kubernetes contexts.

## Script

- `cribl-version.sh`

## What the script does

For each context from `kubectl config get-contexts -o name`:

1. Checks whether namespace `cribl` exists.
2. If namespace exists, queries DaemonSet `cribl-edge` in namespace `cribl`.
3. Reads the version from label:
   - `app.kubernetes.io/version`
4. Prints per-context results and a final summary.
5. Writes runtime logs to a timestamped log file.

## Output states

- `Version: <value>`: Cribl Edge version label was found.
- `NOT-FOUND (namespace 'cribl' does not exist)`: Cribl namespace is missing.
- `NOT-FOUND (cribl-edge DaemonSet not installed)`: Namespace exists, workload missing.
- `NOT-FOUND (cribl-edge not installed or no version label)`: DaemonSet query returned no version label.
- `ERROR-context-query`: Kubernetes query failed for reasons other than not found.

## Prerequisites

- Bash shell
- `kubectl` installed and available in PATH
- Valid kubeconfig with accessible contexts
- RBAC permissions to:
  - get namespaces
  - get daemonsets in namespace `cribl`

## Usage

Run from repo root:

```bash
bash cribl/cribl-version.sh
```

Run from folder:

```bash
cd cribl
bash cribl-version.sh
```

Optional log filename override:

```bash
LOG_FILE=my-cribl-check.log bash cribl/cribl-version.sh
```

## Log file

Default log filename format:

- `YYYYMMDD-HHMM-cribl-version-check.log`

The script truncates/creates the selected log file at startup.

## Notes

- The script currently checks all contexts in kubeconfig.
- The script tracks query errors in the summary, but does not force a non-zero exit code when errors occur.
- Results are summarized by context at the end of execution.


#mmc-k8s
#k8s