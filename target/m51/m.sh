WORK_DIR="/data/local/UnpackerSystem"
MODPATH="/data/data/com.termux/files/home/M51/target/m51/patches/_m51ify"
REMOVAL_LIST="$(cd "$WORK_DIR/vendor/etc/audconf" 2>/dev/null && find -type d -print 2>/dev/null | sort || true)"
while IFS= read -r file; do 
    [ -z "$file" ] && continue
    echo "$file"
    [ ! -d "$MODPATH/vendor/etc/audconf/$file" ] && rm -rf "$WORK_DIR/vendor/etc/audconf/$file"
done <<< "$REMOVAL_LIST"