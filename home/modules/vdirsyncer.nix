{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules."vdirsyncer";
  cat = lib.getExe' pkgs.coreutils "cat";
  oamaPkg = pkgs.oama.override {withGpg = true;};
in {
  options.localModules."vdirsyncer" = {
    enable = lib.mkEnableOption "vdirsyncer";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "google/client_id" = {};
      "google/client_secret" = {};
      "stalwart/url" = {};
      "stalwart/username" = {};
      "stalwart/password" = {};
      "vdirsyncer/home_email" = {};
      "vdirsyncer/work_email" = {};
      "vdirsyncer/home_calendar_uuid" = {};
      "vdirsyncer/work_calendar_uuid" = {};
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

    sops.templates."vdirsyncer-config".content = ''
      [general]
      status_path = "${config.xdg.dataHome}/vdirsyncer/status"

      [pair calendar_home]
      a = "calendar_home_remote"
      b = "calendar_stalwart_remote"
      collections = [["${config.sops.placeholder."vdirsyncer/home_email"}", "${config.sops.placeholder."vdirsyncer/home_email"}", "${config.sops.placeholder."vdirsyncer/home_calendar_uuid"}"]]
      conflict_resolution = "a wins"

      [pair calendar_work]
      a = "calendar_work_remote"
      b = "calendar_stalwart_remote"
      collections = [["${config.sops.placeholder."vdirsyncer/work_email"}", "${config.sops.placeholder."vdirsyncer/work_email"}", "${config.sops.placeholder."vdirsyncer/work_calendar_uuid"}"]]
      conflict_resolution = "a wins"

      [storage calendar_home_remote]
      client_id.fetch = ["command", "${cat}", "${config.sops.secrets."google/client_id".path}"]
      client_secret.fetch = ["command", "${cat}", "${config.sops.secrets."google/client_secret".path}"]
      token_file = "${config.xdg.stateHome}/vdirsyncer/token-home"
      type = "google_calendar"

      [storage calendar_work_remote]
      client_id.fetch = ["command", "${cat}", "${config.sops.secrets."google/client_id".path}"]
      client_secret.fetch = ["command", "${cat}", "${config.sops.secrets."google/client_secret".path}"]
      token_file = "${config.xdg.stateHome}/vdirsyncer/token-work"
      type = "google_calendar"

      [storage calendar_stalwart_remote]
      url.fetch = ["command", "${cat}", "${config.sops.secrets."stalwart/url".path}"]
      username.fetch = ["command", "${cat}", "${config.sops.secrets."stalwart/username".path}"]
      password.fetch = ["command", "${cat}", "${config.sops.secrets."stalwart/password".path}"]
      type = "caldav"
    '';

    services.vdirsyncer = {
      enable = true;
      configFile = config.sops.templates."vdirsyncer-config".path;
    };
  };
}
