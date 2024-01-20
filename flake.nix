{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
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
    home-manager,
    nur,
    deploy-rs,
    pre-commit-hooks,
    flake-parts,
    ...
  }: let
    lib = nixpkgs.lib;
    secrets = import ./secrets;
    hosts = {
      elena = {system = "x86_64-linux";};
      mareg = {system = "x86_64-linux";};
      roan = {system = "x86_64-linux";};
      skye = {system = "x86_64-linux";};
      tio = {system = "aarch64-linux";};
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
          inherit inputs;
          secrets = secrets;
        };
        modules =
          [
            {
              nixpkgs = rec {
                config = import ./home/${secrets.user.username}/nixpkgs/config.nix;
                overlays = [
                  nur.overlay
                  self.overlays.packages
                  (final: prev: {
                    unstable = import nixpkgs-unstable {
                      inherit system;
                      inherit config;
                    };
                  })
                ];
              };
              system.stateVersion = "23.11";

              # Use same nixpkgs for flakes and system
              # ref: https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
              nix = {
                registry = {
                  nixpkgs.flake = nixpkgs;
                  nixpkgs-unstable.flake = nixpkgs-unstable;
                };
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
              home-manager.extraSpecialArgs.secrets = secrets;
            }
          ]
          ++ extraModules;
      };
    mkNode = {
      hostname,
      system,
    }: {
      hostname = secrets.network.zerotier.hosts."${hostname}".address6;
      sshUser = "root";
      fastConnection = false;
      autoRollback = false;
      magicRollback = false;
      remoteBuild = true;

      profiles = {
        system = {
          user = "root";
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations."${hostname}";
        };
      };
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
      flake = {
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
          })
        hosts;

        overlays.packages = final: prev: import ./packages {pkgs = prev;};
      };
    };
}
