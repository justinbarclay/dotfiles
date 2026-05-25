{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  installShellFiles,
}:

let
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation {
  pname = "antigravity-cli";
  inherit (sources) version;

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchurl {
    inherit
      (sources.sources.${stdenv.hostPlatform.system}
        or (throw "Unsupported system: ${stdenv.hostPlatform.system}"))
      url
      sha512
      ;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ]
    ++ [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp antigravity $out/bin/agy
    ln -s $out/bin/agy $out/bin/antigravity-cli
    runHook postInstall
  '';

  postInstall = ''
    if $out/bin/agy completion bash >/dev/null 2>&1; then
      installShellCompletion --bash <($out/bin/agy completion bash)
    fi
    if $out/bin/agy completion zsh >/dev/null 2>&1; then
      installShellCompletion --zsh <($out/bin/agy completion zsh)
    fi
    if $out/bin/agy completion fish >/dev/null 2>&1; then
      installShellCompletion --fish <($out/bin/agy completion fish)
    fi
  '';

  meta = with lib; {
    description = "Antigravity CLI - A powerful tool for agentic workflows";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources.sources;
    mainProgram = "agy";
    maintainers = with maintainers; [
      taranarmo
      caverav
    ];
  };
}
