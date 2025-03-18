{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix/nixpkgs-stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nvidia-patch.url = "github:arcnmx/nvidia-patch.nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    nixos-artwork = {
      url = "github:NixOS/nixos-artwork";
      flake = false;
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nur,
    deploy-rs,
    pre-commit-hooks,
    flake-parts,
    ...
  }: let
    lib = nixpkgs.lib;
    secrets = import ./secrets;
    sopsFiles = {
      default = ./secrets/sops/secrets.enc.yaml;
      terranix = ./secrets/sops/terranix.enc.yaml;
    };
    hosts = {
      elena = {system = "x86_64-linux";};
      mac-vm = {system = "x86_64-darwin";};
      mareg = {system = "x86_64-linux";};
      roan = {system = "x86_64-linux";};
      skye = {system = "x86_64-linux";};
      tio = {system = "aarch64-linux";};
      vps-oci1 = {system = "x86_64-linux";};
      vps-oci2 = {system = "x86_64-linux";};
      vps-oci-arm1 = {system = "aarch64-linux";};
    };
    nixpkgsConfig = ./nixpkgs-config.nix;
    mkPkgs = system: rec {
      config = import nixpkgsConfig;
      overlays = [
        nur.overlays.default
        self.overlays.packages
        (final: prev: {
          unstable = import nixpkgs-unstable {
            inherit config system;
          };
          hwi = prev.hwi.overrideAttrs (old: {
            # Blockstream Jade needs cbor2
            propagatedBuildInputs = old.propagatedBuildInputs ++ [prev.python3Packages.cbor2];
          });
        })
      ];
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with flake-parts.lib; let
        args = {inherit secrets sopsFiles hosts nixpkgsConfig mkPkgs;};
      in [
        (importApply ./nixos/flake-module.nix args)
        (importApply ./darwin/flake-module.nix args)
        (importApply ./home/flake-module.nix args)
      ];
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {
        config,
        self',
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            deploy-rs.defaultPackage.${system}
            git-crypt
            sops
            ssh-to-age
          ];

          shellHook = ''
            ${self'.checks.pre-commit-check.shellHook}

            export SOPS_AGE_KEY=$(${lib.getExe pkgs.ssh-to-age} -i ~/.ssh/id_ed25519 -private-key)
          '';
        };

        checks = pkgs.lib.attrsets.mergeAttrsList [
          (deploy-rs.lib.${system}.deployChecks {
            # Only check nodes with the same system
            nodes = lib.filterAttrs (n: v: hosts.${n}.system == system) self.deploy.nodes;
          })
          {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                alejandra.enable = true;
              };
            };
          }
        ];

        packages = import ./packages {inherit pkgs;};

        apps = {
          bootstrap = {
            type = "app";
            program = toString (pkgs.writeShellScript "bootstrap" ''
              hostname=$1
              ssh_host=$2
              extra_files=$(mktemp -d)
              mkdir -p $extra_files/persist
              # TODO: don't hardcode persist
              ${lib.getExe pkgs.sops} --decrypt secrets/sops/bootstrap/$hostname.tar.enc | ${lib.getExe pkgs.gnutar} -C $extra_files/persist -xp
              ${lib.getExe pkgs.nixos-anywhere} --flake .#$hostname --extra-files $extra_files $ssh_host
              rm -rf $extra_files
            '');
          };
        };

        formatter = pkgs.alejandra;
      };
      flake = {
        deploy.nodes = let
          mkNode = {
            hostname,
            system,
          }: {
            inherit hostname;
            sshUser = secrets.user.username;
            fastConnection = false;
            autoRollback = false;
            magicRollback = false;
            remoteBuild = false;

            profiles =
              lib.optionalAttrs (builtins.hasAttr hostname self.nixosConfigurations) {
                system = {
                  user = "root";
                  path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations."${hostname}";
                };
              }
              // lib.optionalAttrs (builtins.hasAttr hostname self.darwinConfigurations) {
                system = {
                  user = "root";
                  path = deploy-rs.lib.${system}.activate.darwin self.darwinConfigurations."${hostname}";
                };
              }
              // lib.optionalAttrs (builtins.hasAttr hostname self.homeConfigurations) {
                home = {
                  user = secrets.user.username;
                  path = deploy-rs.lib.${system}.activate.home-manager self.homeConfigurations."${hostname}";
                };
              };
          };
        in (builtins.mapAttrs (hostname: host:
          mkNode {
            inherit hostname;
            inherit (host) system;
          })
        hosts);

        overlays.packages = final: prev: import ./packages {pkgs = prev;};
      };
    };
}
