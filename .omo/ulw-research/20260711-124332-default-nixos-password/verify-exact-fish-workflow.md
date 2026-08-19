# Verification — Exact Documented Fish Workflow

## Artifact identity

```text
4b3c745b7e114f500d1161ce92cec515e6439c717e348725b2a6c7da64853ba8  .omo/ulw-research/20260711-124332-default-nixos-password/SYNTHESIS.md
a856308af7491054ef6cfa5b34ad79d2412d8b85570ecd6510ee6c639f8ad989  .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
733641ec36135a3bee4696899192b17cd18ed4cea2013f4a58b238fa0c547e38  .omo/ulw-research/20260711-124332-default-nixos-password/run-fish-workflow-verification.sh
```

## Extracted documented workflow

```fish
function install_with_bootstrap_password
    set runtime "$XDG_RUNTIME_DIR"
    test -n "$runtime"; or return 1
    findmnt -no FSTYPE --target "$runtime" | string match -qr '^tmpfs$'; or return 1

    set stage (mktemp -d "$runtime/nixos-extra.XXXXXXXX"); or return 1
    function __cleanup_nixos_password_stage --inherit-variable stage
        command rm -rf -- "$stage"
        functions --erase __cleanup_nixos_password_exit \
          __cleanup_nixos_password_hup __cleanup_nixos_password_int \
          __cleanup_nixos_password_term __cleanup_nixos_password_stage \
          install_with_bootstrap_password
    end
    function __cleanup_nixos_password_exit --on-event fish_exit --inherit-variable stage
        command rm -rf -- "$stage"
    end
    function __cleanup_nixos_password_hup --on-signal HUP
        __cleanup_nixos_password_stage
        exit 129
    end
    function __cleanup_nixos_password_int --on-signal INT
        __cleanup_nixos_password_stage
        exit 130
    end
    function __cleanup_nixos_password_term --on-signal TERM
        __cleanup_nixos_password_stage
        exit 143
    end

    command install -d -m 700 "$stage/var/lib/nixos-bootstrap"; or begin
        __cleanup_nixos_password_stage
        return 1
    end

    # Prompts privately on the controlling terminal; stdout goes directly to the file.
    nix shell nixpkgs#mkpasswd --command mkpasswd --method=yescrypt \
      > "$stage/var/lib/nixos-bootstrap/mei-password.hash"; or begin
        __cleanup_nixos_password_stage
        return 1
    end
    command chmod 600 "$stage/var/lib/nixos-bootstrap/mei-password.hash"; or begin
        __cleanup_nixos_password_stage
        return 1
    end

    test (command tail -c 1 "$stage/var/lib/nixos-bootstrap/mei-password.hash" \
      | command od -An -tuC | string trim) = 10; and \
    test (command wc -l < "$stage/var/lib/nixos-bootstrap/mei-password.hash" \
      | string trim) -eq 1; and \
    command grep -Eqx '^\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{0,86}\$[./A-Za-z0-9]{43}$' \
      "$stage/var/lib/nixos-bootstrap/mei-password.hash"; or begin
        __cleanup_nixos_password_stage
        return 1
    end

    nix run github:nix-community/nixos-anywhere -- \
      --flake ".#x86_64-linux" \
      --target-host "root@$TARGET" \
      --build-on local \
      --extra-files "$stage" \
      --option max-jobs 1 \
      --option cores 1

    set rc $status
    __cleanup_nixos_password_stage
    return $rc
end

install_with_bootstrap_password
```

## Harness and transcript

The Fish block is extracted verbatim from `SYNTHESIS.md`. Only its external boundaries are substituted: `findmnt` reports the required tmpfs and `nix` simulates generator/installer outcomes. Signal tests use a dedicated session so the signal reaches Fish and its foreground child, matching terminal/session teardown.

