#!/bin/bash
echo ""
echo "LineageOS 18.x Unified Buildbot - LeaOS version"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
git clone https://github.com/xc112lg/lineage_patches_leaos  -b lineage-18.1
git clone https://github.com/iceows/treble_experimentations

if [ $# -lt 1 ]
then
    echo "Not enough arguments - exiting"
    echo ""
    exit 1
fi

MODE=${1}
NOSYNC=false

for var in "${@:2}"
do
    if [ ${var} == "nosync" ]
    then
        NOSYNC=true
    fi
done

echo "Building with NoSync : $NOSYNC - Mode : ${MODE}"





START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
WITHOUT_CHECK_API=true
WITH_SU=true


repo init -u https://github.com/crdroidandroid/android.git -b 11.0 --git-lfs


prep_build() {
	echo "Preparing local manifests"
	rm -rf .repo/local_manifests
	mkdir -p .repo/local_manifests
	cp ./lineage_build_leaos/local_manifests_leaos/*.xml .repo/local_manifests
	echo ""

	echo "Syncing repos"
	repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j2

	echo ""

	echo "Setting up build environment"
	source build/envsetup.sh &> /dev/null
	mkdir -p ./build-output
	echo ""
}

apply_patches() {
    echo "Applying patch group ${1}"
    bash ./lineage_build_leaos/apply_patches.sh ./lineage_patches_leaos/${1}
}

prep_device() {
    :
}

prep_treble() {
    echo "Applying patch treble prerequisite and phh"

}

finalize_device() {
    :
}

finalize_treble() {
    rm -f device/*/sepolicy/common/private/genfs_contexts
    cd device/phh/treble
    git clean -fdx
    bash generate.sh lineage
    cd ../../..
}

build_device() {
    if [ ${1} == "arm64" ]
    then
        lunch lineage_arm64-userdebug
        make -j$(nproc --all) systemimage
        mv $OUT/system.img ./build-output/lineage-18.1-$BUILD_DATE-UNOFFICIAL-arm64$(${PERSONAL} && echo "-personal" || echo "").img
    else
        brunch ${1}
        mv $OUT/lineage-*.zip ./build-output/lineage-18.1-$BUILD_DATE-UNOFFICIAL-${1}$($PERSONAL && echo "-personal" || echo "").zip
    fi
}

build_treble() {
    case "${1}" in
        ("64BVS") TARGET=treble_arm64_bvS;;
        ("64BVZ") TARGET=treble_arm64_bvZ;;
        ("64BVN") TARGET=treble_arm64_bvN;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
    lunch ${TARGET}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    #make vndk-test-sepolicy
    mv $OUT/system.img ./build-output/LeaOS-18.1-$BUILD_DATE-${TARGET}.img
}

if ${NOSYNC}
then
    echo "ATTENTION: syncing/patching skipped!"
    echo ""
    echo "Setting up build environment"
    source build/envsetup.sh &> /dev/null
    echo ""
else
    prep_build
    echo "Applying patches"
    prep_treble
    apply_patches lineage
    apply_patches generic
    apply_patches personal
    finalize_treble
    echo ""
fi

for var in "${@:2}"
do
    if [ ${var} == "nosync" ]
    then
        continue
    fi
    echo "Starting $(${PERSONAL} && echo "personal " || echo "")build for ${MODE} ${var}"
    build_${MODE} ${var}
done
ls ./build-output | grep 'LeaOS' || true

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
