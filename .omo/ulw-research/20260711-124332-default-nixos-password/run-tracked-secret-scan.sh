#!/usr/bin/env bash
set -euo pipefail

matches=
tracked_list=$(mktemp -t nix-tracked-files.XXXXXX)
trap 'rm -f "$tracked_list"' EXIT
git ls-files -z > "$tracked_list"

while IFS= read -r -d '' path; do
  [[ -r $path ]] || {
    printf 'cannot read tracked path: %s\n' "$path" >&2
    exit 2
  }
done < "$tracked_list"

set +e
password_options=$(
  while IFS= read -r -d '' path; do
    [[ $path == *.nix ]] || continue
    perl -0777 -ne '
      while (/"?(initialPassword|password|hashedPassword|initialHashedPassword|hashedPasswordFile)"?(?:(?:\s+)|(?:\#[^\n]*(?:\n|\z))|(?:\/\*.*?\*\/))*=/sg) {
        print "$ARGV:$1\n";
      }
    ' "$path" || exit
  done < "$tracked_list"
)
rc=$?
set -e
if (( rc != 0 )); then
  printf '%s\n' 'password-option scan failed' >&2
  exit 2
fi
matches+="$password_options"

set +e
password_hashes=$(git grep -nE \
  '\$(1|2[abxy]?|5|6|7|y|gy|sm3|sm3_yescrypt|gost_yescrypt|scrypt|yescrypt|sha(256|512)crypt|bcrypt|pbkdf2(-sha(256|512))?|argon2(id|i|d))\$[./A-Za-z0-9]')
rc=$?
set -e
if (( rc > 1 )); then
  printf '%s\n' 'password-hash scan failed' >&2
  exit 2
fi
matches+="$password_hashes"

set +e
private_keys=$(git grep -nE \
  'BEGIN ([A-Z0-9]+[[:space:]]+)*PRIVATE KEY|BEGIN PGP PRIVATE KEY BLOCK|AGE-SECRET-KEY-1')
rc=$?
set -e
if (( rc > 1 )); then
  printf '%s\n' 'private-key scan failed' >&2
  exit 2
fi
matches+="$private_keys"

if [[ -n $matches ]]; then
  printf '%s\n' "$matches"
  exit 1
fi

printf '%s\n' 'tracked_nix_password_assignments=0' \
  'tracked_modular_password_hashes=0' \
  'tracked_private_key_markers=0'
