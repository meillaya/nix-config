{ inputs, ... }:
{
  den.aspects.sops = { host, ... }: {
    nixos = { pkgs, ... }: {
      imports = [
        inputs.sops-nix.nixosModules.default
      ];
      sops.age.sshKeyPaths = [ "${host.machine.identity.home}/.ssh/id_ed25519" ];
      environment.systemPackages = [ pkgs.sops ];
      sops.secrets."OPENAI_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."ANTHROPIC_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."GEMINI_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."OPENROUTER_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."GITHUB_TOKEN" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
    };
    darwin = { pkgs, ... }: {
      imports = [
        inputs.sops-nix.darwinModules.default
      ];
      sops.age.sshKeyPaths = [
        "${host.machine.identity.home}/.ssh/id_ed25519"
      ];
      environment.systemPackages = [ pkgs.sops ];
      sops.secrets."OPENAI_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."ANTHROPIC_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."GEMINI_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."OPENROUTER_API_KEY" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
      sops.secrets."GITHUB_TOKEN" = {
        sopsFile = ../../../secrets/coding-agents.yaml;
        format = "yaml";
      };
    };
  };
}
