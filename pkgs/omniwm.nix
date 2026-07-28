{ stdenvNoCC, lib, fetchzip }:

stdenvNoCC.mkDerivation {
  pname = "omniwm";
  version = "0.5.9";

  src = fetchzip {
    url = "https://github.com/BarutSRB/OmniWM/releases/download/v0.5.9/OmniWM-v0.5.9.zip";
    hash = "sha256-9yZSO/xk0g72XQtG0Y/2ca64QxqItryMGtFl3o8aqYo=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/Applications/OmniWM.app
    cp -r Contents $out/Applications/OmniWM.app/
    mkdir -p $out/bin
    ln -s $out/Applications/OmniWM.app/Contents/MacOS/omniwmctl $out/bin/omniwmctl
  '';

  meta = {
    description = "Niri and Hyprland inspired tiling window manager for macOS";
    homepage = "https://github.com/BarutSRB/OmniWM";
    license = lib.licenses.gpl2Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "omniwmctl";
  };
}
