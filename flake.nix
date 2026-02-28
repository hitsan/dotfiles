{
  description = "My dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    user = "hitsan";
    email = "15902694+hitsan@users.noreply.github.com";
    home = "/home/${user}";
    root = builtins.toString ./.;
    modules = "${root}/modules";
    shell = "zsh";
    openclaw = nix-openclaw.packages.${system}.openclaw;
  in
  {
    homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit user email home shell modules openclaw; };

      modules = [
        ./home/default.nix
        ./modules
      ];
    };
  };
}
