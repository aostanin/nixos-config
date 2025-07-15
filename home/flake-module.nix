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
    inherit (inputs) nixpkgs home-manager;
    inherit (nixpkgs) lib;
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
          ./modules
          {
            home = {
              inherit (secrets.user) username;
              homeDirectory = homeDirectory;
              stateVersion = "25.05";
            };

            systemd.user.startServices = "sd-switch";

            sops = {
              defaultSopsFile = sopsFiles.default;
              age.sshKeyPaths = ["${homeDirectory}/.ssh/id_ed25519"];
            };
          }
          ./hosts/${hostname}
          inputs.sops-nix.homeManagerModules.sops
          inputs.nixvim.homeManagerModules.nixvim
          inputs.nix-flatpak.homeManagerModules.nix-flatpak
        ];
        extraSpecialArgs = {
          inherit inputs nixpkgsConfig secrets sopsFiles;
        };
      };
  in {
    homeConfigurations = builtins.mapAttrs (hostname: host:
      mkHomeConfiguration {
        inherit hostname;
        inherit (host) system;
      })
    (lib.filterAttrs (k: v: lib.pathExists (./hosts + "/${k}")) hosts);
  };
}
