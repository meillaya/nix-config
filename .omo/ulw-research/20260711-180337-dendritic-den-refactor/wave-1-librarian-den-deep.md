# Wave 1 — authoritative Den deep dive
Observer: Librarian the 17th · upstream pin 1614f6f8ed435c5bb257408bf91fd662f9aac43e · 2026-07-11

## Digest
Den's current architecture is entity declarations + multi-class aspects + schema/policy routing + quirks. Current v0.18 semantics require explicit cross-entity delivery; deprecated ctx, mutual-provider, and per-context guards must not be used. Official migration is coexistence-first: declare entities, retain legacy modules through import-tree, extract coherent aspects, then remove old files. Current main contains fixes beyond v0.18, so pin choice requires deliberate verification.

## EXPAND
- Map this repo's exact files to entity scopes/classes and aspect boundaries.
