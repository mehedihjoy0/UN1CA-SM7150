LOG_STEP_IN "- Fixing corner radius of edge lighting"
SET_PROP "system" "ro.factory.model" "$(GET_PROP "vendor" "ro.product.vendor.model")"

if ! grep -q "ro.factory.model" "$SRC_DIR/unica/mods/prophide/system/bin/prophide.sh"; then
    EVAL "echo \"rezetprop -n ro.factory.model \\\"SM-A715F\\\"\" >> \
        \"$SRC_DIR/unica/mods/prophide/system/bin/prophide.sh\""
fi
LOG_STEP_OUT