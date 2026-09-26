LOG_STEP_IN "- Disabling force encryption"
EVAL "sed -i -E 's/^([^#].*?)fileencryption=[^,]*(.*)$/# &\n\1encryptable\2/' \
    \"$WORK_DIR/vendor/etc/fstab.\"*\"\""
LOG_STEP_OUT

LOG_STEP_IN "- Removing frp"
SET_PROP "product" "ro.frp.pst" --delete
SET_PROP "vendor" "ro.frp.pst" --delete
LOG_STEP_OUT