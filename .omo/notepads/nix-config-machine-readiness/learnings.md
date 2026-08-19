## validators.nix darwin branch: secretTrust relaxation (2026-07-27)
- Inlined `operationallyDisabled` in the darwin branch of `validCrossFields` to relax `secretTrust.state`
- Darwin now allows `secretTrust.state == "disabled" || secretTrust.state == "enrolled"`
- All other constraints unchanged: publicTrust="disabled", boot="disabled", storage="none", devices="disabled", capabilities="disabled", ddcConnectors=[], remoteInstall=false
- `nix flake check` has pre-existing failure: sublimetext4 broken (insecure OpenSSL) — unrelated to validators
- `nix eval .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel` succeeds after change
