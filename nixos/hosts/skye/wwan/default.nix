{pkgs, ...}: {
  networking.modemmanager = {
    fccUnlockScripts = [
      {
        id = "8086:7560";
        # From ModemManager!1496 (unmerged), with the shebang patched and the
        # at+cfun=1 !1496 dropped put back; without it MM can't enable the modem.
        path = ./8086-7560;
      }
    ];
  };

  systemd.services.ModemManager = {
    enable = true;
    wantedBy = ["multi-user.target" "network.target"];
    path = [pkgs.bash pkgs.gawk pkgs.xxd];
  };
}
