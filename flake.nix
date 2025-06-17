{
  description = "My dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap.url = "github:xremap/nix-flake";
  };

  outputs = { self, nixpkgs, home-manager, xremap }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    user = "hitsan";
    home = "/home/${user}";
    root = builtins.toString ./.;
    modules = "${root}/modules";
    shell = "zsh";
  in
  {
    homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit user home shell modules xremap; };

      modules = [ ./home.nix ];
    };
  };
}
