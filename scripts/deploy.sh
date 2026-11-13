#!/bin/bash
# Creates the whole project in the AWS account of the current CLI profile,
# module by module, in the order COMMANDS.md step 5 describes. Each module
# stores its state in the S3 bucket named in its versions.tf.
#
# Usage: scripts/deploy.sh          (set AWS_PROFILE first if you use a named profile)
set -euo pipefail
cd "$(dirname "$0")/.."

export AWS_REGION=${AWS_REGION:-eu-north-1}
tf() { terraform -chdir="$1" "${@:2}"; }
apply() { echo; echo "=== $1"; tf "$1" init -input=false >/dev/null; tf "$1" apply -input=false -auto-approve -var-file=terraform.tfvars "${@:2}"; }

if grep -q 'you@example.com' terraform/aymen/05-monitoring/terraform.tfvars; then
  echo "Put your email in alert_email in terraform/aymen/05-monitoring/terraform.tfvars first." >&2
  exit 1
fi

echo "Deploying to account $(aws sts get-caller-identity --query Account --output text) in $AWS_REGION"

apply terraform/aymen/01-networking
apply terraform/aymen/02-databases
apply terraform/houda/ecr
scripts/push-images.sh
apply terraform/aymen/04-messaging -var "container_image=$(tf terraform/houda/ecr output -raw rabbit_queue_image)"
apply terraform/houda/platform
apply terraform/aymen/05-monitoring

echo
echo "Done. Waiting for the services to start..."
aws ecs wait services-stable --cluster cloud-design-cluster \
  --services api-gateway-service inventory-service billing-service rabbit-queue-service
curl -k "$(tf terraform/houda/platform output -raw app_url)/health"; echo
scripts/postman-env.sh
echo "Confirm the SNS subscription email to receive the alarms."
