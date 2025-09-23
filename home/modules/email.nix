{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules."email";
  cat = lib.getExe' pkgs.coreutils "cat";
  # Need 0.20 or newer for {client_id,client_secret}_cmd
  oamaPkg = pkgs.unstable.oama.override {withGpg = true;};
  oama = lib.getExe oamaPkg;
in {
  options.localModules."email" = {
    enable = lib.mkEnableOption "email";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "google/client_id" = {};
      "google/client_secret" = {};
      "stalwart/url" = {};
      "stalwart/username" = {};
      "stalwart/password" = {};
    };

    xdg.configFile."oama/config.yaml".source = (pkgs.formats.yaml {}).generate "oama-config.yaml" {
      encryption = {
        tag = "GPG";
        contents = "oama";
      };
      services.google = {
        redirect_uri = "http://localhost:8877";
        client_id_cmd = lib.concatStringsSep " " [
          cat
          config.sops.secrets."google/client_id".path
        ];
        client_secret_cmd = lib.concatStringsSep " " [
          cat
          config.sops.secrets."google/client_secret".path
        ];
        auth_scope = lib.concatStringsSep " " [
          "https://mail.google.com/"
          "https://www.googleapis.com/auth/carddav"
          "https://www.googleapis.com/auth/calendar"
        ];
      };
    };

    home.packages = [
      oamaPkg
      pkgs.vdirsyncer
    ];
  };
}
