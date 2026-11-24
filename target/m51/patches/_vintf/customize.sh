TARGET_FIRMWARE_DEST="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

EVAL "mkdir -p \"$SRC_DIR/target/$TARGET_CODENAME/vintf\""
EVAL "cp -af \"$TARGET_FIRMWARE_DEST/system/system/etc/vintf/compatibility_matrix.device.xml\" \"$SRC_DIR/target/$TARGET_CODENAME/vintf\""

EVAL "sed -i -E '/<compatibility-matrix/s/version=\"[^\"]*\"/version=\"9.0\"/' \
    \"$SRC_DIR/target/$TARGET_CODENAME/vintf/compatibility_matrix.device.xml\""
    
EVAL "sed -i -z 's|<sepolicy-version>[0-9]*\.0</sepolicy-version>\(.*\n[[:space:]]*<sepolicy-version>[0-9]*\.0</sepolicy-version>\)*|\
<sepolicy-version>29.0</sepolicy-version>\n\
        <sepolicy-version>30.0</sepolicy-version>\n\
        <sepolicy-version>31.0</sepolicy-version>\n\
        <sepolicy-version>32.0</sepolicy-version>\n\
        <sepolicy-version>33.0</sepolicy-version>\n\
        <sepolicy-version>34.0</sepolicy-version>\n\
        <sepolicy-version>202404</sepolicy-version>\n\
        <sepolicy-version>202504</sepolicy-version>|g' \
    \"$SRC_DIR/target/$TARGET_CODENAME/vintf/compatibility_matrix.device.xml\""

unset TARGET_FIRMWARE_DEST