{ self, inputs, ... }:
{
  perSystem = { system, ... }: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };
  in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          emacsclient-commands
          go-task
        ];
      };
  };
}
