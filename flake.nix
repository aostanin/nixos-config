{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-yuzu.url = "github:nixos/nixpkgs/1cba04796fe93e7f657c62f9d1fb9cae9d0dd86e"; # Last version with Yuzu
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
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
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nix-darwin,
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
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
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
            nodes = pkgs.lib.attrsets.filterAttrs (name: value: hosts.${name}.system == system) self.deploy.nodes;
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
              ${lib.getExe pkgs.sops} --decrypt secrets/sops/bootstrap/$hostname.tar.enc | ${lib.getExe pkgs.gnutar} -C $extra_files/persist -xp
              ${lib.getExe pkgs.nixos-anywhere} --flake .#$hostname --extra-files $extra_files $ssh_host
              rm -rf $extra_files
            '');
          };
          deploy = {
            type = "app";
            program = toString (pkgs.writeShellScript "bootstrap" ''
              hostname=$1
              ${lib.getExe deploy-rs.defaultPackage.${system}} -s .#$hostname
            '');
          };
        };

        formatter = pkgs.alejandra;
      };
      flake = let
        nixpkgsConfig = ./nixpkgs-config.nix;
        mkPkgs = system: rec {
          config = import nixpkgsConfig;
          overlays = [
            nur.overlay
            self.overlays.packages
            (final: prev: {
              unstable = import nixpkgs-unstable {
                inherit config system;
              };
              yuzu = inputs.nixpkgs-yuzu.legacyPackages.${system}.yuzu;
            })
          ];
        };
      in {
        nixosConfigurations = let
          mkNixosSystem = {
            hostname,
            system,
          }:
            lib.nixosSystem {
              inherit system;
              specialArgs = {
                inherit inputs nixpkgsConfig secrets sopsFiles;
              };
              modules = [
                ./nixos/modules
                {
                  nixpkgs = mkPkgs system;
                  system.stateVersion = "24.05";

                  # Use same nixpkgs for flakes and system
                  # ref: https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
                  nix = {
                    registry = {
                      nixpkgs.flake = nixpkgs;
                      nixpkgs-unstable.flake = nixpkgs-unstable;
                      nixos-config.flake = self;
                    };
                    nixPath = [
                      "nixpkgs=/etc/channels/nixpkgs"
                      "nixos-config=/etc/nixos/configuration.nix"
                      "/nix/var/nix/profiles/per-user/root/channels"
                    ];
                  };
                  environment.etc."channels/nixpkgs".source = nixpkgs.outPath;

                  sops = {
                    defaultSopsFile = sopsFiles.default;
                    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key" "/persist/etc/ssh/ssh_host_ed25519_key"];
                  };
                }
                (./nixos/hosts + "/${hostname}")
                inputs.sops-nix.nixosModules.sops
                inputs.nvidia-patch.nixosModules.nvidia-patch
                inputs.disko.nixosModules.disko
                inputs.impermanence.nixosModules.impermanence
              ];
            };
        in
          builtins.mapAttrs (hostname: host:
            mkNixosSystem {
              inherit hostname;
              inherit (host) system;
            })
          (lib.filterAttrs (k: v: lib.pathExists (./nixos/hosts + "/${k}")) hosts);

        darwinConfigurations = let
          mkDarwinSystem = {
            hostname,
            system,
          }:
            nix-darwin.lib.darwinSystem {
              inherit system;
              specialArgs = {
                inherit inputs nixpkgsConfig secrets sopsFiles;
              };
              modules = [
                (./darwin/hosts + "/${hostname}")
              ];
            };
        in
          builtins.mapAttrs (hostname: host:
            mkDarwinSystem {
              inherit hostname;
              inherit (host) system;
            })
          (lib.filterAttrs (k: v: lib.pathExists (./darwin/hosts + "/${k}")) hosts);

        homeConfigurations = let
          mkHomeConfiguration = {
            hostname,
            system,
          }:
            home-manager.lib.homeManagerConfiguration rec {
              pkgs = import nixpkgs ((mkPkgs system) // {inherit system;});
              modules = let
                homeDirectory =
                  if pkgs.stdenv.isDarwin
                  then "/Users/${secrets.user.username}"
                  else "/home/${secrets.user.username}";
              in [
                ./home/modules
                {
                  home = {
                    inherit (secrets.user) username;
                    homeDirectory = homeDirectory;
                    stateVersion = "24.05";
                  };

                  sops = {
                    defaultSopsFile = sopsFiles.default;
                    age.sshKeyPaths = ["${homeDirectory}/.ssh/id_ed25519"];
                  };
                }
                ./home/hosts/${hostname}
                inputs.sops-nix.homeManagerModules.sops
                inputs.nixvim.homeManagerModules.nixvim
              ];
              extraSpecialArgs = {
                inherit inputs nixpkgsConfig secrets sopsFiles;
              };
            };
        in
          builtins.mapAttrs (hostname: host:
            mkHomeConfiguration {
              inherit hostname;
              inherit (host) system;
            })
          (lib.filterAttrs (k: v: lib.pathExists (./home/hosts + "/${k}")) hosts);

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
