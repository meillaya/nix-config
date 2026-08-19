# Verification — independent numeric owner/group rejection

Each fixture has correct modes and valid content; only the selected UID or GID becomes inner ID 1.

```text
valid expected=0 rc=0 output=''
dir-uid expected=nonzero rc=1 output=bootstrap\ password\ hash\ validation\ failed:\ expected\ numeric\ owner\ 0:0\ mode\ 0700\ on\ /var/lib/nixos-bootstrap\;\ got\ 1:0:700
dir-gid expected=nonzero rc=1 output=bootstrap\ password\ hash\ validation\ failed:\ expected\ numeric\ owner\ 0:0\ mode\ 0700\ on\ /var/lib/nixos-bootstrap\;\ got\ 0:1:700
file-uid expected=nonzero rc=1 output=bootstrap\ password\ hash\ validation\ failed:\ expected\ numeric\ owner\ 0:0\ mode\ 0600\ on\ /var/lib/nixos-bootstrap/mei-password.hash\;\ got\ 1:0:600
file-gid expected=nonzero rc=1 output=bootstrap\ password\ hash\ validation\ failed:\ expected\ numeric\ owner\ 0:0\ mode\ 0600\ on\ /var/lib/nixos-bootstrap/mei-password.hash\;\ got\ 0:1:600
```

Verdict: PASS. Numeric UID and GID are each enforced independently under empty target NSS.
