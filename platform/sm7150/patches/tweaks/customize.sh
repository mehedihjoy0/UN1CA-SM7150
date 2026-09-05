LOG_STEP_IN "- Removing performance capping"
DELETE_FROM_WORK_DIR "vendor" "etc/hyper"
DELETE_FROM_WORK_DIR "vendor" "etc/perf"
LOG_STEP_OUT

LOG_STEP_IN "- Removing WAV 32-bit PCM support"
SET_PROP "system" "media.extractor.sec.pcm-32bit" --delete
LOG_STEP_OUT

LOG_STEP_IN "- Replacing default zram size with 0"
EVAL "sed -i -E 's/zramsize=[^\"]*,/zramsize=0,/' \
\"$WORK_DIR/vendor/etc/fstab.ramplus\""
LOG_STEP_OUT