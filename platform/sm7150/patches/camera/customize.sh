LOG_STEP_IN "- Adding Polarr libs from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/etc/public.libraries-polarr.txt"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libBestComposition.polarr.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libFeature.polarr.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libPolarrSnap.polarr.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libTracking.polarr.so"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libYuv.polarr.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding camera libs from stock"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/liblow_light_hdr.arcsoft.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_dynamic_range.arcsoft.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking.arcsoft.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking_util.camera.samsung.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libveengine.arcsoft.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding secimaging_pdk lib from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libsecimaging_pdk.camera.samsung.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding snaplite_native lib from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "lib64/libsnaplite_native.so"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing MIDAS blobs with a73xqxx"
DELETE_FROM_WORK_DIR "vendor" "etc/midas"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "etc/midas"
LOG_STEP_OUT