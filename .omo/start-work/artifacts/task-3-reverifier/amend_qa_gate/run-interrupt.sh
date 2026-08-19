#!/usr/bin/env bash
set -u
clone=$1; label=$2; count=$3; art=/home/mei/nix-config/.omo/start-work/artifacts/task-3-reverifier/amend_qa_gate
cd "$clone" || exit 99
rm -rf .omo/evidence/nix-config-machine-readiness
T=$(mktemp -d "/tmp/task3-amend-qa-${label}.XXXXXX"); printf '%s\n' "$T" > "$art/${label}-tmp-path.txt"
TREE=$(git rev-parse HEAD^{tree}); M=$(sha256sum tests/readiness/cases/task-3.json|cut -d' ' -f1); A=$(sha256sum tests/readiness/adapters/task-3.sh|cut -d' ' -f1)
setsid env TMPDIR="$T" bash tests/readiness/run-task.sh 3 fixture >"$art/${label}.stdout" 2>"$art/${label}.stderr" & pid=$!
ready=no
for _ in $(seq 1 200); do compgen -G "$T/nix-config-task-3.*" >/dev/null && { ready=yes; break; }; kill -0 "$pid" 2>/dev/null || break; sleep .05; done
kill -TERM -- "-$pid" 2>/dev/null; k1=$?
k2=na
if [[ $count == 2 ]]; then sleep .02; kill -TERM -- "-$pid" 2>/dev/null; k2=$?; fi
for _ in $(seq 1 100); do kill -0 "$pid" 2>/dev/null || break; sleep .05; done
forced=no
if kill -0 "$pid" 2>/dev/null; then forced=yes; kill -KILL -- "-$pid" 2>/dev/null; fi
wait "$pid"; rc=$?
sleep .2
residue=$(find "$T" -mindepth 1 -print | wc -l)
procs=$(ps -eo pgid= | awk -v p="$pid" '$1==p{n++} END{print n+0}')
evidence=no; [[ -e .omo/evidence/nix-config-machine-readiness/task-3/fixture.json ]] && evidence=yes
preserved=no; [[ $TREE == $(git rev-parse HEAD^{tree}) && $M == $(sha256sum tests/readiness/cases/task-3.json|cut -d' ' -f1) && $A == $(sha256sum tests/readiness/adapters/task-3.sh|cut -d' ' -f1) && -z $(git status --porcelain) ]] && preserved=yes
pass=$(cat "$art/${label}.stdout" "$art/${label}.stderr"|grep -c 'TASK 3.*PASS' || true)
printf '%s_ready=%s first_kill=%s second_kill=%s exit=%s forced_kill=%s pass_markers=%s evidence_exists=%s temp_residue=%s process_group_residue=%s inputs_preserved=%s\n' "$label" "$ready" "$k1" "$k2" "$rc" "$forced" "$pass" "$evidence" "$residue" "$procs" "$preserved" | tee -a "$art/exits.txt"
exit 0
