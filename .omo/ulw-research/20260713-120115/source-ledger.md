# User-Supplied Source Ledger

Access date target: 2026-07-13. Base status values are `reviewed`, `pending`,
`duplicate`, `moved`, `blocked-recovered`, and `contextual-only`. Slash-qualified
suffixes record scope or disposition, such as `historical`, `obsolete-v4`,
`resolved`, `partial-rate-limited`, or `irrelevant-to-portability`; the base
token remains machine-readable.

| id | URL | status | owner/artifact |
|---|---|---|---|
| S01 | https://github.com/IogaMaster/dotfiles | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S02 | https://github.com/eljangus/Hyprland-Dotfiles | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S03 | https://nixos.org/manual/nixos/stable/#sec-installation-manual | reviewed | wave-1-librarian-official-nixos-docs.md |
| S04 | https://www.socallinuxexpo.org/scale/21x/presentations/case-nix-home-server/ | reviewed | wave-1-librarian-deployment-images-roles.md |
| S05 | https://www.youtube.com/watch?v=Q-QPtHrvLB0 | reviewed | wave-1b-browsing-media-community.md |
| S06 | https://www.youtube.com/watch?v=CwfKlX3rA6E | reviewed | wave-1b-browsing-media-community.md |
| S07 | https://funloop.org/post/2015-02-10-using-nix-from-arch.html | reviewed/historical | wave-1b-browsing-media-community.md |
| S08 | https://github.com/noctalia-dev/noctalia-shell/issues/2272 | reviewed/obsolete-v4 | wave-1b-librarian-niri-noctalia-upstream.md |
| S09 | https://github.com/mrcjkb/nix-flake-github-ci-template | reviewed | wave-1-librarian-operations-ci.md |
| S10 | https://github.com/khyryra/dotfiles/tree/main/nixos-config | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S11 | https://github.com/NazariiPalahnii/nixos | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S12 | https://github.com/LGUG2Z/nixos-wsl-starter?tab=readme-ov-file | reviewed | wave-1-librarian-deployment-images-roles.md |
| S13 | https://saylesss88.github.io/posts/nixpkgs_pull_requests/ | moved | wave-1-librarian-operations-ci.md |
| S14 | https://github.com/NixOS/nixpkgs/issues/213263 | reviewed/resolved | wave-1-librarian-operations-ci.md |
| S15 | https://github.com/dustinlyons/nixos-config?tab=readme-ov-file#installing | reviewed | wave-1-librarian-deployment-images-roles.md |
| S16 | https://github.com/nix-community/nixos-images?tab=readme-ov-file#kexec-tarballs | reviewed | wave-1-librarian-deployment-images-roles.md |
| S17 | https://github.com/DeterminateSystems/nixos-iso?tab=readme-ov-file | reviewed | wave-1-librarian-deployment-images-roles.md |
| S18 | https://github.com/blkflth/blkedn/blob/main/rice/niri/keybinds.nix | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S19 | https://github.com/khyryra/dotfiles/blob/main/nixos-config/applications/niri.nix | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S20 | https://github.com/AdrielVelazquez/nixos-config | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S21 | https://github.com/QuackHack-McBlindy/dotfiles | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S22 | https://github.com/kiriwalawren/nixflix?utm_source=chatgpt.com | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S23 | https://github.com/khyryra/dotfiles/tree/main/nixos-config | duplicate | S10 |
| S24 | https://github.com/basnijholt/dotfiles | reviewed | wave-1-repodive-reference-configs-desktop.md |
| S25 | https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+author%3Ar-ryantm | reviewed/contextual | wave-1-librarian-operations-ci.md |
| S26 | https://github.com/nix-community/fenix | reviewed | wave-1-librarian-operations-ci.md |
| S27 | https://trofi.github.io/posts/240-nixpkgs-bootstrap-intro.html | reviewed/historical | wave-1-librarian-operations-ci.md |
| S28 | https://github.com/utdemir/nix-tree | reviewed | wave-1-librarian-operations-ci.md |
| S29 | https://github.com/snowfallorg/icicle | reviewed | wave-1-librarian-deployment-images-roles.md |
| S30 | https://github.com/sodiboo/niri-flake | reviewed/comparative-only | wave-1b-librarian-niri-noctalia-upstream.md |
| S31 | https://unixporn-dots.github.io/#main_header | reviewed/contextual | wave-1-repodive-reference-configs-desktop.md |
| S32 | https://github.com/search?q=path%3Avscode.nix&type=code | reviewed-partial-rate-limited | wave-1c-librarian-editor-ai-gpu.md (sampled results; exhaustive pagination blocked by GitHub code-search quota) |
| S33 | https://steelph0enix.github.io/posts/llama-cpp-guide/ | reviewed-secondary-with-current-countersearch | wave-1c-librarian-editor-ai-gpu.md |
| S34 | https://www.reddit.com/r/NixOS/comments/zwqaxz/arch_user_convince_me_to_hop_to_nix/ | reviewed/contextual | wave-1b-browsing-media-community.md |
| S35 | https://photon-reddit.com/r/NixOS/comments/1oeo94c/cannot_for_the_life_of_me_free_space/ | blocked-recovered | wave-1-librarian-operations-ci.md |
| S36 | https://saylesss88.github.io/posts/debugging_and_tracing_modules/ | moved | wave-1-librarian-operations-ci.md |
| S37 | https://discourse.nixos.org/t/did-nixos-logos-colours-changed/67866/29 | reviewed-governance-context | wave-1c-librarian-branding-theme-assets.md |
| S38 | https://photon-reddit.com/r/NixOS/comments/1p4v1f0/goddammit_nix_tell_me_which_package_in_my_config/ | blocked-recovered | wave-1-librarian-operations-ci.md |
| S39 | https://photon-reddit.com/r/NixOS/comments/1kr702z/how_do_you_develop_your_flake_if_building_it/ | blocked-recovered | wave-1-librarian-operations-ci.md |
| S40 | https://nixos.org/guides/how-nix-works/ | reviewed | wave-1-librarian-official-nixos-docs.md |
| S41 | https://sakurakat.systems/posts/hyperv-shenanigans/ | reviewed | wave-1-librarian-deployment-images-roles.md |
| S42 | https://discourse.nixos.org/t/nix-community-survey-2024-results-gender-distribution/55489/34 | reviewed/irrelevant | wave-1b-browsing-media-community.md |
| S43 | https://nixos-and-flakes.thiscute.world/ | reviewed | wave-1b-browsing-media-community.md |
| S44 | https://m.youtube.com/watch?v=ZuVQds2hncs | reviewed | wave-1b-browsing-media-community.md |
| S45 | https://tsawyer87.github.io/ | reviewed/caution | wave-1b-browsing-media-community.md |
| S46 | https://photon-reddit.com/r/NixOS/comments/1n89r6t/nixos_hyprland/ | reviewed/irrelevant | wave-1b-browsing-media-community.md |
| S47 | https://nixos.org/manual/nixos/stable/ | duplicate/reviewed | S03 |
| S48 | https://forrestjacobs.com/nixos-on-wsl/ | reviewed/historical | wave-1-librarian-deployment-images-roles.md |
| S49 | https://wiki.nixos.org/wiki/NixOS_Wiki | reviewed | wave-1-librarian-official-nixos-docs.md |
| S50 | https://wiki.nixos.org/wiki/NixOS_Wiki | duplicate | S49 |
| S51 | https://nixos.org/manual/nixpkgs/stable/ | reviewed | wave-1-librarian-official-nixos-docs.md |
| S52 | https://nixos.org/guides/nix-pills/ | reviewed/historical | wave-1-librarian-official-nixos-docs.md |
| S53 | https://photon-reddit.com/r/NixOS | reviewed/dynamic-context | wave-1b-browsing-media-community.md |
| S54 | https://nixos.wiki/wiki/Steam | reviewed/legacy | wave-1-librarian-official-nixos-docs.md |
| S55 | https://devenv.sh/blog/2026/06/26/making-devenv-start-fast-and-the-whole-nixpkgs-with-it/#side-by-side | reviewed/contested | wave-1-librarian-operations-ci.md |
| S56 | https://devenv.sh/ | reviewed | wave-1-librarian-operations-ci.md |
| S57 | https://github.com/denful/den | reviewed | wave-1-librarian-deployment-images-roles.md |
| S58 | https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/FAQ | reviewed | wave-1-librarian-deployment-images-roles.md |
| S59 | https://github.com/mightyiam/dendritic | reviewed | wave-1-librarian-deployment-images-roles.md |
| S60 | https://www.reddit.com/r/NixOS/comments/1s3oc2n/for_the_nixos_neurotics_how_was_your_switch_to/ | reviewed/contextual | wave-1b-browsing-media-community.md |
