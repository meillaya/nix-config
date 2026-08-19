# Wave 1 — authoritative Den web observations
Observed: 2026-07-11

- Den defines aspects as context functions that return class modules for NixOS, Darwin, Home Manager, Hjem, or custom classes. Source: https://github.com/denful/den README lines 283-316.
- Den's primary concepts are entity, aspect, policy, and quirk; hosts select feature aspects rather than owning monolithic import trees. Source: https://github.com/denful/den README lines 306-316.
- Den explicitly supports incremental integration into an existing flake and says its migration guide is intended for existing nixosConfigurations, darwinConfigurations, and homeConfigurations. Source: https://den.denful.dev/guides/from-flake-to-den/ lines 140-155.
- Den's zero-to guide recommends auto-loaded aspect modules in modules/, with legacy plain modules under an underscore-prefixed ignored subtree during migration. Source: https://den.denful.dev/guides/from-zero-to-den/ lines 162-177.
- The guide says aspect-oriented setups should not be monolithic; files may incrementally contribute to any aspect. Source: https://den.denful.dev/guides/from-zero-to-den/ lines 236-245 and 359-376.
- Host and user context values are real function arguments, not _module.args or specialArgs. Source: https://den.denful.dev/guides/from-zero-to-den/ lines 363-367.
- Den includes a user-shell battery and Home Manager integration, both directly relevant to making Nushell primary without coupling user logic to host modules. Source: https://den.denful.dev/guides/from-zero-to-den/ navigation lines 45-84.

## EXPAND
- LEAD: From-Flake migration supports a hybrid state before Den-only outputs — WHY: safest path for current multi-platform flake — ANGLE: inspect exact migration steps and templates.
- LEAD: user-shell battery semantics — WHY: may be authoritative way to set Nushell across NixOS/Darwin — ANGLE: inspect source/tests/options.
- LEAD: import-tree ignored underscore subtree — WHY: possible compatibility bridge but may conflict with desired clean final state — ANGLE: compare direct aspect conversion vs legacy wrapper.
- LEAD: current v0.18.0/versioning policy — WHY: API stability and pin choice — ANGLE: release/version docs and migration notes.
