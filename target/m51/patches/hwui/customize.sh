LOG_STEP_IN "- Adding HWUI libs from extra"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "system" "system/lib/libhwui.so"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "system" "system/lib64/libhwui.so"
LOG_STEP_OUT