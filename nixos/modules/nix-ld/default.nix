{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.localModules.nix-ld;
in {
  options.localModules.nix-ld = {
    enable = lib.mkEnableOption "nix-ld";
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
      libraries = (pkgs.steam-run.fhsenv.args.multiPkgs pkgs) ++ [pkgs.fuse];
    };
  };
}
