{ flake ? builtins.getFlake ("path:" + toString ../.) }:
let
  policy = import ../lib/nixpkgs.nix { inputs = flake.inputs; };
  policyConfig = policy.config;
  darwin = flake.darwinConfigurations."aarch64-darwin".config;
  standalone = flake.homeConfigurations."standalone-linux".config;
  standaloneArm = flake.homeConfigurations."standalone-linux-aarch64".config;
  authority = flake.machineAuthority;
  shellName = shell: shell.pname or shell.name or (builtins.baseNameOf (toString shell));
  expectedDarwinApps = [
    "build" "build-switch" "clean" "search-pkgs" "update"
  ];
  hasShell = name: shells: builtins.any (shell: shellName shell == name) shells;
  hasInfix = flake.inputs.nixpkgs.lib.hasInfix;
  countExactLine = expected: text:
    builtins.length (
      builtins.filter
        (line: line == expected)
        (flake.inputs.nixpkgs.lib.splitString "\n" text)
    );
  packageName = package: package.pname or package.name or (builtins.baseNameOf (toString package));
  hasPackages = names: packages:
    let present = map packageName packages;
    in builtins.all (name: builtins.elem name present) names;
  hasAnyPackage = names: packages:
    let present = map packageName packages;
    in builtins.any (name: builtins.elem name present) names;
  hasAnyHomeFile = names: files:
    builtins.any
      (file: builtins.any (name: hasInfix name file) names)
      (builtins.attrNames files);
  noctaliaServiceCount = services:
    builtins.length (
      builtins.filter
        (name: hasInfix "noctalia" name)
        (builtins.attrNames services)
    );
  noctaliaSettings = standalone.programs.noctalia.settings;
  standaloneKdePortalUnit =
    standalone.xdg.configFile."systemd/user/plasma-xdg-desktop-portal-kde.service".source;
  requiredLinuxApplications = [
    "calibre" "devenv" "gimp" "ghostty" "helium" "kitty" "obsidian"
    "ollama" "qbittorrent" "noctalia" "zen-beta"
  ];
  expectedDarwinShellActivation = ''
    desired_shell=/run/current-system/sw/bin/nu
    if [[ ! -x "$systemConfig/sw/bin/nu" ]]; then
      printf >&2 'error: configured Nushell is not executable: %s\n' "$systemConfig/sw/bin/nu"
      exit 1
    fi

    current_shell=$(/usr/bin/dscl . -read /Users/mei UserShell)
    current_shell="''${current_shell#UserShell: }"
    if [[ "$current_shell" != "$desired_shell" ]]; then
      /usr/bin/dscl . -create /Users/mei UserShell "$desired_shell"
    fi
  '';
  assertHm = hm:
    assert hm.programs.nushell.enable;
    assert hm.programs.nushell.settings.show_hints;
    assert hm.programs.nushell.settings.history.file_format == "sqlite";
    assert hm.programs.nushell.settings.history.sync_on_enter;
    assert hm.programs.nushell.settings.completions.algorithm == "fuzzy";
    assert hm.programs.nushell.settings.color_config.hints == "light_cyan";
    assert hasInfix ".nix-profile/bin" hm.programs.nushell.extraEnv;
    assert hasInfix "/home/mei/.opencode/bin" hm.programs.nushell.extraEnv;
    assert hasInfix "/run/current-system/sw/bin" hm.programs.nushell.extraEnv;
    assert hasInfix "fastfetch" hm.programs.nushell.extraConfig;
    assert hasInfix "which fastfetch" hm.programs.nushell.extraConfig;
    assert hm.programs.kitty.enable;
    assert hm.programs.kitty.settings.background == "#161925";
    assert hm.programs.kitty.settings.foreground == "#c3c7d1";
    assert hm.programs.kitty.settings.color1 == "#ed254e";
    assert hm.programs.kitty.settings.color2 == "#71f79f";
    assert hasInfix "/bin/nu --login" hm.programs.kitty.settings.shell;
    assert hm.programs.bash.enable;
    assert hm.programs.zsh.enable;
    assert hm.programs.fish.enable;
    assert hm.programs.git.settings.credential."https://github.com".helper != [ ];
    assert builtins.head hm.programs.git.settings.credential."https://github.com".helper == "";
    assert hasInfix "gh auth git-credential"
      (builtins.elemAt hm.programs.git.settings.credential."https://github.com".helper 1);
    assert builtins.head hm.programs.git.settings.credential."https://gist.github.com".helper == "";
    assert hasInfix "gh auth git-credential"
      (builtins.elemAt hm.programs.git.settings.credential."https://gist.github.com".helper 1);
    assert countExactLine "set -g allow-passthrough on"
      hm.programs.tmux.extraConfig == 1;
    assert countExactLine "set -g allow-passthrough on"
      hm.xdg.configFile."tmux/tmux.conf".text == 1;
    true;
