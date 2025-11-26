{
  appimageTools,
  fetchurl,
  webkitgtk_4_1,
}: let
  pname = "orca-slicer-appimage";
  version = "2.3.1";

  src = fetchurl {
    url = "https://github.com/OrcaSlicer/OrcaSlicer/releases/download/v${version}/OrcaSlicer_Linux_AppImage_Ubuntu2404_V${version}.AppImage";
    hash = "sha256-8ZnlQIkU79u7+k/WdSzWrUcnIJtIi8R7/5oNpfBTpwE=";
  };

  appimageContents = appimageTools.extract {
    inherit version pname src;
  };
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: [
      webkitgtk_4_1
    ];

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/OrcaSlicer.desktop $out/share/applications/OrcaSlicer.desktop
      install -m 444 -D ${appimageContents}/resources/images/OrcaSlicer.svg $out/share/icons/hicolor/scalable/apps/OrcaSlicer.svg
      substituteInPlace $out/share/applications/OrcaSlicer.desktop --replace-fail "AppRun" "orca-slicer-appimage"
    '';
  }
