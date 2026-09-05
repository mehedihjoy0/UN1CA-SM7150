LOG_STEP_IN "- Fixing edge lighting"
SET_PROP "system" "ro.factory.model" "$(GET_PROP "vendor" "ro.factory.model")"

EVAL "echo \"\nrezetprop -n ro.factory.model \\\"SM-A715F\\\"\" >> \
    \"$SRC_DIR/unica/mods/prophide/system/bin/prophide.sh\""
LOG_STEP_OUT