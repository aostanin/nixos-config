{
  lib,
  secrets,
  ...
}: let
  mac = secrets.network.nics.valmar.integrated;
  interface = "enx${lib.replaceStrings [":"] [""] mac}";
in {
  # br0 for the dev container and the VMs.
  localModules.home-server = {
    enable = true;
    inherit interface;
    inherit (secrets.network.home.hosts.valmar) address;
    # The router's reservation for valmar is keyed on the NIC's MAC.
    macAddress = mac;
  };
}
