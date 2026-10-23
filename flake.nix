{
  description = "Declarative configuration for the HomeLab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, sops-nix, ... }:
    {
      nixosConfigurations.hl-gw-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/hl-gw-01
          sops-nix.nixosModules.sops
        ];
      };
    };
}
