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
    inherit (inputs) nixpkgs nix-darwin;
    inherit (nixpkgs) lib;
    mkDarwinSystem = {
      hostname,
      system,
    }:
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs nixpkgsConfig secrets sopsFiles;
        };
        modules = [
          (./hosts + "/${hostname}")
        ];
      };
  in {
    darwinConfigurations = builtins.mapAttrs (hostname: host:
      mkDarwinSystem {
        inherit hostname;
        inherit (host) system;
      })
    (lib.filterAttrs (k: v: lib.pathExists (./hosts + "/${k}")) hosts);
  };
}
