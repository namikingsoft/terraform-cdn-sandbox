#!/bin/sh -eu

# install shellcheck
if [ ! -e "$HOME/.cabal/bin/shellcheck" ]; then
  cabal update
  cabal install shellcheck
fi

# install terraform
mkdir -p "$HOME/.terraform"
if [ ! -e "$HOME/.terraform" ]; then
  cd "$HOME/.terraform"
  curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
fi
