{
  lib,
  config,
  secrets,
  ...
}: let
  name = "mymcp";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    calendarWritable = lib.mkOption {
      type = with lib.types; listOf str;
      default = ["home" "personal" "tasks"];
      description = ''
        Calendars this assistant may write to. `work` is deliberately absent:
        it carries invitations, so a write there would email other people.
        Enforced in the binary, not by prompt.
      '';
    };

    calendarRead = lib.mkOption {
      type = with lib.types; listOf str;
      default = ["home" "work" "personal"];
      description = ''
        Calendars swept when none is named. Must cover every event calendar in
        `calendarWritable`, or the assistant can add an event it will never
        read back; `tasks` holds VTODOs, so it has no place in an event sweep.
        `contact_birthdays` is left out as generated noise.
      '';
    };

    extraSelfEmails = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = ''
        Further addresses that mean "me", beyond the two vdirsyncer already
        holds. Without these, declined invitations render as real events —
        and the work address is the one that appears in invitations.
      '';
    };

    selfNames = lib.mkOption {
      type = with lib.types; listOf str;
      default = [secrets.user.fullName];
      description = ''
        Display names that mean "me". Each bridge gives you a ghost account
        carrying the remote network's name, so without these a bridged DM
        reads as a chat with yourself.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      {"forgejo/registry_token" = {};}
      // lib.genAttrs (map (k: "containers/${name}/${k}") [
        "bearer_token"
        "matrix_url"
        "matrix_token"
        "miniflux_url"
        "miniflux_api_key"
        "searx_url"
        "redlib_url"
        "rwgps_api_key"
        "rwgps_auth_token"
        "grist_url"
        "grist_api_key"
      ]) (_: {})
      // lib.genAttrs [
        "nextcloud/url"
        "nextcloud/username"
        "nextcloud/password"
        # Reused rather than duplicated: the same two addresses vdirsyncer syncs.
        "vdirsyncer/home_email"
        "vdirsyncer/work_email"
      ] (_: {});

    # Same stale-mount trap as searxng: podman reads --env-file once, at
    # container creation.
    sops.templates."${name}.env" = {
      restartUnits = ["podman-${name}.service"];
      content = let
        p = k: config.sops.placeholder."containers/${name}/${k}";
      in ''
        MYMCP_TOKEN=${p "bearer_token"}
        MATRIX_URL=${p "matrix_url"}
        MATRIX_TOKEN=${p "matrix_token"}
        MATRIX_SELF_NAMES=${lib.concatStringsSep "," cfg.selfNames}
        MINIFLUX_URL=${p "miniflux_url"}
        MINIFLUX_API_KEY=${p "miniflux_api_key"}
        SEARX_URL=${p "searx_url"}
        REDLIB_URL=${p "redlib_url"}
        RWGPS_API_KEY=${p "rwgps_api_key"}
        RWGPS_AUTH_TOKEN=${p "rwgps_auth_token"}
        GRIST_URL=${p "grist_url"}
        GRIST_API_KEY=${p "grist_api_key"}
        NEXTCLOUD_URL=${config.sops.placeholder."nextcloud/url"}
        NEXTCLOUD_USER=${config.sops.placeholder."nextcloud/username"}
        NEXTCLOUD_PASSWORD=${config.sops.placeholder."nextcloud/password"}
        CALENDAR_WRITABLE=${lib.concatStringsSep "," cfg.calendarWritable}
        CALENDAR_READ=${lib.concatStringsSep "," cfg.calendarRead}
        CALENDAR_SELF_EMAILS=${lib.concatStringsSep "," (
          [
            config.sops.placeholder."vdirsyncer/home_email"
            config.sops.placeholder."vdirsyncer/work_email"
          ]
          ++ cfg.extraSelfEmails
        )}
      '';
    };

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/${name}:latest";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      # No healthcheck: the image is distroless, so there is no shell or wget to
      # run one with. /healthz answers unauthenticated if something else probes.
      proxy = {
        enable = true;
        port = 8080;
      };
    };
  };
}
