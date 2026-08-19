# https://github.com/pascua28/UN1CA/tree/sixteen/target/a71/patches/display/customize.sh

LOG_STEP_IN "- Removing legacy display composer"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.graphics.composer@2.4-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.graphics.composer@2.4-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/vintf/manifest/android.hardware.graphics.composer-qti-display.xml"
LOG_STEP_OUT

LOG_STEP_IN "- Adding AIDL display composer from r9qxxx"
BLOBS_LIST="
bin/hw/vendor.display.color@1.0-service
bin/hw/vendor.qti.hardware.display.composer-service
etc/init/vendor.qti.hardware.display.composer-service.rc
etc/snapdragon_color_libs_config.xml
etc/vintf/manifest/vendor.qti.hardware.display.composer-service.xml
lib64/libdisp-aba.so
lib64/libdisplayconfig.qti.so
lib64/libdisplaydebug.so
lib64/libdisplayqos.so
lib64/libdisplayskuutils.so
lib64/libdpps.so
lib64/libdrm.so
lib64/libdrmutils.so
lib64/libgpu_tonemapper.so
lib64/libhdr_tm.so
lib64/libhdrdynamic.so
lib64/libhdrdynamicootf.so
lib64/libhistogram.so
lib64/libqdMetaData.so
lib64/libqdcm-mode-parser.so
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
lib64/hw/android.hardware.graphics.mapper@3.0-impl-qti-display.so
lib64/hw/android.hardware.graphics.mapper@4.0-impl-qti-display.so
"

for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "r9qxxx" "vendor" "$blob"
done

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

unset BLOBS_LIST



