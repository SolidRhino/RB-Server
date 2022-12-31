{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let
  myNix = writeShellScriptBin "nix" ''
    exec ${nixFlakes}/bin/nix --option experimental-features "nix-command flakes" "$@"
  '';

in mkShell {
  buildInputs = [
    make
    git
    myNix
  ];
}