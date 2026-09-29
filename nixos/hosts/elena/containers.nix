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
  };

  # Paseo reserves its public base hostname and subdomains for workspace dev
  # servers, so the UI reaches it under the backend's own Host.
  localModules.ingress = let
    backendUrl = "http://${secrets.network.home.hosts.dev.address}:6767";
  in {
    paseo = {
      inherit backendUrl;
      hosts = ["paseo.${secrets.domain}"];
      passHostHeader = false;
    };
    paseo-services = {
      inherit backendUrl;
      hosts = ["*.paseo.${secrets.domain}"];
    };
  };

  # A runaway agent should hit this instead of taking elena down with it. No
  # swap: zram lives in host RAM uncharged, so it would only delay the OOM kill.
  systemd.services."container@dev".serviceConfig = {
    MemoryHigh = "28G";
    MemoryMax = "32G";
    MemorySwapMax = "0";
  };
}
