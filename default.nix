{pkgs ? import ./nix/pkgs.nix {}}:
let
    # This function wraps pkg-config such that it can find the given packages.
    # This seems to be a neat way of using pkg-config with a build workflow
    # based on the “nix run” command.
    pkg-config_with_packages = packages: pkgs.stdenvNoCC.mkDerivation {
        name = "pkg-config_with_packages";
        buildInputs = [pkgs.makeWrapper];
        phases = ["installPhase"];
        installPhase = ''
            make_wrapper_flags=()
            for package in ${pkgs.lib.concatMapStringsSep " " (p: "${p}") packages}; do
                make_wrapper_flags+=(--prefix PKG_CONFIG_PATH : $package/lib/pkgconfig)
            done

            mkdir --parents $out/bin
            makeWrapper ${pkgs.pkg-config}/bin/pkg-config $out/bin/pkg-config \
                "''${make_wrapper_flags[@]}"
        '';
    };

    executables = [
        pkgs.bash
        pkgs.coreutils
        pkgs.gnum4
        pkgs.graphviz
        pkgs.ldc
        pkgs.snowflake
    ];

    libraries = [
        pkgs.zeromq4
    ];
in
    executables ++ [(pkg-config_with_packages libraries)]
