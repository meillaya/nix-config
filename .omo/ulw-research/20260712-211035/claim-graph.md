# Claim Graph

## verified-claims
- C1: Darwin shell declaration is not applied to the real account because mei is outside knownUsers/UID-managed activation.
- C2: A narrow idempotent postActivation can safely reconcile only UserShell without owning the admin account.
- C3: Kitty is absent now; local pinned pkgs.kitty supports both Darwin outputs and ships Kitty.app plus CLI.
- C4: kitty-direct 40x30 with the managed PNG removes ImageMagick conversion dependence and emits valid Kitty APC.
- C5: rendered tmux currently blocks passthrough; allow-passthrough on is required for nested graphics.

| claim_id | statement | type | risk | scope | intent ids | supporting observations | contradicting observations | groups | convergence | counter-search | primary | dependencies | status | synthesis |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| C1 | Declared Darwin Nushell is inert for existing mei account because generated activation excludes non-known user | causal/code | high | repo/runtime | I1 | O4,O5,O6,O8,O9,O10 | none | leader-repo,darwin-shell-repo,nix-darwin-docs | converged | primaryUser/hidden chsh searched and refuted | nix-darwin source | none | supported | Root cause 1 |
| C2 | Narrow postActivation dscl reconciliation is idempotent and safer than knownUsers ownership | design/code | high | Darwin activation | I1 | O17,O19 | built-in knownUsers can work but violates admin ownership guidance | shell-design,shell-stub | converged | chsh and knownUsers alternatives evaluated | nix-darwin source | C1 | supported | Fix 1 |
| C3 | Kitty is absent; pkgs.kitty supplies CLI+Kitty.app for both pinned Darwin configs | code/package | normal | Darwin packages | I2 | O7,O13,O15 | historical policy intentionally omitted it | leader-repo,packages-repo,kitty-docs | converged | kitty-bin/arch/app-copy alternatives refuted | pinned nixpkgs+nix-darwin source | none | supported | Root cause/fix 2 |
| C4 | kitty-direct PNG 40x30 is valid and avoids kitty mode ImageMagick backend | code/compat | high | Fastfetch | I3 | O1,O2,O11,O12,O16 | Apple Terminal lacks Kitty graphics | fastfetch-docs,terminal-compat,wave2-exec | converged | auto/chafa/iterm/sixel evaluated | Fastfetch+Kitty source | C3 | supported | Root cause/fix 3 |
| C5 | tmux passthrough is absent and required for Kitty APC through tmux | code/config | normal | Home Manager tmux | I3 | O16 plus wave3 contract | no contrary config | terminal-compat,wave2-exec,wave3-contract | converged | rendered config and live option checked | tmux/Fastfetch docs | C4 | supported | Fix 3 |
| C6 | Apple Terminal cannot be relied on for bitmap Snoopy | compatibility/absence | high | live macOS | I3 | O1,O2,O3 | physical protocol query unavailable | terminal-compat,Fastfetch-docs | exception: physical Mac unavailable | official docs + independent matrix countersearch | Apple Terminal guide does not claim image support | none | partial | Gap |
