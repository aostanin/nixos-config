{
  config,
  pkgs,
  inputs,
  secrets,
  modulesPath,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/raspberry-pi/3"
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "octopi";
    useDHCP = true;
  };

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];
}
