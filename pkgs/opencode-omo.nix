# oh-my-opencode: harness/wrapper for the Opencode CLI.
#
# Ships prebuilt (dist/), so dontNpmBuild = true.
# Verified against the 5.0.0-beta.7 tarball (2026-08-13): the published
# manifest still retains "workspaces" (30 entries), 29 "workspace:*"
# devDependencies, and bun-based scripts (build/prepare), with NO
# lockfile — npm fails with EUNSUPPORTEDPROTOCOL / missing bun.
# Lockfile AND stripped manifest (no workspaces, devDependencies, or
# scripts) must be injected via postPatch (not postUnpack) because
# buildNpmPackage's npmDeps FOD only inherits prePatch/patches/postPatch.
# 5.0 removed the `omo` bin; the launcher is now `omo-agent-toolkit`
# (plus oh-my-opencode/oh-my-openagent/lazycodex/lazycodex-ai), all
# pointing at bin/oh-my-opencode.js, which spawns the platform binary
# shipped via optionalDependencies (oh-my-opencode-linux-x64, ...).

{ lib, buildNpmPackage, fetchurl, makeWrapper, opencode }:

buildNpmPackage rec {
  pname = "opencode-omo";
  version = "5.0.0-beta.7";

  src = fetchurl {
    url = "https://registry.npmjs.org/oh-my-opencode/-/oh-my-opencode-${version}.tgz";
    hash = "sha256-El/a2jiQvOQOwsqo3ExPdXJae7+HgxpQTEy5fFgjox0=";
  };

  sourceRoot = "package";

  # MUST be postPatch, NOT postUnpack.
  # Inject BOTH lockfile AND stripped manifest.
  postPatch = ''
    cp ${./opencode-omo/package-lock.json} package-lock.json
    cp ${./opencode-omo/package.json} package.json
  '';

  npmDepsHash = "sha256-htCJaqOW5g/rzH8KeEhUlRRMFFqEz/24kD7UYFTYJkA=";

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    makeWrapper $out/bin/omo-agent-toolkit $out/bin/opencode \
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
