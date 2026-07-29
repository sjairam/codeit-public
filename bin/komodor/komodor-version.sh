#!/usr/bin/env bash
# komodor-version.sh.sh
# Report the installed Komodor agent chart version across all kube contexts.
#
# v0.1 change H script
# v0.2 change kubectl
# v0.3 add output
# v0.4 add timestamps for logs
# v0.5 add request timeout, strict mode, single-pass version lookup,
#      configurable namespace/deployment, richer summary; remove stray `end`

set -uo pipefail

# ---- Configuration (override via environment) -------------------------------
NAMESPACE="${KOMODOR_NAMESPACE:-komodor}"
DEPLOYMENT="${KOMODOR_DEPLOYMENT:-agent-komodor-agent}"
TIMEOUT="${KUBECTL_TIMEOUT:-15s}"
LOG="${LOG_FILE:-$(date +%Y%m%d)-komodor-versions.log}"

usage() {
  cat <<EOF
Usage: ${0##*/} [-h]

Checks every kube context for the Komodor agent and reports its chart version.

Environment overrides:
  KOMODOR_NAMESPACE   Namespace to look in         (default: komodor)
  KOMODOR_DEPLOYMENT  Deployment to inspect        (default: agent-komodor-agent)
  KUBECTL_TIMEOUT     Per-request timeout          (default: 15s)
  LOG_FILE            Output log file              (default: <date>-komodor-versions.log)
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
log() { echo "$@" | tee -a "$LOG"; }

log "======================================================"
log " Komodor Version Check"
log " Namespace      : $NAMESPACE"
log " Deployment     : $DEPLOYMENT"
log " Total contexts : ${#CONTEXTS[@]}"
log "======================================================"

for ctx in "${CONTEXTS[@]}"; do
  checked=$((checked + 1))
  log "[$(date -Is)] Checking context: $ctx"

  # Single query: the chart version lives on the deployment's helm.sh/chart label.
  out=$(kubectl --context "$ctx" --request-timeout="$TIMEOUT" \
    get deployment "$DEPLOYMENT" -n "$NAMESPACE" \
    -o "jsonpath={.metadata.labels['helm\.sh/chart']}" 2>&1)
  rc=$?

  if [[ $rc -ne 0 ]]; then
    if echo "$out" | grep -qiE "not found|notfound"; then
      log "  ➖ NOT-FOUND (Komodor agent not installed)"
      RESULTS["$ctx"]="NOT-FOUND"
      not_found=$((not_found + 1))
    else
      log "  ❌ ERROR: failed to query context: $ctx"
      log "         kubectl: $out"
      RESULTS["$ctx"]="ERROR"
      errors=$((errors + 1))
    fi
    continue
  fi

  version=$(printf '%s' "$out" | tr -d '\r\n' | xargs)

  if [[ -z "$version" ]]; then
    log "  ➖ NOT-FOUND (no helm.sh/chart version label)"
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
log " Komodor Versions:"
while IFS= read -r ctx; do
  log "$(printf '  %-55s %s' "$ctx:" "${RESULTS[$ctx]}")"
done < <(printf '%s\n' "${!RESULTS[@]}" | sort)

log ""
log " Checked: $checked | Installed: $installed | Not-found: $not_found | Errors: $errors"
log " Log: $LOG"

# Exit non-zero if any context errored, so CI/automation can detect failures.
[[ $errors -eq 0 ]]
