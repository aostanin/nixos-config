{
  lib,
  fetchurl,
  appimageTools,
  pkgs,
}: let
  pname = "immersed";
  version = "6.8";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "https://immersed.com/dl/Immersed-x86_64.AppImage";
    name = "${pname}-${version}.AppImage";
    sha512 = "qCuY0rJOoSGC0cpbi6CPtqhhlWqEzoRRUzxzdAhVh7WxycGdSYrLycJdSutqfRbI2Fqs6W2xYAE9AUpEpnQb3g==";
  };

  appimageContents = appimageTools.extractType2 {
    inherit name src;
  };
in
  appimageTools.wrapType2 {
    inherit name src;

    multiPkgs = null; # no 32bit needed
    extraPkgs = pkgs:
      (appimageTools.defaultFhsEnvArgs.multiPkgs pkgs)
      ++ [pkgs.libpulseaudio pkgs.libva];

    extraInstallCommands = ''
      ln -s $out/bin/${name} $out/bin/${pname}
      install -m 444 -D ${appimageContents}/Immersed.desktop $out/share/applications/immersed.desktop
      install -m 444 -D ${appimageContents}/Immersed.png \
        $out/share/icons/hicolor/512x512/apps/immersed.png
      substituteInPlace $out/share/applications/immersed.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
    '';
  }
