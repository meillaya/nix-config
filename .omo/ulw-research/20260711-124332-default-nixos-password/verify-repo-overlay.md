# Verification — recommended option and repo overlay

## Candidate evaluation
warning: Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist, ignoring
{
  "authorizedKeys": [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
  ],
  "consumeDeps": [
    "users"
  ],
  "hashFile": "/var/lib/nixos-bootstrap/mei-password.hash",
  "mutableUsers": true,
  "passwordSources": {
    "hashedPassword": null,
    "hashedPasswordFile": "/var/lib/nixos-bootstrap/mei-password.hash",
    "initialHashedPassword": null,
    "initialPassword": null,
    "password": null
  },
  "sysusers": false,
  "userDeps": [
    "bootstrapPasswordHash"
  ],
  "userGroups": [
    "wheel",
    "docker",
    "i2c",
    "video"
  ],
  "userborn": false
}

## Candidate system derivation
warning: Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist, ignoring
evaluation warning: The default value of `gtk.gtk4.theme` has changed from `config.gtk.theme` to `null`.
                    You are currently using the legacy default (`config.gtk.theme`) because `home.stateVersion` is less than "26.05".
                    To silence this warning and keep legacy behavior, set:
                      gtk.gtk4.theme = config.gtk.theme;
                    To adopt the new default behavior, set:
                      gtk.gtk4.theme = null;
warning: Using 'builtins.derivation' to create a derivation named 'options.json' that references the store path '/nix/store/w8w3fia26p35xays42lixahnzigsl8dv-source' without a proper context. The resulting derivation will not have a correct store reference, so this is unreliable and may stop working in the future.
evaluation warning: The xorg package set has been deprecated, 'xorg.xwininfo' has been renamed to 'xwininfo'
evaluation warning: The xorg package set has been deprecated, 'xorg.xrandr' has been renamed to 'xrandr'
evaluation warning: mei profile: `programs.ssh.matchBlocks` defined in `/nix/store/1jzdw4mamzxn3kpfqmlfff6xz7wrmqfn-source/flake.nix' is deprecated. Use `programs.ssh.settings`.
evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
/nix/store/4gikkrzx2g241985yv8g849ss2cmgays-nixos-system-nixos-26.11.20260629.b5aa0fb.drv
## Activation ordering markers
warning: Nix search path entry '/home/mei/.nix-defexpr/channels' does not exist, ignoring
evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
evaluation warning: The default value of `gtk.gtk4.theme` has changed from `config.gtk.theme` to `null`.
                    You are currently using the legacy default (`config.gtk.theme`) because `home.stateVersion` is less than "26.05".
                    To silence this warning and keep legacy behavior, set:
                      gtk.gtk4.theme = config.gtk.theme;
                    To adopt the new default behavior, set:
                      gtk.gtk4.theme = null;
warning: Using 'builtins.derivation' to create a derivation named 'options.json' that references the store path '/nix/store/w8w3fia26p35xays42lixahnzigsl8dv-source' without a proper context. The resulting derivation will not have a correct store reference, so this is unreliable and may stop working in the future.
evaluation warning: The xorg package set has been deprecated, 'xorg.xwininfo' has been renamed to 'xwininfo'
evaluation warning: The xorg package set has been deprecated, 'xorg.xrandr' has been renamed to 'xrandr'
29:#### Activation script snippet bootstrapPasswordHash:
49:#### Activation script snippet users:
61:#### Activation script snippet consumeBootstrapPassword:
