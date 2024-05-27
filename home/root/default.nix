{
  pkgs,
  config,
  lib,
  osConfig,
  secrets,
  secretsPath,
  ...
}: {
  home = {
    stateVersion = osConfig.system.stateVersion;

    # TODO: Nix-ify SSH config
    file.".ssh/config".source = secretsPath + /ssh/ssh_config_root;

    # TODO: Remove if home.file allows setting mode: https://github.com/nix-community/home-manager/issues/3090
    activation.copySshPrivateKey = let
      id_rsa = pkgs.writeText "id_rsa" (builtins.readFile (secretsPath + /ssh/id_rsa));
      target = config.home.homeDirectory + "/.ssh/id_rsa";
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD rm -f ${target}
        $DRY_RUN_CMD cp ${id_rsa} ${target}
        $DRY_RUN_CMD chmod 600 ${target}
      '';

    file.".docker/config.json".source = secrets.docker."config.json";
  };
}
