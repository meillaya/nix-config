{ den, inputs, ... }:
{
  den.aspects.desktop-media =
    { lib, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      supported = system == "x86_64-linux";
      helium = pkgs.callPackage ../../../pkgs/helium.nix {
        helium = inputs.helium.packages.${system}.default;
      };
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

      config = lib.mkIf supported {
        programs.spicetify.enable = true;
        home.packages = [ helium ];
      };
    };
}
