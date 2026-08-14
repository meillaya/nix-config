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
      packages = {
        opencode-omo = pkgs.callPackage ../../pkgs/opencode-omo.nix { };
      } // lib.optionalAttrs (system == "aarch64-darwin") {
        omniwm = pkgs.callPackage ../../pkgs/omniwm.nix { };
      };
    };
}
