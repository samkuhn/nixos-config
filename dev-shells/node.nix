{ pkgs, ... }:
with pkgs; {
  node-21 =
    mkShell {
      nativeBuildInputs = [
        nodejs_21
      ];
    };
}
