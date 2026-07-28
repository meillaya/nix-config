# oh-my-opencode: harness/wrapper for the Opencode CLI.
#
# Ships prebuilt (dist/), so dontNpmBuild = true.
# The published tarball retains "workspaces" (27 entries), 26
# "workspace:*" devDependencies, and bun-based scripts — npm fails
# with EUNSUPPORTEDPROTOCOL / missing bun.  Lockfile AND stripped
# manifest (no workspaces, devDependencies, or scripts) must be
# injected via postPatch (not postUnpack) because buildNpmPackage's
# npmDeps FOD only inherits prePatch/patches/postPatch.

{ lib, buildNpmPackage, fetchurl, makeWrapper, opencode }:

buildNpmPackage rec {
  pname = "opencode-omo";
  version = "4.19.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/oh-my-opencode/-/oh-my-opencode-${version}.tgz";
    hash = "sha256-4y08SVBhz8NzOtFc+DLOx66oqUEIOwnB6uY6mZiZIS4=";
  };

  sourceRoot = "package";

  # MUST be postPatch, NOT postUnpack.
  # Inject BOTH lockfile AND stripped manifest.
  postPatch = ''
    cp ${./opencode-omo/package-lock.json} package-lock.json
    cp ${./opencode-omo/package.json} package.json
  '';

  npmDepsHash = "sha256-5UAlXz0lYSyF2ujpWe2cJN1ylwH93S6Kv6rhMW2W+No=";

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    makeWrapper $out/bin/omo $out/bin/opencode \
      --prefix PATH : ${lib.makeBinPath [ opencode ]}
  '';

  meta = {
    description = "Oh-my-openagent harness for Opencode";
    homepage = "https://github.com/code-yeongyu/oh-my-openagent";
    license = lib.licenses.unfree; # SUL-1.0, not in nixpkgs license set
    platforms = lib.platforms.all;
    mainProgram = "opencode";
  };
}
