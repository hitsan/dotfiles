{
  description = "My dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gogcli = {
      url = "github:steipete/gogcli";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    user = "hitsan";
    email = "15902694+hitsan@users.noreply.github.com";
    home = "/home/${user}";
    root = builtins.toString ./.;
    modules = "${root}/modules";
    shell = "zsh";
  in
  {
    homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit user email home shell modules inputs; };

      modules = [
        ./home/default.nix
        ./modules
      ];
    };
  };
}
