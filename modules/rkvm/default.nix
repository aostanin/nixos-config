{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.rkvm;
  pkg = pkgs.rkvm;
in {
  options.localModules.rkvm = {
    enable = lib.mkOption {
      default = cfg.server.enable || cfg.client.enable;
      type = lib.types.bool;
      description = ''
        Enable rkvm, a Virtual KVM switch for Linux machines.
      '';
    };

    client = {
      enable = lib.mkEnableOption "rkvm-client";

      server = lib.mkOption {
        type = lib.types.str;
        example = "10.0.0.1:5258";
        description = ''
          Address of the rkvm server to connect to.
        '';
      };

      certificate = lib.mkOption {
        type = lib.types.str;
        description = ''
          Certificate contents.
        '';
      };

      password = lib.mkOption {
        type = lib.types.str;
        description = ''
          Password to connect to the rkvm server.
        '';
      };
    };

    server = {
      enable = lib.mkEnableOption "rkvm-server";

      listen = lib.mkOption {
        type = lib.types.str;
        example = "0.0.0.0:5258";
        description = ''
          Address to bind to.
        '';
      };

      certificate = lib.mkOption {
        type = lib.types.str;
        description = ''
          Certificate contents.
        '';
      };

      key = lib.mkOption {
        type = lib.types.str;
        description = ''
          Key contents.
        '';
      };

      password = lib.mkOption {
        type = lib.types.str;
        description = ''
          Password to connect to the rkvm server.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      rkvm-server = lib.mkIf cfg.server.enable {
        description = "rkvm server";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = let
          configFile = pkgs.writeText "rkvm-server.toml" ''
            listen = "${cfg.server.listen}"
            switch-keys = ["right-ctrl", "left-ctrl"]
            certificate = "${pkgs.writeText "rkvm-certificate.pem" cfg.server.certificate}"
            key = "${pkgs.writeText "rkvm-key.pem" cfg.server.key}"
            password = "${cfg.server.password}"
          '';
        in {
          ExecStart = "${pkg}/bin/rkvm-server ${configFile}";
          Restart = "always";
          RestartSec = 5;
          Type = "simple";
        };
      };

      rkvm-client = lib.mkIf cfg.client.enable {
        description = "rkvm client";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = let
          configFile = pkgs.writeText "rkvm-client.toml" ''
            server = "${cfg.client.server}"
            certificate = "${pkgs.writeText "rkvm-certificate.pem" cfg.client.certificate}"
            password = "${cfg.client.password}"
          '';
        in {
          ExecStart = "${pkg}/bin/rkvm-client ${configFile}";
          Restart = "always";
          RestartSec = 5;
          Type = "simple";
        };
      };
    };
  };
}
