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

# https://github.com/rushiranpise/sorry-google
LOG "- Replacing AndroidSystemKeyVerifier with stub"
CONTACTKEYS=$(curl -s ${GITHUB_TOKEN:+-H Authorization: token $GITHUB_TOKEN} \
    "https://api.github.com/repos/rushiranpise/sorry-google/releases/latest" |
    grep -o 'https://[^"]*contactkeys[^"]*\.apk' | head -n1)
DOWNLOAD_FILE "$CONTACTKEYS" "$WORK_DIR/system/system/app/AndroidSystemKeyVerifier/AndroidSystemKeyVerifier.apk"
SET_METADATA "system" "system/app/AndroidSystemKeyVerifier" 0 0 755 "u:object_r:system_file:s0"
SET_METADATA "system" "system/app/AndroidSystemKeyVerifier/AndroidSystemKeyVerifier.apk" 0 0 644 "u:object_r:system_file:s0"

LOG "- Replacing AndroidSystemSafetyCore with stub"
SAFETYCORE=$(curl -s ${GITHUB_TOKEN:+-H Authorization: token $GITHUB_TOKEN} \
    "https://api.github.com/repos/rushiranpise/sorry-google/releases/latest" |
    grep -o 'https://[^"]*safetycore[^"]*\.apk' | head -n1)
DOWNLOAD_FILE "$SAFETYCORE" "$WORK_DIR/system/system/app/AndroidSystemSafetyCore/AndroidSystemSafetyCore.apk"
SET_METADATA "system" "system/app/AndroidSystemSafetyCore" 0 0 755 "u:object_r:system_file:s0"
SET_METADATA "system" "system/app/AndroidSystemSafetyCore/AndroidSystemSafetyCore.apk" 0 0 644 "u:object_r:system_file:s0"

LOG "- Replacing AndroidSystemKeyVerifier with stub"
VERIFIER=$(curl -s ${GITHUB_TOKEN:+-H Authorization: token $GITHUB_TOKEN} \
    "https://api.github.com/repos/rushiranpise/sorry-google/releases/latest" |
    grep -o 'https://[^"]*verifier[^"]*\.apk' | head -n1)
DOWNLOAD_FILE "$VERIFIER" "$WORK_DIR/system/system/app/AndroidSystemKeyVerifier/AndroidSystemKeyVerifier.apk"
SET_METADATA "system" "system/app/AndroidSystemKeyVerifier" 0 0 755 "u:object_r:system_file:s0"
SET_METADATA "system" "system/app/AndroidSystemKeyVerifier/AndroidSystemKeyVerifier.apk" 0 0 644 "u:object_r:system_file:s0"
