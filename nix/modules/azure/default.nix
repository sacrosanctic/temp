{ self, ... }: {
  flake.nixosModules.azure =
    { lib, modulesPath, ... }:
    {
      imports = [
        self.nixosModules.azure-disk-config

        # waagent + cloud-init (+ networkd backend), ttyS0 console, rootdelay/panic,
        # hv_* initrd modules, openssh hardening, by-LUN udev symlinks
        # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/virtualisation/azure-common.nix
        (modulesPath + "/virtualisation/azure-common.nix")
      ];

      # hardware
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      virtualisation.hypervGuest.enable = true;
      boot.initrd.availableKernelModules = [ "sd_mod" ];

      # EFI-capable grub installed at the removable path — Azure hosts boot differently
      boot.loader.grub = {
        # no need to set devices, disko will add all devices that have a EF02 partition to the list already
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      # keep the hostname from the NixOS config, not from the Azure metadata
      services.cloud-init.settings.preserve_hostname = true;
    };
}
