#!/usr/bin/env bash
# v1.1 Add EFS driver
# v1.2 Add logging

set -euo pipefail

# Colors for output (optional, will work even if terminal doesn't support)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging configuration
# Get script name without path and extension for subfolder naming
SCRIPT_NAME=$(basename "$0" .sh)

# Determine log directory based on LOG_IN_CURRENT_DIR environment variable
if [[ "${LOG_IN_CURRENT_DIR:-false}" == "true" ]]; then
  # Create logs in current folder where script is executed
  BASE_LOG_DIR="${LOG_DIR:-$(pwd)/logs}"
else
  # Default to home logs directory
  BASE_LOG_DIR="${LOG_DIR:-${HOME}/logs}"
fi

# Create logs subdirectory named after the script
LOG_DIR="${BASE_LOG_DIR}/${SCRIPT_NAME}"
mkdir -p "$LOG_DIR"

LOG_FILE="${LOG_FILE:-${LOG_DIR}/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log}"

# Logging function
log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local log_entry="[${timestamp}] [${level}] ${message}"
  
  # Write to log file
  echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
  
  # Write to console with appropriate color
  case "$level" in
    "INFO")
      echo -e "${GREEN}${log_entry}${NC}"
      ;;
    "WARN")
      echo -e "${YELLOW}${log_entry}${NC}"
      ;;
    "ERROR")
      echo -e "${RED}${log_entry}${NC}" >&2
      ;;
    "DEBUG")
      if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${log_entry}"
      fi
      ;;
    *)
      echo "$log_entry"
      ;;
  esac
}

# Variable list of namespaces/services to check
# Add or remove namespaces here to control what the script checks
# Note: "kube-system" will check for NFS and EFS CSI driver pods
NAMESPACES_TO_CHECK_LIST=("argocd" "cribl" "datadog" "komodor" "kube-system" )

# Service name mappings (optional - for display purposes)
# Using functions for bash 3.2 compatibility (associative arrays require bash 4+)
get_service_name() {
  local ns="$1"
  case "$ns" in
    "argocd")
      echo "ArgoCD"
      ;;
    "cribl")
      echo "Cribl edge"
      ;;
    "datadog")
      echo "Datadog"
      ;;
    "komodor")
      echo "Komodor agent"
      ;;
    "kube-system")
      echo "NFS/EFS CSI Driver"
      ;;
    *)
      echo "$ns"
      ;;
  esac
}

# Pod name filters for each namespace (optional - for version detection)
get_pod_name_filter() {
  local ns="$1"
  case "$ns" in
    "cribl")
      echo "cribl-edge"
      ;;
    "komodor")
      echo "komodor-agent"
      ;;
    "argocd")
      echo "argocd-server|argocd-repo-server"
      ;;
    "datadog")
      echo "datadog-agent|datadog-cluster-agent"
      ;;
    "kube-system")
      echo "csi-nfs|nfs-csi|efs-csi|csi-efs"
      ;;
    *)
      echo ""
      ;;
  esac
}

NAMESPACE=""
CHECK_ALL_CONTEXTS=true
CONTEXT=""
TABLE_MODE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n NAMESPACE] [-c CONTEXT] [-t] [-h]

Get version information from pods in specified namespaces.
By default, loops through all Kubernetes contexts and checks namespaces defined in NAMESPACES_TO_CHECK_LIST variable.

Options:
  -n NAMESPACE  Namespace to search (default: checks komodor, argocd, datadog, and kube-system)
  -c CONTEXT    Check only this specific context (disables all-context loop)
  -t            Display results in tabular format (context, komodor version, argo version, datadog version, nfs/efs csi version)
  -h            Show this help and exit

Environment Variables:
  LOG_DIR       Base directory for log files (default: ~/logs)
                Logs are stored in a subfolder named after the script (e.g., ~/logs/get_versionsv11/)
  LOG_FILE      Full path to log file (default: LOG_DIR/SCRIPT_NAME/SCRIPT_NAME_YYYYMMDD_HHMMSS.log)
  LOG_IN_CURRENT_DIR  Set to "true" to create logs in current directory (default: false)
  DEBUG         Set to "true" to enable debug logging (default: false)

