# Wave 1 — hlissner organization transfer
Observer: Librarian the 21st · upstream pin 8fd49e4bb971f6035e4fd9c3e059f5dc2e8d87b9 · 2026-07-11

## Digest
hlissner/dotfiles is host-centric and recursively loaded, not dendritic. Transfer only bounded organization ideas: thin host declarations, domain taxonomy, separate role/network/hardware/user concerns, shared versus host-local secrets, isolated local packages/overlays, and a small generic lib. Do not transfer universal recursive loading, string-selector profiles, or lateral global-config feature detection into Den.

## EXPAND
- Map useful profile taxonomy into typed Den entity facts.
- Recast deployable app configs as application aspects.
- Preserve shared/host-local secret distinction with explicit entity wiring.
