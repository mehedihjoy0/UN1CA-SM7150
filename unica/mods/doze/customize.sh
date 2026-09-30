LOG_STEP_IN "- Applying extreme doze"
DELETE_FROM_WORK_DIR "system" "system/etc/deviceidle"
DELETE_FROM_WORK_DIR "system" "system/etc/broadcast_allowlist.xml"

# Array of package names to whitelist
WHITELIST_APPS=(
    "com.android.vending"
    "com.samsung.android.app.sharelive"
    "com.samsung.android.bluelightfilter"
    "com.samsung.android.audiomirroring"
    "com.samsung.android.app.contacts"
)

# Convert array into a regex pattern using native parameter expansion
WHITELIST_REGEX=$(IFS='|'; echo "${WHITELIST_APPS[*]}")
WHITELIST_REGEX="${WHITELIST_REGEX//./\\.}"

# Single-pass tag removal covering permissions and sysconfig
EVAL "find \"$WORK_DIR\" -type f \( -path '*/etc/permissions/*.xml' -o -path '*/etc/sysconfig/*.xml' \) -exec \
    sed -i -E '/$WHITELIST_REGEX/b; /<(allow-(in-(power|data-usage)-save(-except-idle)?|(unthrottled|ignore)-(location|alarms?)(-settings)?|implicit-broadcast|background-activity-starts|auto-restarter|in-app-standby)|(bg-restriction|app-standby|system|cached-app-freezer)-exemption|system-component|auto-start-whitelist)[[:space:]]/d' {} +"
LOG_STEP_OUT
