{
  lib,
  ...
}:
{
  options.local.system.cpu = {
    cores = lib.mkOption {
      type = lib.types.int;
      default = 1;
      example = 4;
      description = "Number of CPU cores available in the system.";
    };
  };

  config = {
    # This module only defines options, no configuration
  };
}
