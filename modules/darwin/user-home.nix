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
      node = "${pkgs.nodejs}/bin/node";
      curl = "${pkgs.curl}/bin/curl";
      bash = "${pkgs.bash}/bin/bash";
    in lib.hm.dag.entryAfter ["writeBoundary"] ''
      # npm postinstall scripts use node; the activation PATH lacks it by default.
      export PATH="${node%/*}:${curl%/*}:${bash%/*}:$PATH"
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
  };

  manual.manpages.enable = false;
}
