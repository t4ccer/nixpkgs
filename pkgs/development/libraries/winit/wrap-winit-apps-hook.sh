if [[ -z "${__nix_wrapWinitAppsHook-}" ]]; then
    __nix_wrapWinitAppsHook=1 # Don't run this hook more than once.

    # Inherit arguments given in mkDerivation
    winitWrapperArgs=(${winitWrapperArgs-})
    winitWrapperArgs+=(--prefix LD_LIBRARY_PATH : "@winitRuntimeInputs@")

    makeWinitWrapper() {
        local original="$1"
        local wrapper="$2"
        shift 2
        makeWrapper "$original" "$wrapper" "${winitWrapperArgs[@]}" "$@"
    }

    wrapWinitApp() {
        local program="$1"
        shift 1
        wrapProgram "$program" "${winitWrapperArgs[@]}" "$@"
    }

    wrapWinitAppsHook() {
        # skip this hook when requested
        [ -z "${dontWrapWinitApps-}" ] || return 0

        # guard against running multiple times (e.g. due to propagation)
        [ -z "$wrapWinitAppsHookHasRun" ] || return 0
        wrapWinitAppsHookHasRun=1

        local targetDirs=("$prefix/bin" "$prefix/sbin")
        echo "wrapping winit applications in ${targetDirs[@]}"

        for targetDir in "${targetDirs[@]}"; do
            [ -d "$targetDir" ] || continue

            find "$targetDir" ! -type d -executable -print0 | while IFS= read -r -d '' file; do
                # Skip the file if it is not a binary (ELF or Mach-O)
                isELF "$file" || isMachO "$file" || continue

                if [ -h "$file" ]; then
                    target="$(readlink -e "$file")"
                    echo "wrapping $file -> $target"
                    rm "$file"
                    makeWinitWrapper "$target" "$file"
                elif [ -f "$file" ]; then
                    echo "wrapping $file"
                    wrapWinitApp "$file"
                fi
            done
        done
    }

    fixupOutputHooks+=(wrapWinitAppsHook)
fi
