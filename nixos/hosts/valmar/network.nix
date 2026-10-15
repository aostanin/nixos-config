{
  lib,
  secrets,
  ...
}: let
  mac = secrets.network.nics.valmar.integrated;
  interface = "enx${lib.replaceStrings [":"] [""] mac}";
in {
  # br0 for the dev container and the VMs, as on elena.
  localModules.home-server = {
    enable = true;
    inherit interface;
    inherit (secrets.network.home.hosts.valmar) address;
    # The router's reservation for valmar is keyed on the NIC's MAC.
    macAddress = mac;
  };

  # networkd owns the wired side; NetworkManager keeps Wi-Fi and VPNs.
  networking.networkmanager.unmanaged = [
    "interface-name:br0"
    "interface-name:${interface}"
  ];
}
