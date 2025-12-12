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
    inherit (inputs) nixpkgs nix-darwin sops-nix nix-homebrew homebrew-core homebrew-cask;
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
          ./modules
          sops-nix.darwinModules.sops
          nix-homebrew.darwinModules.nix-homebrew
          {
            system.stateVersion = 6;
            sops = {
              defaultSopsFile = sopsFiles.default;
              age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
            };
          }
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
