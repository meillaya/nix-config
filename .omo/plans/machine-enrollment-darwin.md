# Plan: Strip the machine-authority gate — expose `build-switch`/`clean`/`update` on darwin + linux

Status: APPROVED (user chose Option B, 2026-08-11) — supersedes `machine-enrollment-darwin.md` v1 (full-enrollment approach, dropped)
Date: 2026-08-11

## 1. Decision

The machine-authority enrollment ceremony is **repo policy, not a Nix requirement** — both
`darwinConfigurations.aarch64-darwin.system` and `nixosConfigurations.x86_64-linux` evaluate to
valid derivations today. Per user choice, **strip the app-gating** instead of enrolling
machines: `nix run .#build-switch` (and `clean`, `update`) become exposed unconditionally.

No key material, no validators change, no capability inventory, no trust chain.

## 2. Why the gate exists (context)

`modules/flake/apps.nix` only exposes mutation apps when a machine "authorizes" them:
`bootMutationAuthorizedFor` (linux) / `darwinMutationAuthorizedFor` (darwin) → `allowsSystemMutation`
(boot.state ≠ disabled || storage ≠ none || capabilities enrolled) — all false for the declared
machines, so `build-switch`/`clean`/`update` never appear. The gate was a safety posture
(evaluation-only until a machine is proven), but it permanently walls real use. Removing it is
a ~15-line change; the underlying scripts already exist and are real.

## 3. Changes

### 3.1 `modules/flake/apps.nix` — remove mutation gates
- `mkDarwinApps`: always expose `build-switch`, `clean`, `update` (delete the
  `lib.optionalAttrs (darwinMutationAuthorizedFor system)` block; base set becomes
  `build`, `search-pkgs`, `build-switch`, `clean`, `update`).
- `mkLinuxApps`: always expose `build-switch`, `clean` (delete the
  `lib.optionalAttrs (bootMutationAuthorizedFor system)` block).
- Remove now-unused helpers/imports, keeping only what's still referenced:
  - `bootMutationAuthorizedFor`, `linuxMachinesFor` → unused, delete.
  - `darwinMutationAuthorizedFor` → unused, delete.
  - `machineAuthority` import, `validatedMachines`, `darwinMachinesFor`, `darwinMachineFor`,
    `darwinCredentialAuthorizedFor`, `mkCredentialApp` → KEEP: the key apps
    (`copy-keys`/`create-keys`/`check-keys`) remain gated on `darwinCredentialAuthorizedFor`
    (stays false — trusts stay disabled). Out of scope for this change.
- NOTE: aarch64-darwin machine record stays exactly as-is (all "disabled" states). It is data
  consumed by the darwin config (identity/location/display/platformExpectations via aspects),
  not a gate anymore.

### 3.2 `apps/x86_64-linux/build-switch` — make it real (currently a stub)
Current script prints "build-only until … enrolled" and execs `build`. Replace with a real
switch mirroring the darwin pattern, host-parametrized like `apps/x86_64-linux/build`:

```bash
#!/usr/bin/env bash
set -euo pipefail
# --host HOST (default: x86_64-linux), passthrough nix args
nix build ".#nixosConfigurations.${host}.config.system.build.toplevel" "$@"
sudo ./result/sw/bin/nixos-rebuild switch --flake ".#${host}" "$@"
unlink ./result
```

(Verify the toplevel's nixos-rebuild path — `result/sw/bin/nixos-rebuild` per NixOS toplevel
layout; adjust if the toplevel exposes it at `result/bin/`.) No physical NixOS machine runs this
today (ThinkPad + this PC are CachyOS/standalone) — it's forward-ready.

### 3.3 `apps/x86_64-linux/clean` — make it real (currently a stub)
Mirror `apps/aarch64-darwin/clean`: `sudo nix-collect-garbage --delete-older-than 7d`.

### 3.4 Tests — TWO files must flip (Momus REJECT catch: `dendritic-apps.sh` is wired into
`nix flake check` via `modules/flake/checks.nix:27-36` and asserts the OPPOSITE of this plan)

**`tests/dendritic-config-eval.nix`:**
- `apps.aarch64-darwin` expected set → `["build" "build-switch" "clean" "search-pkgs" "update"]`
  (attrNames order; verify actual order at implementation).
- `apps.x86_64-linux` expected set → includes `build-switch`, `clean`.
- `!allowsSystemMutation` / `!allowsCredentialMutation` asserts: mutation asserts flip or are
  removed (the model still declares disabled states — if kept, test the model as data, not the
  app surface). `!allowsCredentialMutation` stays true (trusts unchanged).

