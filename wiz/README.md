# Wiz Version Check

This folder contains a script to check Wiz component versions across all kube contexts.

## Script

- `wiz-versions.sh`

The script reports versions for:
- `wiz-sensor`
- `wiz-admission-controller`

## How it works

For each context from `kubectl config get-contexts -o name`, the script:
1. Checks `wiz-sensor`
2. Checks `wiz-admission-controller`
3. Prints per-context status
4. Prints an all-context summary

For each component workload in a context, version is resolved in this order:
1. `app.kubernetes.io/version` label
2. `helm.sh/chart` label
3. first container image tag
4. `UNKNOWN`

The script checks named resources first and then falls back to label matching (`app.kubernetes.io/name`) if needed.

If a workload or namespace is missing, the component is reported as `NOT-FOUND`.

If a kubectl query fails for reasons other than not found, the component is reported as `ERROR` and the script exits non-zero.

## Usage

From repository root:

```bash
./wiz/wiz-versions.sh
```

## Environment overrides

- `WIZ_NAMESPACE` (default: `wiz`)
- `WIZ_SENSOR_KIND` (default: `daemonset`)
- `WIZ_ADMISSION_KIND` (default: `deployment`)
- `WIZ_SENSOR_RESOURCES` (default: `wiz-sensor,wiz-wiz-sensor`)
- `WIZ_ADMISSION_RESOURCES` (default: `wiz-admission-controller,wiz-wiz-admission-controller`)
- `KUBECTL_TIMEOUT` (default: `15s`)
- `LOG_FILE` (default: `<date>-<HHMM>-wiz-versions.log`)

Example:

```bash
WIZ_NAMESPACE=wiz KUBECTL_TIMEOUT=20s ./wiz/wiz-versions.sh

WIZ_SENSOR_RESOURCES=wiz-wiz-sensor \
WIZ_ADMISSION_RESOURCES=wiz-wiz-admission-controller \
./wiz/wiz-versions.sh
```

## Output summary

At the end of the run, the script prints:
- `Checked`: number of contexts inspected
- `With-components`: contexts where at least one Wiz component was found
- `No-components`: contexts where both components were not found
- `Errors`: number of component query errors

It also writes full output to a timestamped log file (or `LOG_FILE` if provided).

## Example output

```text
======================================================
 Wiz Version Check
 Namespace      : wiz
 Components     : wiz-sensor (daemonset), wiz-admission-controller (deployment)
 Total contexts : 3
======================================================
Checking context: cluster-a
  ✅ wiz-sensor: 1.0.10007
  ✅ wiz-admission-controller: 2.12.8

Checking context: cluster-b
  ➖ wiz-sensor: NOT-FOUND
  ➖ wiz-admission-controller: NOT-FOUND

Checking context: cluster-c
  ✅ wiz-sensor: 1.0.10010
  ❌ wiz-admission-controller: ERROR
     kubectl: <error message>

 Wiz Versions:
  cluster-a:
  - wiz-sensor: 1.0.10007
  - wiz-admission-controller: 2.12.8
  cluster-b:
  - wiz-sensor: NOT-FOUND
  - wiz-admission-controller: NOT-FOUND
  cluster-c:
  - wiz-sensor: 1.0.10010
  - wiz-admission-controller: ERROR

 Checked: 3 | With-components: 2 | No-components: 1 | Errors: 1
 Log: 20260703-1024-wiz-versions.log
```


#mmc-k8s
#k8s

