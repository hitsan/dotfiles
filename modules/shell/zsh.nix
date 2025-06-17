{ shell, ... }:
{
  programs.${shell} = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      down = "sudo shutdown -h 0";
      stop = "sudo systemctl suspend";
    };
    initExtra = ''
      PS1='%F{green}$%f '
      setopt no_beep
    '';

    dotDir = ".config/zsh";
  };
}
