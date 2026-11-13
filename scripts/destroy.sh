#!/bin/bash
# Deletes everything scripts/deploy.sh created, in reverse order (COMMANDS.md
# step 12), so nothing is billed anymore. The S3 state bucket stays: it holds
# the (now empty) state files and costs nothing measurable.
#
# Usage: scripts/destroy.sh          (set AWS_PROFILE first if you use a named profile)
set -euo pipefail
cd "$(dirname "$0")/.."

export AWS_REGION=${AWS_REGION:-eu-north-1}
tf() { terraform -chdir="$1" "${@:2}"; }
destroy() { echo; echo "=== $1"; tf "$1" init -input=false >/dev/null; tf "$1" destroy -input=false -auto-approve -var-file=terraform.tfvars "${@:2}"; }

echo "Destroying in account $(aws sts get-caller-identity --query Account --output text) in $AWS_REGION"

destroy terraform/aymen/05-monitoring
destroy terraform/houda/platform
destroy terraform/aymen/04-messaging -var "container_image=$(tf terraform/houda/ecr output -raw rabbit_queue_image)"
destroy terraform/houda/ecr
destroy terraform/aymen/02-databases
destroy terraform/aymen/01-networking

echo
echo "Done. Nothing of the project is running anymore."
