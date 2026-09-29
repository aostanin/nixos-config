{self, ...}: {
  containers.dev = {
    path = self.nixosConfigurations.dev.config.system.build.toplevel;
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";
    enableTun = true;
  };

  # A runaway agent should hit this instead of taking elena down with it.
  systemd.services."container@dev".serviceConfig.MemoryMax = "32G";
}
