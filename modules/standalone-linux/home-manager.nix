{
  inputs,
  userName,
  homeDirectory,
}:
{ config, pkgs, lib, ... }:

let
  standalone-files = import ./files.nix { inherit pkgs; };
in
{
  imports = [ ../linux/home-manager.nix ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = lib.mkDefault userName;
    homeDirectory = lib.mkDefault homeDirectory;
    packages = (import ./packages.nix { inherit pkgs inputs; }) ++ [
      ((pkgs.writeShellScriptBin "codex-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- codex "$@"
      '') // { pname = "codex-wrapped"; })
    ];
    file = standalone-files;
    sessionVariables = {
      BROWSER = "zen-beta";
      TERM = "xterm-256color";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      GTK_THEME = "adw-gtk3-dark";
    };
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
    ];
    stateVersion = "25.11";
  };

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  programs = {
    gpg.enable = true;
    home-manager.enable = true;
  };
}
