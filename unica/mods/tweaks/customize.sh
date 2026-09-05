# Disable app compaction
# Guard the patch as the source firmware might have this already disabled
LOG "- Applying \"Disable app compaction\" to /system/system/framework/services.jar"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/appcompactor/services.jar/0001-Disable-app-compaction.patch" &> /dev/null || true

# Disable FM Radio country restrictions
if [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_AVOID_REGION")" ]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_AVOID_REGION" --delete
fi

LOG_STEP_IN "- Allowing doze for all apps"
EVAL "sed -i -E '/<(allow-(in-(power|data-usage)-save|(unthrottled|ignore)-location)|bg-restriction-exemption)/,/\\/>/d' \"$WORK_DIR\"/**/etc/{permissions,sysconfig}/*.xml"

EVAL "sed -i '/<reviewed-in-power-save/,/\/>/d' \"$WORK_DIR\"/system/system/etc/deviceidle/reviewed_allowlist.xml"
LOG_STEP_OUT
