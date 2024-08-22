{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.redir;

  redirSubmodule = lib.types.submodule {
    options = {
      src = lib.mkOption {
        type = lib.types.str;
        example = ":80";
        description = ''
          Source.
        '';
      };

      dst = lib.mkOption {
        type = lib.types.str;
        example = "127.0.0.1:8080";
        description = ''
          Destination.
        '';
      };
    };
  };
in {
  options.localModules.redir = lib.mkOption {
    type = lib.types.attrsOf redirSubmodule;
    default = {};
    description = ''
      Redir definitions.
    '';
  };

  config = {
    systemd.services = lib.mkMerge (lib.mapAttrsToList (name: opts: {
        "redir-${name}" = {
          description = "redir for ${name}";
          serviceConfig = {
            Restart = "on-failure";
            Type = "simple";
            ExecStart = "${lib.getExe pkgs.redir} -sn ${opts.src} ${opts.dst}";
          };
          wantedBy = ["multi-user.target"];
        };
      })
      cfg);
  };
}
