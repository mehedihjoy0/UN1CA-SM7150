LOG_STEP_IN "- Replacing MIDAS config files with a73xqxx"
DELETE_FROM_WORK_DIR "vendor" "etc/midas"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "etc/midas" 0 2000 755 "u:object_r:vendor_configs_file:s0"
sed -i "s/a73xq/$TARGET_CODENAME/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing singletake config files with a73xqxx"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "etc/singletake" 0 2000 755 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT