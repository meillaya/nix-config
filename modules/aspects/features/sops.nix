{ inputs, ... }:
{
  den.aspects.sops = { host, ... }: {
    nixos = { pkgs, ... }: {
      imports = [
        inputs.sops-nix.nixosModules.default
      ];
      sops.age.sshKeyPaths = [ "${host.machine.identity.home}/.ssh/id_ed25519" ];
      environment.systemPackages = [ pkgs.sops ];
    };
    darwin = { pkgs, ... }: {
      imports = [
        inputs.sops-nix.darwinModules.default
      ];
      sops.age.sshKeyPaths = [
        "${host.machine.identity.home}/.ssh/id_ed25519"
        "${host.machine.identity.home}/.ssh/id_ed25519_agenix"
      ];
      environment.systemPackages = [ pkgs.sops ];
    };
  };
}
