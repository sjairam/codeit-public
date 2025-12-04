#!/bin/bash
# 01 - initial - jairams
# 02 - Add AWS CLI check

AWS=$(command -v aws)

if [ ! -f "${AWS}" ]; then
    echo "ERROR: The aws binary does not exist."
    echo "FIX: Please modify the \${AWS} variable in the program header."
    exit 1
fi

# List all load balancers and get their names and ARNs
load_balancers=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?Type=='application'].{Name:LoadBalancerName, ARN:LoadBalancerArn}" --output text)

# Check if there are any ALBs found
if [ -z "$load_balancers" ]; then
    echo "No Application Load Balancers found."
else
    echo "Application Load Balancers:"
    echo "$load_balancers"
fi
