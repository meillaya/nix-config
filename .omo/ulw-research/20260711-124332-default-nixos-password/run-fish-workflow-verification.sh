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
