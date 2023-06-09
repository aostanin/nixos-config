{
  config,
  pkgs,
  ...
}: {
  hardware.bluetooth = {
    enable = true;
    settings.General.Experimental = true;
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };
}
