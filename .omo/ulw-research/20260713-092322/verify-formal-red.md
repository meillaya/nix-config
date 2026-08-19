# Formal RED — empty target NSS lifecycle regression

## Command
`bash tests/bootstrap-password-lifecycle.sh`

## Exit
`1`

## Relevant output
```text
valid-empty-target-nss expected=pass rc=1 verdict=FAIL output=bootstrap\ password\ hash\ validation\ failed:\ expected\ root:root\ mode\ 0700\ on\ /var/lib/nixos-bootstrap
```

## Verdict
The new case expects a numerically correct fixture to pass with empty target passwd/group. Current production code fails at the name-based directory ownership predicate, so the regression is RED for the intended reason.
