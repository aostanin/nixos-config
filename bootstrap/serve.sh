#!/bin/sh

nix run nixpkgs#miniserve -- -p 9000 nixos-setup.sh
