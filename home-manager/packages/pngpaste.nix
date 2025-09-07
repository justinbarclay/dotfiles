{ lib, darwin, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  name = "pngpaste";
  version = "0.2.3";
  src = fetchFromGitHub {
    owner = "jcsalterego";
    repo = "${name}";
    rev = "67c39829fedb97397b691617f10a68af75cf0867";
    hash = "sha256-uvajxSelk1Wfd5is5kmT2fzDShlufBgC0PDCeabEOSE=";
  };
  buildInputs = [
    # darwin.apple-sdk_14
  ];
  installPhase = ''
    mkdir -p $out/bin
    mv pngpaste $out/bin/pngpaste
  '';
}
