#!/bin/bash
echo ""
echo "cRDOID 18.1 Unified Buildbot - LeaOS version"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
rm -rf treble_experimentations lineage_patches_leaos 
git clone https://github.com/iceows/treble_experimentations
git clone https://github.com/xc112lg/lineage_patches_leaos lineage_patches_leaos -b test

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
    source build/envsetup.sh


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
:
}

finalize_device() {
    :
}

finalize_treble() {
    rm -f device/*/sepolicy/common/private/genfs_contexts

    #rm -f frameworks/base/packages/SystemUI/res/values/lineage_config.xml.orig
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
        ("64BVS") TARGET=treble_arm64_bvS;;
        ("64BVZ") TARGET=treble_arm64_bvZ;;
        ("64BVN") TARGET=treble_arm64_bvN;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
rm out/target/product/*/*.img
cd frameworks/base/
git fetch https://github.com/xc112lg/android_frameworks_base-1.git patch-7
git cherry-pick 052774c602244a6e8921fa11ef1c911907e00d59
cd ../../
    lunch ${TARGET}-userdebug
    make -j$(nproc --all) systemimage
find out/target/product/*/ -type f -name "*.img" -execdir bash -c 'count=1; while [ -f "${1%.img}_newname_${count}.img" ]; do ((count++)); done; mv "$1" "${1%.img}_newname_${count}.img"' bash {} \;
cd frameworks/base/
git fetch https://github.com/xc112lg/android_frameworks_base-1.git patch-7
git cherry-pick 3f96b0f605d9a970d1ad459161d3b0fbfd275b08
cd ../../
    lunch ${TARGET}-userdebug
    make -j$(nproc --all) systemimage
find out/target/product/*/ -type f -name "*.img" -execdir bash -c 'count=1; while [ -f "${1%.img}_newname_${count}.img" ]; do ((count++)); done; mv "$1" "${1%.img}_newname_${count}.img"' bash {} \;
cd frameworks/base/
git fetch https://github.com/xc112lg/android_frameworks_base-1.git patch-7
git cherry-pick 3ae1e19a23b47372be72a63489e0fa1590bd7c52
cd ../../
    lunch ${TARGET}-userdebug
    make -j$(nproc --all) systemimage



}

if ${NOSYNC}
then
    echo "ATTENTION: syncing/patching skipped!"
    echo ""
    echo "Setting up build environment"
    source build/envsetup.sh
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
 #prep_build
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


END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
