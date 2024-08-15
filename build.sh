#!/bin/bash
echo ""
echo "cRDOID 18.1 Unified Buildbot - LeaOS version"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
rm -rf treble_experimentations lineage_patches_leaos .repo/local_manifests frameworks/base lineage-sdk
repo init -u https://github.com/crdroidandroid/android.git -b 11.0 --git-lfs
#repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --git-lfs

git clone https://github.com/iceows/treble_experimentations
git clone https://github.com/xc112lg/lineage_patches_leaos lineage_patches_leaos -b test
#git clone https://github.com/xc112lg/lineage_patches_leaoss lineage_patches_leaos
#git clone https://github.com/iceows/lineage_patches_leaos lineage_patches_leaos -b lineage-18.1
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
       cp -f ./lineage_build_leaos/local_manifests_leaoss/*.xml .repo/local_manifests
    else
       cp -f ./lineage_build_leaos/local_manifests_leaos/*.xml .repo/local_manifests
    fi
    
    echo ""
    
    echo "Syncing repos"
#!/bin/bash
# Copyright (c) 2016-2024 Crave.io Inc. All rights reserved

repo --version
cd .repo/repo
git pull -r
cd -
repo --version


main() {
    # Run repo sync command and capture the output
    find .repo -name '*.lock' -delete
    repo sync -c -j32 --force-sync --no-clone-bundle --no-tags --prune 2>&1 | tee /tmp/output.txt

 if ! grep -qe "Failing repos:\|uncommitted changes are present" /tmp/output.txt ; then
         echo "All repositories synchronized successfully."
         exit 0
    else
        rm -f deleted_repositories.txt
    fi

    # Check if there are any failing repositories
    if grep -q "Failing repos:" /tmp/output.txt ; then
        echo "Deleting failing repositories..."
        # Extract failing repositories from the error message and echo the deletion path
        while IFS= read -r line; do
            # Extract repository name and path from the error message
            repo_info=$(echo "$line" | awk -F': ' '{print $NF}')
            repo_path=$(dirname "$repo_info")
            repo_name=$(basename "$repo_info")
            # Save the deletion path to a text file
            echo "Deleted repository: $repo_info" | tee -a deleted_repositories.txt
            # Delete the repository
            rm -rf "$repo_path/$repo_name"
            rm -rf ".repo/project/$repo_path/$repo_name"/*.git
        done <<< "$(cat /tmp/output.txt | awk '/Failing repos:/ {flag=1; next} /Try/ {flag=0} flag')"
    fi

    # Check if there are any failing repositories due to uncommitted changes
    if grep -q "uncommitted changes are present" /tmp/output.txt ; then
        echo "Deleting repositories with uncommitted changes..."

        # Extract failing repositories from the error message and echo the deletion path
        while IFS= read -r line; do
            # Extract repository name and path from the error message
            repo_info=$(echo "$line" | awk -F': ' '{print $2}')
            repo_path=$(dirname "$repo_info")
            repo_name=$(basename "$repo_info")
            # Save the deletion path to a text file
            echo "Deleted repository: $repo_info" | tee -a deleted_repositories.txt
            # Delete the repository
            rm -rf "$repo_path/$repo_name"
            rm -rf ".repo/project/$repo_path/$repo_name"/*.git
        done <<< "$(cat /tmp/output.txt | grep 'uncommitted changes are present')"
    fi

    # Re-sync all repositories after deletion
    echo "Re-syncing all repositories..."
    find .repo -name '*.lock' -delete
    repo sync -c -j32 --force-sync --no-clone-bundle --no-tags --prune
}

main $*
    
   
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


cd lineage-sdk
sleep 1 &&git fetch https://github.com/xc112lg/android_lineage-sdk-1.git patch-1
sleep 1 &&git cherry-pick ce6079d1f50d62c4c17de2e21760495428bf787f 
cd ..

    case "${1}" in
        ("64BVS") TARGET=treble_arm64_bvS;;
        ("64BVZ") TARGET=treble_arm64_bvZ;;
        ("64BVN") TARGET=treble_arm64_avZ;;
	("64BOZ") TARGET=treble_arm64_boZ;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
rm out/target/product/*/*.img
#rm vendor/addons/config.mk
#mv lineage_build_leaos/config.mk vendor/addons/
#rm frameworks/base/core/java/com/android/internal/util/crdroid/PixelPropsUtils.java
#mv lineage_build_leaos/PixelPropsUtils.java frameworks/base/core/java/com/android/internal/util/crdroid/
# cd frameworks/base
# sleep 1 &&git fetch https://github.com/xc112lg/android_frameworks_base.git patch-1
# sleep 1 &&git cherry-pick ff31cc43e514f3b57846d1cf221411fd08e9726e
# cd ../..


#rm frameworks/base/packages/SystemUI/src/com/android/systemui/globalactions/GlobalActionsDialog.java
#mv lineage_build_leaos/GlobalActionsDialog.java frameworks/base/packages/SystemUI/src/com/android/systemui/globalactions
    lunch ${TARGET}-userdebug
   # make installclean
   # make -j32 systemimage



    
 #   lunch treble_arm64_avZ-userdebug
#    make -j32 systemimage


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
