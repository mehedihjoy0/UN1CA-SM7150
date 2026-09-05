TARGET_FIRMWARE_DEST="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

LOG_STEP_IN "- Adding SoundBooster libs from stock"
for f in "$WORK_DIR"/system/system/lib/lib_SAG_EQ_ver*.so; do
    DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"
done
for f in "$WORK_DIR"/system/system/lib64/lib_SAG_EQ_ver*.so; do
    DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"
done

for f in "$WORK_DIR"/system/system/lib/lib_SoundBooster_ver*.so; do
    DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"
done
for f in "$TARGET_FIRMWARE_DEST"/system/system/lib/lib_SoundBooster_ver*.so; do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/${f##*/}"
done

for f in "$WORK_DIR"/system/system/lib64/lib_SoundBooster_ver*.so; do
    DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"
done
for f in "$TARGET_FIRMWARE_DEST"/system/system/lib64/lib_SoundBooster_ver*.so; do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/${f##*/}"
done

for f in "$WORK_DIR"/system/system/lib/lib_SoundAlive_play_plus_ver*.so; do
    DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"
done
for f in "$TARGET_FIRMWARE_DEST"/system/system/lib/lib_SoundAlive_play_plus_ver*.so; do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/${f##*/}"
done

for f in "$WORK_DIR"/system/system/lib64/lib_SoundAlive_play_plus_ver*.so; do
    DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"
done
for f in "$TARGET_FIRMWARE_DEST"/system/system/lib64/lib_SoundAlive_play_plus_ver*.so; do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/${f##*/}"
done

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libaudiosaplus_sec_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libsamsungSoundbooster_plus_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so"
LOG_STEP_OUT

LOG_STEP_IN "- Increasing audio offload buffer size"
SET_PROP "vendor" "vendor.audio.offload.buffer.size.kb" "256"
LOG_STEP_OUT

LOG_STEP_IN "- Increasing speaker volume values to 90"
EVAL "sed -i -E '/WSA_RX[01] Digital Volume/s/value=\"[^\"]*\"/value=\"90\"/' \
\"$WORK_DIR\"/vendor/etc/mixer_paths*.xml"
LOG_STEP_OUT

unset TARGET_FIRMWARE_DEST