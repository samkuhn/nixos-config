{pkgs, ...}: let
  pname = "cursor";
  version = "0.32.2";

  src = pkgs.fetchurl {
    # this will break if the version is updated.
    # unfortunately, i couldn't seem to find a url that
    # points to a specific version.
    # alternatively, download the appimage manually and
    # include it via src = ./cursor.AppImage, instead of fetchurl
    url = "https://download.cursor.sh/linux/appImage/x64";
    hash = "sha256-q2aQWMUp6Ay5kThrH/QSAFozz8IRqzySOcsM9Cy/vKo=";
  };
  appimageContents = pkgs.appimageTools.extract {inherit pname version src;};
in
  with pkgs;
    appimageTools.wrapType2 {
      inherit pname version src;
      extraInstallCommands = ''
        install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
        substituteInPlace $out/share/applications/${pname}.desktop \
          --replace 'Exec=AppRun' 'Exec=${pname}'
        cp -r ${appimageContents}/usr/share/icons $out/share

        # unless linked, the binary is placed in $out/bin/cursor-someVersion
        ln -s $out/bin/${pname}-${version} $out/bin/${pname}
      '';

      extraBwrapArgs = [
        "--bind-try /etc/nixos/ /etc/nixos/"
      ];

      # vscode likes to kill the parent so that the
      # gui application isn't attached to the terminal session
      dieWithParent = false;

      extraPkgs = pkgs: [
        unzip
        autoPatchelfHook
        asar
        # override doesn't preserve splicing https://github.com/NixOS/nixpkgs/issues/132651
        (buildPackages.wrapGAppsHook.override {inherit (buildPackages) makeWrapper;})
      ];
    }