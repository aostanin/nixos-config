#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gnutar openssh rsync sops

set -euo pipefail

host=$1
mkdir -p $host
rsync -aR --ignore-missing-args root@$host:'/etc/ssh/ssh_host_*' root@$host:/var/lib/tailscale/tailscaled.state $host
tar -C $host -cpf $host.tar.enc .
sops --encrypt --in-place $host.tar.enc
rm -rf $host
