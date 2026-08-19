#!/usr/bin/env bash
set -euo pipefail
D='.omo/ulw-research/20260711-124332-default-nixos-password'
EXPR="let f=builtins.getFlake (toString /home/mei/nix-config); in (f.nixosConfigurations.x86_64-linux.extendModules { modules=[ /home/mei/nix-config/.omo/ulw-research/20260711-124332-default-nixos-password/candidate-bootstrap-password.nix ]; }).config"
nix eval --json --impure --file ".omo/ulw-research/20260711-124332-default-nixos-password/candidate-eval.nix" | jq .
nix eval --raw --impure --expr "$EXPR.system.build.toplevel.drvPath"
nix eval --raw --impure --expr "$EXPR.system.activationScripts.script"   | grep -nE 'Activation script snippet (bootstrapPasswordHash|users|consumeBootstrapPassword):'
nix build --dry-run --impure --expr "$EXPR.system.build.toplevel"
