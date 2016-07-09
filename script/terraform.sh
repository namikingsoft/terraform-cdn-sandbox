#!/bin/bash -eu

# check argument
if [ "$1" != "plan" ] && [ "$1" != "apply" ]; then
  echo "Usage: terraform.sh (plan|apply)"
  exit 1
fi

# configure terraform
terraform remote config \
  -backend=S3 \
  -backend-config="bucket=tfstate.namiking.net" \
  -backend-config="key=terraform-cdn-sandbox-${TF_ENV}.tfstate"

# catch error then push terraform state
trap "terraform remote push" ERR

# pull terraform state
terraform remote pull

# execute terraform
terraform "$1" -var "env=${TF_ENV}"

# push terraform state
terraform remote push
