#!/usr/bin/env bash
set -euo pipefail

scanner=$(readlink -f "$1")
tmp=$(mktemp -d -t nix-secret-scan-verify.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q
git config user.email verifier@example.invalid
git config user.name verifier

run_detected_case() {
  local name=$1 path=$2 content=$3 output rc
  git rm -qrf --ignore-unmatch .
  printf '%s\n' "$content" > "$path"
  git add "$path"
  set +e
  output=$(bash "$scanner" 2>&1)
  rc=$?
  set -e
  [[ $rc -eq 1 ]]
  [[ $output == *"$path:"* ]]
  printf '%s_detection=PASS\n' "$name"
}

run_detected_case plaintext_password config.nix \
  'users.users.mei.password = "fixture-only";'
run_detected_case quoted_password config.nix \
  'users.users.mei."password" = "fixture-only";'
run_detected_case quoted_initial_password config.nix \
  'users.users.mei."initialPassword" = "fixture-only";'
run_detected_case quoted_hashed_password config.nix \
  'users.users.mei."hashedPassword" = "$6$fixture$not-a-real-verifier";'
run_detected_case quoted_initial_hashed_password config.nix \
  'users.users.mei."initialHashedPassword" = "$6$fixture$not-a-real-verifier";'
run_detected_case quoted_hashed_password_file config.nix \
  'users.users.mei."hashedPasswordFile" = "/fixture-only";'
run_detected_case multiline_quoted_password config.nix \
  'users.users.mei."password"
    = "fixture-only";'
run_detected_case line_comment_password config.nix \
  'users.users.mei."password" # legal separator
    = "fixture-only";'
run_detected_case block_comment_password config.nix \
  'users.users.mei."password" /* legal separator */ = "fixture-only";'
run_detected_case initial_sha512_hash config.nix \
  'users.users.mei.initialHashedPassword = "$6$fixture$not-a-real-verifier";'
run_detected_case bcrypt_hash fixture.txt \
  '$2b$12$fixturefixturefixturefixturefixturefixturefixturefixture'
run_detected_case phc_scrypt_hash fixture.txt \
  '$scrypt$ln=16,r=8,p=1$fixture$not-a-real-verifier'
run_detected_case generic_pkcs8 fixture.pem \
  '-----BEGIN PRIVATE KEY-----'
run_detected_case encrypted_pkcs8 fixture.pem \
  '-----BEGIN ENCRYPTED PRIVATE KEY-----'
run_detected_case pgp_private fixture.asc \
  '-----BEGIN PGP PRIVATE KEY BLOCK-----'
run_detected_case age_private fixture.txt \
  'AGE-SECRET-KEY-1FIXTUREONLY'

git rm -qrf --ignore-unmatch .
printf '%s\n' 'users.users.mei.password = "fixture-only";' > unreadable.nix
git add unreadable.nix
chmod 000 unreadable.nix
set +e
unreadable_output=$(bash "$scanner" 2>&1)
unreadable_rc=$?
set -e
chmod 600 unreadable.nix
[[ $unreadable_rc -gt 1 ]]
[[ $unreadable_output == *'cannot read tracked path: unreadable.nix'* ]]
[[ $unreadable_output != *'tracked_nix_password_assignments=0'* ]]
printf '%s\n' 'unreadable_tracked_file_fails_closed=PASS'

git rm -qrf --ignore-unmatch .
printf '%s\n' '{ clean = true; }' > clean.nix
git add clean.nix
mkdir -p mock-bin
cat > mock-bin/perl <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
chmod +x mock-bin/perl
set +e
search_error_output=$(PATH="$PWD/mock-bin:$PATH" bash "$scanner" 2>&1)
search_error_rc=$?
set -e
[[ $search_error_rc -eq 2 ]]
[[ $search_error_output == *'password-option scan failed'* ]]
[[ $search_error_output != *'tracked_nix_password_assignments=0'* ]]
printf '%s\n' 'password_search_process_error_fails_closed=PASS'
rm -rf mock-bin

git rm -qrf --ignore-unmatch .
printf '%s\n' 'url="https://example.invalid/$version/archive-$version.tar.gz"' > clean.sh
git add clean.sh
bash "$scanner" >/dev/null
printf '%s\n' 'ordinary_shell_variables_clean=PASS'
