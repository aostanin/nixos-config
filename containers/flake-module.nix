{
  secrets,
  sopsFiles,
  hosts,
  mkPkgs,
  nixpkgsConfig,
}: {
  self,
  inputs,
  ...
}: {
  flake = let
    inherit (inputs) nixpkgs;
    inherit (nixpkgs) lib;
    home-manager = inputs.home-manager-containers;
    mkContainerConfiguration = {
      hostname,
      system,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs ((mkPkgs system) // {inherit system;});
        modules = let
          homeDirectory = "/home/container";
        in [
          ./modules
          {
            home = {
              username = "container";
              homeDirectory = homeDirectory;
              stateVersion = "24.05";
              enableNixpkgsReleaseCheck = false; # TODO: Remove once stable
            };

            systemd.user.startServices = "sd-switch";

            sops = {
              defaultSopsFile = sopsFiles.containers;
              age.sshKeyPaths = ["${homeDirectory}/.ssh/id_ed25519"];
            };
          }
          ./hosts/${hostname}
          inputs.sops-nix.homeManagerModules.sops
        ];
        extraSpecialArgs = {
          inherit hostname inputs nixpkgsConfig;
          secrets = secrets.containers;
        };
      };
  in {
    containerConfigurations = builtins.mapAttrs (hostname: host:
      mkContainerConfiguration {
        inherit hostname;
        inherit (host) system;
      })
    (lib.filterAttrs (k: v: lib.pathExists (./hosts + "/${k}")) hosts);
  };
}
