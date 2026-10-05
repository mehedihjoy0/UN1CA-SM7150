LOG_STEP_IN "- Adding latest modified firmwares for Galaxy M51"
EVAL "git clone \"https://github.com/mehedihjoy0/M51-FIRMWARES\" \"$TMP_DIR/M51-FIRMWARES\""
EVAL "rm -rf \"$TMP_DIR/M51-FIRMWARES/.git\""

find "$TMP_DIR/M51-FIRMWARES" -type f -name '*.??' -exec sh -c 'b=${0%.*};[ -e $b.00 ]&&cat $b.??>$b&&rm $b.??' {} \;

EVAL "mv \"$TMP_DIR/M51-FIRMWARES/\"* \"$TMP_DIR\""
EVAL "rm -rf \"$TMP_DIR/M51-FIRMWARES\""
LOG_STEP_OUT

