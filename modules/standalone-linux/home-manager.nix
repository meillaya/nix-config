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
      pkgs.nodejs
      ((pkgs.writeShellScriptBin "codex-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- codex "$@"
      '') // { pname = "codex-wrapped"; })
      ((pkgs.writeShellScriptBin "pi-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- pi "$@"
      '') // { pname = "pi-wrapped"; })
      ((pkgs.writeShellScriptBin "hermes-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- hermes "$@"
      '') // { pname = "hermes-wrapped"; })
      ((pkgs.writeShellScriptBin "zeroclaw-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- zeroclaw "$@"
      '') // { pname = "zeroclaw-wrapped"; })
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

  home.activation.installCodingAgents = let
    npm = "${pkgs.nodejs}/bin/npm";
    curl = "${pkgs.curl}/bin/curl";
    bash = "${pkgs.bash}/bin/bash";
  in lib.hm.dag.entryAfter ["writeBoundary"] ''
    install_if_missing() {
      local name="$1" cmd="$2"
      if ! command -v "$name" &>/dev/null; then
        echo "install-coding-agents: installing $name..."
        eval "$cmd"
      else
        echo "install-coding-agents: $name already present, skipping"
      fi
    }
    # npm-based installers use --force because the user's prior manual install
    # may have left symlinks/files at the npm global prefix that block overwrite.
    install_if_missing codex "${npm} install -g --force @openai/codex"
    install_if_missing omx "${npm} install -g --force oh-my-codex"
    install_if_missing omo "${npm} install -g --force oh-my-opencode"
    # curl-based installers are idempotent and overwrite their own paths.
    install_if_missing opencode "${curl} -fsSL https://opencode.ai/install | ${bash}"
    install_if_missing pi "${curl} -fsSL https://pi.dev/install.sh | ${bash}"
    install_if_missing hermes "${curl} -fsSL https://hermes-agent.nousresearch.com/install.sh | ${bash}"
    install_if_missing zeroclaw "${curl} -fsSL https://zeroclawlabs.ai/install.sh | ${bash}"
  '';

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  programs = {
    gpg.enable = true;
    home-manager.enable = true;
  };
}
