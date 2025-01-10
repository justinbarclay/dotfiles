{ lib
, stdenvNoCC
, paratype-pt-mono
, nerd-font-patcher
, python3Packages
}:
stdenvNoCC.mkDerivation rec {
  pname = "paratype-pt-mono-nerd";
  version = "2.005-${nerd-font-patcher.version}";

  src = paratype-pt-mono;

  nativeBuildInputs = [
    nerd-font-patcher
  ] ++ (with python3Packages; [
    python
    fontforge
  ]);

  buildPhase = ''
    runHook preBuild
    mkdir -p build/
    for f in share/fonts/truetype/*; do
      nerd-font-patcher $f --complete --no-progressbars --outputdir ./build
      # note: this will *not* return an error exit code on failure, but instead
      # write out a corrupt file, so an additional check phase is required
    done
    runHook postBuild
  '';


  doCheck = true;
  checkPhase = ''
    runHook preCheck
    # Try to open each font. If a corrupt font was written out, this should fail
    for f in build/*; do
        fontforge - <<EOF
    try:
      fontforge.open(''\'''${f}')
    except:
      exit(1)
    EOF
    done
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    install -Dm 444 build/* $out/share/fonts/truetype
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/ryanoasis/nerd-fonts";
    description = "Ligature-less PT Mono patched with Nerd Fonts icons";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
