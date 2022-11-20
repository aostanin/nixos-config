{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
    smartmontools
    usbutils

    file
    git
    htop
    ncdu
    neovim
    psmisc
    tmux
    wget
    which
  ];
}
