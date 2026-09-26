# shellcheck disable=SC2034
SKIPUNZIP=1

ADD_TO_WORK_DIR "$MODPATH" "system" "." 0 0 755 "u:object_r:system_file:s0"

BUILDER="$(git -C "$SRC_DIR" config --get remote.origin.url | sed -nE \
    's#^(https://github\.com/|git@github\.com:)([^/]+)/.*#\2#p')"
    
LOG_STEP_IN "- Forcing ChoiDujour to fetch OTA metadata from @${BUILDER}'s repository"
SMALI_PATCH "system" "system/priv-app/ChoiDujour/ChoiDujour.apk" "smali/t81.smali" "replace" \
    "b(Z)V" \
    "const-wide v4, 0x5c18d946d5d38297L" \
    "    const-string v3, \"https://raw.githubusercontent.com/$BUILDER/static_resources/refs/heads/sixteen/updates/manifest.json\"\n
    const-wide v4, 0x5c18d946d5d38297L"
SMALI_PATCH "system" \
    "system/priv-app/ChoiDujour/ChoiDujour.apk" \
    "smali/io/mesalabs/choidujour/activity/WhatsNewActivity.smali" \
    "replace" \
    "onCreate(Landroid/os/Bundle;)V" \
    "invoke-direct {v2, v9}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V" \
    "    const-string v9, \"https://raw.githubusercontent.com/$BUILDER/static_resources/refs/heads/sixteen/updates/\"\n
    invoke-direct {v2, v9}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V"
LOG_STEP_OUT

LOG "- Patching /system/system/etc/security/otacerts.zip"
EVAL "rm \"$WORK_DIR/system/system/etc/security/otacerts.zip\""
EVAL "cd \"$SRC_DIR\"; zip -q \"$WORK_DIR/system/system/etc/security/otacerts.zip\" \"./security/aosp_testkey.x509.pem\""

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$MODPATH/suggestions/SecSettings.apk/0001-Launch-UN1CA-Updates-from-suggestions.patch"

# Disable stock OTA references
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateUtils.smali" "return" \
    "isOTAUpgradeAllowed(Landroid/content/Context;)Z" "false"

# Dynamically patch SecSettings
# - Add missing/non-xml files in place
# - Patch existing files
#   - Use the first line of the file to tell sed how to apply the rest of the content
#   - Exception made for files under *res/values* where the "resources" tag gets nuked
while IFS= read -r f; do
    f="${f//$MODPATH\/SecSettings.apk\//}"

    if [ ! -f "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f" ] || \
            [[ "$f" != *".xml" ]]; then
        LOG "- Adding \"$f\" to /system/system/priv-app/SecSettings.apk"
        EVAL "mkdir -p \"$(dirname "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f")\""
        EVAL "cp -a \"$MODPATH/SecSettings.apk/${f//\$/\\$}\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/${f//\$/\\$}\""
    else
        LOG "- Patching \"$f\" in /system/system/priv-app/SecSettings.apk"
        if [[ "$f" == *"res/values"* ]]; then
            PATCH_INST="/<\/resources>/i"
            CONTENT="$(sed -e "/?xml/d" -e "/resources>/d" "$MODPATH/SecSettings.apk/$f")"
        else
            PATCH_INST="$(head -n 1 "$MODPATH/SecSettings.apk/$f")"
            CONTENT="$(tail -n +2 "$MODPATH/SecSettings.apk/$f")"
        fi
        CONTENT="$(sed -e "s/\"/\\\\\"/g" -e "s/\\$/\\\\$/g" -e "s/ /\\\ /g" -e "s/\\\\n/\\\\\\\\\n/g" <<< "$CONTENT")"
        CONTENT="$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' <<< "$CONTENT")"
        EVAL "sed -i \"$PATCH_INST $CONTENT\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f\""
    fi
done < <(find "$MODPATH/SecSettings.apk" -type f)

unset PATCH_INST CONTENT
