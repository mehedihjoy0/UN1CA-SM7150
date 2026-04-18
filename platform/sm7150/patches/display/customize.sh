# https://github.com/pascua28/UN1CA/tree/sixteen/target/a71/patches/display

LOG_STEP_IN "- Removing legacy display composer"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.graphics.composer@2.4-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.graphics.composer@2.4-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer-qti-display.xml"
LOG_STEP_OUT

LOG_STEP_IN "- Adding AIDL display composer from r9qxxx"

BLOBS_LIST="
bin/snaplite_utility_64
bin/snap_utility_64
bin/hw/android.hardware.memtrack@1.0-service
bin/hw/vendor.display.color@1.0-service
bin/hw/vendor.qti.hardware.display.composer-service
etc/snaplite_cache.bin
etc/snap_gpu_kernel_64.bin
etc/init/vendor.qti.hardware.display.composer-service.rc
etc/permissions/android.hardware.opengles.aep.xml
etc/permissions/android.hardware.vulkan.compute-0.xml
etc/permissions/android.hardware.vulkan.level-1.xml
etc/permissions/android.hardware.vulkan.version-1_1.xml
etc/permissions/android.software.vulkan.deqp.level.xml
etc/snapdragon_color_libs_config.xml
etc/vintf/manifest/vendor.qti.hardware.display.composer-service.xml
firmware/a630_sqe.fw
gpu/kbc/sequence_manifest.bin
gpu/kbc/unified_kbcs_32.bin
gpu/kbc/unified_kbcs_64.bin
gpu/kbc/unified_ksqs.bin
lib/egl/eglSubDriverAndroid.so
lib/egl/libEGL_adreno.so
lib/egl/libGLESv1_CM_adreno.so
lib/egl/libGLESv2_adreno.so
lib/egl/libq3dtools_adreno.so
lib/egl/libq3dtools_esx.so
lib/hw/vulkan.adreno.so
lib/libadreno_app_profiles.so
lib/libadreno_utils.so
lib/libC2D2.so
lib/libc2d30_bltlib.so
lib/libCB.so
lib/libgpudataproducer.so
lib/libgsl.so
lib/libkcl.so
lib/libkernelmanager.so
lib/libllvm-glnext.so
lib/libllvm-qcom.so
lib/libOpenCL.so
lib/libVkLayer_q3dtools.so
lib64/libadreno_utils.so
lib64/libC2D2.so
lib64/libc2d30_bltlib.so
lib64/libCB.so
lib64/libdisp-aba.so
lib64/libdisplayconfig.qti.so
lib64/libdisplaydebug.so
lib64/libdisplayqos.so
lib64/libdisplayskuutils.so
lib64/libdpps.so
lib64/libdrm.so
lib64/libdrmutils.so
lib64/libgpudataproducer.so
lib64/libgpu_tonemapper.so
lib64/libgsl.so
lib64/libhdrdynamic.so
lib64/libhdrdynamicootf.so
lib64/libhdr_tm.so
lib64/libhistogram.so
lib64/libkcl.so
lib64/libkernelmanager.so
lib64/libllvm-glnext.so
lib64/libllvm-qcom.so
lib64/libOpenCL.so
lib64/libqdcm-mode-parser.so
lib64/libqdMetaData.so
lib64/libqdutils.so
lib64/libqseed3.so
lib64/libqservice.so
lib64/libsdedrm.so
lib64/libsdm-color.so
lib64/libsdm-colormgr-algo.so
lib64/libsdm-diag.so
lib64/libsdm-disp-vndapis.so
lib64/libsdmcore.so
lib64/libsdmextension.so
lib64/libsdmutils.so
lib64/libsnapdragoncolor-manager.so
lib64/libsnapdragoncolor-qdcm.so
lib64/libtinyxml2_1.so
lib64/libVkLayer_q3dtools.so
lib64/vendor.display.color@1.0.so
lib64/vendor.display.color@1.1.so
lib64/vendor.display.color@1.2.so
lib64/vendor.display.color@1.3.so
lib64/vendor.display.color@1.4.so
lib64/vendor.display.color@1.5.so
lib64/vendor.display.config@2.0.so
lib64/vendor.display.postproc@1.0.so
lib64/vendor.qti.hardware.display.composer@3.0.so
lib64/vendor.qti.hardware.display.mapper@1.0.so
lib64/vendor.qti.hardware.display.mapper@1.1.so
lib64/vendor.qti.hardware.display.mapper@2.0.so
lib64/vendor.qti.hardware.display.mapper@3.0.so
lib64/vendor.qti.hardware.display.mapper@4.0.so
lib64/vendor.qti.hardware.display.mapperextensions@1.0.so
lib64/vendor.qti.hardware.display.mapperextensions@1.1.so
lib64/egl/eglSubDriverAndroid.so
lib64/egl/libEGL_adreno.so
lib64/egl/libGLESv1_CM_adreno.so
lib64/egl/libGLESv2_adreno.so
lib64/egl/libq3dtools_adreno.so
lib64/egl/libq3dtools_esx.so
lib64/hw/android.hardware.graphics.mapper@3.0-impl-qti-display.so
lib64/hw/android.hardware.graphics.mapper@4.0-impl-qti-display.so
lib64/hw/android.hardware.memtrack@1.0-impl.so
lib64/hw/gralloc.default.so
lib64/hw/gralloc.lahaina.so
lib64/hw/hwcomposer.lahaina.so
lib64/hw/lights.lahaina.so
lib64/hw/lights.qcom.so
lib64/hw/memtrack.default.so
lib64/hw/memtrack.lahaina.so
lib64/hw/vulkan.adreno.so
"

for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "r9qxxx" "vendor" "$blob"
done

LOG_STEP_IN "- Applying hex patches for lahaina -> sm6150"
find "$WORK_DIR/vendor/lib64" -type f -name '*lahaina*' -print0 2>/dev/null |
 while IFS= read -r -d '' f; do
   HEX_PATCH "$f"  "6C616861696E612E736F" "736D363135302E736F00"
   EVAL "mv -- \"$f\" \"$(printf '%s' \"$f\" | sed 's/lahaina/sm6150/g')\""
 done
LOG_STEP_OUT

# Fix WaitSync() timeout
HEX_PATCH "$WORK_DIR/vendor/lib64/libsdmutils.so" "40F9F303012A3401" "40F9130080523401"

# Workaround getMetaData() return path to fix GetCustomDimensions() error (from r9q).
# Un-inline pixel format checks from:
# if (format != HAL_PIXEL_FORMAT_YCbCr_420_SP_VENUS_UBWC || format != HAL_PIXEL_FORMAT_YCbCr_420_TP10_UBWC ||
#      format != HAL_PIXEL_FORMAT_YCbCr_420_P010_UBWC)
# to:
# if (!IsUBwcFormat())
# to retain padding and file size
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "60040035a8c35eb828040034a82e40b9" "e803002ae0031f2a28040035a8c35eb8"
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "1f910471200100542981815269f4af72" "e8030034a82e40b9e003082a75feff97"
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "1f01096ba0000054c980815269f4af72" "e803002ae0031f2a280300341f2003d5"
HEX_PATCH "$WORK_DIR/vendor/lib64/libgrallocutils.so" "1f01096bc1020054bf431ef8a9aa4329" "1f2003d51f2003d5bf431ef8a9aa4329"
LOG_STEP_OUT