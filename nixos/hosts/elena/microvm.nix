{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.microvm.nixosModules.host];

  # Installed and updated by `deploy .#router`, not by this host's closure.
  microvm.autostart = ["router"];

  # microvm@ skips a VM that isn't installed yet, but set-booted@ fails on the
  # missing state dir and takes the activation down with it.
  systemd.services = lib.genAttrs (map (vm: "microvm-set-booted@${vm}") config.microvm.autostart) (name: {
    overrideStrategy = "asDropin";
    unitConfig.ConditionPathExists = "${config.microvm.stateDir}/${lib.removePrefix "microvm-set-booted@" name}/current";
  });

  # The host module turns KSM on; a single 1 GiB VM leaves too little to merge
  # to be worth ksmd's scanning.
  hardware.ksm.enable = false;

  # The router's tap shares the uplink as a trunk. VLAN filtering keeps WAN,
  # guest and IoT off the host and the other br0 ports.
  systemd.network = let
    trunkVLANs = [
      {
        PVID = 1;
        EgressUntagged = 1;
      }
      {VLAN = 10;}
      {VLAN = 20;}
      {VLAN = 40;}
    ];
  in {
    netdevs.br0.bridgeConfig = {
      VLANFiltering = true;
      DefaultPVID = 1;
    };
    networks = {
      ${config.localModules.home-server.interface}.bridgeVLANs = trunkVLANs;
      vm-router = {
        matchConfig.Name = "vm-router";
        networkConfig = {
          Bridge = "br0";
          LinkLocalAddressing = "no";
        };
        bridgeVLANs = trunkVLANs;
        # Only exists while the VM runs.
        linkConfig.RequiredForOnline = "no";
      };
    };
  };
}
