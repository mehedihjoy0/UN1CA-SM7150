LOG_STEP_IN "- Adding wpa_supplicant from source"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "bin/hw/wpa_supplicant" 0 2000 755 "u:object_r:hal_wifi_supplicant_default_exec:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding FM radio blobs from stock"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.sec.android.app.fm.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/sysconfig/preinstalled-packages-com.sec.android.app.fm.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/HybridRadio/HybridRadio.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libfmradio_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfmradio_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/fm_helium.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libbeluga.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libfm-hci.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.fm@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/fm_helium.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libbeluga.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libfm-hci.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.fm@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing radio HAL with 1.5"
sed -i "s/1.4::IRadio/1.5::IRadio/g" "$WORK_DIR/vendor/etc/vintf/manifest.xml"
LOG_STEP_OUT