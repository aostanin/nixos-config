{
  lib,
  secrets,
  ...
}: {
  # br0 for the dev container and the VMs.
  localModules.home-server = {
    enable = true;
    interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.expansion10GbE0}";
    # The router's reservation for valmar is keyed on the onboard NIC's MAC,
    # which br0 keeps.
    inherit (secrets.network.home.hosts.valmar) address macAddress;
  };
}
