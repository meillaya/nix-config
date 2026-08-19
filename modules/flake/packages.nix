{ inputs, lib, ... }:
let
  mkConfiguredPkgs = (import ../../lib/nixpkgs.nix { inherit inputs; }).mkPkgs;
in
{
  perSystem = { system, ... }:
    let
      pkgs = mkConfiguredPkgs system;
    in
    {
      packages = lib.optionalAttrs (system == "aarch64-darwin") {
        omniwm = pkgs.callPackage ../../pkgs/omniwm.nix { };
      };
    };
}
