{ stdenvNoCC, lib, fetchzip }:

stdenvNoCC.mkDerivation {
  pname = "omniwm";
  version = "0.6.1";

  src = fetchzip {
    url = "https://github.com/BarutSRB/OmniWM/releases/download/v0.6.1/OmniWM-v0.6.1.zip";
    hash = "sha256-vJlHMODd3bJaXH2Xtxi8BvH6xyMOiaJlzjb/SjXICQQ=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/Applications
    cp -r OmniWM.app $out/Applications/
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
