{self, ...}: {
  containers.dev = {
    path = self.nixosConfigurations.dev.config.system.build.toplevel;
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";
    enableTun = true;
  };

  # A runaway agent should hit this instead of taking elena down with it. No
  # swap: zram lives in host RAM uncharged, so it would only delay the OOM kill.
  systemd.services."container@dev".serviceConfig = {
    MemoryHigh = "28G";
    MemoryMax = "32G";
    MemorySwapMax = "0";
  };
}
