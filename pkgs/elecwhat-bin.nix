{ stdenv, fetchurl, electron, makeWrapper, copyDesktopItems, makeDesktopItem, wrapGAppsHook3, lib }:

stdenv.mkDerivation rec {
  pname = "elecwhat-bin";
  version = "1.14.0";

  src = fetchurl {
    url = "https://github.com/piec/elecwhat/releases/download/v${version}/elecwhat-${version}.pacman";
    hash = "sha256-GcQdKClPQEgZWmhYFgpmypGhh/pibj1dR2PpvNG2yqw=";
  };

  nativeBuildInputs = [ makeWrapper wrapGAppsHook3 copyDesktopItems ];

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir -p extracted
    tar -xJf $src -C extracted
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/elecwhat/resources $out/bin $out/share/icons/hicolor/256x256/apps
    cp -r extracted/opt/elecwhat/resources/app.asar $out/lib/elecwhat/resources/
    if [ -d extracted/opt/elecwhat/resources/app.asar.unpacked ]; then
      cp -r extracted/opt/elecwhat/resources/app.asar.unpacked $out/lib/elecwhat/resources/
    fi
    # Install bundled icon (the upstream .pacman ships icons under
    # extracted/usr/share/icons/hicolor/<size>/apps/).
    if [ -d extracted/usr/share/icons ]; then
      cp -r extracted/usr/share/icons/* $out/share/icons/hicolor/ 2>/dev/null || true
    fi
    makeWrapper ${electron}/bin/electron $out/bin/elecwhat \
      --add-flags $out/lib/elecwhat/resources/app.asar \
      --prefix XDG_DATA_DIRS : "$out/share" \
      --set ELECTRON_OZONE_PLATFORM_HINT "auto"
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "elecwhat";
      exec = "elecwhat %U";
      icon = "elecwhat";
      comment = "WhatsApp client (piec/elecwhat)";
      categories = [ "Network" "InstantMessaging" "Chat" ];
      terminal = false;
      desktopName = "ElecWhat";
      startupWMClass = "elecwhat";
    })
  ];

  meta = {
    description = "WhatsApp client built with Electron (piec/elecwhat)";
    longDescription = ''
      Despite the project name "elecwhat" (a play on "electronic WhatsApp"),
      this package wraps a WhatsApp desktop client, not an electronics
      reference tool. Upstream: https://github.com/piec/elecwhat.
    '';
    homepage = "https://github.com/piec/elecwhat";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "elecwhat";
  };
}
