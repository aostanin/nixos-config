{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.virtwold;
in {
  options.localModules.virtwold = {
    enable = lib.mkEnableOption "virtwold";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = ["br0"];
      description = ''
        The interfaces to listen on.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mkMerge (map (interface: {
        "virtwold-${interface}" = {
          description = "libvirt wake on lan daemon on ${interface}";
          after = ["network.target"];
          wants = ["libvirtd.service"];
          serviceConfig = {
            Restart = "on-failure";
            Type = "simple";
            ExecStart = "${lib.getExe pkgs.virtwold} --interface ${interface} --libvirturi qemu:///system";
          };
          wantedBy = ["multi-user.target"];
        };
      })
      cfg.interfaces);
  };
}
