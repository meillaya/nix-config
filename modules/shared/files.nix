{ pkgs, config, lib, ... }:

let
  homeDirectory =
    let
      hmHome = lib.attrByPath [ "home" "homeDirectory" ] null config;
      primaryUser =
        lib.attrByPath [ "home" "username" ]
          (lib.attrByPath [ "system" "primaryUser" ] null config)
          config;
      managedUserHome =
        if primaryUser == null then
          null
        else
          lib.attrByPath [ "users" "users" primaryUser "home" ] null config;
    in
    if hmHome != null then hmHome else if managedUserHome != null then managedUserHome else "$HOME";
  # GitHub authentication key (public part only; the private key lives in the
  # git-ignored secrets/github-ssh-key.age age-encrypted backup).
  githubPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPoWsO0x+p0FKVKOrfHPc0xeZuOZyMapMt8LxPbWHtb5 mei@entropyos-nix";
in
{
  ".npmrc" = {
    text = ''
      prefix=${homeDirectory}/.local
    '';
  };

  ".config/fastfetch" = {
    source = ../shared/config/fastfetch;
    recursive = true;
  };

  # Pin the opencode plugin to the same oh-my-openagent version the repo
  # installs (5.0.0-beta.7). `@latest` would resolve to 4.19.4 on npm and
  # run the old plugin with its built-in model defaults, ignoring the 5.x
  # `~/.omo/omo.jsonc` config. Runtime changes (MCP servers, providers)
  # belong in opencode.json, which stays unmanaged.
  ".config/opencode/opencode.jsonc" = {
    text = builtins.readFile ../shared/config/opencode/opencode.jsonc;
    force = true;
  };

  ".ssh/id_github.pub" = {
    text = githubPublicKey;
    # force: replace the manual `id_github.pub -> id_ed25519.pub` symlink with the
    # managed file. Safe — the declared githubPublicKey is byte-identical to
    # id_ed25519.pub on the enrolled machines (verified 2026-08-14).
    force = true;
  };

  # Initializes Emacs with org-mode so we can tangle the main config
  ".emacs.d/init.el" = {
    text = builtins.readFile ../shared/config/emacs/init.el;
  };

  # IMPORTANT: The Emacs configuration expects a config.org file at ~/.config/emacs/config.org
  # You can either:
  # 1. Copy the provided config.org to ~/.config/emacs/config.org
  # 2. Set EMACS_CONFIG_ORG environment variable to point to your config.org location
  # 3. Uncomment below to have Nix manage the file:
  #
  # ".config/emacs/config.org" = {
  #   text = builtins.readFile ../shared/config/emacs/config.org;
  # };

}
