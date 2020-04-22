/*
  This file provides a function that extends nixpkgs with additional decentriq-specific functionality.
*/

let
  nixpkgs = import <nixpkgs> {};
  mozillaOverlay = nixpkgs.fetchFromGitHub {
    owner = "mozilla";
    repo = "nixpkgs-mozilla";
    rev = "b52a8b7de89b1fac49302cbaffd4caed4551515f";
    sha256 = "1np4fmcrg6kwlmairyacvhprqixrk7x9h89k813safnlgbgqwrqb";
  };
  rustOverlay = import "${mozillaOverlay.out}/rust-overlay.nix" nixpkgs.pkgs nixpkgs.pkgs;
  rustNightly = rustOverlay.rustChannelOf {
      sha256 = "1w75wp7kfafvldr49d64vzrxxll2dglbsm4j28a9f9yxc12dgn14";
      date = "2020-03-18";
      channel = "nightly";
  };
  rustSgx = rustNightly.rust.override {
    targets = [ "x86_64-fortanix-unknown-sgx" ];
  };
  buildCachedRustPackage = spec:
    let
      # We create a standard buildRustPackage, which we later split into two.
      target = spec.target or nixpkgs.stdenv.hostPlatform.config;
      extraCargoFlags = spec.extraCargoFlags or "";
      cargoFlags = "--release --target=\"${target}\" --manifest-path=\"$buildDirectoryRelative\"/Cargo.toml --target-dir=./target ${extraCargoFlags}";
      original = nixpkgs.rustPlatform.buildRustPackage (spec // {
        inherit target;
        buildDirectoryRelative = spec.buildDirectoryRelative or ".";
        src = nixpkgs.lib.cleanSourceWith { filter = dependenciesFilter; name = spec.name; src = spec.src; };
        buildPhase = spec.buildPhase or ''
          set -euo pipefail
          BUILD="cargo build ${cargoFlags}"
          echo "Running in $PWD: $BUILD"
          $BUILD
        '';
        checkPhase = spec.checkPhase or ''
          set -euo pipefail
          BUILD="cargo test ${cargoFlags}"
          echo "Running in $PWD: $BUILD"
          $BUILD
        '';
      });

      shared = nixpkgs.lib.overrideDerivation original (orig: {
        cargoDeps = nixpkgs.lib.overrideDerivation orig.cargoDeps (origCargoDeps: {
           patchPhase = (origCargoDeps.patchPhase or "") + dummySources;
           installPhase = nixpkgs.lib.replaceStrings ["cargo vendor"] ["cargo vendor --manifest-path='${orig.buildDirectoryRelative}/Cargo.toml'"] origCargoDeps.installPhase;
        });
      });

      # In the patch phase of *vendor and *dependencies we create dummy main.rs-s, build.rs-s and lib.rs-s
      # In the meantime we collect the names of the artifacts into ARTIFACT_NAMES, to be deleted later from the build
      # artifacts.
      # NOTE: we rely on the directories having the same name as the projects!
      dummySources = ''
        set -euo pipefail
        ARTIFACT_NAMES=()
        for cargo in $(find $PWD -name Cargo.toml)
        do
          PROJECT_DIR=$(dirname $cargo)
          ARTIFACT_NAMES+=($(basename $PROJECT_DIR))
          mkdir -p $PROJECT_DIR/src
          echo "fn main(){}" > $PROJECT_DIR/src/main.rs
          echo "fn main(){}" > $PROJECT_DIR/build.rs
          echo "" > $PROJECT_DIR/src/lib.rs
          for rs in $(grep -oE 'src/.*\.rs' $cargo)
          do
            echo "fn main(){}" > $PROJECT_DIR/$rs
          done
        done
      '';

      # The first derivation builds all dependencies. We filter the sources, and we cannot include *any* toplevel source
      # files, otherwise changes to them would invalidate the dependency build cache.
      dependenciesFilter = path: type:
        let
          relative = nixpkgs.lib.removePrefix (toString ./. + "/") (toString path);
        in {
          "directory" = builtins.match ".*/(target|result|build|\.git|\.idea)" path == null;
          "regular" = builtins.match ".*(Cargo\.(lock|toml))" relative != null;
          "symlink" = false;
        }.${type};
      dependencies = nixpkgs.lib.overrideDerivation shared (orig: {
        name = orig.name + "-dependencies";
        src = nixpkgs.lib.cleanSourceWith { filter = dependenciesFilter; name = spec.name; src = spec.src; };

        patchPhase = (orig.patchPhase or "") + dummySources;

        buildPhase = ''
          set -euo pipefail
          BUILD="cargo test --no-run ${cargoFlags}"
          echo "Running in $PWD: $BUILD"
          $BUILD
        '';

        checkPhase = '''';

        installPhase = ''
          set -euo pipefail
          for artifact_name in ''${ARTIFACT_NAMES[@]}
          do
            # Cargo rewrites -s to _s. Sometimes.
            for name in $artifact_name $(echo $artifact_name | sed 's/_/-/g') $(echo $artifact_name | sed 's/-/_/g')
            do
              echo Deleting artifacts named $name
              # Maybe merge these into a single find
              rm -vrf $(find target \
                \( -regextype sed -regex ".*/\(lib\)\?$name\(-[a-f0-9]\{16\}\)\?\(.d\|.so\|.rlib\|.rmeta\)\?" \) \
              )
            done
          done
          mkdir -p $out/target/release
          mkdir -p $out/target/"${target}"/release
          mv target/release/{deps,build,.fingerprint} $out/target/release
          mv target/"${target}"/release/{deps,build,.fingerprint} $out/target/"${target}"/release
        '';
      });

      # The toplevel build uses the dependencies build by symlinking binary artifacts into Cargo's target/ folder.
      # We filter the input `src` so that build artifacts don't invalidate the cache.
      toplevelFilter = path: type:
        let
          relative = nixpkgs.lib.removePrefix (toString ./. + "/") (toString path);
        in {
          "directory" = builtins.match ".*/(target|result|build|\.git|\.idea)" path == null;
          "regular" = builtins.match ".*((/(src|tests|examples)/.*)|(\.(lock|toml|rs)))" relative != null;
          "symlink" = false;
        }.${type};

      toplevel = nixpkgs.lib.overrideDerivation shared (orig: rec {
        src = nixpkgs.lib.cleanSourceWith { filter = toplevelFilter; name = spec.name; src = spec.src; };
        patchPhase = (orig.patchPhase or "") + INSTALL_DEPENDENCIES;

        installPhase = "set -euo pipefail\n" + nixpkgs.lib.replaceStrings ["$releaseDir"] ["./target/release ./target/\"${target}\"/release"] orig.installPhase;
  
        # A magic command to call from nix-shell to install the dependencies into the current folder.
        INSTALL_DEPENDENCIES=''
          cp -pafs ${dependencies.out}/* .
          find target -type d -exec chmod u+w {} \;
        '';
      });
    in toplevel;
in
# This is where we actually call the build. Pass additional parameters to your build here.
{
  inherit
    rustNightly
    rustSgx
    buildCachedRustPackage
    ;
}
