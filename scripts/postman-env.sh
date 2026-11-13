#!/bin/bash
# Writes postman/cloud-design.postman_environment.json with the values the
# Postman collection needs for the current deployment: the API address, the
# Cognito client id and the test user's username and password. Import it in
# Postman (Import -> the file) and select the "cloud-design" environment at
# the top right: the collection then works without typing any value.
#
# The file holds the test user's password, so git ignores it. Run this
# script again after every deploy: the address and the password change.
#
# Usage: scripts/postman-env.sh
set -euo pipefail
cd "$(dirname "$0")/.."

out=postman/cloud-design.postman_environment.json

app_url=$(terraform -chdir=terraform/houda/platform output -raw app_url)
region=$(terraform -chdir=terraform/houda/platform output -raw aws_region 2>/dev/null || echo "${AWS_REGION:-eu-north-1}")
secret_name=$(terraform -chdir=terraform/houda/platform output -raw test_user_secret_name 2>/dev/null)
secret_name=${secret_name:-cloud-design/cognito-test-user}

aws secretsmanager get-secret-value --secret-id "$secret_name" --query SecretString --output text |
  python3 -c '
import json, sys
secret = json.load(sys.stdin)
app_url, region, out = sys.argv[1:4]
def var(key, value, secret_type=False):
    return {"key": key, "value": value, "type": "secret" if secret_type else "default", "enabled": True}
env = {
    "name": "cloud-design",
    "values": [
        var("base_url", app_url),
        var("region", region),
        var("cognito_client_id", secret["client_id"]),
        var("username", secret["username"]),
        var("password", secret["password"], secret_type=True),
    ],
    "_postman_variable_scope": "environment",
}
with open(out, "w") as f:
    json.dump(env, f, indent=2)
    f.write("\n")
' "$app_url" "$region" "$out"

chmod 600 "$out"
echo "Wrote $out (base_url $app_url). Import it in Postman and select the cloud-design environment."
