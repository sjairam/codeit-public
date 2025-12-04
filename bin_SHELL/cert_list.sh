#!/bin/bash
# v0.1 Initial version
# v0.2 Add expire check
# v0.3 Add Total number of certs

set -euo pipefail

# Usage function
usage() {
    echo "Usage: $0 [-r region] [-d] [-e]"
    echo "  -r, --region   AWS region (default: from AWS config or environment)"
    echo "  -d, --detailed Show detailed information for each certificate"
    echo "  -e, --expired  Show only expired certificates"
    echo "  -h, --help     Show this help message"
}

# Check for AWS CLI
AWS=$(command -v aws || true)
if [ -z "$AWS" ]; then
    echo "ERROR: The aws CLI is not installed or not in PATH." >&2
    exit 1
fi

# Check for AWS credentials
if ! aws sts get-caller-identity --output text >/dev/null 2>&1; then
    echo "ERROR: AWS credentials not found or invalid. Please configure them with 'aws configure'." >&2
    exit 2
fi

REGION=""
REGION_ARG=()
DETAILED=false
EXPIRED_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -e|--expired)
            EXPIRED_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [ -n "$REGION" ]; then
    REGION_ARG=(--region "$REGION")
fi

echo "Listing ACM certificates..." >&2

# List certificates (include all statuses so expired ones are not omitted)
# Note: --certificate-statuses takes a space‑separated list, not comma‑separated.
if ! CERT_LIST=$(aws acm list-certificates \
    "${REGION_ARG[@]:-}" \
    --certificate-statuses ISSUED EXPIRED INACTIVE PENDING_VALIDATION \
    --query 'CertificateSummaryList[*].[CertificateArn,DomainName,Status,Type]' \
    --output text 2>/dev/null); then
    echo "ERROR: Failed to retrieve certificate information." >&2
    exit 3
fi

if [ -z "$CERT_LIST" ]; then
    echo "No certificates found in this region."
    exit 0
fi

# If we only want expired certificates, re‑query ACM asking exclusively for EXPIRED.
# This avoids brittle local parsing and guarantees we see exactly what `--certificate-statuses EXPIRED` returns.
if [ "$EXPIRED_ONLY" = true ]; then
    if ! CERT_LIST=$(aws acm list-certificates \
        "${REGION_ARG[@]:-}" \
        --certificate-statuses EXPIRED \
        --query 'CertificateSummaryList[*].[CertificateArn,DomainName,Status,Type]' \
        --output text 2>/dev/null); then
        echo "ERROR: Failed to retrieve expired certificate information." >&2
        exit 3
    fi

    if [ -z "$CERT_LIST" ]; then
        echo "No expired certificates found in this region."
        exit 0
    fi
fi

