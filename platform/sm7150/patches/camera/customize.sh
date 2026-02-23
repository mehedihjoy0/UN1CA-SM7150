LOG_STEP_IN "- Replacing MIDAS config files with source"
DELETE_FROM_WORK_DIR "vendor" "etc/midas"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/midas"
sed -i "s/a73xq/$TARGET_CODENAME/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing singletake config files with source"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/singletake"
LOG_STEP_OUT