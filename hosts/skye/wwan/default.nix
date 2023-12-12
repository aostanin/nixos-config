{
  config,
  pkgs,
  ...
}: {
  networking.networkmanager = {
    fccUnlockScripts = [
      {
        # From https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/issues/751#note_2015323
        # More info: https://askubuntu.com/questions/1479540/where-can-i-find-the-wwan-fcc-unlock-for-80867560
        id = "8086:7560";
        # TODO: Calling the script manually works, but not from ModemManager?
        path = pkgs.writers.writePython3 "8086-fcc_unlock" {} ./8086-fcc_unlock.py;
      }
    ];
  };

  systemd.services.ModemManager = {
    enable = true;
    wantedBy = ["multi-user.target" "network.target"];
    # For debugging
    # serviceConfig.ExecStart = ["" "${pkgs.modemmanager}/sbin/ModemManager --debug"];
  };
}
