{ pkgs, includeDocker ? true, includeOpencode ? true, includeCodingAgentDerivations ? true }:

with pkgs;
[
  # General packages for development and system management
  ast-grep
  aria2
  secretspec
  bash-completion
  bat
  bear
  btop
  bun
  ccache
  coreutils
  duf
  eza
  fastfetch
  gdb
  killall
  openssh
  pipx
  restic
  rsync
  resvg
  sqlite
  wget
  zip

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2

  # Media-related packages
  emacs-all-the-icons-fonts
  dejavu_fonts
  ffmpeg
  fd
  font-awesome
  hack-font
  nerd-fonts.fira-code
  noto-fonts
  noto-fonts-color-emoji
  meslo-lgs-nf

  # Node.js development tools
  nodejs_24

  # Text and terminal utilities
  htop
  jetbrains-mono
  jq
  glances
  micro
  ncdu
  ranger
  ripgrep
  ruff
  superfile
  tectonic
  tldr
  tokei
  tree
  tmux
  unrar
  unzip
  yazi
  zellij
  zoxide
  zsh-powerlevel10k

  # Development tools
  curl
  devenv
  gh
  git-filter-repo
  act
  actionlint
  terraform
  kubectl
  kind
  kubernetes-helm
  awscli2
  claude-code
]
++ pkgs.lib.optionals includeCodingAgentDerivations (
  [
    (pkgs.callPackage ../../pkgs/codex-omx.nix { })
  ]
  ++ pkgs.lib.optionals (includeOpencode && pkgs.stdenv.hostPlatform.system != "x86_64-darwin") [
    (pkgs.callPackage ../../pkgs/opencode-omo.nix { })
  ]
)
++ [
  lazygit
  mcp-nixos
  fzf
  direnv
  flyctl
  railway
  podman
  vagrant
  zed-editor

  # Programming languages and runtimes
  beamPackages.elixir
  beamPackages.erlang
  go
]
++ pkgs.lib.optionals (pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.iverilog) [
  iverilog
]
++ [
  gopls
  jdt-language-server
  nil
  nixd
  basedpyright
  rustc
  cargo
  rust-analyzer
  openjdk
  pandoc
  taplo
  typescript-language-server
  valkey
  vscode-langservers-extracted
  yaml-language-server
  zls

  # Python packages
  python3
  virtualenv
  zig
]
++ pkgs.lib.optionals includeDocker [
  # Cloud-related tools and SDKs
  docker
  docker-compose
]
