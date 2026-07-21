{
  lib,
  pkgs,
  ...
}: let
  # A connected-but-dead bearer only recovers on a full modem reset, not an NM reconnect.
  wwanWatchdog = pkgs.writeShellScript "wwan-watchdog" ''
    set -u
    PATH=${lib.makeBinPath [pkgs.modemmanager pkgs.networkmanager pkgs.iputils pkgs.coreutils pkgs.gnugrep]}

    # Sysfs USB device (e.g. "2-1") for the Quectel modem, empty if not enumerated.
    quectel_usb_dev() {
      local d
      for d in /sys/bus/usb/devices/*/idVendor; do
        [ "$(cat "$d" 2>/dev/null)" = 2c7c ] || continue
        basename "$(dirname "$d")"
        return 0
      done
      return 1
    }

    # Recovery path A: the QMI control port (cdc-wdm0) can hang, and MM then marks
    # the modem invalid and drops it entirely. povo deactivates, so the data-path
    # probe below never runs and mmcli --reset has no modem to act on. The USB
    # device stays enumerated, so re-enumerate it to reload the modem.
    if ! mmcli -L 2>/dev/null | grep -q '/Modem/'; then
      dev="$(quectel_usb_dev)" || exit 0
      # Confirm it's really gone (not just a transient MM restart) before rebinding.
      sleep 30
      mmcli -L 2>/dev/null | grep -q '/Modem/' && exit 0
      echo "wwan-watchdog: modem dropped but USB $dev present; re-enumerating" >&2
      echo "$dev" > /sys/bus/usb/drivers/usb/unbind 2>/dev/null || true
      sleep 3
      echo "$dev" > /sys/bus/usb/drivers/usb/bind 2>/dev/null || true
      exit 0
    fi

    # Nothing further to recover unless NM has WWAN up (skips a removed SIM).
    [ "$(nmcli -t -g GENERAL.STATE connection show povo 2>/dev/null)" = activated ] || exit 0

    wwan_iface() {
      local i
      i="$(nmcli -t -g GENERAL.IP-IFACE connection show povo 2>/dev/null | head -n1)"
      [ -n "$i" ] || i="$(ls /sys/class/net 2>/dev/null | grep -m1 '^ww')"
      printf '%s' "$i"
    }

    probe_ok() {
      # Bind to the WWAN iface so we test it, not a lower-metric default (Starlink).
      local iface bind
      iface="$(wwan_iface)"
      bind=""
      [ -n "$iface" ] && bind="-I $iface"
      ping $bind -c1 -W3 1.1.1.1 >/dev/null 2>&1 && return 0
      ping $bind -c1 -W3 8.8.8.8 >/dev/null 2>&1 && return 0
      return 1
    }

    # Require sustained failure so a transient blip can't trigger a reset.
    for _ in $(seq 1 6); do
      probe_ok && exit 0
      sleep 10
    done

    echo "wwan-watchdog: sustained connectivity loss on '$(wwan_iface)'; resetting modem" >&2
    mmcli -m any --reset 2>&1 || true

    sleep 60
    if probe_ok; then
      echo "wwan-watchdog: connectivity restored after modem reset" >&2
    else
      echo "wwan-watchdog: still no connectivity after modem reset; manual attention needed" >&2
    fi
  '';
in {
  systemd.services.wwan-watchdog = {
    description = "Probe the WWAN data path and reset a zombie modem";
    after = ["ModemManager.service" "NetworkManager.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = wwanWatchdog;
    };
  };
  systemd.timers.wwan-watchdog = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "3min";
    };
  };

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
