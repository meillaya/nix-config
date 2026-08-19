{ ... }:
let
  authority = import ./_machine-authority/model.nix;
  machineFor = authority.getMachine;

  laptop = machineFor "nixos-laptop";
  linuxArm = machineFor "aarch64-linux";
  darwinArm = machineFor "aarch64-darwin";
in
assert laptop.target == "nixosConfigurations.x86_64-linux";
assert linuxArm.target == "nixosConfigurations.aarch64-linux";
assert darwinArm.target == "darwinConfigurations.aarch64-darwin";
{
  den.hosts = {
    aarch64-darwin = {
      aarch64-darwin = {
        system = "aarch64-darwin";
        hostName = darwinArm.hostId;
        machine = darwinArm;
        users.${darwinArm.identity.name}.identity = darwinArm.identity;
      };
    };
  };

  den.homes = {
    x86_64-linux.standalone-linux = {
      machine = laptop;
      userName = laptop.identity.name;
      homeDirectory = laptop.identity.home;
    };
    aarch64-linux.standalone-linux-aarch64 = {
      machine = linuxArm;
      userName = linuxArm.identity.name;
      homeDirectory = linuxArm.identity.home;
    };
  };
}
