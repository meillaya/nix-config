# Wave 2 — implementation and adversarial convergence

- Formal lifecycle GREEN: correct 0:0/700+600 passes with explicit files-only NSS and empty passwd/group.
- Missing-directory/unlocked-account path also passes under empty NSS, proving numeric `install -o 0 -g 0` and `chown 0:0` branches.
- Multi-ID user namespace independently rejects directory/file UID or GID 1 with otherwise correct modes/content; errors report observed numeric tuples.
- Transfer lane's 16-case root-container matrix rejected all wrong UID/GID/mode variants.
- Hostile NSS mapping the name `root` to nonzero IDs makes the old predicate accept a non-root inode; numeric validation rejects it, so the fix strengthens security.
- Exact changed system built and its generated activation crossed the empty-NSS bootstrap boundary; full rootless activation cannot execute later privileged users/mount operations faithfully.
- Recovery guidance now distinguishes direct chroot observation, still-mounted install-only retry, documented `--disko-mode mount`, and destructive default helper rerun.
- Mutation harness snapshots the index; verification must stage the intended tree temporarily and restore the index.

## EXPAND
- Run the new name-lookup and numeric-creation mutants against a temporary staged index.
- Run complete helper, lifecycle, secret, eval, shell, flake and system build gates.
- Sync the numeric module into the retained temporary installer checkout before user retry.
- Remaining live-only evidence: target `/mnt` tuple and a full hardware retry; unavailable without target authority.
