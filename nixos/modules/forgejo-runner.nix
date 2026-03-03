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
      package = pkgs.forgejo-runner;
      instances.default = let
        arch =
          if pkgs.stdenv.hostPlatform.system == "aarch64-linux"
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
          "ubuntu-24.04${arch}:docker://catthehacker/ubuntu:act-24.04"
        ];
        settings = {
          container.docker_host =
            if config.virtualisation.podman.enable
            then "unix:///run/podman/podman.sock"
            else "unix:///run/docker.sock";
        };
      };
    };
  };
}
