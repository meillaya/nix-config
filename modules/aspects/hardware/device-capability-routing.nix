{ den, ... }:
{
  den.aspects.aarch64-darwin-device-capability-routing =
    { host, ... }:
    let
      machine = host.machine;
    in
    {
      darwin.assertions = [
        {
          assertion = machine.capabilities.state == "disabled";
          message = "Darwin device enrollment remains disabled";
        }
        {
          assertion = machine.gpu == "apple-metal";
          message = "Darwin GPU policy must remain Apple Metal";
        }
      ];
    };
}
