{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; includeDocker = false; includeCodingAgentDerivations = false; }; in
shared-packages ++ [
  # App replacements formerly installed as casks
  bruno
  dbeaver-bin
  ghostty-bin
  iterm2
  jetbrains.idea
  kitty
  postman
  vesktop

  # Development tools
  cocoapods
  dockutil
  helix
  micro
  neovim
  omniorb
  (pkgs.callPackage ../../pkgs/omniwm.nix { })
  jetbrains.pycharm
  uv

  # Coding agents (darwin imports shared with includeCodingAgentDerivations =
  # false, so coding-agent derivations are added explicitly here)
  (pkgs.callPackage ../../pkgs/zeroclaw.nix { })
]
