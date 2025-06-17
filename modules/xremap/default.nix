{ xremap, user, ... }:
{
  imports = [
    xremap.nixoModules.default
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
}
