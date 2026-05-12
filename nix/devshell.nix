{ self, inputs, ... }:
{
  perSystem = { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          emacsclient-commands
          go-task
        ];
      };
  };
}
