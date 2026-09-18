LOG_STEP_IN "- Replacing default zram size with 0"
EVAL "sed -i -E 's/zramsize=[^\"]*,/zramsize=0,/' \
    \"$WORK_DIR/vendor/etc/fstab.ramplus\""
EVAL "sed -i -E 's/zramsize=[^\"]*/zramsize=0/' \
    \"$WORK_DIR/vendor/etc/fstab.emmc\""
LOG_STEP_OUT