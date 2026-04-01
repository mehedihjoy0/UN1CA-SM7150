LOG_STEP_IN "- Adding wpa_supplicant from source"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "bin/hw/wpa_supplicant"
LOG_STEP_OUT

LOG_STEP_IN "- Adding FM radio blobs from stock"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.sec.android.app.fm.xml"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/sysconfig/preinstalled-packages-com.sec.android.app.fm.xml"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/HybridRadio/HybridRadio.apk"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libfmradio_jni.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfmradio_jni.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/fm_helium.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libbeluga.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libfm-hci.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.fm@1.0.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/fm_helium.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libbeluga.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libfm-hci.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.fm@1.0.so"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing radio HAL version with 1.5"
EVAL "sed -i \"s/1.4::IRadio/1.5::IRadio/g\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT