{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  cfg = config.localModules.forgejo-runner;
in {
  options.localModules.forgejo-runner = {
    enable = lib.mkEnableOption "forgejo-runner";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."forgejo/runner_token" = {};

    services.gitea-actions-runner = {
      package = pkgs.forgejo-actions-runner;
      instances.default = {
        enable = true;
        name = config.networking.hostName;
        url = secrets.forgejo.url;
        tokenFile = config.sops.secrets."forgejo/runner_token".path;
        labels = [
          "nixos:host"
          "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
          "ubuntu-22.04:docker://catthehacker/ubuntu:act-22.04"
        ];
      };
    };
  };
}
