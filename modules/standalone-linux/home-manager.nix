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
      ((pkgs.writeShellScriptBin "kimi-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
        SECRETS_FILE="${config.home.homeDirectory}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- kimi "$@"
      '') // { pname = "kimi-wrapped"; })
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
    tar = "${pkgs.gnutar}/bin";
    gzip = "${pkgs.gzip}/bin";
    bzip2 = "${pkgs.bzip2}/bin";
    xz = "${pkgs.xz}/bin";
    uv = pkgs.uv;
    # npm postinstall scripts for oh-my-opencode invoke `node -e`
    # via `sh -c`; npm rebuilds the script env in a way that drops the parent
    # PATH, so the postinstall cannot find node even when activation PATH includes
    # the nix-store nodejs bin. --ignore-scripts mirrors pkgs/opencode-omo.nix:33-34;
    # the package author wraps the postinstall in a try/catch with the message
    # "[omx] Postinstall skipped after a non-fatal error". @openai/codex is left
    # untouched (its install succeeds in the original failure log and its
    # postinstall is unanalyzed).
    # The activation PATH is prefixed with `${pkgs.gnutar}/bin`,
    # `${pkgs.gzip}/bin`, `${pkgs.bzip2}/bin`, `${pkgs.xz}/bin`,
    # `${pkgs.bash}/bin`, `${pkgs.curl}/bin`, and `${pkgs.unzip}/bin`
    # because the opencode curl|bash installer (the only remaining
    # curl|bash line in this activation block) downloads a .tar.gz and
    # extracts it with `tar` on Linux but a .zip with `unzip` on macOS,
    # and the HM activation PATH excludes /usr/bin and the host's
    # interactive shell PATH. pi and zeroclaw used to be here too but
    # their installers are TTY-interactive and removed; the user
    # installs them manually (see README). hermes is automated below
    # via `uv tool install hermes-agent` (non-interactive, idempotent).
  in lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="${tar}:${gzip}:${bzip2}:${xz}:${pkgs.bash}/bin:${pkgs.curl}/bin:${pkgs.unzip}/bin:$PATH:$HOME/.local/bin:$HOME/.kimi-code/bin"
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
    # 5.0 renamed the launcher bin `omo` -> `omo-agent-toolkit`; pin the
    # same beta.7 version as pkgs/opencode-omo.nix.
    install_if_missing omo-agent-toolkit "${npm} install -g --ignore-scripts --force oh-my-opencode@5.0.0-beta.7"
    # kimi is installed manually with the official installer (single binary at
    # ~/.kimi-code/bin/kimi, already on the shell PATH); its npm postinstall
    # invokes `node` via `sh -c` and fails under the HM activation PATH, and
    # the npm route would shadow the official binary via PATH ordering.
    install_if_missing hermes "${uv}/bin/uv tool install hermes-agent"
    # curl-based installers are idempotent and overwrite their own paths.
    # opencode is non-interactive and runs unattended; pi and zeroclaw
    # have interactive TTY-only installers and must be installed manually
    # by the user (e.g. `npm install -g <package>` after this activation
    # completes).
    install_if_missing opencode "${curl} -fsSL https://opencode.ai/install | ${bash}"
  '';

  targets.genericLinux.enable = true;
  fonts.fontconfig = {
    enable = true;
    # The desktop theme (GTK + KDE) declares Fira Sans as the UI font; make
    # the generic `sans-serif` family resolve to it too so apps that ask for
    # a generic family (e.g. mpv OSD, Chromium fallbacks) render the same
    # system font instead of silently substituting Noto Sans.
    defaultFonts.sansSerif = [ "Fira Sans" ];
  };

  programs = {
    gpg.enable = true;
    home-manager.enable = true;
  };
}
