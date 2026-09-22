{ self, inputs, ... }: {
  flake.nixosConfigurations.azure = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      self.nixosModules.base
      self.nixosModules.cron
      self.nixosModules.azure
      ../config.nix
    ];
  };
}
