{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-yuzu.url = "github:nixos/nixpkgs/1cba04796fe93e7f657c62f9d1fb9cae9d0dd86e"; # Last version with Yuzu
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
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
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-yuzu,
    home-manager,
    nix-darwin,
    nur,
    deploy-rs,
    pre-commit-hooks,
    flake-parts,
    ...
  }: let
    lib = nixpkgs.lib;
    secretsPath = ./secrets;
    secrets = import secretsPath;
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
          inherit (self'.checks.pre-commit-check) shellHook;

          buildInputs = [
            deploy-rs.defaultPackage.${system}
            pkgs.git-crypt
          ];
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

        formatter = pkgs.alejandra;

        packages = import ./packages {inherit pkgs;};
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
                inherit inputs nixpkgsConfig secrets secretsPath;
              };
              modules = [
                ./modules
                {
                  nixpkgs = mkPkgs system;
                  system.stateVersion = "23.11";

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
                }
                (./hosts + "/${hostname}")
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  # TODO: Deploy ssh keys without home-manager
                  home-manager.users.root = import ./home/root;
                  home-manager.extraSpecialArgs = {
                    inherit inputs secrets secretsPath;
                  };
                }
              ];
            };
        in
          builtins.mapAttrs (hostname: host:
            mkNixosSystem {
              inherit hostname;
              inherit (host) system;
            })
          (lib.filterAttrs (k: v: lib.pathExists (./hosts + "/${k}")) hosts);

        darwinConfigurations = let
          mkDarwinSystem = {
            hostname,
            system,
          }:
            nix-darwin.lib.darwinSystem {
              inherit system;
              specialArgs = {
                inherit inputs nixpkgsConfig secrets secretsPath;
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
              modules = [
                ./home/modules
                {
                  home.username = secrets.user.username;
                  home.homeDirectory =
                    if pkgs.stdenv.isDarwin
                    then "/Users/${secrets.user.username}"
                    else "/home/${secrets.user.username}";
                  home.stateVersion = "23.11";
                }
                ./home/hosts/${hostname}
              ];
              extraSpecialArgs = {
                inherit inputs nixpkgsConfig secrets secretsPath;
                nixpkgs-yuzu = import nixpkgs-yuzu {
                  inherit system;
                };
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
            hostname = secrets.network.zerotier.hosts."${hostname}".address6;
            sshUser = secrets.user.username;
            fastConnection = false;
            autoRollback = false;
            magicRollback = false;
            remoteBuild = true;

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
