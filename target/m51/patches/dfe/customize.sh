LOG_STEP_IN "- Disabling force encryption in fstab files"
patch_fstab() {
    local file="$1"
    LINE=$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "${file}")
    sed -i "${LINE}s/,fileencryption=ice//g" "${file}"
}

for fstab in "${WORK_DIR}"/vendor/etc/fstab.*; do
    patch_fstab "$fstab"
done
LOG_STEP_OUT 

LOG_STEP_IN "- Removing frp"
SET_PROP "product" "ro.frp.pst" --delete
SET_PROP "vendor" "ro.frp.pst" --delete
LOG_STEP_OUT 

unset -f patch_fstab