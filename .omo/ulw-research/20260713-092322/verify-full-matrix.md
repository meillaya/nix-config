# Verification — full local matrix

- Built system: `/nix/store/llvz0c9whmx6d90ig81ki05354i8np4w-nixos-system-nixos-26.11.20260705.d407951`
- `bash -n`: PASS for helper and all bootstrap shell tests.
- `shellcheck -e SC2329`: PASS. SC2329 is excluded only for helper functions invoked indirectly from traps.
- `bootstrap-password-install-helper.sh`: PASS, including PTY/agent behavior, generator boundaries, signals, status propagation and cleanup.
- `bootstrap-password-lifecycle.sh`: PASS, including explicit files-only empty NSS, numeric creation/migration, modes, symlinks, sentinel and hash shape.
- `bootstrap-password-secret-scan.sh`: PASS.
- `bootstrap-password-config-eval.nix`: PASS.
- `bootstrap-password-mutations.sh`: PASS directly against the tracked working tree through its isolated temporary index; both dependency edges and every numeric/name, creation, lifecycle, helper and secret mutant were killed while the real index remained unchanged. Full log: `verify-mutations-direct.log`.
- Multi-ID wrong owner/group matrix: PASS. Evidence: `verify-numeric-owner-matrix.md`.
- Diagnostic/recovery Bash and Nushell block syntax: PASS.
- `git diff --check`: PASS.
- `nix flake check --all-systems --no-build`: PASS; only existing derivation-context and unchecked `denful` warnings.
- Full x86_64 NixOS system build: PASS.

## Generated activation anchors
```text
34:#### Activation script snippet bootstrapPasswordHash:
59:  /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/chown 0:0 "$tmp"
68:  /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/install -d -o 0 -g 0 -m 0700 "$hash_dir" \
72:hash_dir_meta="$(/nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/stat -c '%u:%g:%a' "$hash_dir")" \
84:hash_file_meta="$(/nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/stat -c '%u:%g:%a' "$hash_file")" \
112:#### Activation script snippet users:
124:#### Activation script snippet consumeBootstrapPassword:
138:  hash_dir_meta="$(/nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/stat -c '%u:%g:%a' "$hash_dir")" || {
149:  /nix/store/sr26flm2nkfa12dkrwj2630kqsfakky4-coreutils-9.11/bin/chown 0:0 "$tmp"
```
