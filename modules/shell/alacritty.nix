{ ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "JetBrainsMono Nerd Font";
      };
      key_bindings = [
        { key = "Backslash"; mods = "Control"; action = "None"; }
      ];
    };
  };
}
