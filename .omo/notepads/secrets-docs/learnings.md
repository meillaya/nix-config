
## age-identity.md (2026-07-27)
- Created docs/secrets/age-identity.md documenting age identity for sops.
- Repo uses sops.age.sshKeyPaths (modules/aspects/features/sops.nix) → runtime SSH→age conversion, so standalone age key usually unnecessary.
- Key commands: `age-keygen -o ~/.config/sops/age/keys.txt`, `age-keygen -y <file>` (public key), `ssh-to-age < ~/.ssh/id_ed25519.pub` (needs ssh-to-age tool).
- .sops.yaml creation_rules require an age1... recipient.
