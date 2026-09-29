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

  # The host module turns KSM on, but it only scans memory advised as mergeable
  # and the router VM's is pinned by VFIO, so there's nothing to merge.
  hardware.ksm.enable = false;
}
