{ stdenv
, src
, lib
  # deps
, installShellFiles
, boehmgc
, libevent
, libiconv
, libxml2
, libyaml
, llvmPackages
, makeWrapper
, openssl
, pcre2
, pkg-config
, which
, zlib
}:
stdenv.mkDerivation rec {
  name = "crystal";
  inherit src;
  inherit (stdenv) isDarwin;

  nativeBuildInputs = [ makeWrapper installShellFiles ];

  strictDeps = true;
  outputs = [ "out" "lib" "bin" ];

  buildInputs = [
    boehmgc
    libevent
    libxml2
    libyaml
    openssl
    pcre2
    zlib
  ] ++ lib.optionals isDarwin [ libiconv ];

  dontConfigure = true;
  dontBuild = true;

  tarball_bin = if isDarwin then "./embedded/bin" else "./bin";
  tarball_src = if isDarwin then "src" else "share/crystal/src";
  completion = if isDarwin then ''
    installShellCompletion --cmd crystal etc/completion.*
  '' else ''
    installShellCompletion --bash share/bash-completion/completions/crystal
    installShellCompletion --zsh share/zsh/site-functions/_crystal
    installShellCompletion --fish share/fish/vendor_completions.d/crystal.fish
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ${tarball_bin}/shards $bin/bin/shards
    install -Dm755 ${tarball_bin}/crystal $bin/bin/crystal
    wrapProgram $bin/bin/crystal \
       --suffix PATH : ${lib.makeBinPath [ pkg-config llvmPackages.clang which ]} \
       --suffix CRYSTAL_PATH : lib:$lib/crystal \
       --suffix CRYSTAL_LIBRARY_PATH : ${ lib.makeLibraryPath (buildInputs) } \
       --suffix PKG_CONFIG_PATH : ${openssl.dev}/lib/pkgconfig \
       --suffix CRYSTAL_OPTS : "-Duse_pcre2"

    install -dm755 $lib/crystal
    cp -r ${tarball_src}/* $lib/crystal/

    ${completion}

    mkdir -p $out
    ln -s $bin/bin $out/bin
    ln -s $lib $out/lib

    runHook postInstall
  '';

  dontStrip = true;
}



