#!/bin/bash
DEVICE="$1"
SYNC="$2"
LOG="$3"
START_TIME=`date +'%d/%m/%y %H:%M:%S'`
SYNC_LOG="sync_error.txt"

# Sync with latest sources
if [ "$SYNC" == "sync" ]; then
   if [ -f $SYNC_LOG ]; then
      rm $SYNC_LOG
   fi
   echo -e "Syncing latest sources"
   repo sync -j `getconf _NPROCESSORS_ONLN` -c -f --force-sync --no-tags 2> $SYNC_LOG

   if grep -E "^error|^fatal" $SYNC_LOG
   then
      echo "------------------------------------------------------------------------------------"
      echo "error: Exited sync due to fetch errors, please check $SYNC_LOG and correct the issue"
      echo "------------------------------------------------------------------------------------"
      exit
   else
      echo
      echo "Repo sync successful"
      echo
   fi
fi

echo "."
echo "."
echo "."
echo "-----------------------------------------------------------------------------"
echo "Setting up environment to build YAOSP"
echo "-----------------------------------------------------------------------------"

# Setup ccache
export USE_CCACHE=1
export CCACHE_DIR="/home/$USER/.ccache"
/usr/bin/ccache -M 100G

# Force restart Jack
export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx15g"
./prebuilts/sdk/tools/jack-admin kill-server
./prebuilts/sdk/tools/jack-admin start-server

rm out/target/product/*/system/build.prop
source build/envsetup.sh
croot

if [ "$DEVICE" = "hammerhead" ]; then
   lunch aosp_hammerhead-userdebug
else if [ "$DEVICE" = "flo" ]; then
   lunch aosp_flo-userdebug
else if [ "$DEVICE" = "bullhead" ]; then
   lunch aosp_bullhead-userdebug
else
   echo "-----------------------------------------------------------------------------"
   echo "Unsupported device '$DEVICE', stopping ..."
   echo "-----------------------------------------------------------------------------"
   exit
fi
fi
fi

echo "-----------------------------------------------------------------------------"
echo "Building YAOSP for $DEVICE"
echo "-----------------------------------------------------------------------------"

make -j `getconf _NPROCESSORS_ONLN` dist

echo "Started  : $START_TIME"
echo "Finished : `date +'%d/%m/%y %H:%M:%S'`"

AOSP_TARGET_PACKAGE="out/target/product/$DEVICE/YAOSP-v`grep ro.yaosp.version= out/target/product/$DEVICE/system/build.prop | awk -F= '{print $2;}'`-$DEVICE-`grep ro.build.version.release= out/target/product/$DEVICE/system/build.prop | awk -F= '{print $2;}'`-`grep ro.build.id= out/target/product/$DEVICE/system/build.prop | awk -F= '{print $2;}'`-`date +'%Y%m%d-%H%M%S'`.zip"

if [ -e out/dist/aosp_$DEVICE-ota-eng.$USER.zip ]; then

   if [ "$LOG" = "log" ]; then
      . scripts/changelog.sh
   fi
   echo
   echo "-----------------------------------------------------------------------------"
   echo "Package complete for $DEVICE"
   echo "-----------------------------------------------------------------------------"

   ln -f out/dist/aosp_$DEVICE-ota-eng.$USER.zip $AOSP_TARGET_PACKAGE

   echo
   echo "Package :"
   echo

   md5sum $AOSP_TARGET_PACKAGE

   echo

else

   echo
   echo "-----------------------------------------------------------------------------"
   echo "Package for $DEVICE - Not completed due to errors"
   echo "-----------------------------------------------------------------------------"

fi
