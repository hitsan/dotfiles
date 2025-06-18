{ xremap, user, ... }:
{
  imports = [
    xremap.nixosModule.default
  ];
  services.xremap = {
    userName = user;
    serviceMode = "user";
    config = {
      modmap = [
        {
          name = "Capslock to ctrl";
          remap = {
            CapsLock = "Ctrl_L";
          };
        }
      ];
    };
  };
}
