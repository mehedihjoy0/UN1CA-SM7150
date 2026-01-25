LOG_STEP_IN "- Adding Viper4AndroidFX-RE"

# https://github.com/WSTxda/ViPERFX_RE
V4A=$(curl -s ${GITHUB_TOKEN:+-H Authorization: token $GITHUB_TOKEN} \
    "https://api.github.com/repos/WSTxda/ViPERFX_RE/releases/latest" | \
    sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*viper4android_module[^"]*\.zip\)".*/\1/p' | head -n1)

DOWNLOAD_FILE "$V4A" "$TMP_DIR/viper.zip"

for arch in armeabi-v7a arm64-v8a; do
    unzip -j "$TMP_DIR/viper.zip" "common/files/libv4a_re_${arch}.so" -d "$TMP_DIR"
    if [ "$arch" = "armeabi-v7a" ]; then
        cp -f "$TMP_DIR/libv4a_re_${arch}.so" "$WORK_DIR/vendor/lib/soundfx/libv4a_re.so"
        SET_METADATA "vendor" "lib/soundfx/libv4a_re.so" 0 0 644 "u:object_r:vendor_file:s0"
    else
        cp -f "$TMP_DIR/libv4a_re_${arch}.so" "$WORK_DIR/vendor/lib64/soundfx/libv4a_re.so"
        SET_METADATA "vendor" "lib64/soundfx/libv4a_re.so" 0 0 644 "u:object_r:vendor_file:s0"
    fi
    rm -f "$TMP_DIR/libv4a_re_${arch}.so"
done

rm -f "$TMP_DIR/viper.zip"

CFGS="$(find "$WORK_DIR/system" "$WORK_DIR/vendor" -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
for f in ${CFGS}; do
    case "$f" in
        *.conf)
            sed -i "/v4a_standard_re {/,/}/d" "$f"
            sed -i "/v4a_re {/,/}/d" "$f"
            sed -i "s/^effects {/effects {\n  v4a_standard_re {\n    library v4a_re\n    uuid 90380da3-8536-4744-a6a3-5731970e640f\n  }/g" "$f"
            sed -i "s/^libraries {/libraries {\n  v4a_re {\n    path \/vendor\/lib\/soundfx\/libv4a_re.so\n  }/g" "$f"
            ;;
        *.xml)
            sed -i "/v4a_standard_re/d" "$f"
            sed -i "/v4a_re/d" "$f"
            sed -i "/<libraries>/ a\        <library name=\"v4a_re\" path=\"libv4a_re.so\"\/>" "$f"
            sed -i "/<effects>/ a\        <effect name=\"v4a_standard_re\" library=\"v4a_re\" uuid=\"90380da3-8536-4744-a6a3-5731970e640f\"\/>" "$f"
            ;;
    esac
done

# https://github.com/WSTxda/ViperFX-RE-Releases
V4A_APK=$(curl -s ${GITHUB_TOKEN:+-H Authorization: token $GITHUB_TOKEN} \
    "https://api.github.com/repos/WSTxda/ViperFX-RE-Releases/releases/latest" | \
    sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p' | grep -i 'viper.*\.apk' | head -n1)

DOWNLOAD_FILE "$V4A_APK" "$WORK_DIR/system/system/preload/Viper4AndroidFX-RE/com.wstxda.viper4android==/base.apk"

while IFS= read -r i; do
    i="${i//$WORK_DIR\/system\//}"

    if [ -d "$WORK_DIR/system/$i" ]; then
        SET_METADATA "system" "$i" 0 0 755 "u:object_r:system_file:s0"
    else
        SET_METADATA "system" "$i" 0 0 644 "u:object_r:system_file:s0"
    fi

    if [[ "$i" == *".apk" ]] && \
            ! grep -q "$i" "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"; then
        LOG "- Adding \"$i\" to /system/system/etc/vpl_apks_count_list.txt"
        EVAL "echo \"$i\" >> \"$WORK_DIR/system/system/etc/vpl_apks_count_list.txt\""
    fi
done <<< "$(find "$WORK_DIR/system/system/preload")"

LOG_STEP_OUT

unset V4A CFGS V4A_APK