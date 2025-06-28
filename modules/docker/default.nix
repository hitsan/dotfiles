{ shell, ... }:
{
  programs = {
    lazydocker.enable = true;
    ${shell}.shellAliases = {
      lazd = "lazydocker";
    };
  };
}
