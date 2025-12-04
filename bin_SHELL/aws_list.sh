#!/bin/bash
set -euo pipefail

# Usage function
usage() {
    echo "Usage: $0 [-r region]"
    echo "  -r, --region   AWS region (default: from AWS config or environment)"
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
# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
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

echo "Listing all running EC2 instances with InstanceID, Name, State, and Private IP..." >&2

if ! aws ec2 describe-instances \
    "${REGION_ARG[@]:-}" \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].{InstanceID:InstanceId, Name:Tags[?Key==`Name`].Value | [0], State:State.Name, PrivateIP:PrivateIpAddress}' \
    --output table; then
    echo "ERROR: Failed to retrieve EC2 instance information." >&2
    exit 3
fi