{
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./backup.nix
    ./home-assistant.nix
    ./kernel.nix
    ./network.nix
    ./router.nix
    ./power-management.nix
    ./wlan.nix
    ./wwan.nix
  ];

  networking.hostName = "every-router";

  # 26.05 stage-1 systemd runs the activation script inside an initrd chroot
  # (`initrd-nixos-activation.service` → `chroot /sysroot prepare-root` →
  # `$systemConfig/activate`) BEFORE switch-root. On this MT7986 the activation
  # consistently hangs at the `setupSecretsForUsers` step, which invokes
  # `sops-install-secrets`. Falling back to the legacy bash stage-1 init runs
  # activation post-switch-root and avoids the hang. This is deprecated and is
  # slated for removal in NixOS 26.11 — revisit then.
  #
  # Investigation summary (2026-06-02):
  # 1. First failed boot: serial showed
  #      `crypto/rand: blocked for 60 seconds waiting to read random data`
  #    Go's getrandom(2) was blocking because the kernel crng was not yet
  #    initialised at the moment activation ran (~13s vs `crng init done` at
  #    ~15s in a normal boot of the same kernel).
  # 2. Added `rng_core.default_quality=1024` kernel param — no change. The
  #    mtk-rng driver likely already self-reports quality > 0, so the kernel
  #    parameter is a no-op for this device.
  # 3. Added a `seed-entropy` initrd systemd unit that ran
  #      `timeout 5 rngd -f -r /dev/hwrng`
  #    ordered Before=initrd-nixos-activation.service. rngd ran successfully
  #    and the `crypto/rand: blocked` warning DID NOT reappear — so the kernel
  #    pool was initialised in time. But activation still hung at
  #    "setting up secrets for users..." for the full 2-minute timeout, this
  #    time consuming ~100% CPU for the entire duration (1min 59.673s CPU
  #    over 1min 59.999s wall clock per the systemd service exit log). Cause
  #    of the busy-loop unidentified — could be a sops-install-secrets bug in
  #    the initrd chroot context, a Go runtime quirk on aarch64, or something
  #    else. Did not reach root cause before reverting.
  #
  # When revisiting: try (a) running sops under strace/perf in initrd to see
  # what the busy loop is, (b) check for upstream sops-nix / nixpkgs fixes,
  # (c) consider the `system.nixos-init` alternative initrd path (Rust-based,
  # introduced in 26.05 as the eventual replacement and may not hit this).
  boot.initrd.systemd.enable = false;

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };

    # FIXME: When cloudflared is enabled, all network traffic breaks when Starlink is disconnected
    # cloudflared.enable = true;

    tailscale = {
      isServer = true;
      extraFlags = [
        "--advertise-exit-node"
        "--advertise-routes=10.0.50.0/24"
      ];
    };

    traefik.enable = true;
  };

  # TODO: Change default gateway based on if Starlink is actually connected

  services.traefik.dynamicConfigOptions = {
    http.routers.home-assistant = {
      rule = "Host(`every.${config.localModules.containers.domain}`)";
      entrypoints = "websecure";
      service = "home-assistant";
    };
    http.services.home-assistant.loadbalancer.servers = [
      {url = "http://127.0.0.1:8123";}
    ];
  };
}
