# Disable app compaction
# Guard the patch as the source firmware might have this already disabled
LOG "- Applying \"Disable app compaction\" to /system/system/framework/services.jar"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/appcompactor/services.jar/0001-Disable-app-compaction.patch" | true \
    > /dev/null

# Show battery regulatory info in Settings
# Requires SEM_BATTERY_PROPERTY_IC_AUTHENTICATION_RESULT support
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_GALAXYDIAGNOSTICS" "TRUE"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_SETTINGS" "TRUE"
