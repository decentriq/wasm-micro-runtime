{ ssh-dir ? null
}:
let
  pkgs = import <nixpkgs> {};
  nixpkgsPin = builtins.readFile ./NIXPKGS_PIN;
in pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
  ];
  buildInputs = with pkgs; [
    go
    pkgconfig
    openssl
    cmake
    perl
    cacert
    nix
    nixops
    git
  ];

  # TODO switch off nix's auto-fortification, which breaks debug builds. See https://github.com/NixOS/nixpkgs/issues/60919
  hardeningDisable = [ "fortify" ];
  RUST_BACKTRACE = "full";
  RUST_LOG = "info";

  NIX_PATH = "nixpkgs=${nixpkgsPin}:nixos=${nixpkgsPin}";
}

