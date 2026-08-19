# Intent vs Reality

| intent_id | expected truth | observed reality | diff | violated invariant | intent source | supporting observations | status | claim ids |
|---|---|---|---|---|---|---|---|---|
| I1 | Fresh installs permit `mei` local authentication | Current production repo still has no password; isolated candidate proves safe mechanism | Implementation not requested/applied | Fresh-install accessibility | User request/current lockout | O1,V1,V2 | violated in production; proposed design true | C1,C7 |
| I2 | No plaintext/reusable verifier is committed | Current/history audit clean; candidate references only external path | None | Credential confidentiality | User asks safe update | O5,O6,O9,V1 | true | C2 |
| I3 | Rebuild/reinstall lifecycle is predictable | Current backend mutable/classic; candidate sentinel semantics verified | Must remain mutable/classic | Credential lifecycle | User asks new-machine defaults | O2,O3,O11,V1,V2 | true for proposed design | C3,C5 |
| I4 | Existing SSH/groups/Disko/HM remain intact | Overlay preserves groups/key/evaluation; wrong key and no FDE pre-exist | Password design does not fix those separate risks | Adjacent behavior | Existing repo | O1,O7,V1 | true with caveats | C4,C7 |
| I5 | Missing/malformed secret fails safely | Stock updater warns; custom validator rejects all tested bad cases | Validation required | Fail-closed auth | Security requirement | O11,O12,V2 | true for proposed design | C5 |
