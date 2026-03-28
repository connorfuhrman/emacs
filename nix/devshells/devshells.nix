{ pkgs, ...}:
{
  cpp = import ./cpp.nix { inherit pkgs; };
}
