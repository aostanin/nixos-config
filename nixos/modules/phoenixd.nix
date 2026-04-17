{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.phoenixd;
in {
  options.localModules.phoenixd = {
    enable = lib.mkEnableOption "phoenixd";

    package = lib.mkPackageOption pkgs "phoenixd" {};

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/phoenixd";
      description = ''
        Directory to store phoenixd state (seed, database, config).
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--chain=testnet" "--auto-liquidity=off"];
      description = ''
        Extra arguments to pass to phoenixd.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 phoenixd phoenixd -"
    ];

    systemd.services.phoenixd = {
      after = ["network.target" "network-online.target"];
      wants = ["network.target" "network-online.target"];
      wantedBy = ["multi-user.target"];
      environment.PHOENIX_DATADIR = cfg.dataDir;
      serviceConfig = {
        User = "phoenixd";
        Group = "phoenixd";
        Restart = "on-failure";
      };
      script = ''
        ${lib.getExe' cfg.package "phoenixd"} \
          ${lib.escapeShellArgs cfg.extraArgs}
      '';
    };

    users = {
      users.phoenixd = {
        group = "phoenixd";
        isSystemUser = true;
      };

      groups.phoenixd = {};
    };
  };
}
