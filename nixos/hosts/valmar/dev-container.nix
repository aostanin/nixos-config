{
  config,
  secrets,
  ...
}: {
  containers.dev = {
    # Installed and switched by `deploy .#dev`, not by this host's closure.
    # Resolved inside the container, where per-container/dev is mounted at
    # /nix/var/nix/profiles.
    path = "/nix/var/nix/profiles/system";
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

  # State is rpool/containers/dev (received from elena), mounted natively at
  # /var/lib/nixos-containers/dev. Safe because /var/lib is the rolled-back
  # root rather than an impermanence bind.

  # A runaway agent should hit this instead of taking valmar down with it. No
  # MemoryHigh: above it the whole container stalls in reclaim indefinitely
  # rather than OOM-killing the culprit. No swap: zram lives in host RAM
  # uncharged, so it would only delay the OOM kill.
  systemd.services."container@dev".serviceConfig = {
    MemoryMax = "32G";
    MemorySwapMax = "0";
  };

  assertions = [
    {
      assertion = config.localModules.home-server.enable;
      message = "the dev container bridges to br0 (network.nix)";
    }
  ];
}
