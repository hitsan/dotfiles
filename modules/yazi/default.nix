{ shell, ... }:
{
  programs = {
    yazi.enable = true;
    ${shell}.shellAliases = {
      yz = "yazi";
    };
  };
}
