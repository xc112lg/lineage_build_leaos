#!/bin/bash

set -e

patches="$(readlink -f -- "$1")"

shopt -s nullglob
failed_patches=() # Array to store failed patches
for project in "$patches"/*; do
    p="$(basename "$project" | tr _ / | sed -e 's;platform/;;g')"
    [ "$p" == build ] && p=build/make
    [ "$p" == vendor/hardware/overlay ] && p=vendor/hardware_overlay
    [ "$p" == vendor/partner/gms ] && p=vendor/partner_gms
        [ "$p" == external/harfbuzz/ng ] && p=external/harfbuzz_ng
    pushd "$p"
    git clean -fdx; git reset --hard
    for patch in "$patches"/$(basename "$project")/*.patch; do
        if git apply --check "$patch"; then
            git am "$patch"
        else
            echo "Reverting changes from $patch"
            git reset --hard HEAD # Reset changes from previous patch
            if patch -f -p1 --dry-run < "$patch" > /dev/null; then
                patch -f -p1 < "$patch"
                git add -u
                git commit -m "Reverted changes from failed patch: $(basename "$patch")"
            else
                echo "Failed applying $patch"
                failed_patches+=("$patch") # Store failed patch
            fi
        fi
    done
    popd
done

# Display failed patches
if [ ${#failed_patches[@]} -gt 0 ]; then
    echo "Failed to apply the following patches:"
    for failed_patch in "${failed_patches[@]}"; do
        echo "$failed_patch"
    done
fi
