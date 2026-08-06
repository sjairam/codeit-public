#!/usr/bin/env bash
# kyverno-versions.sh
# Report installed Kyverno component versions across all kube contexts.
#
# v0.1 initial script
# v0.2 remove log timestamps and print component versions on multiple lines

set -uo pipefail

# ---- Configuration (override via environment) -------------------------------
NAMESPACE="${KYVERNO_NAMESPACE:-kyverno}"
LABEL_SELECTOR="${KYVERNO_LABEL_SELECTOR:-app.kubernetes.io/part-of=kyverno}"
TIMEOUT="${KUBECTL_TIMEOUT:-15s}"
LOG="${LOG_FILE:-$(date +%Y%m%d-%H%M)-kyverno-versions.log}"

usage() {
  cat <<EOF
Usage: ${0##*/} [-h]

Checks every kube context for Kyverno components and reports their versions.

Environment overrides:
  KYVERNO_NAMESPACE       Namespace to look in         (default: kyverno)
  KYVERNO_LABEL_SELECTOR  Deployment label selector    (default: app.kubernetes.io/part-of=kyverno)
  KUBECTL_TIMEOUT         Per-request timeout          (default: 15s)
  LOG_FILE                Output log file              (default: <date>-<HHMM>-kyverno-versions.log)
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
with_components=0
no_components=0
errors=0
declare -A RESULTS

# log writes to both stdout and the log file
log() { printf '%s\n' "$*" | tee -a "$LOG"; }

extract_version() {
  local app_ver chart image first_image image_tag

  app_ver="$1"
  chart="$2"
  image="$3"

  # Prefer explicit app version label; then chart label; finally image tag.
  if [[ -n "$app_ver" ]]; then
    printf '%s' "$app_ver"
    return
  fi

  if [[ -n "$chart" ]]; then
    printf '%s' "$chart"
    return
  fi

  first_image=$(printf '%s' "$image" | awk -F',' '{print $1}')
  if [[ "$first_image" == *":"* ]]; then
    image_tag="${first_image##*:}"
    printf '%s' "$image_tag"
    return
  fi

  printf '%s' "UNKNOWN"
}

log "======================================================"
log " Kyverno Version Check"
log " Namespace      : $NAMESPACE"
log " Label selector : $LABEL_SELECTOR"
log " Total contexts : ${#CONTEXTS[@]}"
log "======================================================"

for ctx in "${CONTEXTS[@]}"; do
  checked=$((checked + 1))
  log "Checking context: $ctx"

  out=$(kubectl --context "$ctx" --request-timeout="$TIMEOUT" \
    get deployment -n "$NAMESPACE" -l "$LABEL_SELECTOR" \
    -o "jsonpath={range .items[*]}{.metadata.name}{'|'}{.metadata.labels['app\.kubernetes\.io/version']}{'|'}{.metadata.labels['helm\.sh/chart']}{'|'}{range .spec.template.spec.containers[*]}{.image}{','}{end}{'\n'}{end}" 2>&1)
  rc=$?

  if [[ $rc -ne 0 ]]; then
    if echo "$out" | grep -qiE "not found|notfound|namespaces .* not found"; then
      log "  ➖ NOT-FOUND (namespace/components not found)"
      RESULTS["$ctx"]="NOT-FOUND"
      no_components=$((no_components + 1))
    else
      log "  ❌ ERROR: failed to query context: $ctx"
      log "         kubectl: $out"
      RESULTS["$ctx"]="ERROR"
      errors=$((errors + 1))
    fi
    continue
  fi

  normalized=$(printf '%s' "$out" | tr -d '\r' | sed '/^$/d')

  if [[ -z "$normalized" ]]; then
    log "  ➖ NOT-FOUND (no deployments matched selector)"
    RESULTS["$ctx"]="NOT-FOUND"
    no_components=$((no_components + 1))
    continue
  fi

  with_components=$((with_components + 1))
  result=""

  while IFS='|' read -r dep app_ver chart images; do
    dep=$(printf '%s' "$dep" | xargs)
    app_ver=$(printf '%s' "$app_ver" | xargs)
    chart=$(printf '%s' "$chart" | xargs)
    images=$(printf '%s' "$images" | sed 's/,$//' | xargs)

    [[ -z "$dep" ]] && continue

    version=$(extract_version "$app_ver" "$chart" "$images")

    result+="  - $dep: $version"
    result+=$'\n'
  done <<< "$normalized"

  if [[ -z "$result" ]]; then
    log "  ➖ NOT-FOUND (components returned but versions unavailable)"
    RESULTS["$ctx"]="NOT-FOUND"
    no_components=$((no_components + 1))
  else
    log "  ✅ Components:"
    while IFS= read -r line; do
      [[ -n "$line" ]] && log "$line"
    done <<< "$result"
    RESULTS["$ctx"]="${result%$'\n'}"
  fi
done

# ---- Summary ----------------------------------------------------------------
log ""
log " Kyverno Versions:"
while IFS= read -r ctx; do
  if [[ "${RESULTS[$ctx]}" == "NOT-FOUND" || "${RESULTS[$ctx]}" == "ERROR" ]]; then
    log "$(printf '  %-55s %s' "$ctx:" "${RESULTS[$ctx]}")"
    continue
  fi

  log "  $ctx:"
  while IFS= read -r line; do
    [[ -n "$line" ]] && log "$line"
  done <<< "${RESULTS[$ctx]}"
done < <(printf '%s\n' "${!RESULTS[@]}" | sort)

log ""
log " Checked: $checked | With-components: $with_components | Not-found: $no_components | Errors: $errors"
log " Log: $LOG"

# Exit non-zero if any context errored, so CI/automation can detect failures.
[[ $errors -eq 0 ]]