# Wave 1 — Root pinned-nixpkgs option inspection

## Pinned nixpkgs metadata
null

## Current repo declarations
     1	{ config, inputs, pkgs, agenix, lib, ... }:
     2	
     3	let user = "mei";
     4	    keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ]; in
     5	{
     6	  imports = [
     7	    ../../modules/nixos/secrets.nix
     8	    ../../modules/nixos/disk-config.nix
     9	    ../../modules/nixos/niri.nix
    10	    ../../modules/shared
    11	    agenix.nixosModules.default
    12	  ];
    13	
    14	  # Use the systemd-boot EFI boot loader.
    15	  boot = {
    16	    loader = {
    17	      systemd-boot = {
    18	        enable = true;
    19	        configurationLimit = 42;
    20	      };
    21	      efi.canTouchEfiVariables = true;
    22	    };
    23	    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    24	    # Uncomment for AMD GPU
    25	    # initrd.kernelModules = [ "amdgpu" ];
    26	    kernelPackages = pkgs.linuxPackages_latest;
    27	    kernelModules = [ "uinput" ];
    28	  };
    29	
    30	  hardware.i2c.enable = true;
    31	
    32	  # Set your time zone.
    33	  time.timeZone = "America/New_York";
    34	
    35	  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
   265	
   266	
   267	 # Add docker daemon
   268	  virtualisation.docker.enable = true;
   269	  virtualisation.docker.logDriver = "json-file";
   270	
   271	  # It's me, it's you, it's everyone
   272	  users.users = {
   273	    ${user} = {
   274	      isNormalUser = true;
   275	      extraGroups = [
   276	        "wheel" # Enable ‘sudo’ for the user.
   277	        "docker"
   278	        "i2c"
   279	        "video"
   280	      ];
   281	      shell = pkgs.zsh;
   282	      openssh.authorizedKeys.keys = keys;
   283	    };
   284	
   285	    root = {
   286	      openssh.authorizedKeys.keys = keys;
   287	    };
   288	  };
   289	
   290	  # Don't require password for users in `wheel` group for these commands
   291	  security.sudo = {
   292	    enable = true;
   293	    extraRules = [{
   294	      commands = [
   295	       {
   296	         command = "${pkgs.systemd}/bin/reboot";
   297	         options = [ "NOPASSWD" ];
   298	        }
   299	      ];
   300	      groups = [ "wheel" ];
   301	    }];
   302	  };
   303	
   304	  fonts.packages = with pkgs; [
   305	    dejavu_fonts
   306	    emacs-all-the-icons-fonts

## Existing secret module
     1	{ config, pkgs, agenix, secrets, ... }:
     2	
     3	let user = "mei"; in
     4	{
     5	  age.identityPaths = [
     6	    "/home/${user}/.ssh/id_ed25519"
     7	  ];
     8	
     9	  # Your secrets go here
    10	  #
    11	  # Note: the installWithSecrets command you ran to boostrap the machine actually copies over
    12	  #       a Github key pair. However, if you want to store the keypair in your nix-secrets repo
    13	  #       instead, you can reference the age files and specify the symlink path here. Then add your
    14	  #       public key in shared/files.nix.
    15	  #
    16	  #       If you change the key name, you'll need to update the SSH configuration in shared/home-manager.nix
    17	  #       so Github reads it correctly.
    18	
    19	  #
    20	  # age.secrets."github-ssh-key" = {
    21	  #   symlink = false;
    22	  #   path = "/home/${user}/.ssh/id_github";
    23	  #   file =  "${secrets}/github-ssh-key.age";
    24	  #   mode = "600";
    25	  #   owner = "${user}";
    26	  #   group = "wheel";
    27	  # };
    28	
    29	}

## Password-related references
./modules/nixos/README.md:108:- **Super + Shift + x** - Open KeePassXC password manager
./docs/service-notes/nixos-anywhere-disko-install.md:156:## 6. First login and password note
./docs/service-notes/nixos-anywhere-disko-install.md:158:This repo creates the `mei` user but does not declare an initial password.
./docs/service-notes/nixos-anywhere-disko-install.md:159:After install, prefer SSH key access if your key was included. If password login
./docs/service-notes/nixos-anywhere-disko-install.md:160:is needed and no password was set, boot the ISO again and mount the installed
./hosts/nixos/default.nix:282:      openssh.authorizedKeys.keys = keys;
./hosts/nixos/default.nix:286:      openssh.authorizedKeys.keys = keys;
./hosts/nixos/default.nix:290:  # Don't require password for users in `wheel` group for these commands

## Pinned option names and rendered metadata
warning: Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist, ignoring
{
  "hashedPassword": {
    "declarations": [
      "/nix/store/9d4098cn315jkl7dxv3kb1dnzg1x2gpi-source/nixos/modules/config/users-groups.nix"
    ],
    "default": "null",
    "description": "Specifies the hashed password for the user.\n\nThe {option}`initialHashedPassword`, {option}`hashedPassword`,\n{option}`initialPassword`, {option}`password` and\n{option}`hashedPasswordFile` options all control what password is set for\nthe user.\n\nIn a system where [](#opt-systemd.sysusers.enable) is `false`, typically\nonly one of {option}`hashedPassword`, {option}`password`, or\n{option}`hashedPasswordFile` will be set.\n\nIn a system where [](#opt-systemd.sysusers.enable) or [](#opt-services.userborn.enable) is `true`,\ntypically only one of {option}`initialPassword`, {option}`initialHashedPassword`,\nor {option}`hashedPasswordFile` will be set.\n\nIf the option {option}`users.mutableUsers` is true, the password defined\nin one of the above password options will only be set when the user is\ncreated for the first time. After that, you are free to change the\npassword with the ordinary user management commands. If\n{option}`users.mutableUsers` is false, you cannot change user passwords,\nthey will always be set according to the password options.\n\nIf none of the password options are set, then no password is assigned to\nthe user, and the user will not be able to do password-based logins.\n\nIf multiple of these password options are set at the same time then a\nspecific order of precedence is followed, which can lead to surprising\nresults. The order of precedence differs depending on whether the\n{option}`users.mutableUsers` option is set.\n\n\nIf the option {option}`users.mutableUsers` is\n`false`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`hashedPassword` -> {option}`initialPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\nIf the option {option}`users.mutableUsers` is\n`true`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`initialPassword` -> {option}`hashedPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\n\nTo generate a hashed password run `mkpasswd`.\n\nIf set to an empty string (`\"\"`), this user will be able to log in without\nbeing asked for a password (but not via remote services such as SSH, or\nindirectly via {command}`su` or {command}`sudo`). This should only be used\nfor e.g. bootable live systems. Note: this is different from setting an\nempty password, which can be achieved using\n{option}`users.users.<name?>.password`.\n\nIf set to `null` (default) this user will not be able to log in using a\npassword (i.e. via {command}`login` command).\n\n"
  },
  "hashedPasswordFile": {
    "declarations": [
      "/nix/store/9d4098cn315jkl7dxv3kb1dnzg1x2gpi-source/nixos/modules/config/users-groups.nix"
    ],
    "default": "null",
    "description": "The full path to a file that contains the hash of the user's\npassword. The password file is read on each system activation. The\nfile should contain exactly one line, the salted password hash\nproduced by `mkpasswd`.\n\nThe {option}`initialHashedPassword`, {option}`hashedPassword`,\n{option}`initialPassword`, {option}`password` and\n{option}`hashedPasswordFile` options all control what password is set for\nthe user.\n\nIn a system where [](#opt-systemd.sysusers.enable) is `false`, typically\nonly one of {option}`hashedPassword`, {option}`password`, or\n{option}`hashedPasswordFile` will be set.\n\nIn a system where [](#opt-systemd.sysusers.enable) or [](#opt-services.userborn.enable) is `true`,\ntypically only one of {option}`initialPassword`, {option}`initialHashedPassword`,\nor {option}`hashedPasswordFile` will be set.\n\nIf the option {option}`users.mutableUsers` is true, the password defined\nin one of the above password options will only be set when the user is\ncreated for the first time. After that, you are free to change the\npassword with the ordinary user management commands. If\n{option}`users.mutableUsers` is false, you cannot change user passwords,\nthey will always be set according to the password options.\n\nIf none of the password options are set, then no password is assigned to\nthe user, and the user will not be able to do password-based logins.\n\nIf multiple of these password options are set at the same time then a\nspecific order of precedence is followed, which can lead to surprising\nresults. The order of precedence differs depending on whether the\n{option}`users.mutableUsers` option is set.\n\n\nIf the option {option}`users.mutableUsers` is\n`false`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`hashedPassword` -> {option}`initialPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\nIf the option {option}`users.mutableUsers` is\n`true`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`initialPassword` -> {option}`hashedPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\n\n"
  },
  "initialHashedPassword": {
    "declarations": [
      "/nix/store/9d4098cn315jkl7dxv3kb1dnzg1x2gpi-source/nixos/modules/config/users-groups.nix"
    ],
    "default": "null",
    "description": "Specifies the initial hashed password for the user, i.e. the\nhashed password assigned if the user does not already\nexist. If {option}`users.mutableUsers` is true, the\npassword can be changed subsequently using the\n{command}`passwd` command. Otherwise, it's\nequivalent to setting the {option}`hashedPassword` option.\n\nThe {option}`initialHashedPassword`, {option}`hashedPassword`,\n{option}`initialPassword`, {option}`password` and\n{option}`hashedPasswordFile` options all control what password is set for\nthe user.\n\nIn a system where [](#opt-systemd.sysusers.enable) is `false`, typically\nonly one of {option}`hashedPassword`, {option}`password`, or\n{option}`hashedPasswordFile` will be set.\n\nIn a system where [](#opt-systemd.sysusers.enable) or [](#opt-services.userborn.enable) is `true`,\ntypically only one of {option}`initialPassword`, {option}`initialHashedPassword`,\nor {option}`hashedPasswordFile` will be set.\n\nIf the option {option}`users.mutableUsers` is true, the password defined\nin one of the above password options will only be set when the user is\ncreated for the first time. After that, you are free to change the\npassword with the ordinary user management commands. If\n{option}`users.mutableUsers` is false, you cannot change user passwords,\nthey will always be set according to the password options.\n\nIf none of the password options are set, then no password is assigned to\nthe user, and the user will not be able to do password-based logins.\n\nIf multiple of these password options are set at the same time then a\nspecific order of precedence is followed, which can lead to surprising\nresults. The order of precedence differs depending on whether the\n{option}`users.mutableUsers` option is set.\n\n\nIf the option {option}`users.mutableUsers` is\n`false`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`hashedPassword` -> {option}`initialPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\nIf the option {option}`users.mutableUsers` is\n`true`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`initialPassword` -> {option}`hashedPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\n\nTo generate a hashed password run `mkpasswd`.\n\nIf set to an empty string (`\"\"`), this user will be able to log in without\nbeing asked for a password (but not via remote services such as SSH, or\nindirectly via {command}`su` or {command}`sudo`). This should only be used\nfor e.g. bootable live systems. Note: this is different from setting an\nempty password, which can be achieved using\n{option}`users.users.<name?>.password`.\n\nIf set to `null` (default) this user will not be able to log in using a\npassword (i.e. via {command}`login` command).\n\n"
  },
  "initialPassword": {
    "declarations": [
      "/nix/store/9d4098cn315jkl7dxv3kb1dnzg1x2gpi-source/nixos/modules/config/users-groups.nix"
    ],
    "default": "null",
    "description": "Specifies the initial password for the user, i.e. the\npassword assigned if the user does not already exist. If\n{option}`users.mutableUsers` is true, the password\ncan be changed subsequently using the\n{command}`passwd` command. Otherwise, it's\nequivalent to setting the {option}`password`\noption. The same caveat applies: the password specified here\nis world-readable in the Nix store, so it should only be\nused for guest accounts or passwords that will be changed\npromptly.\n\nThe {option}`initialHashedPassword`, {option}`hashedPassword`,\n{option}`initialPassword`, {option}`password` and\n{option}`hashedPasswordFile` options all control what password is set for\nthe user.\n\nIn a system where [](#opt-systemd.sysusers.enable) is `false`, typically\nonly one of {option}`hashedPassword`, {option}`password`, or\n{option}`hashedPasswordFile` will be set.\n\nIn a system where [](#opt-systemd.sysusers.enable) or [](#opt-services.userborn.enable) is `true`,\ntypically only one of {option}`initialPassword`, {option}`initialHashedPassword`,\nor {option}`hashedPasswordFile` will be set.\n\nIf the option {option}`users.mutableUsers` is true, the password defined\nin one of the above password options will only be set when the user is\ncreated for the first time. After that, you are free to change the\npassword with the ordinary user management commands. If\n{option}`users.mutableUsers` is false, you cannot change user passwords,\nthey will always be set according to the password options.\n\nIf none of the password options are set, then no password is assigned to\nthe user, and the user will not be able to do password-based logins.\n\nIf multiple of these password options are set at the same time then a\nspecific order of precedence is followed, which can lead to surprising\nresults. The order of precedence differs depending on whether the\n{option}`users.mutableUsers` option is set.\n\n\nIf the option {option}`users.mutableUsers` is\n`false`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`hashedPassword` -> {option}`initialPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\nIf the option {option}`users.mutableUsers` is\n`true`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`initialPassword` -> {option}`hashedPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\n\n"
  },
  "password": {
    "declarations": [
      "/nix/store/9d4098cn315jkl7dxv3kb1dnzg1x2gpi-source/nixos/modules/config/users-groups.nix"
    ],
    "default": "null",
    "description": "Specifies the (clear text) password for the user.\nWarning: do not set confidential information here\nbecause it is world-readable in the Nix store. This option\nshould only be used for public accounts.\n\nThe {option}`initialHashedPassword`, {option}`hashedPassword`,\n{option}`initialPassword`, {option}`password` and\n{option}`hashedPasswordFile` options all control what password is set for\nthe user.\n\nIn a system where [](#opt-systemd.sysusers.enable) is `false`, typically\nonly one of {option}`hashedPassword`, {option}`password`, or\n{option}`hashedPasswordFile` will be set.\n\nIn a system where [](#opt-systemd.sysusers.enable) or [](#opt-services.userborn.enable) is `true`,\ntypically only one of {option}`initialPassword`, {option}`initialHashedPassword`,\nor {option}`hashedPasswordFile` will be set.\n\nIf the option {option}`users.mutableUsers` is true, the password defined\nin one of the above password options will only be set when the user is\ncreated for the first time. After that, you are free to change the\npassword with the ordinary user management commands. If\n{option}`users.mutableUsers` is false, you cannot change user passwords,\nthey will always be set according to the password options.\n\nIf none of the password options are set, then no password is assigned to\nthe user, and the user will not be able to do password-based logins.\n\nIf multiple of these password options are set at the same time then a\nspecific order of precedence is followed, which can lead to surprising\nresults. The order of precedence differs depending on whether the\n{option}`users.mutableUsers` option is set.\n\n\nIf the option {option}`users.mutableUsers` is\n`false`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`hashedPassword` -> {option}`initialPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\nIf the option {option}`users.mutableUsers` is\n`true`, then the order of precedence is as shown\nbelow, where values on the left are overridden by values on the right:\n{option}`initialHashedPassword` -> {option}`initialPassword` -> {option}`hashedPassword` -> {option}`password` -> {option}`hashedPasswordFile`\n\n\n\n"
  },
  "passwordFile": {
    "declarations": [
      "/nix/store/9d4098cn315jkl7dxv3kb1dnzg1x2gpi-source/nixos/modules/config/users-groups.nix"
    ],
    "default": "null",
    "description": "Deprecated alias of hashedPasswordFile"
  }
}

## mutableUsers metadata
warning: Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist, ignoring
{
  "declarations": [
    "/nix/store/15aqljmnm6xnyci8lldyzq8vgl9xhqqn-source/nixos/modules/config/users-groups.nix"
  ],
  "default": true
}
