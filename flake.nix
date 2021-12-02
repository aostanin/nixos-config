{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, nur, deploy-rs, flake-utils }:
    let
      secrets = import ./secrets;
      mkNixosSystem = { hostname, system ? "x86_64-linux", extraModules ? [ ] }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          hardwareModulesPath = nixos-hardware;
          homeModulesPath = home-manager.nixosModules;
        };
        modules = [
          {
            nixpkgs = {
              config = import ./home/aostanin/nixpkgs/config.nix;
              overlays = [
                nur.overlay
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    inherit system;
                    config = import ./home/aostanin/nixpkgs/config.nix;
                  };
                })
              ] ++ (import ./home/aostanin/nixpkgs/overlays.nix);
            };
            system.stateVersion = "21.11";
          }
          (./hosts + "/${hostname}/configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = import ./home;
          }
        ] ++ extraModules;
      };
      mkNode = { hostname }: {
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
    in
    {
      nixosConfigurations = {
        elena = mkNixosSystem { hostname = "elena"; };
        mareg = mkNixosSystem { hostname = "mareg"; };
        roan = mkNixosSystem { hostname = "roan"; };
        valmar = mkNixosSystem { hostname = "valmar"; };
      };

      deploy.nodes = {
        elena = mkNode { hostname = "elena"; };
        mareg = mkNode { hostname = "mareg"; };
        roan = mkNode { hostname = "roan"; };
        valmar = mkNode { hostname = "valmar"; };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      devShell = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems (system:
        with nixpkgs.legacyPackages.${system}; mkShell {
          buildInputs = [
            cargo # For nixpkgs-fmt
            git-crypt
            nixos-generators
            pre-commit
          ] ++ lib.optionals (builtins.hasAttr system deploy-rs.defaultPackage) [
            # deploy-rs is missing aarch64-darwin
            deploy-rs.defaultPackage.${system} # TODO: There has to be a better way to write this?
          ];

          shellHook = ''
            pre-commit install -f --hook-type pre-commit
          '';
        });
    };
}
