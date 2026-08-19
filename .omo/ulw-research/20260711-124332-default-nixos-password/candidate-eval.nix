let
  f = builtins.getFlake (toString /home/mei/nix-config);
  c = (f.nixosConfigurations.x86_64-linux.extendModules {
    modules = [ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ];
  }).config;
in {
  hashFile = c.users.users.mei.hashedPasswordFile;
  mutableUsers = c.users.mutableUsers;
  sysusers = c.systemd.sysusers.enable;
  userborn = c.services.userborn.enable;
  userGroups = c.users.users.mei.extraGroups;
  authorizedKeys = c.users.users.mei.openssh.authorizedKeys.keys;
  userDeps = c.system.activationScripts.users.deps;
  consumeDeps = c.system.activationScripts.consumeBootstrapPassword.deps;
  passwordSources = {
    password = c.users.users.mei.password;
    initialPassword = c.users.users.mei.initialPassword;
    hashedPassword = c.users.users.mei.hashedPassword;
    initialHashedPassword = c.users.users.mei.initialHashedPassword;
    hashedPasswordFile = c.users.users.mei.hashedPasswordFile;
  };
}
