{ ... }: {
  flake.nixosModules.cron =
    { config, pkgs, ... }:
    let
      run = pkgs.writeShellApplication {
        name = "run";
        runtimeInputs = with pkgs; [
          bash
          util-linux
          coreutils
        ];
        text = builtins.readFile ./run.sh;
      };
    in
    {
      services.cron = {
        enable = true;
        systemCronJobs = [
          "* * * * * ${config.user.name} ${run}/bin/run ${config.user.name}"
        ];
      };
    };
}
