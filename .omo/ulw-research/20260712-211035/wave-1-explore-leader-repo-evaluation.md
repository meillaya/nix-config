# Wave 1 — Leader repo and evaluated-output investigation

## Key findings
- `modules/aspects/users/mei.nix:15-16` sets Darwin `environment.shells` and `users.users.mei.shell = pkgs.nushell`.
- Both Darwin configs evaluate the shell to Nushell and render `/run/current-system/sw/bin/nu` into `/etc/shells`.
- However, `users.knownUsers` contains only Nix build users; `mei` has no UID and is absent. The rendered `system.activationScripts.users.text` contains no `mei` block.
- Pinned nix-darwin `modules/users/default.nix` computes `createdUsers` only from known users/UIDs, and only those receive `dscl ... UserShell` updates. Its docs explicitly say not to add the admin user to `knownUsers`.
- Darwin packages contain `ghostty-bin` and Fastfetch but no Kitty.
- Pinned nixpkgs Kitty 0.47.4 supports both Darwin architectures, builds `kitty.app`, installs it under `$out/Applications/kitty.app`, and provides `$out/bin/kitty`.
- nix-darwin builds `/Applications/Nix Apps` from `/Applications` paths of `environment.systemPackages`, so adding `pkgs.kitty` is sufficient to surface the app bundle.

## Sources
- `/home/mei/nix-config/modules/aspects/users/mei.nix:13-17`
- `/home/mei/nix-config/modules/darwin/packages.nix:1-29`
- pinned nix-darwin `/nix/store/vya0lv78g5bjnbq851cb8amdsil0n3id-source/modules/users/default.nix:13-20,59-70,275-318`
- pinned nixpkgs `/nix/store/w8w3fia26p35xays42lixahnzigsl8dv-source/pkgs/by-name/ki/kitty/package.nix`
- pinned nix-darwin `/nix/store/vya0lv78g5bjnbq851cb8amdsil0n3id-source/modules/system/applications.nix:59-67,85-111`

## EXPAND
- LEAD: choose an idempotent activation for the existing admin account using `chsh` or `dscl`, without adding it to knownUsers — WHY: evaluated option alone is inert — ANGLE: official macOS/nix-darwin contract and generated activation test.
- LEAD: verify Kitty app linkage after package inclusion for both Darwin architectures — WHY: package metadata supports Darwin but config currently omits it — ANGLE: evaluate package names and system.build.applications inputs.
