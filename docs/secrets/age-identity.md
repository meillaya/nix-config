# Age Identity for SOPS

SOPS encrypts secrets to **age recipients** (`age1...` public keys). This repo's
sops-nix module (`modules/aspects/features/sops.nix`) sets `sops.age.sshKeyPaths`,
which converts your SSH ed25519 host/user key to an age identity **at runtime** —
so you usually don't need a standalone age key on the machine. You still need an
`age1...` recipient to put in `.sops.yaml` creation rules.

## Option A: Convert an existing SSH key (recommended)

Convert your SSH ed25519 public key to an age public key:

```sh
ssh-to-age < ~/.ssh/id_ed25519.pub
```

Requires the [ssh-to-age](https://github.com/Mic92/ssh-to-age) tool. The output is
an `age1...` recipient — use it as the recipient in `.sops.yaml`.

At runtime, sops-nix derives the matching age **private** key from the SSH key
listed in `sops.age.sshKeyPaths`, so no separate age secret key is needed on the host.

## Option B: Generate a standalone age key

Generate a new age identity:

```sh
age-keygen -o ~/.config/sops/age/keys.txt
```

Extract the public key (the `age1...` recipient):

```sh
age-keygen -y ~/.config/sops/age/keys.txt
```

Use the printed `age1...` value as the recipient in `.sops.yaml`.

## Wiring the recipient into .sops.yaml

The `.sops.yaml` creation rules require an age recipient. Whichever option you used,
add the `age1...` public key under `creation_rules`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.sops\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Notes

- `age-keygen -y` prints only the public key from a private key file.
- The repo relies on `sops.age.sshKeyPaths` for runtime SSH→age conversion; a
  standalone age key (Option B) is only needed if you're not using an SSH key.
- Keep `~/.config/sops/age/keys.txt` (Option B) private — it holds the secret key.