```bash
#!/usr/bin/env bash
set -euo pipefail
D=$1
TMP=$(mktemp -d -t nix-fish-workflow-verify.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/runtime"
cat > "$TMP/bin/findmnt" <<'MOCK'
#!/usr/bin/env sh
printf 'tmpfs\n'
MOCK
cat > "$TMP/bin/nix" <<'MOCK'
#!/usr/bin/env sh
case "$1" in
  shell)
    [ "${MOCK_SHELL_FAIL:-0}" = 1 ] && exit 7
    if [ "${MOCK_SHELL_MULTILINE:-0}" = 1 ]; then
      printf '%s\n%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012' extra
      exit 0
    fi
    if [ "${MOCK_SHELL_NO_FINAL_NEWLINE:-0}" = 1 ]; then
      printf '%s' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
      exit 0
    fi
    if [ "${MOCK_SHELL_UNTERMINATED_TRAILING:-0}" = 1 ]; then
      printf '%s\n%s' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012' extra
      exit 0
    fi
    printf '%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
    ;;
  run)
    [ "${MOCK_RUN_SLEEP:-0}" = 1 ] && sleep 300
    exit "${MOCK_RUN_RC:-0}"
    ;;
  *) exit 9 ;;
esac
MOCK
chmod +x "$TMP/bin/findmnt" "$TMP/bin/nix"
run_env=(env PATH="$TMP/bin:$PATH" XDG_RUNTIME_DIR="$TMP/runtime" TARGET=mock-target)
"${run_env[@]}" fish "$D/verify-fish-workflow.fish"
if find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .; then exit 1; fi
printf 'success_path_cleanup=PASS\n'
set +e
MOCK_SHELL_FAIL=1 "${run_env[@]}" fish "$D/verify-fish-workflow.fish"
rc=$?
set -e
[ "$rc" -ne 0 ]
if find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .; then exit 1; fi
printf 'generator_failure_cleanup=PASS rc=%s\n' "$rc"
set +e
MOCK_SHELL_MULTILINE=1 "${run_env[@]}" fish "$D/verify-fish-workflow.fish"
rc=$?
set -e
[ "$rc" -ne 0 ]
if find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .; then exit 1; fi
printf 'multiline_hash_rejected_cleanup=PASS rc=%s\n' "$rc"
set +e
MOCK_SHELL_NO_FINAL_NEWLINE=1 "${run_env[@]}" fish "$D/verify-fish-workflow.fish"
rc=$?
set -e
[ "$rc" -ne 0 ]
if find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .; then exit 1; fi
printf 'no_final_newline_rejected_cleanup=PASS rc=%s\n' "$rc"
set +e
MOCK_SHELL_UNTERMINATED_TRAILING=1 "${run_env[@]}" fish "$D/verify-fish-workflow.fish"
rc=$?
set -e
[ "$rc" -ne 0 ]
if find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .; then exit 1; fi
printf 'unterminated_trailing_content_rejected_cleanup=PASS rc=%s\n' "$rc"
set +e
MOCK_RUN_RC=42 "${run_env[@]}" fish "$D/verify-fish-workflow.fish"
rc=$?
set -e
[ "$rc" -eq 42 ]
if find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .; then exit 1; fi
printf 'installer_failure_cleanup=PASS installer_rc=42 workflow_rc=%s\n' "$rc"
run_signal_case() {
  local signal=$1 expected_rc=$2 pid rc
  MOCK_RUN_SLEEP=1 setsid "${run_env[@]}" fish "$D/verify-fish-workflow.fish" &
  pid=$!
  for _ in $(seq 1 100); do
    find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q . && break
    sleep 0.05
  done
  find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .
  kill -"$signal" -- "-$pid"
  set +e
  wait "$pid"
  rc=$?
  set -e
  [ "$rc" -eq "$expected_rc" ]
  if find "$TMP/runtime" -mindepth 1 -maxdepth 1 -type d | grep -q .; then exit 1; fi
  printf '%s_cleanup=PASS rc=%s\n' "${signal,,}" "$rc"
}
run_signal_case HUP 129
run_signal_case INT 130
run_signal_case TERM 143
```

