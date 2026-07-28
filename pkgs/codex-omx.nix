# oh-my-codex: harness/wrapper for the Codex CLI.
#
# Ships prebuilt (dist/), so dontNpmBuild = true.
# The postinstall script downloads native Rust binaries — skip it.
# Lockfile must be injected via postPatch (not postUnpack) because
# buildNpmPackage's npmDeps FOD only inherits prePatch/patches/postPatch.

{ lib, buildNpmPackage, fetchurl, makeWrapper, codex }:

buildNpmPackage rec {
  pname = "codex-omx";
  version = "0.20.3";

  src = fetchurl {
    url = "https://registry.npmjs.org/oh-my-codex/-/oh-my-codex-${version}.tgz";
    hash = "sha256-tsrP8puzUN9++Q1YnbAuX5b9fRT+J04Hk50O+w9Buu0=";
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./codex-omx/package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-3IZ3EAEMo8oMrHSbItMxIhdBdw5pQ7qxsyocqVrTMzM=";

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    makeWrapper $out/bin/omx $out/bin/codex \
      --prefix PATH : ${lib.makeBinPath [ codex ]}
  '';

  meta = {
    description = "Oh-my-codex harness for Codex CLI";
    homepage = "https://github.com/Yeachan-Heo/oh-my-codex";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "codex";
  };
}