Examples:
  $(basename "$0")                    # Check all contexts for komodor, argocd, datadog, and NFS/EFS CSI driver
  $(basename "$0") -t                 # Show tabular format with all contexts
  $(basename "$0") -c my-context      # Check only my-context for all namespaces
  $(basename "$0") -n komodor         # Check all contexts in komodor namespace only
  $(basename "$0") -n argocd          # Check all contexts in argocd namespace only
  $(basename "$0") -n datadog         # Check all contexts in datadog namespace only
  $(basename "$0") -n kube-system     # Check all contexts for NFS/EFS CSI driver in kube-system namespace only
  DEBUG=true $(basename "$0")         # Enable debug logging
  LOG_DIR=/tmp/logs $(basename "$0")  # Use custom log directory
  LOG_IN_CURRENT_DIR=true $(basename "$0")  # Create logs in current directory
EOF
}

# Check if kubectl is available
check_kubectl() {
  log "DEBUG" "Checking if kubectl is available"
  if ! command -v kubectl >/dev/null 2>&1; then
    log "ERROR" "kubectl is not installed or not in PATH"
    echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}" >&2
    exit 1
  fi
  log "DEBUG" "kubectl is available"
}


# Check if context is accessible
check_context() {
  local ctx="$1"
  log "DEBUG" "Checking accessibility of context: $ctx"
  if ! kubectl --context="$ctx" cluster-info >/dev/null 2>&1; then
    log "WARN" "Context '$ctx' is not accessible"
    return 1
  fi
  log "DEBUG" "Context '$ctx' is accessible"
  return 0
}

# Extract version from image tag
get_version_from_image() {
  local image="$1"
  # Extract version from image tag (e.g., komodor/agent:1.2.3 or komodor/agent:v1.2.3)
  echo "$image" | grep -oE '[:@](v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?|latest)' | sed 's/^[:@]//' || echo ""
}

# Get version from pod labels/annotations
# Note: this function is kept for backward compatibility but no longer used.
# Version resolution is now done from pre-fetched pod fields to avoid
# per-pod kubectl calls which were a major performance bottleneck.
get_version_from_pod() {
  echo ""
}

# Get version from deployment/daemonset
get_version_from_workload() {
  local workload_type="$1"
  local workload_name="$2"
  local ctx_arg="$3"
  local ns="$4"
  local version=""
  
  # Try to get version from labels
  version=$(kubectl $ctx_arg get "$workload_type" "$workload_name" -n "$ns" -o jsonpath='{.metadata.labels.app\.kubernetes\.io/version}' 2>/dev/null || echo "")
  
  if [[ -z "$version" ]]; then
    version=$(kubectl $ctx_arg get "$workload_type" "$workload_name" -n "$ns" -o jsonpath='{.metadata.labels.version}' 2>/dev/null || echo "")
  fi
  
  echo "$version"
}

