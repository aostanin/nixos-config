{
  self,
  secrets,
  ...
}: {
  containers.dev = {
    path = self.nixosConfigurations.dev.config.system.build.toplevel;
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";
    enableTun = true;
    # Deploys switch it in place (see reloadIfChanged below) instead of
    # restarting it under running agents. Changes to the nspawn side (flags,
    # mounts, network) still need an explicit restart.
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
  # swap: zram lives in host RAM uncharged, so it would only delay the OOM kill.
  systemd.services."container@dev".reloadIfChanged = true;
  systemd.services."container@dev".serviceConfig = {
    MemoryHigh = "28G";
    MemoryMax = "32G";
    MemorySwapMax = "0";
  };
}
