{
  lib,
  pkgs,
  config,
  ...
}: let
  # TODO: Audio only works on second launch on, and input only works if Wayland session is logged in?
  # Input only works because uaccess means user with seat is needed. When logged into wayland, user gets a seat
  cfg = config.localModules.headlessGaming;

  sunshinePkg =
    (pkgs.sunshine.override {
      cudaSupport = true;
      # Workaround for build https://github.com/NixOS/nixpkgs/issues/240795#issuecomment-1616015395
      stdenv = pkgs.cudaPackages.backendStdenv;
    })
    .overrideAttrs (old: {
      # Sunshine can crash when updating the tray https://github.com/LizardByte/Sunshine/pull/2013
      cmakeFlags = old.cmakeFlags or [] ++ ["-DSUNSHINE_ENABLE_TRAY=OFF" "-DSUNSHINE_REQUIRE_TRAY=OFF"];
    });

  xorgConf = let
    xorgConfig = ''
      Section "ServerFlags"
        # Prevent X from grabbing other GPUs
        Option "AutoAddGPU" "false"
        Option "AutoBindGPU" "false"

        # Disable keybindings
        Option "DontVTSwitch" "true"
        Option "DontZap" "true"
        Option "DontZoom" "true"
      EndSection

      Section "ServerLayout"
        Identifier "Layout0"
        Screen "Screen0"
      EndSection

      Section "Screen"
        Identifier "Screen0"
        Device "Device0"
        Monitor "Monitor0"
        DefaultDepth 24
        Option "TwinView" "true"
        SubSection "Display"
            Modes "1920x1080"
        EndSubSection
      EndSection

      Section "Device"
        Identifier "Device0"
        Driver "nvidia"
        BusID "${cfg.gpuBusId}"
        Option "ProbeAllGpus" "false"
        Option "MetaModes" "1920x1080"
        # Fake connected monitor
        Option "ConnectedMonitor" "DP-0"
        Option "UseEDID" "false"
        Option "ModeValidation" "NoDFPNativeResolutionCheck,NoVirtualSizeCheck,NoMaxPClkCheck,NoHorizSyncCheck,NoVertRefreshCheck,NoWidthAlignmentCheck"
      EndSection

      Section "Monitor"
        Identifier "Monitor0"
        Option "Enable" "true"
      EndSection
    '';
    xserverCfg = config.services.xserver;
    fontsForXServer =
      config.fonts.packages
      ++ [
        pkgs.xorg.fontadobe100dpi
        pkgs.xorg.fontadobe75dpi
      ];
  in
    # Taken from https://github.com/NixOS/nixpkgs/blob/f757546d0fbd88e37026ab526573c1099e9afa2e/nixos/modules/services/x11/xserver.nix#L106-L135
    pkgs.runCommand "xserver.conf"
    {
      config = xorgConfig;
      preferLocalBuild = true;
    }
    ''
      echo 'Section "Files"' >> $out
      for i in ${toString fontsForXServer}; do
        if test "''${i:0:''${#NIX_STORE}}" == "$NIX_STORE"; then
          for j in $(find $i -name fonts.dir); do
            echo "  FontPath \"$(dirname $j)\"" >> $out
          done
        fi
      done

      for i in $(find ${toString xserverCfg.modules} -type d | sort); do
        if test $(echo $i/*.so* | wc -w) -ne 0; then
          echo "  ModulePath \"$i\"" >> $out
        fi
      done

      echo 'EndSection' >> $out
      echo >> $out

      echo "$config" >> $out
    '';

  xinitScript = pkgs.writeShellScript "xinitrc" ''
    exec ${lib.getExe' pkgs.matchbox "matchbox-window-manager"} -use_titlebar no &
    /run/wrappers/bin/sunshine
  '';

  headlessGamingScript = pkgs.writeShellScriptBin "headless-gaming" ''
    ${lib.getExe pkgs.xorg.xinit} ${xinitScript} -- ${lib.getExe pkgs.xorg.xorgserver} :${toString cfg.vt} \
      -nolisten tcp -nolisten local \
      -config ${xorgConf} \
      -sharevts -novtswitch \
      -seat ${cfg.seat}
  '';
in {
  options.localModules.headlessGaming = {
    enable = lib.mkEnableOption "headless gaming";

    gpuBusId = lib.mkOption {
      type = lib.types.str;
      example = "PCI:1:0:0";
    };

    seat = lib.mkOption {
      type = lib.types.str;
      default = "seat1";
    };

    vt = lib.mkOption {
      type = lib.types.int;
      default = 99;
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # For Sunshine
      KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", GROUP="input", MODE="0660"

      # Assign Sunshine devices to seat
      SUBSYSTEM=="input", ATTRS{id/product}=="dead", ATTRS{id/vendor}=="beef", TAG+="seat", TAG+="${cfg.seat}", ENV{ID_SEAT}="${cfg.seat}"
      SUBSYSTEM=="input", ATTRS{id/product}=="4038", ATTRS{id/vendor}=="046d", TAG+="seat", TAG+="${cfg.seat}", ENV{ID_SEAT}="${cfg.seat}"

      # What loginctl attach does https://github.com/systemd/systemd/blob/ef9eb646e5fb7b460aca25de06d1315fcf44ca19/src/login/logind-dbus.c#L1559
      # TODO: Dynamically add to /run/udev/rules.d and run udevadm trigger
      #TAG=="seat", ENV{ID_FOR_SEAT}=="drm-pci-0000_01_00_0", ENV{ID_SEAT}="${cfg.seat}"
    '';

    # Handles loading uinput and other permissions
    hardware.steam-hardware.enable = true;

    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = lib.getExe' sunshinePkg "sunshine";
    };

    services.xserver = {
      # Only needed to let NixOS setup services.xserver.modules
      enable = true;
      videoDrivers = ["nvidia"];
    };

    environment.systemPackages = [
      headlessGamingScript
    ];
  };
}
