LOG_STEP_IN "- Adding HIDL face biometrics libs from extra"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "system" "system/lib/android.hardware.biometrics.face@1.0.so"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "system" "system/lib/vendor.samsung.hardware.biometrics.face@2.0.so"
LOG_STEP_OUT