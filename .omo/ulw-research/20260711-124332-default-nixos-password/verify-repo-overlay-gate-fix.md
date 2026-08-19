# Verification — Repository Overlay After Gate Fixes

## Artifact identity

```text
2f371c11bf897b2302e8e4a4cf27f11c0f409859aedb2d7dac6a71be36e4f2f5  .omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix
666237b548d5a5be6620d31dba21ef03a9c1a267118716ec45e2edf8c0954f1d  .omo/ulw-research/20260711-124332-default-nixos-password/candidate-eval.nix
5442d6326c69c5448a982c5032d08b8f794c254c21e9a0286d6d10b6702b20f2  .omo/ulw-research/20260711-124332-default-nixos-password/run-candidate-evaluation.sh
```

## Exact harness

```bash
#!/usr/bin/env bash
set -euo pipefail
D='.omo/ulw-research/20260711-124332-default-nixos-password'
EXPR="let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config"
nix eval --json --impure --file ".omo/ulw-research/20260711-124332-default-nixos-password/candidate-eval.nix" | jq .
nix eval --raw --impure --expr "$EXPR.system.build.toplevel.drvPath"
nix eval --raw --impure --expr "$EXPR.system.activationScripts.script"   | grep -nE 'Activation script snippet (bootstrapPasswordHash|users|consumeBootstrapPassword):'
nix build --dry-run --impure --expr "$EXPR.system.build.toplevel"
```

## Transcript

```text
+ set -euo pipefail
+ D=.omo/ulw-research/20260711-124332-default-nixos-password
+ EXPR='let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config'
+ nix eval --json --impure --file .omo/ulw-research/20260711-124332-default-nixos-password/candidate-eval.nix
+ jq .
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
+ nix eval --raw --impure --expr 'let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config.system.build.toplevel.drvPath'
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
evaluation warning: mei profile: `programs.ssh.matchBlocks` defined in `/nix/store/9bj7w3db4h6dav37l23lp931vnkpvvhn-source/flake.nix' is deprecated. Use `programs.ssh.settings`.
evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
/nix/store/7vrmva7311b4gfmaf21yx9xs40wcrdbn-nixos-system-nixos-26.11.20260629.b5aa0fb.drv+ nix eval --raw --impure --expr 'let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config.system.activationScripts.script'
+ grep -nE 'Activation script snippet (bootstrapPasswordHash|users|consumeBootstrapPassword):'
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
67:#### Activation script snippet users:
79:#### Activation script snippet consumeBootstrapPassword:
+ nix build --dry-run --impure --expr 'let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config.system.build.toplevel'
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
evaluation warning: mei profile: `programs.ssh.matchBlocks` defined in `/nix/store/97ij7qaab4q3byx839dh4vkbxxb7bbvj-source/flake.nix' is deprecated. Use `programs.ssh.settings`.
evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
these 24 derivations will be built:
  /nix/store/0jim45kqww0vb3azj2nr8yf63jk1ccjg-hm_homemei.configrofibinpowermenu.sh.drv
  /nix/store/10slsgqh9wszmiz5pi46xgp6j3h3cbj0-hm_homemei.configrofinetworkmenu.rasi.drv
  /nix/store/5xw36zhg5yi8j3k885plnw8rgvdgs3y1-hm_homemei.configroficonfirm.rasi.drv
  /nix/store/79aw1vcqbipr2p3lnv3p1zzaa1y7g94i-hm_homemei.configrofimessage.rasi.drv
  /nix/store/7s42mb9jffd6v53r4hcww88nz7q1mn8s-hm_homemei.configrofipowermenu.rasi.drv
  /nix/store/bd2k3kranpr25d10jrlw3hh7jdnw52n6-hm_homemei.configniriconfig.kdl.drv
  /nix/store/c8r2kidhfpmps9yz6rfmp1sw0lwrg0bq-hm_homemei.configroficolors.rasi.drv
  /nix/store/d7jh7q0k7d8l71ddwbk6yd60fa1ahbpi-hm_homemei.configrofibinlauncher.sh.drv
  /nix/store/hdlqw2fbwlwq1zscsn758h7igf77g4j0-hm_homemei.configsxhkdsxhkdrc.drv
  /nix/store/r93kc1i6c1j466903g32lvkg62152f3w-hm_homemei.configrofistyles.rasi.drv
  /nix/store/rk3b1nbnsgwbq4b0dv20674syxj9wz2c-hm_homemei.configpolybarbinchecknixosupdates.sh.drv
  /nix/store/rp2hsc2h84pjjqhfi0ydsajkwj4l6r9z-hm_homemei.configrofilauncher.rasi.drv
  /nix/store/v0z6rzr9mvpdxagw3dhbq2jfk9ag4mpf-hm_homemei.configpolybarbinsearchnixosupdates.sh.drv
  /nix/store/wv2h24nj4h43ribpgg9yrz3g4916q4hd-hm_homemei.configpolybarbinpopupcalendar.sh.drv
  /nix/store/xcrv8bmnbasl3fg7yhnrjd3ql9v1sibs-hm_homemei.configbspwmbspwmrc.drv
  /nix/store/x3h497bjlggpmxywz3zhqw2kyridg9x8-home-manager-files.drv
  /nix/store/fn3yi5jvq5q5b6swbhkqlvj8dbwrsbk2-home-manager-generation.drv
  /nix/store/f66xm1bm3wckqlpc4li5qiyd3dq72b7w-unit-home-manager-mei.service.drv
  /nix/store/ssqxch83433pa0h5y6l58bdfmj05s3zz-system-units.drv
  /nix/store/i6jcv38zxarlpz5q9aclfjxzi613gv9v-etc.drv
  /nix/store/p757cymfkk8n3nqf0qcy7lxfjb1c5nya-users-groups.json.drv
  /nix/store/6dh7rzp9wf9d1j3cksbr8bni69cc3hl0-activate.drv
  /nix/store/sgh3r830kdi5gg3wkhwqx0msdnj8041d-dry-activate.drv
  /nix/store/7vrmva7311b4gfmaf21yx9xs40wcrdbn-nixos-system-nixos-26.11.20260629.b5aa0fb.drv
```

## Verdict

- Candidate evaluation: PASS.
- Existing groups and configured authorized key: preserved.
- Exactly one password source: external `hashedPasswordFile`.
- Backend: mutable classic users; sysusers/userborn disabled.
- Activation order: validator line 29, users line 67, consumer line 79.
- System derivation evaluation and `nix build --dry-run`: PASS.
