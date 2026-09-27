{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.mime-apps;

  browser = ["firefox.desktop"];
  editor = ["nvim.desktop"];
  pdf = ["org.pwmt.zathura-pdf-mupdf.desktop"];
  ebook = ["okularApplication_epub.desktop"];
  files = ["thunar.desktop"];
in {
  options.localModules.mime-apps = {
    enable = lib.mkEnableOption "mime-apps";
  };

  config = lib.mkIf cfg.enable {
    # Without an explicit mimeapps.list, xdg-open picks whichever .desktop sorts
    # first in mimeinfo.cache, which lands on chromium for links and images,
    # handbrake for video and audacity for audio.
    xdg.mimeApps = {
      enable = true;

      # These take priority over defaultApplicationPackages below.
      defaultApplications = {
        "text/html" = browser;
        "application/xhtml+xml" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        # Not declared by any .desktop; synthesised by `xdg-settings set
        # default-web-browser`. x-scheme-handler/unknown is the fallback apps
        # hand to xdg-open for schemes they don't recognise.
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;

        "application/pdf" = pdf;
        "application/epub+zip" = ebook;

        # gwenview and kate both claim inode/directory, so thunar loses the
        # mimeinfo.cache race without this.
        "inode/directory" = files;

        "text/markdown" = editor;
        "application/json" = editor;

        # gwenview can display these, but a double-click means "edit".
        "application/x-krita" = ["org.kde.krita.desktop"];
        "image/x-xcf" = ["gimp.desktop"];
      };

      # Derive the long tail from each app's own MimeType= list.
      defaultApplicationPackages = [
        config.programs.mpv.finalPackage
        pkgs.kdePackages.gwenview
        config.programs.nixvim.finalPackage
      ];
    };
  };
}
