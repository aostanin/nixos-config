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

    # CI decryption identity for git-agecrypt'ed files (readable by the
    # DynamicUser runner via supplementary group)
    sops.secrets."forgejo/agecrypt_identity" = {
      group = "forgejo-runner-secrets";
      mode = "0440";
    };
    users.groups.forgejo-runner-secrets = {};
    systemd.services.gitea-runner-default.serviceConfig.SupplementaryGroups = ["forgejo-runner-secrets"];

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
        hostPackages = with pkgs; [
          bash
          config.nix.package
          coreutils
          curl
          gawk
          git-agecrypt
          gitMinimal
          gnused
          nodejs
          wget
        ];
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
          # Default 3h cancels from-source kernel builds
          runner.timeout = "12h";
        };
      };
    };
  };
}
