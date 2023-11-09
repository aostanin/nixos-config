{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.localModules.rkvm;
  pkg = pkgs.unstable.rkvm; # TODO: Use stable once released
in {
  options.localModules.rkvm = {
    enable = mkOption {
      default = cfg.server.enable || cfg.client.enable;
      type = types.bool;
      description = ''
        Enable rkvm, a Virtual KVM switch for Linux machines.
      '';
    };

    client = {
      enable = mkEnableOption "rkvm-client";

      server = mkOption {
        type = types.str;
        example = "10.0.0.1:5258";
        description = ''
          Address of the rkvm server to connect to.
        '';
      };

      certificate = mkOption {
        type = types.str;
        description = ''
          Certificate contents.
        '';
      };

      password = mkOption {
        type = types.str;
        description = ''
          Password to connect to the rkvm server.
        '';
      };
    };

    server = {
      enable = mkEnableOption "rkvm-server";

      listen = mkOption {
        type = types.str;
        example = "0.0.0.0:5258";
        description = ''
          Address to bind to.
        '';
      };

      certificate = mkOption {
        type = types.str;
        description = ''
          Certificate contents.
        '';
      };

      key = mkOption {
        type = types.str;
        description = ''
          Key contents.
        '';
      };

      password = mkOption {
        type = types.str;
        description = ''
          Password to connect to the rkvm server.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services = {
      rkvm-server = mkIf cfg.server.enable {
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

      rkvm-client = mkIf cfg.client.enable {
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
