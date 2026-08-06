#!/usr/bin/env bash
# cribl-version.sh
# Report the installed Cribl Edge DaemonSet version across all kube contexts.

set -uo pipefail

# ---- Configuration (override via environment) -------------------------------
NAMESPACE="${CRIBL_NAMESPACE:-cribl}"
DAEMONSET="${CRIBL_DAEMONSET:-cribl-edge}"
TIMEOUT="${KUBECTL_TIMEOUT:-15s}"
LOG="${LOG_FILE:-$(date +%Y%m%d-%H%M)-cribl-version-check.log}"

usage() {
  cat <<EOF
Usage: ${0##*/} [-h]

Checks every kube context for the Cribl Edge DaemonSet and reports its version.

Environment overrides:
  CRIBL_NAMESPACE  Namespace to look in          (default: cribl)
  CRIBL_DAEMONSET  DaemonSet to inspect          (default: cribl-edge)
  KUBECTL_TIMEOUT  Per-request timeout           (default: 15s)
  LOG_FILE         Output log file               (default: <date>-<HHMM>-cribl-version-check.log)
EOF
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

command -v kubectl >/dev/null 2>&1 || {
  echo "ERROR: kubectl not found in PATH" >&2
  exit 1
}

# ---- Collect contexts -------------------------------------------------------
mapfile -t CONTEXTS < <(kubectl config get-contexts -o name | sort -u)

if [[ ${#CONTEXTS[@]} -eq 0 ]]; then
  echo "ERROR: no kube contexts found" >&2
  exit 1
fi

: > "$LOG"

checked=0
installed=0
not_found=0
errors=0
declare -A RESULTS

# log writes to both stdout and the log file
log() { printf '%s\n' "$*" | tee -a "$LOG"; }

log "======================================================"
log " Cribl Edge Version Check"
log " Namespace      : $NAMESPACE"
log " DaemonSet      : $DAEMONSET"
log " Total contexts : ${#CONTEXTS[@]}"
log "======================================================"

for ctx in "${CONTEXTS[@]}"; do
  checked=$((checked + 1))
  log "Checking context: $ctx"

  # Verify the Cribl namespace exists in this context.
  ns_out=$(kubectl --context "$ctx" --request-timeout="$TIMEOUT" get ns "$NAMESPACE" -o name 2>&1)
  ns_rc=$?
  if [[ $ns_rc -ne 0 ]]; then
    if echo "$ns_out" | grep -qiE "not found|notfound"; then
      log "  NOT-FOUND (namespace '$NAMESPACE' does not exist)"
      RESULTS["$ctx"]="NOT-FOUND"
      not_found=$((not_found + 1))
      continue
    fi

    log "  ERROR: failed to query context: $ctx"
    log "         kubectl: $ns_out"
    RESULTS["$ctx"]="ERROR"
    errors=$((errors + 1))
    continue
  fi

  # Read version from the DaemonSet's app.kubernetes.io/version label.
  ds_out=$(kubectl --context "$ctx" --request-timeout="$TIMEOUT" \
    get daemonset "$DAEMONSET" -n "$NAMESPACE" \
    -o "jsonpath={.metadata.labels['app\.kubernetes\.io/version']}" 2>&1)
  ds_rc=$?
  if [[ $ds_rc -ne 0 ]]; then
    if echo "$ds_out" | grep -qiE "not found|notfound"; then
      log "  NOT-FOUND (DaemonSet '$DAEMONSET' not installed)"
      RESULTS["$ctx"]="NOT-FOUND"
      not_found=$((not_found + 1))
      continue
    fi

    log "  ERROR: failed to query context: $ctx"
    log "         kubectl: $ds_out"
    RESULTS["$ctx"]="ERROR"
    errors=$((errors + 1))
    continue
  fi

  version=$(printf '%s' "$ds_out" | tr -d '\r\n' | xargs)
  if [[ -z "$version" ]]; then
    log "  NOT-FOUND (no app.kubernetes.io/version label found)"
    RESULTS["$ctx"]="NOT-FOUND"
    not_found=$((not_found + 1))
  else
    log "  ✅ Version: $version"
    RESULTS["$ctx"]="$version"
    installed=$((installed + 1))
  fi
done

# ---- Summary ----------------------------------------------------------------
log ""
log " Cribl Versions:"
while IFS= read -r ctx; do
  log "$(printf '  %-55s %s' "$ctx:" "${RESULTS[$ctx]}")"
done < <(printf '%s\n' "${!RESULTS[@]}" | sort)

log ""
log " Checked: $checked | Installed: $installed | Not-found: $not_found | Errors: $errors"
log " Log: $LOG"

# Exit non-zero if any context errored, so CI/automation can detect failures.
[[ $errors -eq 0 ]]

