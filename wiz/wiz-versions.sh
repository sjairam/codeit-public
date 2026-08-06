#!/usr/bin/env bash
# wiz-versions.sh
# Report Wiz component versions across all kube contexts.
#
# v0.1 initial script
# v0.2 add multi-context support and per-context summary

set -uo pipefail

# ---- Configuration (override via environment) -------------------------------
NAMESPACE="${WIZ_NAMESPACE:-wiz}"
WIZ_SENSOR_KIND="${WIZ_SENSOR_KIND:-daemonset}"
WIZ_ADMISSION_KIND="${WIZ_ADMISSION_KIND:-deployment}"
WIZ_SENSOR_RESOURCES="${WIZ_SENSOR_RESOURCES:-wiz-sensor,wiz-wiz-sensor}"
WIZ_ADMISSION_RESOURCES="${WIZ_ADMISSION_RESOURCES:-wiz-admission-controller,wiz-wiz-admission-controller}"
TIMEOUT="${KUBECTL_TIMEOUT:-15s}"
LOG="${LOG_FILE:-$(date +%Y%m%d-%H%M)-wiz-versions.log}"

usage() {
  cat <<EOF
Usage: ${0##*/} [-h]

Checks every kube context for Wiz components and reports their versions:
  - wiz-sensor
  - wiz-admission-controller

Environment overrides:
  WIZ_NAMESPACE               Namespace to look in         (default: wiz)
  WIZ_SENSOR_KIND             Sensor workload kind         (default: daemonset)
  WIZ_ADMISSION_KIND          Admission workload kind      (default: deployment)
  WIZ_SENSOR_RESOURCES        Sensor resource names        (default: wiz-sensor,wiz-wiz-sensor)
  WIZ_ADMISSION_RESOURCES     Admission resource names     (default: wiz-admission-controller,wiz-wiz-admission-controller)
  KUBECTL_TIMEOUT             Per-request timeout          (default: 15s)
  LOG_FILE                    Output log file              (default: <date>-<HHMM>-wiz-versions.log)
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
  local app_ver chart image image_tag

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

  if [[ "$image" == *":"* ]]; then
    image_tag="${image##*:}"
    printf '%s' "$image_tag"
    return
  fi

  printf '%s' "UNKNOWN"
}

check_component() {
  local ctx="$1"
  local kind="$2"
  local resources_csv="$3"
  local label_name="$4"
  local out rc normalized version resource candidates candidate
  local app_ver chart image

  COMPONENT_STATUS=""
  COMPONENT_VALUE=""

  IFS=',' read -r -a candidates <<< "$resources_csv"

  out=""
  resource=""
  for candidate in "${candidates[@]}"; do
    candidate=$(printf '%s' "$candidate" | xargs)
    [[ -z "$candidate" ]] && continue

    out=$(kubectl --context "$ctx" --request-timeout="$TIMEOUT" \
      get "$kind" "$candidate" -n "$NAMESPACE" \
      -o "jsonpath={.metadata.name}|{.metadata.labels['app\\.kubernetes\\.io/version']}|{.metadata.labels['helm\\.sh/chart']}|{.spec.template.spec.containers[0].image}" 2>&1)
    rc=$?

    if [[ $rc -eq 0 ]]; then
      resource="$candidate"
      break
    fi

    if ! echo "$out" | grep -qiE "not found|notfound|namespaces .* not found"; then
      COMPONENT_STATUS="ERROR"
      COMPONENT_VALUE="$out"
      return
    fi
  done

  if [[ -z "$resource" ]]; then
    out=$(kubectl --context "$ctx" --request-timeout="$TIMEOUT" \
      get "$kind" -n "$NAMESPACE" -l "app.kubernetes.io/name=$label_name" \
      -o "jsonpath={range .items[0]}{.metadata.name}|{.metadata.labels['app\\.kubernetes\\.io/version']}|{.metadata.labels['helm\\.sh/chart']}|{.spec.template.spec.containers[0].image}{end}" 2>&1)
    rc=$?

    if [[ $rc -ne 0 ]]; then
      if echo "$out" | grep -qiE "not found|notfound|namespaces .* not found"; then
        COMPONENT_STATUS="NOT-FOUND"
        COMPONENT_VALUE=""
      else
        COMPONENT_STATUS="ERROR"
        COMPONENT_VALUE="$out"
      fi
      return
    fi
  fi

  normalized=$(printf '%s' "$out" | tr -d '\r\n' | xargs)

  if [[ -z "$normalized" ]]; then
    COMPONENT_STATUS="NOT-FOUND"
    COMPONENT_VALUE=""
    return
  fi

  IFS='|' read -r app_ver chart image <<< "$normalized"
  if [[ "$normalized" == *"|"*"|"*"|"* ]]; then
    IFS='|' read -r _ app_ver chart image <<< "$normalized"
  fi
  app_ver=$(printf '%s' "$app_ver" | xargs)
  chart=$(printf '%s' "$chart" | xargs)
  image=$(printf '%s' "$image" | xargs)

  version=$(extract_version "$app_ver" "$chart" "$image")

  COMPONENT_STATUS="FOUND"
  COMPONENT_VALUE="$version"
}

log "======================================================"
log " Wiz Version Check"
log " Namespace      : $NAMESPACE"
log " Components     : wiz-sensor ($WIZ_SENSOR_KIND), wiz-admission-controller ($WIZ_ADMISSION_KIND)"
log " Total contexts : ${#CONTEXTS[@]}"
log "======================================================"

for ctx in "${CONTEXTS[@]}"; do
  checked=$((checked + 1))
  log "Checking context: $ctx"

  ctx_has_component=0

  check_component "$ctx" "$WIZ_SENSOR_KIND" "$WIZ_SENSOR_RESOURCES" "wiz-sensor"
  sensor_status="$COMPONENT_STATUS"
  sensor_value="$COMPONENT_VALUE"

  if [[ "$sensor_status" == "FOUND" ]]; then
    log "  ✅ wiz-sensor: $sensor_value"
    sensor_display="$sensor_value"
    ctx_has_component=1
  elif [[ "$sensor_status" == "NOT-FOUND" ]]; then
    log "  ➖ wiz-sensor: NOT-FOUND"
    sensor_display="NOT-FOUND"
  else
    log "  ❌ wiz-sensor: ERROR"
    log "     kubectl: $sensor_value"
    sensor_display="ERROR"
    errors=$((errors + 1))
  fi

  check_component "$ctx" "$WIZ_ADMISSION_KIND" "$WIZ_ADMISSION_RESOURCES" "wiz-admission-controller"
  admission_status="$COMPONENT_STATUS"
  admission_value="$COMPONENT_VALUE"

  if [[ "$admission_status" == "FOUND" ]]; then
    log "  ✅ wiz-admission-controller: $admission_value"
    admission_display="$admission_value"
    ctx_has_component=1
  elif [[ "$admission_status" == "NOT-FOUND" ]]; then
    log "  ➖ wiz-admission-controller: NOT-FOUND"
    admission_display="NOT-FOUND"
  else
    log "  ❌ wiz-admission-controller: ERROR"
    log "     kubectl: $admission_value"
    admission_display="ERROR"
    errors=$((errors + 1))
  fi

  if [[ $ctx_has_component -eq 1 ]]; then
    with_components=$((with_components + 1))
  else
    no_components=$((no_components + 1))
  fi

  RESULTS["$ctx"]="  - wiz-sensor: $sensor_display
  - wiz-admission-controller: $admission_display"
done

log ""
log " Wiz Versions:"
while IFS= read -r ctx; do
  log "  $ctx:"
  while IFS= read -r line; do
    [[ -n "$line" ]] && log "$line"
  done <<< "${RESULTS[$ctx]}"
done < <(printf '%s\n' "${!RESULTS[@]}" | sort)

log ""
log " Checked: $checked | With-components: $with_components | No-components: $no_components | Errors: $errors"
log " Log: $LOG"

# Exit non-zero if any component query errored, so CI/automation can detect failures.
[[ $errors -eq 0 ]]
