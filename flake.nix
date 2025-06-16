{
  description = "My flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    user = "hitsan";
    home = "/home/${user}";
    root = builtins.toString ./.;
    home_path = "${root}/home-manager";
    shell = "zsh";
  in
  {
    homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit user home shell home_path; };

      modules = [ ./home-manager/home.nix ];
    };
  };
}
