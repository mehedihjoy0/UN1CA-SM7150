TARGET_FIRMWARE_DEST="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

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

ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "system" "system/lib64/libsecimaging_pdk.camera.samsung.so"

LOG_STEP_IN "- Replacing HIDL snap HAL with AIDL from extra"
BLOBS_LIST="
bin/hw/vendor.samsung.hardware.snap@1.2-service
etc/init/vendor.samsung.hardware.snap@1.2-service.rc
lib/vendor.samsung.hardware.snap@1.0.so
lib/vendor.samsung.hardware.snap@1.1.so
lib/vendor.samsung.hardware.snap@1.2.so
lib64/vendor.samsung.hardware.snap@1.0.so
lib64/vendor.samsung.hardware.snap@1.1.so
lib64/vendor.samsung.hardware.snap@1.2.so
"
for blob in $BLOBS_LIST; do
    DELETE_FROM_WORK_DIR "vendor" "$blob"
done

BLOBS_LIST="
bin/hw/vendor.samsung.hardware.snap-service
etc/init/vendor.samsung.hardware.snap-default.rc
lib64/libsnap_compute.so
lib64/libsnap_compute_wrapper.so
lib64/libsnap_v1.samsung.so
lib64/libsnap_vndk.so
lib64/libsnaplite_native.so
lib64/libsnaplite_wrapper.so
lib64/vendor.samsung.hardware.snap-V1-ndk_platform.so
"
for blob in $BLOBS_LIST; do
    ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "vendor" "$blob"
done

EVAL "sed -i '/<hal format=\"hidl\" optional=\"true\">/{N; /vendor.samsung.hardware.snap/{N;N;N;N;N;N;N; s|.*|\
    <hal format=\"aidl\">\n\
        <name>vendor.samsung.hardware.snap</name>\n\
        <version>3</version>\n\
        <interface>\n\
            <name>ISehSnap</name>\n\
            <instance>default</instance>\n\
        </interface>\n\
    </hal>|}}' \
    \"$SRC_DIR/target/$TARGET_CODENAME/vintf/compatibility_matrix.device.xml\""

EVAL "sed -i '/<hal format=\"hidl\">/{N; /vendor.samsung.hardware.snap/{N;N;N;N;N;N;N;N; s|.*|\
    <hal format=\"aidl\">\n\
        <name>vendor.samsung.hardware.snap</name>\n\
        <fqname>ISehSnap/default</fqname>\n\
    </hal>|}}' \
    \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT

LOG_STEP_IN "- Fixing portrait preview"
EVAL "sed -i '/\"LD_FD_engine\"/,/}/ s/\"mode_preview\": null/\"mode_preview\": \"true\"/' \
    \"$TARGET_FIRMWARE_DEST/system/system/cameradata/portrait_data/single_bokeh_feature.json\""
LOG_STEP_OUT

LOG_STEP_IN "- Patching /vendor/ueventd.rc"
EVAL "cat \"$MODPATH/ueventd.rc.diff\" >> \"$WORK_DIR/vendor/ueventd.rc\""
LOG_STEP_OUT

unset TARGET_FIRMWARE_DEST