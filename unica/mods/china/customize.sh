LOG_STEP_IN "- Removing Device Care & SAppLock"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.lool.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.sm.devicesecurity_v6.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/signature-permissions-com.samsung.android.lool.xml"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SmartManager_v5"
DELETE_FROM_WORK_DIR "system" "system/app/SmartManager_v6_DeviceSecurity"
DELETE_FROM_WORK_DIR "system" "system/priv-app/SAppLock"
LOG_STEP_OUT 

LOG_STEP_IN "- Injecting China apps from China firmware"
ADD_TO_WORK_DIR "e1qzcx" "system" "."
LOG_STEP_OUT

LOG_STEP_IN "- Adding AppLock support"
SMALI_PATCH "system" "system/framework/framework.jar" "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replaceall" \
    "sput-boolean v1, Lcom/samsung/android/rune/CoreRune;->FW_SUPPORT_APPLOCK:Z" \
    "const/4 v1, 0x1\n\n    sput-boolean v1, Lcom/samsung/android/rune/CoreRune;->FW_SUPPORT_APPLOCK:Z"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk"\
    "smali_classes3/com/samsung/android/settings/usefulfeature/applock/AppLockPreferenceController.smali"\
    "return" "getAvailabilityStatus()I" "0"
LOG_STEP_OUT

LOG_STEP_IN "- Patching floating_feature.xml"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SMARTMANAGER_CONFIG_PACKAGE_NAME" "com.samsung.android.sm_cn"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SECURITY_CONFIG_DEVICEMONITOR_PACKAGE_NAME" "com.samsung.android.sm.devicesecurity"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_NAL_PRELOADAPP_REGULATION" "TRUE"
LOG_STEP_OUT