{ pkgs, lib, user, ... }:
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = user.identity.name;
    homeDirectory = user.identity.home;
    packages = (pkgs.callPackage ./packages.nix { }) ++ [
      pkgs.nodejs
      ((pkgs.writeShellScriptBin "pi-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${user.identity.home}/.config/sops/age/keys.txt"
        SECRETS_FILE="${user.identity.home}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- pi "$@"
      '') // { pname = "pi-wrapped"; })
      ((pkgs.writeShellScriptBin "hermes-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${user.identity.home}/.config/sops/age/keys.txt"
        SECRETS_FILE="${user.identity.home}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- hermes "$@"
      '') // { pname = "hermes-wrapped"; })
      ((pkgs.writeShellScriptBin "zeroclaw-wrapped" ''
        set -euo pipefail
        export SOPS_AGE_KEY_FILE="${user.identity.home}/.config/sops/age/keys.txt"
        SECRETS_FILE="${user.identity.home}/nix-config/secrets/coding-agents.yaml"
        exec sops exec-env "$SECRETS_FILE" -- zeroclaw "$@"
      '') // { pname = "zeroclaw-wrapped"; })
    ];
    stateVersion = "23.11";
    activation.installCodingAgents = let
      npm = "${pkgs.nodejs}/bin/npm";
      curl = "${pkgs.curl}/bin/curl";
      bash = "${pkgs.bash}/bin/bash";
      tar = "${pkgs.gnutar}/bin";
      gzip = "${pkgs.gzip}/bin";
      bzip2 = "${pkgs.bzip2}/bin";
      xz = "${pkgs.xz}/bin";
      # npm postinstall scripts for oh-my-codex and oh-my-opencode invoke `node -e`
      # via `sh -c`; npm rebuilds the script env in a way that drops the parent
      # PATH, so the postinstall cannot find node even when activation PATH includes
      # the nix-store nodejs bin. --ignore-scripts mirrors pkgs/codex-omx.nix:27-28
      # and pkgs/opencode-omo.nix:33-34; the package authors wrap postinstalls in
      # try/catch with the message "[omx] Postinstall skipped after a non-fatal
      # error". @openai/codex is left untouched (its install succeeds in the
      # original failure log and its postinstall is unanalyzed).
      # The activation PATH is prefixed with `${pkgs.gnutar}/bin`,
      # `${pkgs.gzip}/bin`, `${pkgs.bzip2}/bin`, `${pkgs.xz}/bin`,
      # `${pkgs.bash}/bin`, and `${pkgs.curl}/bin` because the opencode
      # curl|bash installer (the only remaining curl|bash line in this
      # activation block) downloads a .tar.gz and extracts it with `tar`,
      # and the HM activation PATH excludes /usr/bin and the host's
      # interactive shell PATH. pi, hermes, and zeroclaw used to be here
      # too but their installers are TTY-interactive and removed; user
      # installs them manually (see README).
    in lib.hm.dag.entryAfter ["writeBoundary"] ''
      export PATH="${tar}:${gzip}:${bzip2}:${xz}:${pkgs.bash}/bin:${pkgs.curl}/bin:$PATH"
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
      install_if_missing omx "${npm} install -g --ignore-scripts --force oh-my-codex"
      install_if_missing omo "${npm} install -g --ignore-scripts --force oh-my-opencode"
      # curl-based installers are idempotent and overwrite their own paths.
      # opencode is non-interactive and runs unattended; pi, hermes, and zeroclaw
      # have interactive TTY-only installers and must be installed manually by the
      # user (e.g. `npm install -g <package>` after this activation completes).
      install_if_missing opencode "${curl} -fsSL https://opencode.ai/install | ${bash}"
    '';
  };

  manual.manpages.enable = false;
}
