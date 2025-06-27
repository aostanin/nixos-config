# nixos-config

## Contents

| Path        | Usage                       |
| ----------- | --------------------------- |
| `/darwin`   | nix-darwin Configurations   |
| `/home`     | Home Manager Configurations |
| `/nixos`    | NixOS Configurations        |
| `/packages` | Packaged applications       |
| `/secrets`  | git-crypt and SOPS secrets  |
| `/terranix` | Terraform Configuration     |

## Hosts

| Host         | Description            |
| ------------ | ---------------------- |
| elena        | Home Desktop           |
| every-router | BananaPi R3 Mini       |
| mac-vm       | macOS VM on elena      |
| mareg        | ThinkPad T440p         |
| octopi       | Raspberry Pi 3         |
| roan         | ThinkPad X250          |
| skye         | ThinkPad X13 Gen 4 AMD |
| tio          | Raspberry Pi 4 4 GB    |
| vps-oci1     | Oracle Cloud AMD Micro |
| vps-oci2     | Oracle Cloud AMD Micro |
| vps-oci-arm1 | Oracle Cloud Ampere    |

### Adding a new host

1. Add to `hosts` in `flake.nix`.
2. Create a NixOS configuration in `nixos/hosts/<HOST>`.
3. Create a Home Manager configuration in `nixos/hosts/<HOST>`
4. Add age key to `.sops.yaml`. Use `ssh-keyscan <IP_ADDRESS> | ssh-to-age` to get the key.
5. Update the keys on SOPS encrypted files with `fd -p secrets/sops -tf -e enc -e enc.yaml -x sops updatekeys -y`.
6. Add Cloudflare Tunnel and TailScale settings to `secrets/terranix/default.nix`.
7. Run `nix run .# -- apply` from the `terranix` directory to set up the Cloudflare Tunnel.
8. Deploy the NixOS configuration with `deploy -s --ssh-user root --hostname <IP_ADDRESS> .#<HOST>.system`
9. Run `nix run .# -- apply` from the `terranix` directory again to set the TailScale settings.
10. Deploy the Home Manager configuration with `deploy -s .#<HOST>.home`.