# Main function to get versions for a specific namespace and context
get_versions() {
  local ctx="$1"
  local ns="$2"
  local ctx_arg=""
  local ctx_label=""
  
  if [[ -n "$ctx" ]]; then
    ctx_arg="--context=$ctx"
    ctx_label=" (context: $ctx)"
  else
    ctx_label=" (current context)"
  fi
  
  # Determine service name based on namespace
  local service_name=""
  service_name=$(get_service_name "$ns")
  
  log "INFO" "Getting ${service_name} versions from namespace: ${ns}${ctx_label}"
  echo -e "${GREEN}Getting ${service_name} versions from namespace: ${ns}${ctx_label}${NC}"
  echo ""
  
  # Check if context is accessible
  if [[ -n "$ctx" ]]; then
    if ! check_context "$ctx"; then
      log "ERROR" "Cannot access context '$ctx'"
      echo -e "${RED}Error: Cannot access context '$ctx'${NC}" >&2
      return 1
    fi
  fi
  
  # Check if namespace exists
  local ctx_arg_for_check=""
  if [[ -n "$ctx" ]]; then
    ctx_arg_for_check="--context=$ctx"
  fi
  
  log "DEBUG" "Checking if namespace '$ns' exists"
  if ! kubectl $ctx_arg_for_check get namespace "$ns" >/dev/null 2>&1; then
    log "WARN" "Namespace '$ns' does not exist in this context"
    echo -e "${YELLOW}Warning: Namespace '$ns' does not exist in this context${NC}" >&2
    return 0
  fi
  log "DEBUG" "Namespace '$ns' exists"
  
  # Get all pods in the namespace with required metadata in a single call
  log "DEBUG" "Retrieving pods from namespace '$ns'"
  pods=$(kubectl $ctx_arg get pods -n "$ns" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.ownerReferences[0].kind}{"\t"}{.metadata.ownerReferences[0].name}{"\t"}{.metadata.labels.app\.kubernetes\.io/version}{"\t"}{.metadata.labels.version}{"\t"}{.metadata.annotations.app\.kubernetes\.io/version}{"\t"}{.spec.containers[0].image}{"\n"}{end}' \
    2>/dev/null || echo "")
  
  if [[ -z "$pods" ]]; then
    log "WARN" "Could not retrieve pods from namespace '$ns'"
    echo -e "${YELLOW}Warning: Could not retrieve pods from namespace '$ns'${NC}" >&2
    return 0
  fi
  
  local pod_count=$(echo "$pods" | grep -c . || echo "0")
  log "INFO" "Retrieved $pod_count pod(s) from namespace '$ns'"
  
  echo -e "${GREEN}Pod Name${NC}\t\t\t${GREEN}Workload${NC}\t\t${GREEN}Version${NC}\t\t${GREEN}Image${NC}"
  echo "--------------------------------------------------------------------------------"
  
  processed_workloads=""
  komodor_agent_metrics_shown=false
  
  # Get pod filter pattern for this namespace
  filter_pattern=$(get_pod_name_filter "$ns")
  
  while IFS=$'\t' read -r pod_name workload_kind workload_name label_app_version label_version annot_app_version image; do
    if [[ -z "$pod_name" ]]; then
      continue
    fi
    
    # Apply pod name filter if defined for this namespace
    if [[ -n "$filter_pattern" ]]; then
      if ! echo "$pod_name" | grep -qE "$filter_pattern"; then
        continue
      fi
    fi
    
    # Skip komodor-agent-metrics pods if we've already shown one for this context
    if [[ "$pod_name" == *"komodor-agent-metrics"* ]]; then
      if [[ "$komodor_agent_metrics_shown" == true ]]; then
        continue
      fi
      komodor_agent_metrics_shown=true
    fi
    
    # Try multiple methods to get version
    version=""
    
    # Method 1: From pod labels/annotations (already fetched)
    if [[ -n "$label_app_version" ]]; then
      version="$label_app_version"
    elif [[ -n "$label_version" ]]; then
      version="$label_version"
    elif [[ -n "$annot_app_version" ]]; then
      version="$annot_app_version"
    fi
    
    # Method 2: From workload (deployment/daemonset) labels
    if [[ -z "$version" && -n "$workload_kind" && -n "$workload_name" ]]; then
      workload_key="${workload_kind}/${workload_name}"
      # Check if we've already processed this workload
      if echo "$processed_workloads" | grep -q "^${workload_key}:"; then
        # Extract version from stored string
        version=$(echo "$processed_workloads" | grep "^${workload_key}:" | cut -d: -f2-)
      else
        version=$(get_version_from_workload "$workload_kind" "$workload_name" "$ctx_arg" "$ns")
        # Store in format: "workload_key:version\n"
        processed_workloads="${processed_workloads}${workload_key}:${version}"$'\n'
      fi
    fi
    
    # Method 3: Extract from image tag
    if [[ -z "$version" ]]; then
      version=$(get_version_from_image "$image")
    fi
    
    # Format output
    if [[ -z "$version" ]]; then
      version="${YELLOW}unknown${NC}"
    fi
    
    workload_display="${workload_kind:-standalone}"
    if [[ -n "$workload_name" ]]; then
      workload_display="${workload_kind:-pod}/${workload_name}"
    fi
    
    # Truncate long names for better display
    pod_display="$pod_name"
    if [[ ${#pod_display} -gt 30 ]]; then
      pod_display="${pod_display:0:27}..."
    fi
    
    workload_display_short="$workload_display"
    if [[ ${#workload_display_short} -gt 20 ]]; then
      workload_display_short="${workload_display_short:0:17}..."
    fi
    
    image_display="$image"
    if [[ ${#image_display} -gt 40 ]]; then
      image_display="${image_display:0:37}..."
    fi
    
    printf "%-30s\t%-20s\t%-15s\t%s\n" "$pod_display" "$workload_display_short" "$version" "$image_display"
  done <<< "$pods"
  
  echo ""
  
  # Summary: Get unique versions
  echo -e "${GREEN}Summary:${NC}"
  log "DEBUG" "Extracting unique versions from namespace '$ns'"
  # If filter pattern is defined, only get versions from filtered pods
  if [[ -n "$filter_pattern" ]]; then
    # Get all pods, filter by name pattern, then extract versions from images
    unique_versions=$(kubectl $ctx_arg get pods -n "$ns" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | \
      grep -E "$filter_pattern" | \
      awk -F'\t' '{print $2}' | \
      sed -E 's/.*[:@](v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?|latest).*/\1/' | \
      sort -u | grep -v '^$' || echo "")
  else
    unique_versions=$(kubectl $ctx_arg get pods -n "$ns" -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | \
      sed -E 's/.*[:@](v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?|latest).*/\1/' | \
      sort -u | grep -v '^$' || echo "")
  fi
  
  if [[ -n "$unique_versions" ]]; then
    local version_count=$(echo "$unique_versions" | grep -c . || echo "0")
    log "INFO" "Found $version_count unique version(s) in namespace '$ns'"
    echo -e "Unique versions found:"
    echo "$unique_versions" | while read -r v; do
      if [[ -n "$v" ]]; then
        echo "  - $v"
        log "DEBUG" "Version found: $v"
      fi
    done
  else
    log "WARN" "Could not determine unique versions for namespace '$ns'"
    echo -e "${YELLOW}Could not determine unique versions${NC}"
  fi
  
  echo ""
  echo "=================================================================================="
  echo ""
}

# Wrapper function for backward compatibility
get_komodor_versions() {
  get_versions "$1" "${NAMESPACE:-komodor}"
}

# Get a single version for a namespace and context (returns version string)
get_single_version() {
  local ctx="$1"
  local ns="$2"
  local ctx_arg=""
  
  if [[ -n "$ctx" ]]; then
    ctx_arg="--context=$ctx"
  fi
  
  # Check if context is accessible
  if [[ -n "$ctx" ]]; then
    if ! check_context "$ctx" >/dev/null 2>&1; then
      echo "N/A (inaccessible)"
      return 0
    fi
  fi
  
  # Check if namespace exists
  if ! kubectl $ctx_arg get namespace "$ns" >/dev/null 2>&1; then
    echo "N/A (no namespace)"
    return 0
  fi
  
  # Get all pods in the namespace with required metadata in a single call
  pods=$(kubectl $ctx_arg get pods -n "$ns" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.ownerReferences[0].kind}{"\t"}{.metadata.ownerReferences[0].name}{"\t"}{.metadata.labels.app\.kubernetes\.io/version}{"\t"}{.metadata.labels.version}{"\t"}{.metadata.annotations.app\.kubernetes\.io/version}{"\t"}{.spec.containers[0].image}{"\n"}{end}' \
    2>/dev/null || echo "")
  
  if [[ -z "$pods" ]]; then
    echo "N/A (no pods)"
    return 0
  fi
  
  # Try to get version from first relevant pod
  local version=""
  local found_version=""
  
  while IFS=$'\t' read -r pod_name workload_kind workload_name label_app_version label_version annot_app_version image; do
    if [[ -z "$pod_name" ]]; then
      continue
    fi
    
    # Use pod name filter if defined for this namespace
    filter_pattern=$(get_pod_name_filter "$ns")
    if [[ -n "$filter_pattern" ]]; then
      if ! echo "$pod_name" | grep -qE "$filter_pattern"; then
        continue
      fi
    fi
    
    # Method 1: From pod labels/annotations (already fetched)
    if [[ -n "$label_app_version" ]]; then
      version="$label_app_version"
    elif [[ -n "$label_version" ]]; then
      version="$label_version"
    elif [[ -n "$annot_app_version" ]]; then
      version="$annot_app_version"
    else
      version=""
    fi
    
    # Method 2: From workload (deployment/daemonset) labels
    if [[ -z "$version" && -n "$workload_kind" && -n "$workload_name" ]]; then
      version=$(get_version_from_workload "$workload_kind" "$workload_name" "$ctx_arg" "$ns")
    fi
    
    # Method 3: Extract from image tag
    if [[ -z "$version" && -n "$image" ]]; then
      version=$(get_version_from_image "$image")
    fi
    
    if [[ -n "$version" ]]; then
      found_version="$version"
      break
    fi
  done <<< "$pods"
  
  # If no version found from preferred pods, try any pod
  if [[ -z "$found_version" ]]; then
    while IFS=$'\t' read -r pod_name workload_kind workload_name label_app_version label_version annot_app_version image; do
      if [[ -z "$pod_name" ]]; then
        continue
      fi
      
      # Method 1: From pod labels/annotations (already fetched)
      if [[ -n "$label_app_version" ]]; then
        version="$label_app_version"
      elif [[ -n "$label_version" ]]; then
        version="$label_version"
      elif [[ -n "$annot_app_version" ]]; then
        version="$annot_app_version"
      else
        version=""
      fi
      
      if [[ -z "$version" && -n "$workload_kind" && -n "$workload_name" ]]; then
        version=$(get_version_from_workload "$workload_kind" "$workload_name" "$ctx_arg" "$ns")
      fi
      
      if [[ -z "$version" && -n "$image" ]]; then
        version=$(get_version_from_image "$image")
      fi
      
      if [[ -n "$version" ]]; then
        found_version="$version"
        break
      fi
    done <<< "$pods"
  fi
  
  if [[ -z "$found_version" ]]; then
    echo "N/A"
  else
    echo "$found_version"
  fi
}

# Helper function to write table lines to both stdout and log file
table_log() {
  local line="$1"
  # Remove color codes for log file
  local line_clean=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
  # Write to stdout (with colors if present)
  echo "$line"
  # Write to log file (without colors)
  echo "$line_clean" >> "$LOG_FILE" 2>/dev/null || true
}

# Display versions in tabular format
show_table() {
  log "DEBUG" "Entering show_table function"
  check_kubectl
  
  # Get all contexts
  log "DEBUG" "Retrieving all Kubernetes contexts"
  contexts=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && contexts+=("$line")
  done < <(kubectl config get-contexts -o name 2>/dev/null || true)
  
  if [[ ${#contexts[@]} -eq 0 ]]; then
    log "ERROR" "No Kubernetes contexts found"
    echo -e "${RED}Error: No Kubernetes contexts found${NC}" >&2
    exit 1
  fi
  
  log "INFO" "Found ${#contexts[@]} context(s) for table display"
  
  # Build table header dynamically based on NAMESPACES_TO_CHECK_LIST
  header="%-40s"
  header_names=("CONTEXT")
  separator="------------------------------------------------------------------------------------------------------------------------"
  for ns in "${NAMESPACES_TO_CHECK_LIST[@]}"; do
    service_name=$(get_service_name "$ns")
    # Convert to uppercase and create column header
    header_name=$(echo "$service_name" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
    header="${header} %-25s"
    header_names+=("$header_name")
    separator="${separator}-------------------------"
  done
  header="${header}\n"
  
  # Print table header to both stdout and log file
  header_line=$(printf "$header" "${header_names[@]}")
  table_log "$header_line"
  table_log "$separator"
  
  # Collect data for each context
  for ctx in "${contexts[@]}"; do
    log "DEBUG" "Collecting version data for context: $ctx"
    # Check context accessibility once per context
    if ! check_context "$ctx"; then
      log "WARN" "Context '$ctx' is inaccessible, marking as N/A"
      versions=()
      for _ns in "${NAMESPACES_TO_CHECK_LIST[@]}"; do
        versions+=("N/A (inaccessible)")
      done
      row_line=$(printf "$header" "$ctx" "${versions[@]}")
      table_log "$row_line"
      continue
    fi
    
    versions=()
    for ns in "${NAMESPACES_TO_CHECK_LIST[@]}"; do
      log "DEBUG" "Getting version for namespace '$ns' in context '$ctx'"
      version=$(get_single_version "$ctx" "$ns")
      # Remove color codes for table display
      version_clean=$(echo "$version" | sed 's/\x1b\[[0-9;]*m//g')
      versions+=("$version_clean")
      log "DEBUG" "Version for '$ns' in '$ctx': $version_clean"
    done
    
    row_line=$(printf "$header" "$ctx" "${versions[@]}")
    table_log "$row_line"
  done
  log "DEBUG" "Table display completed"
}

# Parse command line arguments
log "DEBUG" "Parsing command line arguments"
while getopts ":n:c:th" opt; do
  case "$opt" in
    n)
      NAMESPACE="$OPTARG"
      log "DEBUG" "Namespace specified: $NAMESPACE"
      ;;
    c)
      CONTEXT="$OPTARG"
      CHECK_ALL_CONTEXTS=false
      log "DEBUG" "Context specified: $CONTEXT"
      ;;
    t)
      TABLE_MODE=true
      log "DEBUG" "Table mode enabled"
      ;;
    h)
      usage
      exit 0
      ;;
    :)
      log "ERROR" "Option -$OPTARG requires an argument"
      echo -e "${RED}Error: option -$OPTARG requires an argument${NC}" >&2
      usage
      exit 1
      ;;
    *)
      log "ERROR" "Unknown option -$OPTARG"
      echo -e "${RED}Error: unknown option -$OPTARG${NC}" >&2
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

# Determine which namespaces to check
NAMESPACES_TO_CHECK=()
if [[ -n "$NAMESPACE" ]]; then
  # User specified a namespace, check only that one
  NAMESPACES_TO_CHECK=("$NAMESPACE")
  log "INFO" "Checking single namespace: $NAMESPACE"
else
  # Default: use the variable list defined at the beginning of the script
  NAMESPACES_TO_CHECK=("${NAMESPACES_TO_CHECK_LIST[@]}")
  log "INFO" "Checking default namespaces: ${NAMESPACES_TO_CHECK[*]}"
fi

# Main execution
main() {
  # Record start time
  START_TIME=$(date +%s)
  START_TIME_READABLE=$(date '+%Y-%m-%d %H:%M:%S')
  
  log "INFO" "=========================================="
  log "INFO" "Starting get_versionv11.sh"
  log "INFO" "Log file: $LOG_FILE"
  log "INFO" "Start time: $START_TIME_READABLE"
  log "INFO" "=========================================="
  
  check_kubectl
  
  # If table mode is requested, show table and exit
  if [[ "$TABLE_MODE" == true ]]; then
    log "INFO" "Running in table mode"
    show_table
    END_TIME=$(date +%s)
    END_TIME_READABLE=$(date '+%Y-%m-%d %H:%M:%S')
    ELAPSED=$((END_TIME - START_TIME))
    log "INFO" "Execution completed"
    log "INFO" "Start time: ${START_TIME_READABLE}"
    log "INFO" "End time:   ${END_TIME_READABLE}"
    log "INFO" "Elapsed:    ${ELAPSED} second(s)"
    log "INFO" "=========================================="
    echo ""
    echo "=================================================================================="
    echo -e "${GREEN}Execution completed${NC}"
    echo -e "Start time: ${START_TIME_READABLE}"
    echo -e "End time:   ${END_TIME_READABLE}"
    echo -e "Elapsed:    ${ELAPSED} second(s)"
    echo "=================================================================================="
    exit 0
  fi
  
  if [[ "$CHECK_ALL_CONTEXTS" == true ]]; then
    # Get all contexts
    log "INFO" "Checking all contexts mode enabled"
    contexts=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && contexts+=("$line")
    done < <(kubectl config get-contexts -o name 2>/dev/null || true)
    
    if [[ ${#contexts[@]} -eq 0 ]]; then
      log "ERROR" "No Kubernetes contexts found"
      echo -e "${RED}Error: No Kubernetes contexts found${NC}" >&2
      exit 1
    fi
    
    log "INFO" "Found ${#contexts[@]} Kubernetes context(s) to check"
    log "INFO" "Checking namespaces: ${NAMESPACES_TO_CHECK[*]}"
    echo -e "${GREEN}Found ${#contexts[@]} Kubernetes context(s) to check${NC}"
    echo -e "${GREEN}Checking namespaces: ${NAMESPACES_TO_CHECK[*]}${NC}"
    echo ""
    echo "=================================================================================="
    echo ""
    
    # Loop through each context and each namespace
    for ctx in "${contexts[@]}"; do
      log "INFO" "Processing context: $ctx"
      # Check context accessibility once per context
      if ! check_context "$ctx"; then
        log "ERROR" "Cannot access context '$ctx', skipping"
        echo -e "${RED}Error: Cannot access context '$ctx'${NC}" >&2
        echo ""
        echo "--------------------------------------------------------------------------------"
        echo ""
        continue
      fi
      
      for ns in "${NAMESPACES_TO_CHECK[@]}"; do
        log "DEBUG" "Processing namespace '$ns' in context '$ctx'"
        get_versions "$ctx" "$ns" || true
      done
    done
    
    log "INFO" "Completed checking all contexts"
    echo -e "${GREEN}Completed checking all contexts${NC}"
  else
    # Check only the specified context (or current if empty) for all specified namespaces
    if [[ -n "$CONTEXT" ]]; then
      log "INFO" "Checking single context mode: $CONTEXT"
      if ! check_context "$CONTEXT"; then
        log "ERROR" "Cannot access context '$CONTEXT'"
        echo -e "${RED}Error: Cannot access context '$CONTEXT'${NC}" >&2
        exit 1
      fi
    else
      log "INFO" "Checking current context"
    fi
    
    for ns in "${NAMESPACES_TO_CHECK[@]}"; do
      log "DEBUG" "Processing namespace '$ns'"
      get_versions "$CONTEXT" "$ns" || true
    done
  fi
  
  # Record end time and display timing information
  END_TIME=$(date +%s)
  END_TIME_READABLE=$(date '+%Y-%m-%d %H:%M:%S')
  ELAPSED=$((END_TIME - START_TIME))
  
  log "INFO" "Execution completed"
  log "INFO" "Start time: ${START_TIME_READABLE}"
  log "INFO" "End time:   ${END_TIME_READABLE}"
  log "INFO" "Elapsed:    ${ELAPSED} second(s)"
  log "INFO" "=========================================="
  echo ""
  echo "=================================================================================="
  echo -e "${GREEN}Execution completed${NC}"
  echo -e "Start time: ${START_TIME_READABLE}"
  echo -e "End time:   ${END_TIME_READABLE}"
  echo -e "Elapsed:    ${ELAPSED} second(s)"
  echo "=================================================================================="
}

main

exit 0