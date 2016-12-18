#!/bin/bash
start_time=`date +'%d/%m/%y %H:%M:%S'`

echo "."
echo "."
echo "."
echo "-----------------------------------------------------------------------------"
echo "Setting up environment to build YAOSP"
echo "-----------------------------------------------------------------------------"

# Setup ccache
export USE_CCACHE=1
export CCACHE_DIR="/home/$USER/.ccache"
/usr/bin/ccache -M 50G

# Force restart Jack
export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx15g"
./prebuilts/sdk/tools/jack-admin kill-server
./prebuilts/sdk/tools/jack-admin start-server

rm out/target/product/*/system/build.prop
source build/envsetup.sh
croot

if [ "$1" = "hammerhead" ]; then
   lunch aosp_hammerhead-userdebug
else if [ "$1" = "flo" ]; then
   lunch aosp_flo-userdebug
else if [ "$1" = "bullhead" ]; then
   lunch aosp_bullhead-userdebug
else
   echo "-----------------------------------------------------------------------------"
   echo "Unsupported device '$1', stopping ..."
   echo "-----------------------------------------------------------------------------"
   exit
fi
fi
fi

echo "-----------------------------------------------------------------------------"
echo "Building YAOSP for $1"
echo "-----------------------------------------------------------------------------"

make -j `getconf _NPROCESSORS_ONLN` dist

echo "Started  : $start_time"
echo "Finished : `date +'%d/%m/%y %H:%M:%S'`"

AOSP_TARGET_PACKAGE="out/target/product/$1/YAOSP-v`grep ro.yaosp.version= out/target/product/$1/system/build.prop | awk -F= '{print $2;}'`-$1-`grep ro.build.version.release= out/target/product/$1/system/build.prop | awk -F= '{print $2;}'`-`grep ro.build.id= out/target/product/$1/system/build.prop | awk -F= '{print $2;}'`-`date +'%Y%m%d-%H%M%S'`.zip"

if [ -e out/dist/aosp_$1-ota-eng.$USER.zip ]; then

   . scripts/changelog.sh
   echo
   echo "-----------------------------------------------------------------------------"
   echo "Package complete for $1"
   echo "-----------------------------------------------------------------------------"

   ln -f out/dist/aosp_$1-ota-eng.$USER.zip $AOSP_TARGET_PACKAGE

   echo
   echo "Package :"
   echo

   md5sum $AOSP_TARGET_PACKAGE

   echo

else

   echo
   echo "-----------------------------------------------------------------------------"
   echo "Package for $1 - Not completed due to errors"
   echo "-----------------------------------------------------------------------------"

fi
