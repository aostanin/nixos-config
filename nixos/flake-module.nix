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
    inherit (inputs) nixpkgs nixpkgs-unstable sops-nix nvidia-patch disko impermanence;
    inherit (nixpkgs) lib;
  in {
    nixosConfigurations = let
      mkNixosSystem = {
        hostname,
        system,
      }:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs nixpkgsConfig secrets sopsFiles;
          };
          modules = [
            ./modules
            {
              nixpkgs = mkPkgs system;
              system.stateVersion = "24.05";

              # Use same nixpkgs for flakes and system
              # ref: https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
              nix = {
                registry = {
                  nixpkgs.flake = nixpkgs;
                  nixpkgs-unstable.flake = nixpkgs-unstable;
                  nixos-config.flake = self;
                };
                nixPath = [
                  "nixpkgs=/etc/channels/nixpkgs"
                  "/nix/var/nix/profiles/per-user/root/channels"
                ];
              };
              environment.etc."channels/nixpkgs".source = nixpkgs.outPath;

              sops = {
                defaultSopsFile = sopsFiles.default;
                age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
              };
            }
            (./hosts + "/${hostname}")
            sops-nix.nixosModules.sops
            nvidia-patch.nixosModules.nvidia-patch
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
          ];
        };
    in
      builtins.mapAttrs (hostname: host:
        mkNixosSystem {
          inherit hostname;
          inherit (host) system;
        })
      (lib.filterAttrs (k: v: lib.pathExists (./hosts + "/${k}")) hosts);
  };
}
