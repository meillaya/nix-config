# Lifecycle GREEN — numeric ownership under empty target NSS

## Command
`bash tests/bootstrap-password-lifecycle.sh`

## Exit
`0`

## Relevant output
```text
valid expected=pass rc=0 verdict=PASS output=''
valid-empty-target-nss expected=pass rc=0 verdict=PASS output=''
sentinel-existing-unlocked expected=pass rc=0 verdict=PASS output=''
sentinel-fresh expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ consumed\ sentinel\ requires\ an\ existing\ unlocked\ password
sentinel-locked expected=fail rc=1 verdict=PASS output=bootstrap\ password\ hash\ validation\ failed:\ consumed\ sentinel\ requires\ an\ existing\ unlocked\ password
```

## Verdict
PASS: numeric validator accepts correct 0:0 metadata with empty target passwd/group while the full negative lifecycle suite remains green.
