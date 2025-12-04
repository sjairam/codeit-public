#!/bin/bash

clear

AWS=$(command -v aws)

Usage() {
    echo "Finds a specific ALB after "list_alb" has been execited"
    echo
    echo "Syntax: ./find_ALB [-h|-s <<arn>> ]"
    echo "options:"
    echo "-h                     Print this message."
    echo
}


check_binaries() {
  if [ ! -f "${AWS}" ]; then
    echo "ERROR: The aws binary does not exist."
    echo "FIX: Please modify the \${AWS} variable in the program header."
    exit 1
  fi

}

check_binaries

###################
###################

# Verify that an instance ID is provided.
if [ -z "$1" ]; then
  echo " Usage: $0 <instance-id>"
  exit 1
fi

INSTANCE_ID=$1

# Get all Load Balancers
load_balancers=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text)

if [ -z "$load_balancers" ]; then
  echo "No load balancers found."
  exit 1
fi

# Iterate through each load balancer to find target groups
for lb_arn in $load_balancers; do
  # Get all target groups associated with the load balancer
  target_groups=$(aws elbv2 describe-target-groups --load-balancer-arn "$lb_arn" --query 'TargetGroups[*].TargetGroupArn' --output text)

  # Iterate through each target group
  for tg_arn in $target_groups; do
    # Check if the instance is registered to this target group
    registered_targets=$(aws elbv2 describe-target-health --target-group-arn "$tg_arn" --query 'TargetHealthDescriptions[*].Target.Id' --output text)

    # Match the instance ID
    for target in $registered_targets; do
      if [ "$target" == "$INSTANCE_ID" ]; then
        # If found, print the load balancer and target group
        lb_name=$(aws elbv2 describe-load-balancers --load-balancer-arns "$lb_arn" --query 'LoadBalancers[*].LoadBalancerName' --output text)
        tg_name=$(aws elbv2 describe-target-groups --target-group-arns "$tg_arn" --query 'TargetGroups[*].TargetGroupName' --output text)
        echo "Instance ID $INSTANCE_ID is registered to:"
        echo "Load Balancer: $lb_name"
        echo "Target Group: $tg_name"
        exit 0
      fi
    done
  done
done

echo "Instance ID $INSTANCE_ID is not associated with any ALB."
exit 0