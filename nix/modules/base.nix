{ ... }: {
  flake.nixosModules.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options = {
        user.name = lib.mkOption {
          type = lib.types.str;
          description = "Login user owning the deployed app and cron runner";
        };

        user.sshPublicKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Admin SSH public keys for root and the app user";
        };
      };

      config = {
        networking.hostName = "nixos";
        time.timeZone = "Asia/Taipei";
        system.stateVersion = "25.05";

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        security.sudo.wheelNeedsPassword = false;
        services.openssh.enable = true;
        networking.firewall.enable = true;

        # for low ram
        zramSwap.enable = true;

        users.users.root.openssh.authorizedKeys.keys = config.user.sshPublicKeys;

        users.users.${config.user.name} = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "docker"
          ];
          openssh.authorizedKeys.keys = config.user.sshPublicKeys;
        };

        virtualisation.docker.enable = true;

        environment.systemPackages = with pkgs; [
          neovim
          tmux
          docker
          docker-compose
          git
        ];
      };
    };
}