# Function to check if certificate is expired
is_expired() {
    local arn="$1"
    local not_after
    not_after=$(aws acm describe-certificate \
        "${REGION_ARG[@]:-}" \
        --certificate-arn "$arn" \
        --query 'Certificate.NotAfter' \
        --output text 2>/dev/null || true)

    if [ -z "$not_after" ] || [ "$not_after" = "None" ]; then
        # If we can't get the date, don't consider it expired
        return 1
    fi

    # Convert NotAfter (ISO8601) to Unix timestamp and compare with current time.
    # Prefer Python for robust ISO8601 parsing (handles Z, offsets, fractional seconds),
    # and fall back to platform-specific date(1) parsing if Python is unavailable.
    local expiry_ts=""

    if command -v python3 >/dev/null 2>&1; then
        expiry_ts=$(python3 - <<PY 2>/dev/null || echo ""
from datetime import datetime, timezone
s = "${not_after}"
# Normalise common AWS formats:
# - "YYYY-MM-DDTHH:MM:SSZ"
# - "YYYY-MM-DDTHH:MM:SS.sssZ"
# - "YYYY-MM-DDTHH:MM:SS+00:00"
if s.endswith("Z"):
    s = s[:-1] + "+00:00"
dt = datetime.fromisoformat(s)
if dt.tzinfo is None:
    dt = dt.replace(tzinfo=timezone.utc)
print(int(dt.timestamp()))
PY
        )
    fi

    # Fallback: try "python" if it exists and Python 3 is available there
    if [ -z "$expiry_ts" ] && command -v python >/dev/null 2>&1; then
        expiry_ts=$(python - <<PY 2>/dev/null || echo ""
from __future__ import print_function
from datetime import datetime, timezone
s = "${not_after}"
if s.endswith("Z"):
    s = s[:-1] + "+00:00"
dt = datetime.fromisoformat(s)
if dt.tzinfo is None:
    dt = dt.replace(tzinfo=timezone.utc)
print(int(dt.timestamp()))
PY
        )
    fi

    # Fallback to date(1) if Python parsing failed
    if [ -z "$expiry_ts" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS/BSD date: try to normalise to a format date(1) understands.
            # 1) Drop fractional seconds, if any
            local base="${not_after%%.*}"
            # 2) Replace a trailing 'Z' with '+0000'
            if [[ "$base" == *Z ]]; then
                base="${base%Z}+0000"
            # 3) If we have a timezone like +00:00, convert to +0000
            elif [[ "$base" =~ \+[0-9]{2}:[0-9]{2}$ ]]; then
                base="${base:0:${#base}-3}${base: -2}"
            fi
            # Now parse with timezone
            expiry_ts=$(date -j -u -f "%Y-%m-%dT%H:%M:%S%z" "$base" "+%s" 2>/dev/null || echo "")
        else
            # Linux/GNU date can usually handle ISO8601 directly
            expiry_ts=$(date -d "$not_after" "+%s" 2>/dev/null || echo "")
        fi
    fi

    local current_ts
    current_ts=$(date "+%s")

    if [ -n "$expiry_ts" ] && [ "$expiry_ts" -lt "$current_ts" ]; then
        return 0  # Expired
    else
        return 1  # Not expired
    fi
}

if [ "$DETAILED" = true ]; then
    # Detailed view with additional information
    echo ""
    echo "Certificate Details:"
    echo "==================="
    echo ""
    
    while IFS=$'\t' read -r arn domain status type; do
        echo "Domain: $domain"
        echo "Status: $status"
        echo "Type: $type"
        echo "ARN: $arn"
        
        # Get detailed certificate information using AWS CLI query
        if aws acm describe-certificate \
            "${REGION_ARG[@]:-}" \
            --certificate-arn "$arn" \
            --query 'Certificate.{IssuedAt:IssuedAt,NotBefore:NotBefore,NotAfter:NotAfter,KeyAlgorithm:KeyAlgorithm,SubjectAlternativeNames:SubjectAlternativeNames,InUseBy:InUseBy}' \
            --output table 2>/dev/null; then
            echo ""
        else
            echo "  (Unable to retrieve detailed information)"
            echo ""
        fi
        
        echo "---"
        echo ""
    done <<< "$CERT_LIST"
else
    # Simple table view
    echo ""
    if [ "$EXPIRED_ONLY" = true ]; then
        # Build table manually for filtered results
        echo "Domain Name | Status | Type"
        echo "------------|--------|------"
        while IFS=$'\t' read -r arn domain status type; do
            echo "$domain | $status | $type"
        done <<< "$CERT_LIST"
    else
        aws acm list-certificates \
            "${REGION_ARG[@]:-}" \
            --certificate-statuses ISSUED EXPIRED INACTIVE PENDING_VALIDATION \
            --query 'CertificateSummaryList[*].[DomainName,Status,Type]' \
            --output table
    fi
fi

# Count total certificates
TOTAL_COUNT=$(echo "$CERT_LIST" | wc -l | tr -d ' ')
echo ""
echo "Total certificates: $TOTAL_COUNT"

