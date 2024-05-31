{
  pkgs,
  config,
  lib,
  secrets,
  secretsPath,
  ...
}: let
  cfg = config.localModules.ssh;

  ssh_config = pkgs.callPackage (secretsPath + /ssh) {inherit secrets;};
in {
  options.localModules.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      matchBlocks = ssh_config.matchBlocks;
    };

    # TODO: Remove if home.file allows setting mode: https://github.com/nix-community/home-manager/issues/3090
    home.activation.copySshPrivateKey = let
      id_rsa = pkgs.writeText "id_rsa" (builtins.readFile (secretsPath + /ssh/id_rsa));
      target = config.home.homeDirectory + "/.ssh/id_rsa";
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD rm -f ${target}
        $DRY_RUN_CMD cp ${id_rsa} ${target}
        $DRY_RUN_CMD chmod 600 ${target}
      '';
  };
}
