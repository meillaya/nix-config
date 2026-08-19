# Verification Economics — Converged

The gate is chosen by consequence and evidence layer, not by convenience.
“Not run because expensive” is never a green result.

| Gate / claim | Error cost | Typical cost | Chosen evidence | Decision / cadence | Current outcome | Residual risk |
|---|---|---|---|---|---|---|
| Exact evaluation of all six outputs | Medium | Seconds/minutes; cheap | `nix eval`/`flake check --all-systems --no-build` | Every change | Six paths evaluate; warnings and unsupported false green exist | No native build/activation proof |
| Strict package-platform metadata | High for false support | Cheap once global bypass removed | `availableOn`, `meta.broken`, native eval | Every change | ARM Chrome and Intel-Darwin iverilog exposed | Additional packages enumerate after first failure |
| Native closure build per claimed system | High | Minutes/hours and storage; remote builders may be needed | Native `nix build` with no skipped-success | PR for retained native systems; scheduled for expensive variants | x86 NixOS realized; five configurations lack equivalent native proof | Activation/hardware still separate |
| Lightweight source/architecture tests | Medium | Seconds | Existing three checks + six executable suites | Every PR/pre-push | Existing suites pass but are incompletely exported | Semantic/runtime gaps |
| Production-derived Disko VM | Critical release risk | Tens of minutes/GiB | Exact `system.build.installTest` with faithful dummy secret | Installer/release changes and release candidate | Red fixture; isolated disk/boot path green | Physical disk/firmware/transport absent |
| FAT capacity arithmetic/image allocation | High rollback risk | Seconds/minutes; non-destructive | Exact payload sizes + mtools/dosfstools image | Every kernel/initrd/retention/layout change | 100 MiB holds two unique payloads | Future initrd size and physical ESP state |
| systemd-boot ENOSPC fault injection | High | Seconds; synthetic | Exact builder harness, then VFAT VM/power-cut test | Builder/layout changes; release | Synthetic control flow executed; selected old generation survived | Real VFAT/power-loss untested |
| Strict SSH wrapper option/mismatch tests | Critical conditional | Seconds/minutes; non-destructive | `ssh -G`, disposable keys/servers, bounded retry/timeouts | Every installer change | Insecure option precedence proved; design harness pending integration | Physical stage transitions |
| Kexec artifact digest/signature | Critical conditional | Build minutes/hours + ~474 MiB | Exact Nix build, store verify, signed manifest controls | Every installer artifact release | Local exact artifact and 6/6 harness pass | Independent rebuild and signer custody |
| Secret current/history scan | High incident cost | Seconds/minutes | Pinned scanner + custom redacted controls | Every PR and release; full history after incident | Current incident detected; report redaction passes | Deleted forks/clones unknowable |
| Age recipient/closure boundary | High | Seconds/minutes synthetic; VM for integration | Recipient-isolation controls, closure/log scan | Every secret-policy change | Primitive passes; production integration absent | Host identity custody/rekey |
| Session generated-artifact checks | High usability/security | Seconds/minutes | Unit/D-Bus/command/asset/schema assertions | Every desktop change | Lock/notification/OBS/assets defects deterministically found | Cold-login ordering/visual behavior |
| Cold Niri login/lock/portal/render test | High | Minutes; physical GUI session | Journal/D-Bus trace, real clients, lock/resume/hotplug, screenshots | Each desktop release and hardware class | Not run | Cannot claim immediate session readiness |
| Sacrificial physical disk install/recovery | Critical/destructive | Hours + spare machine/disk | Signed manifest, wrong/missing/correct disk/mount, install/reboot/rollback | Before release and each storage/installer change | Not run | Highest remaining install risk |
| Per-host hardware acceptance | Critical to “works immediately” | Hours per host; physical | Inventory + boot/Wi-Fi/GPU/audio/suspend/hotplug/rollback | Enrollment; expire on kernel/firmware/hardware change | Not run for claimed class | Static evidence cannot substitute |
| Native Apple Silicon activation/rollback | High for Darwin claim | Hours; physical Mac | Build/switch, dscl, TCC, apps, CoreText/Kitty, rollback | Each Darwin release | Not run | Evaluation only |
| Native AArch64 boot/recovery | High | Hours; named target | Native build and physical SystemReady/board boot | Before ARM support claim | Not run | Current output is only template |
| Offline cold-store install | High availability | Hours; disconnected media/target | Exact closure/tool/media manifest, offline install/recovery | Each offline kit release | Not run | USB source checkout is insufficient |
| CI cache deployment | Medium | Engineering/credential surface | Measure native timing first; signed Nix substitution | Only if measured cost justifies it | Not implemented | Added supply-chain surface may exceed benefit |
| Performance/tooling experiments | Low to readiness | Variable | Local benchmark after correctness | Optional | Deferred/dead-end for current objective | No safety impact |

## Gate ordering

Cheap deterministic gates run first: redacted incident scan → exact eval and
strict platform checks → unit/source/generated-artifact tests → native builds →
VM/install/fault gates → sacrificial installs → physical-host acceptance.
Dependent expensive gates never erase an earlier red result.
