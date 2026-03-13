{pkgs, ...}: {
  localModules = {
    aerospace.enable = true;
    common.enable = true;
    karabiner-elements.enable = true;
    linuxBuilder.enable = true;
  };

  environment.systemPackages = [
    pkgs.nvtopPackages.apple
  ];

  networking = {
    computerName = "Andrei’s MacBook Pro";
    hostName = "Andreis-MacBook-Pro";
  };
}
