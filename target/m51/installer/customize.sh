LOG_STEP_IN "- Adding the latest modified DXE4 firmwares of Galaxy M51"
git clone https://github.com/mehedihjoy0/M51-FIRMWARE $TMP_DIR/M51-FIRMWARE

local FIRMWARES=$(find "$TMP_DIR/M51-FIRMWARE" -type f -print)

for split_firmware in $FIRMWARES; do
  base_firmware="${split_firmware%.??}"
  if [[ "$split_firmware" =~ \.[0-9][0-9]$ ]] && [ -e "$base_firmware.00" ]; then
    if cat "$base_firmware".?? > "$base_firmware" 2>/dev/null; then
       rm -f "$base_firmware".??        
     fi
  fi
done

mv $TMP_DIR/M51-FIRMWARE/* $TMP_DIR
rm -rf $TMP_DIR/M51-FIRMWARE
LOG_STEP_OUT

