{
  description = "NixOS Configuration";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    home-manager.url = "github:nix-community/home-manager/release-20.09";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, deploy-rs }: {
    nixosConfigurations.mareg = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/mareg/configuration.nix ];
    };

    deploy.nodes.mareg = {
      hostname = "10.147.17.192";
      sshUser = "root";
      fastConnection = true;
      autoRollback = false;
      magicRollback = false;

      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mareg;
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
