{
  appimageTools,
  fetchurl,
  webkitgtk_4_0,
}: let
  pname = "orca-slicer-appimage";
  version = "2.3.0";

  src = fetchurl {
    url = "https://github.com/SoftFever/OrcaSlicer/releases/download/v${version}/OrcaSlicer_Linux_AppImage_V${version}.AppImage";
    hash = "sha256-cwediOw28GFdt5GdAKom/jAeNIum4FGGKnz8QEAVDAM=";
  };

  appimageContents = appimageTools.extract {
    inherit version pname src;
  };
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: [
      webkitgtk_4_0
    ];

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/OrcaSlicer.desktop $out/share/applications/OrcaSlicer.desktop
      install -m 444 -D ${appimageContents}/resources/images/OrcaSlicer.svg $out/share/icons/hicolor/scalable/apps/OrcaSlicer.svg
    '';
  }
