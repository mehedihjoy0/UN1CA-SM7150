LOG_STEP_IN "- Adding bluetooth audio HAL from extra"
BLOBS_LIST="
bin/hw/android.hardware.audio.service
etc/bluetooth_audio_policy_configuration.xml
lib/libsehbluetooth_audio_session.so
lib/vendor.samsung.hardware.bluetooth.audio@2.0.so
lib/vendor.samsung.hardware.bluetooth.audio@2.1.so
lib/hw/audio.bluetooth.default.so
lib/hw/vendor.samsung.hardware.bluetooth.audio@2.1-impl.so
lib64/libsehbluetooth_audio_session.so
lib64/vendor.samsung.hardware.bluetooth.audio@2.0.so
lib64/vendor.samsung.hardware.bluetooth.audio@2.1.so
lib64/hw/audio.bluetooth.default.so
lib64/hw/vendor.samsung.hardware.bluetooth.audio@2.1-impl.so
"
for blob in $BLOBS_LIST; do
    ADD_TO_WORK_DIR "$TARGET_EXTRA_FIRMWARES" "vendor" "$blob"
done

EVAL "sed -i '/<!-- hidden sound Audio HAL -->/s|^|\
        <!-- Bluetooth Audio HAL -->\n\
        <xi:include href=\"bluetooth_audio_policy_configuration.xml\"/>\n\n|' \
        \"$WORK_DIR/vendor/etc/audio_policy_configuration_base.xml\""

EVAL "sed -i '/<name>vendor\.samsung\.hardware\.bluetooth<\/name>/ {
    :a
    N
    /<\/hal>/!ba
    s|.*|&\n\
    <hal format=\"hidl\">\n\
        <name>vendor.samsung.hardware.bluetooth.audio<\/name>\n\
        <transport>hwbinder<\/transport>\n\
        <version>2.1<\/version>\n\
        <interface>\n\
            <name>ISehBluetoothAudioProvidersFactory<\/name>\n\
            <instance>default<\/instance>\n\
        <\/interface>\n\
        <fqname>@2.1::ISehBluetoothAudioProvidersFactory\/default<\/fqname>\n\
    <\/hal>|
}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT