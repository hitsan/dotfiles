{ shell, home, user, ... }:
{
  programs.${shell} = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # Basic aliases
      cat = "bat";
      cd = "z";
      l = "eza";
      ll = "eza -l";
      lt = "eza -T";
      home = "home-manager switch --flake ~/dotfiles#${user}";
      hflake = "home-manager switch --flake ~/dotfiles#${user}";
      
      # System aliases
      down = "sudo shutdown -h 0";
      stop = "sudo systemctl suspend";
    };
    
    initContent = ''
      PS1='%F{green}$%f '
      setopt no_beep
    '';

    dotDir = "${home}/.config/zsh";
  };
  
  home.sessionPath = [
    "${home}/.nix-profile/bin"
  ];
}