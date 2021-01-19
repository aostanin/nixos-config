{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager.url = "github:nix-community/home-manager/release-20.09";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, nur, deploy-rs }:
    let
      secrets = import ./secrets;
      system = "x86_64-linux";
      mkNixosSystem = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          hardwareModulesPath = nixos-hardware;
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
          }
          (./hosts + "/${hostname}/configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = import ./home;
          }
        ];
      };
      mkNode = hostname: {
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
        elena = mkNixosSystem "elena";
        mareg = mkNixosSystem "mareg";
        roan = mkNixosSystem "roan";
        valmar = mkNixosSystem "valmar";
      };

      deploy.nodes = {
        elena = mkNode "elena";
        mareg = mkNode "mareg";
        roan = mkNode "roan";
        valmar = mkNode "valmar";
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
