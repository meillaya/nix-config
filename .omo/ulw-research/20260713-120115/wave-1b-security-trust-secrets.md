# Wave 1B — Install trust, SSH, secrets, cache and supply-chain audit

Observer: `security_trust_secrets`; tracked/history/store/evaluated exact-pin audit, upstream counter-search; observed 2026-07-13. Secret values are never reproduced.

## Findings

1. **Critical:** pinned nixos-anywhere `4dfb813...` hard-codes `UserKnownHostsFile=/dev/null` and `StrictHostKeyChecking=no` before user options. OpenSSH first-value semantics means helper cannot restore strict checking. Destructive root provisioning is MITM-vulnerable on untrusted networks; upstream issue #552 documents the limitation.
2. **High:** tracked Noctalia JSON contains a 32-character Wallhaven credential, introduced at commit `024d78a...`, present in public Git history and world-readable flake source store. Digest only: `sha256:0ae7611982a35114`. Do not test it; revoke/regenerate, review account, remove current value, then decide history rewrite.
3. **High:** exact nixos-anywhere downloads a mutable GitHub release kexec asset, untars and executes it as root without checksum/signature/attestation verification. Prefer locked custom build or pinned digest/attestation and fail closed.
4. **High:** same unrestricted key authorizes `mei` and root; generated policy allows root public-key login and user password/keyboard-interactive auth. Compromise yields direct root. Use no root login, key-only user access, separate restricted break-glass key if required.
5. **Medium:** bootstrap password persists indefinitely after safe verifier consumption; rotate/expire or disable remote password auth after key validation. Root disk is unencrypted.
6. **Medium:** `trusted-users` includes `mei`/admin, a root-equivalent Nix daemon authority boundary.
7. **Medium:** conditional plaintext HM file sources would enter world-readable Nix store if used. Current ignored/inactive state avoids active exposure; use agenix runtime paths instead.
8. **Medium:** agenix identity uses everyday personal SSH key, coupling login and decryption authority. No active age secrets now; use per-host recipients plus recovery recipient before enabling.
9. **Medium:** generated `sync-secrets` interpolates `${self}/secrets`, resolving to immutable store source; documented synchronization cannot update working tree. Wire explicit writable checkout path/specialArgs.
10. **Low:** nix-community substituter lacks matching trusted key and obsolete Noctalia trust remains. `require-sigs=true` makes this primarily availability/confusion, not unsigned acceptance.
11. Positive: all top-level inputs/fixed-output sources are pinned/digested; no GitHub Actions exist; bootstrap tmpfs/modes/yescrypt/agent isolation/atomic lifecycle tests are strong.
12. Wi-Fi secret-safe paths exist upstream: agenix-decrypted runtime environment files with NetworkManager ensureProfiles, or wpa_supplicant secretsFile/ext references. Never inline PSKs in Nix.

## Primary sources

- https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/src/nixos-anywhere.sh#L70
- https://github.com/nix-community/nixos-anywhere/issues/552
- https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases
- https://man.openbsd.org/sshd_config
- https://wallhaven.cc/help/api
- https://github.com/ryantm/agenix/blob/b027ee29d959fda4b60b57566d64c98a202e0feb/README.md
- https://nix.dev/manual/nix/2.18/command-ref/conf-file.html?highlight=trusted-user
- https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nm-settings-keyfile.html
- https://github.com/NixOS/nixpkgs/blob/d407951447dcd00442e97087bf374aad70c04cea/nixos/modules/services/networking/networkmanager.nix#L406-L474

## Claims

- Host authentication is disabled and cannot be repaired by current helper options.
- Exposed Wallhaven credential is in public history/store regardless of current Noctalia use.
- Mutable unverified kexec asset executes as root.
- Root/user key sharing and password auth are broad remote attack surfaces.
- Current bootstrap local secret lifecycle is strong but transport and post-install rotation remain weak.

## EXPAND
- LEAD: confirm Wallhaven rotation/account review — WHY: exposure cannot be mitigated by source only — ANGLE: user account action, do not validate key.
- LEAD: strict known-host lifecycle across ISO/kexec/final host — WHY: critical MITM boundary — ANGLE: patched/vendor installer plus out-of-band fingerprints.
- LEAD: reproducible/digest-verified kexec artifact — WHY: root supply chain — ANGLE: custom locked image or immutable attestation.
- LEAD: live installed-host SSH/NM/cache/password audit — WHY: repo eval may differ from runtime — ANGLE: sshd -T, keyfile modes, timers, password expiry.
- LEAD: repair agenix/sync boundary — WHY: future secret use would fail/expose — ANGLE: per-host recipients/runtime paths/writable checkout.
