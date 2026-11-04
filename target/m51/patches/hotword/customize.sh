TARGET_EXTRA_FIRMWARES_DEST="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_EXTRA_FIRMWARES")_$(cut -d "/" -f 2 -s <<< "$TARGET_EXTRA_FIRMWARES")"

LOG_STEP_IN "- Adding Google Hotword Enrollment apps from extra"
for f in "$WORK_DIR"/product/priv-app/HotwordEnrollment*; do
    DELETE_FROM_WORK_DIR "product" "priv-app/${f##*/}"
done

for f in "$TARGET_EXTRA_FIRMWARES_DEST"/product/priv-app/HotwordEnrollment*; do
    ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "product" "priv-app/${f##*/}"
done
LOG_STEP_OUT

unset TARGET_EXTRA_FIRMWARES_DEST