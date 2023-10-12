{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix/nixpkgs-stable";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nixos-hardware,
    nur,
    deploy-rs,
    pre-commit-hooks,
    flake-utils,
  }: let
    lib = nixpkgs.lib;
    secrets = import ./secrets;
    hosts = {
      elena = {system = "x86_64-linux";};
      mareg = {system = "x86_64-linux";};
      roan = {system = "x86_64-linux";};
      tio = {
        system = "aarch64-linux";
        options = {remoteBuild = false;};
      };
      valmar = {system = "x86_64-linux";};
      vps-oci1 = {system = "x86_64-linux";};
      vps-oci2 = {system = "x86_64-linux";};
    };
    mkNixosSystem = {
      hostname,
      system,
      extraModules ? [],
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          hardwareModulesPath = nixos-hardware;
          homeModulesPath = home-manager.nixosModules;
        };
        modules =
          [
            {
              nixpkgs = {
                config = import ./home/${secrets.user.username}/nixpkgs/config.nix;
                overlays =
                  [
                    nur.overlay
                    (final: prev: {
                      unstable = import nixpkgs-unstable {
                        inherit system;
                        config = import ./home/${secrets.user.username}/nixpkgs/config.nix;
                      };
                    })
                  ]
                  ++ (import ./home/${secrets.user.username}/nixpkgs/overlays.nix);
              };
              system.stateVersion = "23.05";

              # Use same nixpkgs for flakes and system
              # ref: https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
              nix = {
                registry.nixpkgs.flake = nixpkgs;
                registry.nixpkgs-unstable.flake = nixpkgs-unstable;
                nixPath = [
                  "nixpkgs=/etc/channels/nixpkgs"
                  "nixos-config=/etc/nixos/configuration.nix"
                  "/nix/var/nix/profiles/per-user/root/channels"
                ];
              };
              environment.etc."channels/nixpkgs".source = nixpkgs.outPath;
            }
            (./hosts + "/${hostname}/configuration.nix")
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = import ./home;
            }
          ]
          ++ extraModules;
      };
    mkNode = {
      hostname,
      system,
      options,
    }:
      {
        hostname = secrets.network.zerotier.hosts."${hostname}".address6;
        sshUser = "root";
        fastConnection = false;
        autoRollback = false;
        magicRollback = false;

        profiles = {
          system = {
            user = "root";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations."${hostname}";
          };
        };
      }
      // options;
  in {
    nixosConfigurations = builtins.mapAttrs (hostname: host:
      mkNixosSystem {
        inherit hostname;
        system = host.system;
      })
    hosts;

    deploy.nodes = builtins.mapAttrs (hostname: host:
      mkNode {
        inherit hostname;
        system = host.system;
        options = ({options = {};} // host).options;
      })
    hosts;

    checks =
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib
      // lib.genAttrs flake-utils.lib.defaultSystems (
        system: {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
            };
          };
        }
      );

    devShell = lib.genAttrs flake-utils.lib.defaultSystems (system:
      with nixpkgs.legacyPackages.${system};
        mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;

          buildInputs = [
            deploy-rs.defaultPackage.${system}
            git-crypt
            nixos-generators
          ];
        });

    formatter = lib.genAttrs flake-utils.lib.defaultSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
