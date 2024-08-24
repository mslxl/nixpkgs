cargoBuildHook() {
    echo "Executing cargoBuildHook"

    runHook preBuild

    # Let stdenv handle stripping, for consistency and to not break
    # separateDebugInfo.
    export "CARGO_PROFILE_${cargoBuildType@U}_STRIP"=false

    if [ ! -z "${buildAndTestSubdir-}" ]; then
        # ensure the output doesn't end up in the subdirectory
        export CARGO_TARGET_DIR="$(pwd)/target"

        pushd "${buildAndTestSubdir}"
    fi

    local flagsArray=(
        "-j" "$NIX_BUILD_CORES"
        "--target" "@rustHostPlatformSpec@"
        "--offline"
    )

    if [ "${cargoBuildType}" != "debug" ]; then
        flagsArray+=("--profile" "${cargoBuildType}")
    fi

    if [ -n "${cargoBuildNoDefaultFeatures-}" ]; then
        flagsArray+=("--no-default-features")
    fi

    if [ -n "${cargoBuildFeatures-}" ]; then
        flagsArray+=("--features=$(concatStringsSep "," cargoBuildFeatures)")
    fi

    concatTo flagsArray cargoBuildFlags

    echoCmd 'cargoBuildHook flags' "${flagsArray[@]}"
    @setEnv@ cargo build "${flagsArray[@]}"

    if [ ! -z "${buildAndTestSubdir-}" ]; then
        popd
    fi

    runHook postBuild

    echo "Finished cargoBuildHook"
}

if [ -z "${dontCargoBuild-}" ] && [ -z "${buildPhase-}" ]; then
  buildPhase=cargoBuildHook
fi
