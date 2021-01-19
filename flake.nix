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

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, nur, deploy-rs }: {
    nixosConfigurations.mareg = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
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
        nixos-hardware.nixosModules.lenovo-thinkpad-t440p
        nixos-hardware.nixosModules.common-pc-laptop-ssd
        ./hosts/mareg/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.root = import ./home/root/home.nix;
          home-manager.users.aostanin = import ./home/aostanin/home.nix;
        }
      ];
    };

    deploy.nodes.mareg = {
      hostname = "10.147.17.192";
      sshUser = "root";
      fastConnection = true;
      autoRollback = false;
      magicRollback = false;

      profiles = {
        system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mareg;
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
