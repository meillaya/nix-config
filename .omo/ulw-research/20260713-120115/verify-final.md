# Final exact-tree verification

Executed 2026-07-13 against production revision `e9f78180748f1feb428ffb20f9d932c5d9918a48`. Research artifacts are ignored; tracked production status was required clean.

## Command results

| Check | rc | Seconds | Evidence |
|---|---:|---:|---|
| `git-status-clean` | 0 | 0 | [`git-status-clean.log`](verification-logs/git-status-clean.log) |
| `source-ledger-complete` | 0 | 0 | [`source-ledger-complete.log`](verification-logs/source-ledger-complete.log) |
| `base-lane-count` | 0 | 0 | [`base-lane-count.log`](verification-logs/base-lane-count.log) |
| `expansion-waves` | 0 | 0 | [`expansion-waves.log`](verification-logs/expansion-waves.log) |
| `credential-report-redaction` | 0 | 0 | [`credential-report-redaction.log`](verification-logs/credential-report-redaction.log) |
| `test-bootstrap-password-install-helper` | 0 | 2 | [`test-bootstrap-password-install-helper.log`](verification-logs/test-bootstrap-password-install-helper.log) |
| `test-bootstrap-password-lifecycle` | 0 | 3 | [`test-bootstrap-password-lifecycle.log`](verification-logs/test-bootstrap-password-lifecycle.log) |
| `test-bootstrap-password-mutations` | 0 | 35 | [`test-bootstrap-password-mutations.log`](verification-logs/test-bootstrap-password-mutations.log) |
| `test-bootstrap-password-secret-scan` | 0 | 1 | [`test-bootstrap-password-secret-scan.log`](verification-logs/test-bootstrap-password-secret-scan.log) |
| `test-dendritic-apps` | 0 | 0 | [`test-dendritic-apps.log`](verification-logs/test-dendritic-apps.log) |
| `test-dendritic-architecture` | 0 | 0 | [`test-dendritic-architecture.log`](verification-logs/test-dendritic-architecture.log) |
| `test-dendritic-boundaries` | 0 | 0 | [`test-dendritic-boundaries.log`](verification-logs/test-dendritic-boundaries.log) |
| `test-dendritic-shells` | 0 | 11 | [`test-dendritic-shells.log`](verification-logs/test-dendritic-shells.log) |
| `flake-check-all-systems-no-build` | 0 | 8 | [`flake-check-all-systems-no-build.log`](verification-logs/flake-check-all-systems-no-build.log) |
| `eval-x86-toplevel` | 0 | 27 | [`eval-x86-toplevel.log`](verification-logs/eval-x86-toplevel.log) |
| `eval-arm-toplevel` | 0 | 11 | [`eval-arm-toplevel.log`](verification-logs/eval-arm-toplevel.log) |
| `eval-darwin-arm` | 0 | 6 | [`eval-darwin-arm.log`](verification-logs/eval-darwin-arm.log) |
| `eval-darwin-intel` | 0 | 5 | [`eval-darwin-intel.log`](verification-logs/eval-darwin-intel.log) |
| `eval-hm-x86` | 0 | 6 | [`eval-hm-x86.log`](verification-logs/eval-hm-x86.log) |
| `eval-hm-arm` | 0 | 5 | [`eval-hm-arm.log`](verification-logs/eval-hm-arm.log) |

All rows above returned zero. `nix flake check --all-systems --no-build` evaluated all declared systems but did not realize foreign-platform outputs; its log retains the scoped `options.json` context warning and unchecked `denful` warning.

## Publication and closing-context verification

The independent final review added seven repository-local observations without
changing production code or the 60-entry supplied-source ledger. The converged
model now contains 141 sequential observations, 58 matching canonical claim
IDs across both claim artifacts, and 20 closed intent rows.

The report was rebuilt from `SYNTHESIS.md` with `build-report.sh`. Its preflight
derives and verifies source/observation/claim counts and production revision,
Pandoc emits a fresh HTML5 intermediate, and the atomic postprocessor is
idempotent. A second postprocess produced the identical HTML SHA-256 with four
table regions and four captions. `xmllint --html --noout`, Ruff, Basedpyright,
Python compilation, Node syntax checks, and both `qpdf --check` runs returned
zero.

Browser QA loaded the repository-root HTTP surface at mobile, tablet, and
desktop widths. Every run returned 200 with no console/page errors, overflow,
duplicate IDs, missing fragments, unsafe schemes, or table semantic failures;
all 28 same-origin artifact/source-snapshot links returned 200. All 24 unique
external report citations returned 2xx/3xx after redirects. The 32-page Letter
and 30-page A4 PDFs are tagged, have extractable text without NUL/replacement
characters, and contain no author-specific `file://`, `/home/mei`, or `/tmp`
annotations.

## Evaluated output identities

- `eval-x86-toplevel`: `/nix/store/2skzh1yk3bzz5g30zxf6ngcai78m3vci-nixos-system-nixos-26.11.20260705.d407951`
- `eval-arm-toplevel`: `/nix/store/1vfrlw263xl9mfqcay2al1pj7c5cbmll-nixos-system-nixos-aarch64-26.11.20260705.d407951`
- `eval-darwin-arm`: `/nix/store/lf0n3hhss1w6k5vz4nilgpi9z0bgdnks-darwin-system-26.11.a1fa429`
- `eval-darwin-intel`: `/nix/store/v8pazliybqjihjhll595s0xi146blp0y-darwin-system-26.11.a1fa429`
- `eval-hm-x86`: `/nix/store/d9kfhvbx41x9n1r78j5sls3319b7lsmm-home-manager-generation`
- `eval-hm-arm`: `/nix/store/23rmdki82sqm6g5i09kxxdjcjbffcdlg-home-manager-generation`

## Intentional red/negative evidence

- Production `nixosConfigurations.x86_64-linux.config.system.build.installTest` is **red**: it formats/mounts successfully and then fails because the generic Disko fixture does not stage the required bootstrap hash. Evidence: `wave-2-installtest-build.log` and `wave-2-esp-vm-capacity.md`.
- A research-only causal isolation of the bootstrap consumer is **green** through Disko, systemd-boot, OVMF reboot, and `local-fs.target`; this does not replace a faithful dummy-secret fixture.
- Exact 100 MiB FAT allocation accepts two fully unique current kernel+initrd payloads and rejects the third.
- Strict platform evaluation with `allowUnsupportedSystem=false` exposes x86-only Google Chrome in the declared AArch64 Linux output; the current permissive policy therefore creates a real false green.
- Exact Noctalia rejects `msg screen-lock`; exact supported command is `msg session lock`. OBS launcher exits 127 in the realized clean profile.

## Evidence boundary

- No physical NixOS laptop, AArch64 machine, Intel/ARM Mac activation, Wi-Fi controller, Secure Boot firmware, suspend/resume, or destructive sacrificial install was available for this final run.
- Evaluation and store-artifact success are not reported as physical readiness.
- Credential validity was deliberately not tested. A byte scan confirmed the tracked credential value does not appear anywhere under this research session.
- All production tracked files remained unchanged.
