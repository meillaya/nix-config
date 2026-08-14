# ZeroClaw — open-source, self-hosted AI agent runtime.
#
# Installed per the repo's own rule: the checksum-verified prebuilt release
# tarball from GitHub releases (one asset per platform triple), NOT the npm
# package and NOT the install.sh source build. The tarball contains a bare
# `zeroclaw` binary at the archive root (plus `zerocode` and a `web/dist/`
# dashboard — only the `zeroclaw` CLI is installed here).
#
# Hash verification: the three per-platform hashes below were obtained by
# `nix-prefetch-url --type sha256 <asset-url>` and cross-checked against the
# SHA-256 `digest` fields of the v0.8.4 GitHub release API payload (all match).

{ stdenv, fetchurl, lib, autoPatchelfHook }:

let
  version = "0.8.4";
  # Per-platform prebuilt asset. ZeroClaw ships one tarball per Rust target
  # triple; map Nix's host platform system to the exact release asset name.
  sources = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-+sIvmvL5QP07t+d960L6x9BS38gSEoEmlHA/fCDTTt8=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      hash = "sha256-SmPHLdS/ZNTWaXeAQOFXiIanMfxSfvGlsK7x0Y9rKdk=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      hash = "sha256-qizDyUfHNoBZ/K8Lm/Y2xKtler1qr2OyQG6gx+QE9bM=";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw
    "zeroclaw: no prebuilt release for platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "zeroclaw";
  inherit version;

  src = fetchurl {
    url = "https://github.com/zeroclaw-labs/zeroclaw/releases/download/v${version}/zeroclaw-${source.triple}.tar.gz";
    hash = source.hash;
  };

  # The Linux-gnu binaries are dynamically linked against glibc/libgcc_s;
  # patch their RPATH into the nix store. macOS binaries need no patching.
  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];

  # The archive mixes top-level files (`zeroclaw`, `zerocode`) with a
  # `web/` dashboard directory, which confuses stdenv's single-dir
  # source-root detection. Skip unpacking and extract the binary member
  # directly in installPhase.
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    tar -xzf "$src" zeroclaw
    install -Dm755 zeroclaw "$out/bin/zeroclaw"
    runHook postInstall
  '';

  meta = {
    description = "ZeroClaw — open-source, self-hosted AI agent runtime";
    homepage = "https://github.com/zeroclaw-labs/zeroclaw";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    mainProgram = "zeroclaw";
  };
}
