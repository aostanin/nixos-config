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

  systemd.services.ModemManager = {
    enable = true;
    wantedBy = ["multi-user.target" "network.target"];
  };

  # Restart ModemManager when WWAN interface appears
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="ww*", DRIVERS=="qmi_wwan", RUN+="${pkgs.systemd}/bin/systemctl restart ModemManager"
  '';
}
