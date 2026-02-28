{ lib, openclaw, ... }:
{
  home.packages = [ (lib.lowPrio openclaw) ];
}
