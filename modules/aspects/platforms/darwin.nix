{ den, ... }:
{
  den.aspects.darwin-platform.includes = [
    den.aspects.shared-policy
    den.aspects.darwin-base
    den.aspects.sops
    den.aspects.darwin-home
  ];
}
