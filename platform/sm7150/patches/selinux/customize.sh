LOG_STEP_IN "- Replacing vendor sepolicy with extra"
ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "vendor" "etc/selinux"

EVAL "sed -i -E 's/SM-[A-Z0-9]+/\
    $(GET_PROP "vendor" "ro.product.vendor.model")/g' \
    \"$WORK_DIR/vendor/etc/selinux/vendor_sepolicy_version\""
LOG_STEP_OUT

