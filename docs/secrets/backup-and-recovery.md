# Backup & Recovery

How the secrets in this repo are encrypted, what can recover what, and the exact
procedure to restore access on a new machine.

## Secret inventory

| Artifact | Contents | Encrypted to | Tracked in git? |
| --- | --- | --- | --- |
| `secrets/github-ssh-key.age` | `~/.ssh/id_ed25519` (GitHub auth key, also the age identity) | `keys.txt` + SSH-derived + **recovery** | No (`secrets/*` ignored) |
| `secrets/coding-agents.yaml` | Agent API keys (currently placeholder values) | `keys.txt` + **recovery** | Yes (committed, sops-encrypted) |
| `~/.ssh/id_ed25519` + `.pub` | GitHub SSH auth key | — | No |
| `~/.config/sops/age/keys.txt` | Sops/age identity (`age1xxj3ft...`) | — | No |
| `~/.config/sops/age/recovery.txt` | **Recovery identity** (`age1f3fgneph45yn900kqvzkysztspyz7puh9uqneujpxft5rsqjeglq99lnz0`) | — | No |

The `age1...` recipients are declared in `.sops.yaml` as `&admin` (keys.txt) and
`&recovery` (recovery.txt). The SSH-derived recipient is computed at runtime from
`~/.ssh/id_ed25519.pub` via `ssh-to-age`.

## The recovery key (store offline)

`~/.config/sops/age/recovery.txt` is the master recovery path. **Copy it to a
password manager, encrypted USB, or second trusted device.** It is the only key
that can decrypt both the SSH key backup and the sops file from a machine that
never had the original keys.

Without it, the encrypted backups are only usable from this machine — losing the
machine loses the ability to decrypt them.

## Scenario A — New machine, old machine still available

Copy two files from the old machine:

```sh
scp old-machine:~/.config/sops/age/keys.txt ~/.config/sops/age/keys.txt
scp old-machine:~/.ssh/id_ed25519{,.pub} ~/.ssh/
```

Then on the new machine everything works as-is:

```sh
ssh -T git@github.com                                   # authenticated
sops --decrypt secrets/coding-agents.yaml                # opens with keys.txt
age -d -i ~/.config/sops/age/keys.txt \
  secrets/github-ssh-key.age > ~/.ssh/id_ed25519         # restore SSH key if needed
```

`~/.ssh/id_github.pub` is re-declared automatically by home-manager
(`modules/shared/files.nix`).

## Scenario B — New machine, old machine lost (disaster recovery)

Requires the recovery key stored offline.

```sh
# 1. Import the recovery identity
install -m 0600 <recovery-key-content> ~/.config/sops/age/recovery.txt

# 2. Restore the GitHub SSH key from the age backup
age -d -i ~/.config/sops/age/recovery.txt \
  ~/nix-config/secrets/github-ssh-key.age > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

# 3. Decrypt the sops secret store with the recovery key
sops --decrypt --age ~/.config/sops/age/recovery.txt \
  ~/nix-config/secrets/coding-agents.yaml
```

The GitHub account itself is never lost — SSH keys are an auth convenience, not
the account credential. Re-register access via `gh auth login` (password + 2FA)
and a fresh key if the restored one is unavailable.

## Adding a new recovery recipient

When another trusted device should also be able to recover secrets:

```sh
age-keygen -o ~/.config/sops/age/recovery-new.txt
age-keygen -y ~/.config/sops/age/recovery-new.txt   # prints the age1... recipient
```

Add the `age1...` value to the `keys:` list in `.sops.yaml`, reference it in the
relevant `creation_rules` key groups, then re-key both stores:

```sh
age -e -r <ssh-derived> -r age1xxj3ft... -r <new-recipient> \
  -o secrets/github-ssh-key.age ~/.ssh/id_ed25519
sops updatekeys secrets/coding-agents.yaml
```

The `ssh-to-age` recipient for the SSH key is obtained with:

```sh
ssh-to-age < ~/.ssh/id_ed25519.pub
```
