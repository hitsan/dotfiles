{ ... }:
{
  programs.ssh = {
    enable = true;
    startAgent = true;
    addKeysToAgent = "yes";
  };
}
