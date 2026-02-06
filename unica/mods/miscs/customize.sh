LOG_STEP_IN "- Adding BixbyInterpeter"
ADD_TO_WORK_DIR "pa3qxxx" "system" "system/priv-app/BixbyInterpreter"
LOG_STEP_OUT

LOG_STEP_IN "- Adding GoogleCTS"
DOWNLOAD_FILE "https://appteka.store/get/e2VT2_UvCKdz01Quc1RwUb6KyWab2XRC4yLWKzTNh6pZsU84-iJu_KlYpfSb4Qafr0ntDjaz31JvidmwBdsn/com.google.android.cts_1.0_1.apk" "$WORK_DIR/system/system/app/GoogleCTS/GoogleCTS.apk"
LOG_STEP_OUT

while IFS= read -r i; do
    i="${i//$WORK_DIR\/system\//}"

    if [ -d "$WORK_DIR/system/$i" ]; then
        SET_METADATA "system" "$i" 0 0 755 "u:object_r:system_file:s0"
    else
        SET_METADATA "system" "$i" 0 0 644 "u:object_r:system_file:s0"
    fi
done <<< "$(find "$WORK_DIR/system/system/app")"