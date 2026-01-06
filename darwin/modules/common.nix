{
  config,
  pkgs,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.common;
in {
  options.localModules.common = {
    enable = lib.mkEnableOption "common";
  };

  config = lib.mkIf cfg.enable {
    localModules.homebrew.enable = lib.mkDefault true;

    system.primaryUser = secrets.user.username;

    nix = {
      enable = true;
      settings = {
        experimental-features = ["nix-command" "flakes"];
        trusted-users = [
          "root"
          "@admin"
        ];
      };
    };

    programs.zsh.enable = true;

    security.sudo.extraConfig = ''
      %admin ALL = (ALL) NOPASSWD: ALL
    '';

    fonts.packages = with pkgs; [
      nerd-fonts.hack
      noto-fonts
    ];

    environment.variables = {
      LANG = "en_US.UTF-8";
      LC_TIME = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
    };

    services = {
      openssh.enable = true;

      tailscale.enable = true;
    };

    system.defaults = {
      ActivityMonitor.IconType = 6; # CPU History

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "WhenScrolling";
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        "com.apple.keyboard.fnState" = true; # F-keys behave as standard function keys
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleTemperatureUnit = "Celsius";
        AppleICUForce24HourTime = true;
      };

      WindowManager.EnableStandardClickToShowDesktop = false;

      menuExtraClock = {
        Show24Hour = true;
        ShowAMPM = false;
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
        ShowDate = 0; # When space allows
        ShowSeconds = false;
      };

      controlcenter = {
        BatteryShowPercentage = true;
        Sound = true;
        Bluetooth = true;
        AirDrop = false;
        Display = true;
        FocusModes = false;
        NowPlaying = false;
      };

      dock = {
        autohide = true;
        mru-spaces = false;
        orientation = "left";
        show-recents = false;
        static-only = true;
      };

      finder = {
        AppleShowAllFiles = true;
        ShowStatusBar = true;
        ShowPathbar = false;
        FXDefaultSearchScope = "SCcf"; # Current folder
        FXPreferredViewStyle = "Nlsv"; # List view
        AppleShowAllExtensions = true;
        CreateDesktop = false;
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
        FXEnableExtensionChangeWarning = false;
        NewWindowTarget = "Home";
      };

      hitoolbox.AppleFnUsageType = "Do Nothing";

      screencapture = {
        disable-shadow = true;
        target = "clipboard";
      };

      spaces.spans-displays = true;

      trackpad = {
        TrackpadRightClick = true;
        TrackpadFourFingerPinchGesture = 0;
        TrackpadFourFingerVertSwipeGesture = 0;
        TrackpadThreeFingerHorizSwipeGesture = 0;
        TrackpadThreeFingerVertSwipeGesture = 0;
      };

      universalaccess = {
        reduceMotion = true;
        reduceTransparency = true;
      };
    };
  };
}
