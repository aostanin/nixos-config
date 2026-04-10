{pkgs, ...}: {
  # Don't let systemd-networkd manage WWAN interfaces
  systemd.network.networks.wwan = {
    matchConfig.Name = "ww*";
    linkConfig.Unmanaged = true;
  };

  networking.networkmanager = {
    enable = true;
    # Only manage WWAN interfaces
    unmanaged = ["*,except:type:gsm"];
    ensureProfiles.profiles = {
      povo = {
        connection = {
          id = "povo";
          type = "gsm";
          autoconnect = "true";
          metered = "1";
        };
        gsm.apn = "povo.jp";
        ipv4 = {
          method = "auto";
          route-metric = 100;
        };
        ipv6 = {
          addr-gen-mode = "stable-privacy";
          method = "auto";
          route-metric = 100;
        };
      };
    };
  };

  # Wait for udev to settle before starting ModemManager, otherwise it may
  # capture the pre-rename interface name (wwan0) before udev renames it
  # (e.g. to wwu1i4), causing connection attempts to fail.
  systemd.services.ModemManager = {
    enable = true;
    wantedBy = ["multi-user.target" "network.target"];
    serviceConfig.ExecStartPre = ["${pkgs.systemd}/bin/udevadm settle --timeout=30"];
  };
}
