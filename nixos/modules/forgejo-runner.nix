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
      instances.default = let
        arch =
          if pkgs.system == "aarch64-linux"
          then "-arm64"
          else "";
      in {
        enable = true;
        name = config.networking.hostName;
        url = secrets.forgejo.url;
        tokenFile = config.sops.secrets."forgejo/runner_token".path;
        labels = [
          "nixos${arch}:host"
          "ubuntu-latest${arch}:docker://catthehacker/ubuntu:act-latest"
          "ubuntu-22.04${arch}:docker://catthehacker/ubuntu:act-22.04"
        ];
      };
    };
  };
}
