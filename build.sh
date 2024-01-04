#!/bin/bash
echo ""
echo "LineageOS 20.x Unified Buildbot - LeaOS version"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

if [ $# -lt 1 ]
then
    echo "Not enough arguments - exiting"
    echo ""
    exit 1
fi


MODE=${1}
if [ ${MODE} != "device" ] && [ ${MODE} != "treble" ]
then
    echo "Invalid mode - exiting"
    echo ""
    exit 1
fi

NOSYNC=false
for var in "${@:2}"
do
    if [ ${var} == "nosync" ]
    then
        NOSYNC=true
    fi
done

echo "Building with NoSync : $NOSYNC - Mode : ${MODE}"

# Abort early on error
set -eE
trap '(\
echo;\
echo \!\!\! An error happened during script execution;\
echo \!\!\! Please check console output for bad sync,;\
echo \!\!\! failed patch application, etc.;\
echo\
)' ERR


WITHOUT_CHECK_API=true
WITH_SU=true
START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"


prep_build() {
    echo "Preparing local manifests"
    mkdir -p .repo/local_manifests

    
    if [ ${MODE} == "device" ]
    then
       cp ./lineage_build_leaos/local_manifests_leaoss/*.xml .repo/local_manifests
    else
       cp ./lineage_build_leaos/local_manifests_leaos/*.xml .repo/local_manifests
    fi
    
    echo ""
    
    echo "Syncing repos"
    repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
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

    # EMUI 8
    # cd hardware/lineage/compat
    # git fetch https://github.com/LineageOS/android_hardware_lineage_compat refs/changes/13/361913/9
    # git cherry-pick FETCH_HEAD
    # cd ../../../

    # EMUI 9
    unzip -o ./vendor/huawei/hi6250-9-common/proprietary/vendor/firmware/isp_dts.zip -d ./vendor/huawei/hi6250-9-common/proprietary/vendor/firmware
    # EMUI 8
    unzip -o ./vendor/huawei/hi6250-8-common/proprietary/vendor/firmware/isp_dts.zip -d ./vendor/huawei/hi6250-8-common/proprietary/vendor/firmware
}

prep_treble() {

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

      	# croot
      	#TEMPORARY_DISABLE_PATH_RESTRICTIONS=true
      	#export TEMPORARY_DISABLE_PATH_RESTRICTIONS
      	#breakfast ${1} 
      	#mka bootimage 2>&1 | tee make_anne.log 
        brunch ${1}
        mv $OUT/lineage-*.zip ./build-output/LeaOS-OSS-20.0-$BUILD_DATE-${1}.zip

}

build_treble() {
    case "${1}" in
        ("64VN") TARGET=arm64_bvN;;
        ("64VS") TARGET=arm64_bvS;;
        ("64GN") TARGET=arm64_bgN;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
    lunch lineage_${TARGET}-userdebug
    make -j$(nproc --all) systemimage
    mv $OUT/system.img ./build-output/LeaOS-20.0-$BUILD_DATE-${TARGET}.img
}

if ${NOSYNC}
then
    echo "ATTENTION: syncing/patching skipped!"
    echo ""
    echo "Setting up build environment"
    source build/envsetup.sh &> /dev/null
    echo ""

else
    echo "Prep build" 
    prep_build
    prep_${MODE}
    
    echo "Applying patches"    
    
    if [ ${MODE} == "device" ]
    then
    	apply_patches patches_device
    	apply_patches patches_device_iceows
    else
    prep_build
    echo "Applying patches"
    prep_treble
    apply_patches lineage
    apply_patches generic
    apply_patches personal
    finalize_treble
    fi
    finalize_${MODE}
    echo ""
fi


for var in "${@:2}"
do
    if [ ${var} == "nosync" ]
    then
        continue
    fi
    echo "Starting personal " || echo " build for ${MODE} ${var}"
    build_${MODE} ${var}
done
ls ./build-output | grep 'LeaOS' || true

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
