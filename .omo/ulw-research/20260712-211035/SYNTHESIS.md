# ULW-Research Synthesis: macOS Nushell, Kitty, and Fastfetch Snoopy

Workers: 10 lanes · Waves: 3 · Sources: 19 observations · Verifications: 5

## Executive summary

Three independent configuration gaps explain the report. First, the Darwin option says Nushell, but pinned nix-darwin mutates only `knownUsers` with UIDs; the primary admin `mei` is intentionally outside that ownership set, so generated activation contains no account `UserShell` write [Source 1][Source 2]. Second, Kitty is simply absent from Darwin packages, although the pinned `pkgs.kitty` supports both configured Darwin systems and ships both `kitty.app` and the CLI [Source 3][Source 4]. Third, the shared asset now resolves, but `kitty` mode retains an ImageMagick conversion dependency and tmux passthrough is off. `kitty-direct` with explicit 40x30 dimensions emits a valid APC for the exact PNG; tmux must allow passthrough [Source 5][Source 6].

The minimal safe fix is: preserve the primary-admin ownership boundary and add an idempotent postActivation that reconciles only Directory Service `UserShell`; add `pkgs.kitty` to Darwin packages; switch the shared PNG logo to `kitty-direct` with height 30; and enable tmux passthrough. Physical macOS GUI rendering remains the only unavailable proof.

## Root causes and fixes

1. **Nushell account state:** `modules/aspects/users/mei.nix` declares Nu, but generated users activation omits mei. Upstream derives mutations only from knownUsers+UID and warns against enrolling admin users [Source 1][Source 2]. Fix with narrow idempotent postActivation, proven across mismatch/match/read-failure/write-failure [Source 7].
2. **Kitty delivery:** `modules/darwin/packages.nix` omits Kitty. Pinned nixpkgs builds Darwin `kitty.app`; pinned nix-darwin copies `/Applications` from system packages into `/Applications/Nix Apps` [Source 3][Source 4]. Add `kitty` to the Darwin package list.
3. **Snoopy pipeline:** historical missing asset caused ASCII fallback and is already fixed, but explicit `kitty` still depends on conversion. `kitty-direct` sends the PNG path directly and exact local execution emitted `a=T,f=100,t=f,c=40,r=30` [Source 5][Source 6]. Add tmux `allow-passthrough on` [Source 8].

## Contradictions resolved

- Kitty absence did not cause the historical Apple fallback; missing asset resolution did [Source 9]. Kitty installation and Fastfetch robustness are separate current requirements.
- Unsupported Kitty protocol alone normally emits ignored bytes without ASCII fallback; missing source/backend failure causes builtin ASCII [Source 5].
- `system.primaryUser` does not enroll a nix-darwin managed user [Source 2].

## Gaps

- Cannot run `dscl`, copy Kitty.app into `/Applications/Nix Apps`, or visually inspect Kitty on physical macOS from this Linux runner.
- Apple Terminal bitmap-protocol absence remains a partial high-risk absence claim; the required acceptance surface is Kitty, not Apple Terminal.

## Expansion trace

- Wave 1: repo ownership/history, nix-darwin source/docs, Kitty packaging, Fastfetch protocols, terminal compatibility.
- Wave 2: exact postActivation design, terminal override countersearch, kitty-direct APC and tmux inspection.
- Wave 3: four-case activation stub and rendered tmux/JSONC contract. Zero unchecked actionable leads remain; live Mac checks are environment-gated.

## Sources

1. `modules/aspects/users/mei.nix:13-17` and generated Darwin activation evidence (`wave-1-explore-darwin-shell.md`).
2. [nix-darwin users source](https://github.com/nix-darwin/nix-darwin/blob/d5bd9cd77aea4c0a8f49e7fd85545671a208ed15/modules/users/default.nix#L17-L41).
3. Pinned nixpkgs `pkgs/by-name/ki/kitty/package.nix` (`wave-1-librarian-kitty-darwin.md`).
4. [nix-darwin applications source](https://github.com/nix-darwin/nix-darwin/blob/c3e90c89649b07d1a96e4b9dd6cd0d6e44b91a74/modules/system/applications.nix#L59-L111).
5. [Fastfetch logo source](https://github.com/fastfetch-cli/fastfetch/blob/e0c31be9d5e8bd227307d50050850c51d80b93a4/src/logo/logo.c#L607-L685).
6. `wave-2-verify-fastfetch-tmux.md` exact APC execution.
7. `wave-3-verify-shell-idempotence.md` four-case stub proof.
8. [Fastfetch logo options](https://github.com/fastfetch-cli/fastfetch/wiki/Logo-options#kitty-direct).
9. `wave-1-explore-darwin-packages-fastfetch.md` historical dual-Darwin evaluation and fallback reproduction.

## Implementation outcome

GREEN is now observed for every repo-testable intent: both Darwin package graphs contain Kitty; the generated shell activation is idempotent and fully regression-locked; the exact managed Fastfetch profile emits one direct Kitty APC at 40x30; tmux passthrough renders exactly once; and all-system flake evaluation plus dendritic regressions pass. Five independent review lanes approved after the initial test-coverage blockers were corrected.
