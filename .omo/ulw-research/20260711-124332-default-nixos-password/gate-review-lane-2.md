# Gate review lane 2

Verdict: REJECTION.

Required fixes:
1. Reject valid first line plus unterminated second line.
2. Capture exact harnesses, fixtures, commands, and candidate digests.
3. Add Fish signal cleanup and execution evidence.
4. Remove “first login works” overstatement.
5. Add reviewed `/run` source-chain evidence.

All five were addressed before resubmission.

Subsequent rounds rejected and drove fixes for:
- copied/mirrored validator evidence and stale digests;
- a fresh-machine sentinel bypass and policy-forcing drift;
- incomplete Fish boundary, installer-status, and signal cases;
- mutation-insensitive consumer checks;
- stale recommendation markers and unsupported evidence links;
- tracked-secret scanner coverage for quoted, multiline, and comment-separated Nix
  attributes, non-yescrypt modular/PHC hashes, generic/encrypted private keys, and
  unreadable/search-process error paths.

Each rejection was fixed, executed, recorded, independently code-reviewed, and
resubmitted to the same gate reviewer.

Final verdict: **UNCONDITIONAL APPROVAL**.
