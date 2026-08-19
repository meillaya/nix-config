{ ... }:
{
  # Evaluation inventory, not a claim that every target is enrolled for
  # production release or activation.
  flake.configurationEvaluationPaths = [
    "darwinConfigurations.aarch64-darwin"
    "homeConfigurations.standalone-linux"
    "homeConfigurations.standalone-linux-aarch64"
  ];
}
