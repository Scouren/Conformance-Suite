{
  description = "Verilog-AMS conformance suite: tests, the conform harness, and the reference simulators it compares against";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # SPRack translates the decks written in another dialect (an oracle's
    # `tokenizer`) into the one each simulator reads (tools/rawcheck.py).
    sprack.url = "github:Scouren/SPRack";
    sprack.inputs.nixpkgs.follows = "nixpkgs";
    sprack.inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      sprack,
    }:
    let
      lib = nixpkgs.lib;

      # The harness is stdlib Python; `conform` runs it from the suite it
      # ships in (tools/rawcheck.py beside it).
      conform =
        { writeShellScriptBin, python3 }:
        writeShellScriptBin "conform" ''
          PYTHONPATH=${self}''${PYTHONPATH:+:$PYTHONPATH} exec ${python3}/bin/python3 -m harness "$@"
        '';

      # The sprack CLI at the locked SPRack commit, built with the Zig its
      # own flake pins (nixpkgs' is older than its minimum).
      sprackCli =
        { stdenvNoCC, zig }:
        stdenvNoCC.mkDerivation {
          pname = "sprack";
          version = sprack.shortRev or "dirty";
          src = sprack;
          nativeBuildInputs = [ zig ];
          dontConfigure = true;
          buildPhase = ''
            export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-global ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-local
            zig build -Doptimize=ReleaseSafe --prefix $out
          '';
          dontInstall = true;
          meta.mainProgram = "sprack";
        };

      # OpenVAF-Reloaded: a Verilog-A compiler to OSDI, not in nixpkgs. The
      # release is an x86_64-linux binary.
      openvaf-r =
        {
          stdenv,
          fetchurl,
          autoPatchelfHook,
          llvmPackages_18,
        }:
        stdenv.mkDerivation rec {
          pname = "openvaf-reloaded";
          version = "24.0.2mob";
          src = fetchurl {
            url = "https://github.com/OpenVAF/OpenVAF-Reloaded/releases/download/v${version}/openvaf-r-v${version}-linux-x86_64.tar.gz";
            hash = "sha256-sSt7FybRA+GMJYjDofkfhHXPA9+KO94U2Rl5fSIeMRA=";
          };
          nativeBuildInputs = [ autoPatchelfHook ];
          buildInputs = [
            llvmPackages_18.libllvm
            stdenv.cc.cc.lib
          ];
          installPhase = ''
            install -Dm755 bin/openvaf-r $out/bin/openvaf-r
            ln -s openvaf-r $out/bin/openvaf
          '';
          meta = {
            homepage = "https://github.com/OpenVAF/OpenVAF-Reloaded";
            platforms = [ "x86_64-linux" ];
            mainProgram = "openvaf-r";
          };
        };

      # VACASK: a Verilog-A circuit simulator, not in nixpkgs, built from source
      # with its OSDI device models compiled by OpenVAF-Reloaded. The SPICE
      # decks under tests/netlist/ are benchmarked against it.
      vacask =
        {
          stdenv,
          lib,
          fetchFromGitHub,
          cmake,
          ninja,
          pkg-config,
          python3,
          bison,
          flex,
          suitesparse,
          openblas,
          boost,
          tomlplusplus,
          openvaf-r,
        }:
        stdenv.mkDerivation {
          pname = "vacask";
          version = "unstable-2026";
          src = fetchFromGitHub {
            owner = "robtaylor";
            repo = "VACASK";
            rev = "bcd48e2dd25182f5aaa3392c4e27b4e198372744";
            hash = "sha256-/x6yJ+fklipvYbtI5rHx4d5YIpC9IJ5uhHCtWC5eJJg=";
          };
          nativeBuildInputs = [
            cmake
            ninja
            pkg-config
            python3
            bison
            flex
          ];
          buildInputs = [
            suitesparse
            openblas
            boost
            tomlplusplus
          ];
          # nixpkgs' boost (>= 1.87) has no libboost_system and no stage/ dir,
          # and its suitesparse puts klu.h directly in include/.
          postPatch = ''
            sed -i 's/set(Boost_NO_SYSTEM_PATHS TRUE)//' CMakeLists.txt
            sed -i 's/find_package(Boost 1.88 REQUIRED COMPONENTS filesystem process system)/find_package(Boost REQUIRED COMPONENTS filesystem process)/' CMakeLists.txt
            sed -i 's|set(Boost_EXTRA_LINK_DIR "''${Boost_INCLUDE_DIRS}/stage/lib")|set(Boost_EXTRA_LINK_DIR "''${Boost_LIBRARY_DIRS}")|' CMakeLists.txt
            sed -i 's/boost_system boost_filesystem boost_process/boost_filesystem boost_process/' CMakeLists.txt
            sed -i 's|suitesparse/klu.h|klu.h|g' include/klumatrix.h
          '';
          # Upstream's install() stages the OSDI models in lib/vacask/mod, the
          # only place `load "spice/resistor.osdi"` resolves from.
          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DOPENVAF_DIR=${openvaf-r}/bin"
            "-DTOMLPP_DIR=${tomlplusplus}"
            "-DSuiteSparse_DIR=${suitesparse}"
          ];
          meta = {
            description = "VACASK, the Verilog-A Circuit Analysis Kernel";
            homepage = "https://github.com/robtaylor/VACASK";
            license = lib.licenses.gpl2Plus;
            platforms = [ "x86_64-linux" ];
            mainProgram = "vacask";
          };
        };

      packagesFor =
        pkgs:
        let
          openvaf-r' = pkgs.callPackage openvaf-r { };
        in
        {
          conform = pkgs.callPackage conform { };
          sprack = pkgs.callPackage sprackCli { zig = sprack.inputs.zig-overlay.packages.${pkgs.stdenv.hostPlatform.system}.master; };
          openvaf-r = openvaf-r';
          vacask = pkgs.callPackage vacask { openvaf-r = openvaf-r'; };
        };
    in
    {
      overlays.default = final: _: packagesFor final;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        built = packagesFor pkgs;
        available = lib.filter (p: lib.meta.availableOn pkgs.stdenv.hostPlatform p);
      in
      {
        packages = lib.filterAttrs (_: p: lib.meta.availableOn pkgs.stdenv.hostPlatform p) built // {
          default = built.conform;
        };

        devShells.default = pkgs.mkShell {
          packages = available [
            built.conform
            built.sprack
            built.openvaf-r
            built.vacask
            pkgs.ngspice
            pkgs.xyce
            pkgs.iverilog
            pkgs.verilator
            pkgs.python3
          ];
        };

        checks.selftest = pkgs.runCommand "conform-selftest" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          cp -r ${self}/. suite && chmod -R u+w suite && cd suite
          python3 tools/rawcheck.py --selftest
          python3 -m unittest discover -s harness -t .
          touch $out
        '';

        formatter = pkgs.nixfmt;
      }
    );
}