```text
+ set -euo pipefail
+ D=.omo/ulw-research/20260711-124332-default-nixos-password
++ mktemp -d -t nix-fish-workflow-verify.XXXXXX
+ TMP=/tmp/nix-fish-workflow-verify.THISCK
+ trap 'rm -rf "$TMP"' EXIT
+ mkdir -p /tmp/nix-fish-workflow-verify.THISCK/bin /tmp/nix-fish-workflow-verify.THISCK/runtime
+ cat
+ cat
+ chmod +x /tmp/nix-fish-workflow-verify.THISCK/bin/findmnt /tmp/nix-fish-workflow-verify.THISCK/bin/nix
+ run_env=(env PATH="$TMP/bin:$PATH" XDG_RUNTIME_DIR="$TMP/runtime" TARGET=mock-target)
+ env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf 'success_path_cleanup=PASS\n'
success_path_cleanup=PASS
+ set +e
+ MOCK_SHELL_FAIL=1
+ env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
+ rc=1
+ set -e
+ '[' 1 -ne 0 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf 'generator_failure_cleanup=PASS rc=%s\n' 1
generator_failure_cleanup=PASS rc=1
+ set +e
+ MOCK_SHELL_MULTILINE=1
+ env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
+ rc=1
+ set -e
+ '[' 1 -ne 0 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf 'multiline_hash_rejected_cleanup=PASS rc=%s\n' 1
multiline_hash_rejected_cleanup=PASS rc=1
+ set +e
+ MOCK_SHELL_NO_FINAL_NEWLINE=1
+ env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
+ rc=1
+ set -e
+ '[' 1 -ne 0 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf 'no_final_newline_rejected_cleanup=PASS rc=%s\n' 1
no_final_newline_rejected_cleanup=PASS rc=1
+ set +e
+ MOCK_SHELL_UNTERMINATED_TRAILING=1
+ env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
+ rc=1
+ set -e
+ '[' 1 -ne 0 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf 'unterminated_trailing_content_rejected_cleanup=PASS rc=%s\n' 1
unterminated_trailing_content_rejected_cleanup=PASS rc=1
+ set +e
+ MOCK_RUN_RC=42
+ env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
+ rc=42
+ set -e
+ '[' 42 -eq 42 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf 'installer_failure_cleanup=PASS installer_rc=42 workflow_rc=%s\n' 42
installer_failure_cleanup=PASS installer_rc=42 workflow_rc=42
+ run_signal_case HUP 129
+ local signal=HUP expected_rc=129 pid rc
+ pid=798921
+ MOCK_RUN_SLEEP=1
+ setsid env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
++ seq 1 100
+ for _ in $(seq 1 100)
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ sleep 0.05
+ for _ in $(seq 1 100)
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ break
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ kill -HUP -- -798921
+ set +e
+ wait 798921
+ rc=129
+ set -e
+ '[' 129 -eq 129 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf '%s_cleanup=PASS rc=%s\n' hup 129
hup_cleanup=PASS rc=129
+ run_signal_case INT 130
+ local signal=INT expected_rc=130 pid rc
+ pid=798959
+ MOCK_RUN_SLEEP=1
+ setsid env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
++ seq 1 100
+ for _ in $(seq 1 100)
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ sleep 0.05
+ for _ in $(seq 1 100)
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ break
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ kill -INT -- -798959
+ set +e
+ wait 798959
+ rc=130
+ set -e
+ '[' 130 -eq 130 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf '%s_cleanup=PASS rc=%s\n' int 130
int_cleanup=PASS rc=130
+ run_signal_case TERM 143
+ local signal=TERM expected_rc=143 pid rc
+ pid=798995
+ MOCK_RUN_SLEEP=1
+ setsid env PATH=/tmp/nix-fish-workflow-verify.THISCK/bin:/home/mei/.local/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/mei/.codex/tmp/arg0/codex-arg0D719H2:/home/mei/.cargo/bin:/home/mei/.cache/.bun/bin:/home/mei/Android/Sdk/platform-tools:/home/mei/.ghcup/bin:/home/mei/.local/bin:/home/mei/.dx:/home/mei/go/bin:/home/mei/.bun/bin:/home/mei/.spicetify:/home/mei/.omx-runs/run-20260711153534-ce5a/.omx/runtime/bin:/home/mei/.opam/default/bin:/home/mei/.nix-profile/bin:/home/mei/.cabal/bin:/home/mei/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/lib/rustup/bin XDG_RUNTIME_DIR=/tmp/nix-fish-workflow-verify.THISCK/runtime TARGET=mock-target fish .omo/ulw-research/20260711-124332-default-nixos-password/verify-fish-workflow.fish
++ seq 1 100
+ for _ in $(seq 1 100)
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ sleep 0.05
+ for _ in $(seq 1 100)
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ break
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ kill -TERM -- -798995
+ set +e
+ wait 798995
+ rc=143
+ set -e
+ '[' 143 -eq 143 ']'
+ find /tmp/nix-fish-workflow-verify.THISCK/runtime -mindepth 1 -maxdepth 1 -type d
+ grep -q .
+ printf '%s_cleanup=PASS rc=%s\n' term 143
term_cleanup=PASS rc=143
+ rm -rf /tmp/nix-fish-workflow-verify.THISCK
```

## Verdict

- Syntax: PASS (`fish --no-execute`).
- Success and generator failure: cleanup PASS.
- Multiline, no-final-newline, and valid-first-line-plus-unterminated-trailing output: rejected before install; cleanup PASS.
- Installer failure: exact status 42 preserved; cleanup PASS.
- HUP/INT/TERM: exact statuses 129/130/143; cleanup PASS.
- Temporary fixture directory: removed by trap.
- Scope: unit-style execution of the exact documented control flow; not a substitute for the explicitly unperformed destructive VM/laptop install.
