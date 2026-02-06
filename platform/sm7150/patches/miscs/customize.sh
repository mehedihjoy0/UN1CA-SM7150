LOG_STEP_IN "- Adding \"ro.netflix.bsp_rev\" prop with \"Q7250-19133-1\" in /system/system/build.prop"
SET_PROP "system" "ro.netflix.bsp_rev" "Q7250-19133-1"
LOG_STEP_OUT 

LOG_STEP_IN "- Removing frp"
SET_PROP "product" "ro.frp.pst" --delete
SET_PROP "vendor" "ro.frp.pst" --delete
LOG_STEP_OUT 

LOG_STEP_IN "- Removing media.extractor.sec.pcm-32bit"
SET_PROP "system" "media.extractor.sec.pcm-32bit" --delete
LOG_STEP_OUT 

LOG_STEP_IN "- Fixing edge lighting"
SET_PROP "system" "ro.factory.model" "SM-M515F"
LOG_STEP_OUT 

LOG_STEP_IN "- Increasing audio buffer size to 1024"
SET_PROP "vendor" "vendor.audio.offload.buffer.size.kb" "1024"
LOG_STEP_OUT 

LOG_STEP_IN "- Adding tlc from source"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "bin/hw/vendor.samsung.hardware.tlc.iccc@1.0-service"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "etc/init/vendor.samsung.hardware.tlc.iccc@1.0-service.rc"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.tlc.iccc@1.0.so"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.tlc.iccc@1.0-impl.so"
LOG_STEP_OUT