# Wave 2 — Repo Fastfetch kitty-direct and tmux verification

## Findings
- Rendered HM tmux config has zero allow-passthrough lines; live value is off.
- Fastfetch 2.65.1 with repo Snoopy PNG and kitty-direct width=40,height=30 emitted one complete Kitty APC: `a=T,f=100,t=f,c=40,r=30`.
- Payload decoded to the managed PNG path. Temp artifacts were removed and tracked status stayed clean.
- Minimal paired change: kitty-direct config plus `set -g allow-passthrough on`.

## EXPAND
- LEAD: verify Home Manager tmux option syntax and ensure the rendered config emits exactly `set -g allow-passthrough on` — WHY: required for Fastfetch inside tmux — ANGLE: config/test RED→GREEN.
