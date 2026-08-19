# Wave 2 — Safe primary-admin shell reconciliation

## Findings
- Compose an idempotent `postActivation.text = lib.mkAfter` snippet in the user aspect.
- Preflight the new generation at `$systemConfig/sw/bin/nu`, but store stable `/run/current-system/sw/bin/nu` in Directory Service.
- Read `/Users/mei UserShell`, normalize `UserShell: ` prefix, and write only on mismatch.
- `set -e` behavior makes missing/inaccessible account or failed write fatal rather than silently succeeding.
- postActivation composes with existing Dock activation; knownUsers remains rejected for the primary admin.

## Proposed assertions
- generated postActivation contains `desired_shell=/run/current-system/sw/bin/nu`.
- generated postActivation contains `/usr/bin/dscl . -create /Users/mei UserShell "$desired_shell"`.

## EXPAND
- LEAD: stub dscl for mismatch and match to prove one write then no-op — WHY: validates idempotence and parsing — ANGLE: wave-3 executable shell-fragment harness.
