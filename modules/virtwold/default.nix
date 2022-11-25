{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.virtwold;
in {
  options.services.virtwold = {
    enable = mkEnableOption "virtwold";

    interfaces = mkOption {
      type = types.listOf types.str;
      example = ["br0"];
      description = ''
        The interfaces to listen on.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services = mkMerge (map (interface: {
        "virtwold-${interface}" = {
          description = "libvirt wake on lan daemon on ${interface}";
          after = ["network.target"];
          wants = ["libvirtd.service"];
          serviceConfig = {
            Restart = "on-failure";
            Type = "simple";
            ExecStart = "${pkgs.virtwold}/bin/virtwold -interface ${interface}";
          };
          wantedBy = ["multi-user.target"];
        };
      })
      cfg.interfaces);
  };
}
