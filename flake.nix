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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
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
    secrets = import ./secrets;
    mkNixosSystem = {
      hostname,
      system ? "x86_64-linux",
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          hardwareModulesPath = nixos-hardware;
          homeModulesPath = home-manager.nixosModules;
        };
        modules =
          [
            {
              nixpkgs = {
                config = import ./home/aostanin/nixpkgs/config.nix;
                overlays =
                  [
                    nur.overlay
                    (final: prev: {
                      unstable = import nixpkgs-unstable {
                        inherit system;
                        config = import ./home/aostanin/nixpkgs/config.nix;
                      };
                    })
                  ]
                  ++ (import ./home/aostanin/nixpkgs/overlays.nix);
              };
              system.stateVersion = "22.05";

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
    mkNode = {hostname}: {
      hostname = secrets.network.zerotier.hosts."${hostname}".address;
      sshUser = "root";
      fastConnection = true;
      autoRollback = false;
      magicRollback = false;

      profiles = {
        system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."${hostname}";
        };
      };
    };
  in {
    nixosConfigurations = {
      elena = mkNixosSystem {hostname = "elena";};
      mareg = mkNixosSystem {hostname = "mareg";};
      roan = mkNixosSystem {hostname = "roan";};
      router = mkNixosSystem {hostname = "router";};
      valmar = mkNixosSystem {hostname = "valmar";};
    };

    deploy.nodes = {
      elena = mkNode {hostname = "elena";};
      mareg = mkNode {hostname = "mareg";};
      roan = mkNode {hostname = "roan";};
      router = mkNode {hostname = "router";};
      valmar = mkNode {hostname = "valmar";};
    };

    checks =
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib
      // nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems (
        system: {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
            };
          };
        }
      );

    devShell = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems (system:
      with nixpkgs.legacyPackages.${system};
        mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;

          buildInputs = [
            deploy-rs.defaultPackage.${system}
            git-crypt
            nixos-generators
          ];
        });

    formatter = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