in
assert builtins.attrNames (flake.nixosConfigurations or { }) == [ ];
assert builtins.attrNames flake.darwinConfigurations == [ "aarch64-darwin" ];
assert builtins.attrNames flake.homeConfigurations == [ "standalone-linux" "standalone-linux-aarch64" ];
assert builtins.attrNames (flake.overlays or { }) == [ ];
assert flake.configurationEvaluationPaths == [
  "darwinConfigurations.aarch64-darwin"
  "homeConfigurations.standalone-linux"
  "homeConfigurations.standalone-linux-aarch64"
];
assert authority.machineIds == [
  "aarch64-darwin"
  "aarch64-linux"
  "nixos-laptop"
];
assert !(policyConfig ? allowBroken);
assert !(policyConfig ? permittedInsecurePackages);
assert !(policyConfig ? allowUnfree);
assert policyConfig.allowInsecure == true;
assert policyConfig ? allowUnfreePredicate;
assert builtins.attrNames flake.apps.aarch64-darwin == expectedDarwinApps;
assert builtins.attrNames (flake.apps.x86_64-linux or { }) == [ ];
assert builtins.attrNames (flake.apps.aarch64-linux or { }) == [ ];
assert darwin.system.stateVersion == 5;
assert darwin.system.primaryUser == "mei";
assert shellName darwin.users.users.mei.shell == "nushell";
assert hasShell "nu" darwin.environment.shells;
assert hasShell "bash" darwin.environment.shells;
assert hasShell "zsh" darwin.environment.shells;
assert hasShell "fish" darwin.environment.shells;
assert hasPackages [ "kitty" ] darwin.environment.systemPackages;
assert !(hasPackages [ "obsidian" ] darwin.environment.systemPackages);
assert flake.inputs.nixpkgs.lib.hasInfix expectedDarwinShellActivation
  darwin.system.activationScripts.postActivation.text;
assert assertHm darwin.home-manager.users.mei;
assert standalone.home.username == "mei";
assert standalone.home.homeDirectory == "/home/mei";
assert standaloneArm.home.username == "mei";
assert standaloneArm.home.homeDirectory == "/home/mei";
assert standalone.home.stateVersion == "25.11";
assert hasPackages requiredLinuxApplications standalone.home.packages;
assert !(hasAnyPackage [ "mako" "swaybg" "swaylock" "waybar" "wlogout" ] standalone.home.packages);
assert !(hasAnyPackage [ "mako" "swaybg" "swaylock" "waybar" "wlogout" ] standaloneArm.home.packages);
assert !(hasAnyHomeFile [ ".config/mako/" ".config/waybar/" ".config/wlogout/" ] standalone.home.file);
assert !(hasAnyHomeFile [ ".config/mako/" ".config/waybar/" ".config/wlogout/" ] standaloneArm.home.file);
assert hasInfix "xdg-desktop-portal-kde" (toString standaloneKdePortalUnit);
assert flake.inputs.nixpkgs.lib.hasSuffix
  "/share/systemd/user/plasma-xdg-desktop-portal-kde.service"
  (toString standaloneKdePortalUnit);
assert hasPackages [ "obsidian" ] standalone.home.packages;
assert !(hasPackages [ "heroic" ] standalone.home.packages);
assert !(hasPackages [ "steam" ] standalone.home.packages);
assert standalone.programs.noctalia.enable;
assert standalone.programs.spicetify.enable;
assert hasPackages [ "helium" ] standalone.home.packages;
assert standalone.programs.noctalia.systemd.enable;
assert standalone.programs.noctalia.validateConfig;
assert standalone.programs.noctalia.settings.shell.launch_apps_as_systemd_services;
assert packageName standalone.xdg.configFile."noctalia/config.toml".source
  == "noctalia-config";
assert noctaliaServiceCount standalone.systemd.user.services == 1;
assert standalone.systemd.user.services.noctalia.Unit.X-SwitchMethod == "keep-old";
assert standalone.systemd.user.services.noctalia.Install.WantedBy == [ "graphical-session.target" ];
assert standalone.systemd.user.services.noctalia.Service.Restart == "on-failure";
assert builtins.any (hasInfix "/bin/noctalia")
  standalone.systemd.user.services.noctalia.Service.ExecStart;
assert standaloneArm.programs.noctalia.enable;
assert !standaloneArm.programs.spicetify.enable;
assert !(hasPackages [ "helium" ] standaloneArm.home.packages);
assert standaloneArm.programs.noctalia.validateConfig;
assert standaloneArm.programs.noctalia.settings.shell.launch_apps_as_systemd_services;
assert noctaliaServiceCount standaloneArm.systemd.user.services == 1;
assert standaloneArm.systemd.user.services.noctalia.Unit.X-SwitchMethod == "keep-old";
assert assertHm standalone;
assert assertHm standaloneArm;
assert hasInfix "/bin/nu --login" standalone.home.file.".config/ghostty/config".text;
"dendritic-config-eval=PASS"
