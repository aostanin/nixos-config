{ config, pkgs, ... }:

{
  boot.blacklistedKernelModules = [
    "ast" # Conflicts with nvidia
  ];

  users.users.kodi = {
    isNormalUser = true;
    extraGroups = [
      "input"
      "video"
    ];
  };

  environment.systemPackages = with pkgs; [
    (kodi.withPackages (p: with p; [
      jellyfin
      pvr-iptvsimple
      youtube
    ]))
    firefox
  ];

  # Needed for KMS
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${(pkgs.unstable.sunshine.override {
      # TODO: Fails with cuda support
      # cudaSupport = true;
    })}/bin/sunshine";
  };

  services.udev.extraRules = ''
    # For sunshine
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  services.xserver = {
    enable = true;
    layout = "jp";
    resolutions = [{ x = 1920; y = 1080; }];
    displayManager = {
      defaultSession = "none+bspwm";
      autoLogin = {
        enable = true;
        user = "kodi";
      };
      lightdm.enable = true;
    };
    windowManager.bspwm.enable = true;
  };

  # Needed for VAAPI
  hardware.nvidia.modesetting.enable = true;

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
  };
}
