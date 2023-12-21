#!/bin/sh

HOSTNAME=$1
IP=$2

nixos-rebuild boot --fast --flake ../#$HOSTNAME --target-host root@$IP
ssh root@$IP shutdown -r now
