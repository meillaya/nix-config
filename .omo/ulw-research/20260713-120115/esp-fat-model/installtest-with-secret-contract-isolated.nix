let
  f = builtins.getFlake (toString /home/mei/nix-config);
  lib = f.inputs.nixpkgs.lib;
  c = f.nixosConfigurations.x86_64-linux.extendModules {
    modules = [
      {
        disko.tests.extraConfig = {
          users.users.mei.hashedPasswordFile = lib.mkForce null;
          users.users.mei.hashedPassword = lib.mkForce "!";
          system.activationScripts.bootstrapPasswordHash.text = lib.mkForce "true";
          system.activationScripts.consumeBootstrapPassword.text = lib.mkForce "true";
        };
      }
    ];
  };
in
c.config.system.build.installTest
