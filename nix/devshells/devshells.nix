{ self, inputs, ... }:

{
  perSystem = { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      devShells = {
        default = import ./default.nix { inherit pkgs; };
        cpp = import ./cpp.nix { inherit pkgs; };
      };
    };
}
