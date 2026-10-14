{secrets, ...}: {
  containers.dev = {
    # Installed and switched by `deploy .#dev`, not by this host's closure.
    path = "/nix/var/nix/profiles/per-container/dev/system";
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";
    enableTun = true;
    bindMounts."/home/${secrets.user.username}/dev" = {
      hostPath = "/home/${secrets.user.username}/dev";
      isReadOnly = false;
    };
    # Don't restart it under running agents when this host's nixpkgs moves.
    # Changes to the nspawn side (flags, mounts, network) need an explicit
    # restart.
    restartIfChanged = false;
  };

  # Paseo's web UI, plus its service proxy for workspace dev servers.
  localModules.ingress.paseo = {
    backendUrl = "http://${secrets.network.home.hosts.dev.address}:6767";
    hosts = [
      "paseo.${secrets.domain}"
      "*.paseoapps.${secrets.domain}"
    ];
  };

  # A runaway agent should hit this instead of taking elena down with it. No
  # MemoryHigh: above it the whole container stalls in reclaim indefinitely
  # rather than OOM-killing the culprit. No swap: zram lives in host RAM
  # uncharged, so it would only delay the OOM kill.
  systemd.services."container@dev".serviceConfig = {
    MemoryMax = "32G";
    MemorySwapMax = "0";
  };
}
