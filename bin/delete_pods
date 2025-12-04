#!/usr/bin/env bash
# v0.1 initial
# v0.2 HD ip
# v03 paramaterise IP
# v04 fix mapfile variables
set -euo pipefail

# Delete all pods that are scheduled on a specific node.
# Usage:
#   ./delete_pods.sh NODE_NAME [--fast]
#
# - NODE_NAME: Kubernetes node name to match (required)
# - --fast: use force/zero grace and don't wait

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 NODE_NAME [--fast]" >&2
  exit 1
fi

NODE_NAME="$1"
FAST_MODE="${2:-}"

echo "Finding pods on node: ${NODE_NAME} ..." >&2

# Get list of namespace and pod names for pods on the node
PODS_LIST=$(kubectl get pods \
  --all-namespaces \
  --field-selector "spec.nodeName=${NODE_NAME}" \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')

if [[ -z "${PODS_LIST}" ]]; then
  echo "No pods found on node ${NODE_NAME}. Nothing to delete." >&2
  exit 0
fi

PODS_COUNT=$(printf "%s" "${PODS_LIST}" | grep -c . || true)
echo "Pods to delete: ${PODS_COUNT}" >&2

DELETE_ARGS=(delete pod)
if [[ "${FAST_MODE}" == "--fast" ]]; then
  # Aggressive deletion: zero grace, force, and don't wait
  DELETE_ARGS+=(--grace-period=0 --force --wait=false)
fi

errors=0
while IFS=$'\t' read -r ns pod; do
  if [[ -z "${ns:-}" || -z "${pod:-}" ]]; then
    continue
  fi
  echo "Deleting pod ${pod} in namespace ${ns} ..." >&2
  if ! kubectl "${DELETE_ARGS[@]}" "$pod" -n "$ns"; then
    echo "Failed to delete ${ns}/${pod}" >&2
    errors=$((errors+1))
  fi
done <<< "${PODS_LIST}"

if [[ $errors -gt 0 ]]; then
  echo "Completed with $errors errors." >&2
  exit 1
fi

echo "All targeted pods deleted successfully."