if [[ "$BUILD_TYPE" == "-decrypted" ]]; then
	LOG "- Disabling force encryption"
	EVAL "sed -i -E 's/^([^#].*?)fileencryption=[^,]*(.*)$/# &\n\1encryptable\2/' \
	    \"$WORK_DIR/vendor/etc/fstab.\"*\"\""
	
	LOG "- Removing frp"
	SET_PROP "product" "ro.frp.pst" --delete
	SET_PROP "vendor" "ro.frp.pst" --delete
fi