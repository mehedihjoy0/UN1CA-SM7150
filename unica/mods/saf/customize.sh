LOG_STEP_IN "- Removing SAF restriction from all directories"
SMALI_PATCH "system" "system/priv-app/ExternalStorageProvider/ExternalStorageProvider.apk" \
    "smali/com/android/externalstorage/ExternalStorageProvider.smali" \
    "return" "shouldBlockDirectoryFromTree(Ljava/lang/String;)Z" "false"
SMALI_PATCH "system" "system/priv-app/ExternalStorageProvider/ExternalStorageProvider.apk" \
    "smali/com/android/externalstorage/ExternalStorageProvider.smali" \
    "return" "shouldHideDocument(Ljava/lang/String;)Z" "false"
LOG_STEP_OUT