**`tests/dendritic-apps.sh`:**
- Lines 43-50: linux expected apps list →
  `["build" "build-switch" "clean" "home-news" "home-switch" "search-pkgs" "sync-secrets" "update"]`
  and DELETE lines 51-52 (`assert "build-switch" not in apps` / `assert "clean" not in apps`).
- Lines 56-67: shrink the boot-mutating grep to ONLY the `build` scripts
  (`apps/x86_64-linux/build`, `apps/aarch64-linux/build`) — `build-switch`/`clean` now
  legitimately contain `nixos-rebuild switch` / `nix-collect-garbage --delete-older-than`;
  `build` must remain non-mutating.
- Line 101: darwin expected → `["build" "build-switch" "clean" "search-pkgs" "update"]`.
- Line 106: remove the `grep -Fq 'machineAuthority.allowsSystemMutation'` check (both callers
  deleted in §3.1). Lines 104 (`darwinMachinesFor`), 105 (`validatedMachines`),
  107 (`allowsCredentialMutation`) stay — still referenced by the retained credential path.

### 3.5 `README.md` + stale doc prose (Momus note)
- README: macOS section — `build-switch`/`clean`/`update` now exposed; remove "evaluation-only /
  operationally disabled / build-only Darwin app" language. KEEP the "first real activation
  NOT VERIFIED" caveat. NixOS section — remove "does not expose build-switch" language;
  document `nix run .#build-switch -- --host <host>`.
- Also update stale gating prose in `docs/architecture/dendritic.md` (~L140-145) and
  `docs/service-notes/homebrew-free-migration.md` (~L53-54) if they assert the old gated
  behavior (no check enforces docs — cosmetic but keeps docs honest).

### 3.6 No changes
- `modules/entities/_machine-authority/model.nix`, `validators.nix`, `crypto.nix` — untouched.
- `secrets/` — untouched (no `MOONSHOT_API_KEY` work needed here; that lives in plan 2).
- SSH keys already generated on the Mac (id_ed25519, id_ed25519_agenix) remain the Mac's
  identity keys — user re-registers the NEW pubkeys on GitHub (old ones were replaced by
  create-keys).

## 4. Verification

1. `nix eval .#apps.aarch64-darwin --apply builtins.attrNames` → `["build" "build-switch" "clean" "search-pkgs" "update"]`.
2. `nix eval .#apps.x86_64-linux --apply builtins.attrNames` → previous set + `build-switch` + `clean`.
3. `nix eval .#darwinConfigurations.aarch64-darwin.system.drvPath` still evaluates.
4. `nix eval .#nixosConfigurations.x86_64-linux.config.system.build.toplevel.drvPath` still evaluates.
5. `nix flake check` passes (updated `tests/dendritic-config-eval.nix` AND
   `tests/dendritic-apps.sh`).
6. On the Mac after commit + pull: `nix run .#build` (build) then `nix run .#build-switch`.

## 5. Risks / notes

- `build-switch` on darwin is the repo's FIRST live root-activation path (Linux scripts were
  build-only stubs) — the darwin script runs `sudo ./result/sw/bin/darwin-rebuild switch`.
  Accepted per user decision. The README "NOT VERIFIED" caveat applies to the first real switch.
- `update` (now on darwin too) mutates flake.lock + local source pins; run deliberately.
- `nixos-rebuild` path in the linux script must be verified at implementation time.
- The machine-authority model remains as dead-but-harmless data; a later cleanup could delete
  it, but that has wide blast radius (aspects consume machine fields) — explicitly OUT of scope.

## 6. Out of scope

- Full enrollment (validators branch, capability inventory, trust chain) — dropped by user choice.
- Credential apps (`copy-keys`/`create-keys`/`check-keys`) — remain gated; separate change if wanted.
- Deleting the machine-authority model/validators (kept as data; see 5).
- Plan 2 (coding agents) — separate approved plan.

## 7. Status: COMPLETED

- [x] Executed 2026-08-14 via /start-work (Atlas orchestration, 9 parallel workers + verify wave).
- [x] Verified: apps.aarch64-darwin = [build build-switch clean search-pkgs update];
      apps.x86_64-linux = [build build-switch clean home-news home-switch search-pkgs sync-secrets update];
      darwin + nixos drvPaths evaluate; all plan-scoped `nix flake check` checks pass.
- [x] Committed: `8de1a88` (strip-gate; docs for both plans in this commit).
- [x] Boulder: machine-enrollment-darwin work marked completed.
- [~] Deferred (not this plan's scope): `nix flake check` overall still FAILS on
      `package-policy` for the PRE-EXISTING `modules/aspects/features/desktop-media.nix`
      change (predates this plan, untouched by it). Resolving it is a user decision /
      separate change.
