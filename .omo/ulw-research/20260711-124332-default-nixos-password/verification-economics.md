# Verification Economics

| claim | risk | error cost | verification cost/time | chosen path | decision | outcome | residual risk |
|---|---|---|---|---|---|---|---|
| C1 | high | fresh-machine lockout | medium | upstream source + isolated Nix overlay | verify | supported | no real destructive reinstall run |
| C2 | high | credential disclosure | medium | Nix/NIST sources + full Git object scan | verify | supported | unknown secret formats remain theoretically possible |
| C3 | high | password reset/retention surprise | low | pinned option eval + updater source | verify | supported | backend must stay classic mutable |
| C4 | normal | unrelated config regression | low | overlay eval of groups/keys/derivation | verify | supported | actual boot/UI not exercised |
| C5 | high | empty password or lockout | low | source analysis + eleven-case exact emitted-validator matrix, consumer execution, and Fish boundary matrix | verify | supported | full activation/PAM VM test remains |
| C6 | high | first-boot lockout from wrong path | medium | two independent source chains + upstream integration test | verify | `/run` refuted; `/var/lib` supported | no local nixos-anywhere VM test |
| C7 | normal | usability/security mismatch | medium | adversarial policy review | verify conditionally | partial/conditional | user policy choices remain |
