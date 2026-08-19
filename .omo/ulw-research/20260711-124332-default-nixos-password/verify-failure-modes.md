# Verification — bootstrap hash failure modes

## Validator cases
valid expected=pass rc=0 verdict=PASS output=PASS
sentinel expected=pass rc=0 verdict=PASS output=PASS
missing expected=fail rc=1 verdict=PASS output=FAIL: missing
empty expected=fail rc=1 verdict=PASS output=FAIL: line_count
multiline expected=fail rc=1 verdict=PASS output=FAIL: line_count
malformed expected=fail rc=1 verdict=PASS output=FAIL: format
wrongmode expected=fail rc=1 verdict=PASS output=FAIL: mode_or_owner

## Sentinel consumption simulation
consumed_sentinel expected=pass rc=0 verdict=PASS output=PASS
content_is_sentinel=PASS

## Local runtime path evidence
run_fstype=tmpfs
var_lib_mount=/

## mkpasswd method support

## mkpasswd method support (correct package)
yescrypt        Yescrypt

## Candidate build dry-run
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
evaluation warning: mei profile: `programs.ssh.matchBlocks` defined in `/nix/store/ap1pci4ifwlinqcfljym8s22ri6094h5-source/flake.nix' is deprecated. Use `programs.ssh.settings`.
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
  /nix/store/6fnnn44sqnmmyrd64xcqhbdlcqsflaaa-activate.drv
  /nix/store/sgh3r830kdi5gg3wkhwqx0msdnj8041d-dry-activate.drv
  /nix/store/4gikkrzx2g241985yv8g849ss2cmgays-nixos-system-nixos-26.11.20260629.b5aa0fb.drv
candidate_build_dry_run=PASS

## Tracked repository verifier scan
tracked_secret_pattern_scan=PASS
