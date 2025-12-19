#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gnutar openssh sops

set -euo pipefail

host=$1
mkdir -m 0755 -p $host/etc/ssh
ssh-keygen \
  -t rsa \
  -b 4096 \
  -f "$host/etc/ssh/ssh_host_rsa_key" \
  -N ""
ssh-keygen \
  -t ed25519 \
  -f "$host/etc/ssh/ssh_host_ed25519_key" \
  -N ""
tar -C $host -cpf $host.tar.enc .
sops --encrypt --in-place $host.tar.enc
rm -rf $host
