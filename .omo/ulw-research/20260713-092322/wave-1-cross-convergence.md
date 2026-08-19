# Wave 1 — Cross-lane convergence (live digest)

- NSS lane evaluated exact activation order: bootstrap validator precedes `users` and `etc`; empty passwd/group makes GNU stat emit `UNKNOWN:UNKNOWN` while numeric IDs remain `0:0`.
- Activation lane confirmed nixos-install seeds only `/etc/NIXOS` and `/etc/mtab` before entering target chroot; it does not pre-create passwd/group.
- Transfer lane independently confirmed the exact short-path explicit chown results in numeric 0:0 and therefore cannot satisfy a name-based lookup while NSS data is absent.
- Skeptic lane converged on the same name-resolution cause and rejected transfer ownership as the supported explanation.
- Upstream issue #480 corroborates activation runs during installer execution; its installer hostname observation is not filesystem-root evidence and does not contradict the chrooted target path.

## EXPAND
- LEAD: add a formal empty-NSS lifecycle regression and run current validator RED — WHY: lock exact bug at repository test seam — ANGLE: bind empty passwd/group in a namespace.
- LEAD: run numeric validator GREEN plus adversarial owner/mode cases — WHY: prove minimal fix preserves security — ANGLE: `%u:%g:%a` predicate.
- LEAD: establish safe recovery/diagnostic steps for the already-failed target — WHY: user needs an actionable next run — ANGLE: installer-state inspection and full rerun boundary.
