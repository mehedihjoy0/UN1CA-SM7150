LOG_STEP_IN "- Adding BixbyInterpeter from r0qxxx"
ADD_TO_WORK_DIR "r0qxxx" "system" "system/priv-app/BixbyInterpreter/BixbyInterpreter.apk"
LOG_STEP_OUT

LOG_STEP_IN "- Adding Routines from r0qxxx"
ADD_TO_WORK_DIR "r0qxxx" "system" "system/priv-app/Routines/Routines.apk"
LOG_STEP_OUT

LOG_STEP_IN "- Adding PhotoEditor_AIFull from r0qxxx"
DELETE_FROM_WORK_DIR "system" "system/priv-app/PhotoEditor_Full"
ADD_TO_WORK_DIR "r0qxxx" "system" "system/priv-app/PhotoEditor_AIFull/PhotoEditor_AIFull.apk"
LOG_STEP_OUT

LOG_STEP_IN "- Adding CTS from r0qxxx"
ADD_TO_WORK_DIR "r0qxxx" "product" "etc/sysconfig/google_searcle.xml"
ADD_TO_WORK_DIR "r0qxxx" "product" "etc/sysconfig/sysconfig_gemini.xml"
ADD_TO_WORK_DIR "r0qxxx" "product" "etc/sysconfig/sysconfig_contextual_search.xml"
ADD_TO_WORK_DIR "r0qxxx" "product" "overlay/DefaultContextualSearchOverlay.apk"
SET_PROP "product" "ro.com.google.cdb.spa1" "bsxasm1"
LOG_STEP_OUT