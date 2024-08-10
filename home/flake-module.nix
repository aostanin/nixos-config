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
  in {
    homeConfigurations = let
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
                stateVersion = "24.05";
              };

              sops = {
                defaultSopsFile = sopsFiles.default;
                age.sshKeyPaths = ["${homeDirectory}/.ssh/id_ed25519"];
              };
            }
            ./hosts/${hostname}
            inputs.sops-nix.homeManagerModules.sops
            inputs.nixvim.homeManagerModules.nixvim
          ];
          extraSpecialArgs = {
            inherit inputs nixpkgsConfig secrets sopsFiles;
          };
        };
    in
      builtins.mapAttrs (hostname: host:
        mkHomeConfiguration {
          inherit hostname;
          inherit (host) system;
        })
      (lib.filterAttrs (k: v: lib.pathExists (./hosts + "/${k}")) hosts);
  };
}
