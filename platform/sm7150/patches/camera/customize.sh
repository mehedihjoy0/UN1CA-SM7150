LOG_STEP_IN "- Replacing MIDAS config files with source"
DELETE_FROM_WORK_DIR "vendor" "etc/midas"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/midas"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing singletake config files with source"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/singletake"
LOG_STEP_OUT