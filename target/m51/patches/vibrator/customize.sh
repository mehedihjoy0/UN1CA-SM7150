LOG_STEP_IN "- Adding AIDL vibrator HAL from extra"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/vendor.samsung.hardware.vibrator@2.2-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.0.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.1.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.2.so"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "vendor" "bin/hw/vendor.samsung.hardware.vibrator-service"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "vendor" "etc/init/vendor.samsung.hardware.vibrator-default.rc"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "vendor" "etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "vendor" "lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so"
LOG_STEP_OUT

LOG_STEP_IN "- Patching /vendor/etc/vintf/manifest.xml"
EVAL "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/android.hardware.vibrator/d}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT