DOWNLOAD_KERNEL()
{
    EVAL "rm -rf \"$TMP_DIR\""
    EVAL "mkdir -p \"$TMP_DIR/out/kernel_extracted\""

    KERNEL_REPO="https://api.github.com/repos/mehedihjoy0/android_kernel_samsung_sm7150/releases/latest"
    KERNEL_URL=$(curl -s ${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"} \
        "$KERNEL_REPO" | grep -o 'https://[^"]*m51-ksu[^"]*\.zip' | head -n1)
    
    KERNEL_ZIP="$TMP_DIR/LostPrime-Kernel-m51.zip"
    
    DOWNLOAD_FILE "$KERNEL_URL" "$KERNEL_ZIP"
}

EXTRACT_KERNEL()
{
    EVAL "unzip -oq \"$KERNEL_ZIP\" -d \"$TMP_DIR/out/kernel_extracted\""
    
    BOOT_FILE="boot.img"
    EVAL "cp -a \"$WORK_DIR/kernel/$BOOT_FILE\" \"$TMP_DIR/$BOOT_FILE\""
    
    MKBOOT_FILEIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/$BOOT_FILE" --out "$TMP_DIR/out" --format mkbootimg 2>&1)"

    OUT_KERNEL="$(find "$TMP_DIR/out" -maxdepth 1 -type f \( -name "kernel" -o -name "Image" -o -name "zImage" \) | LC_ALL=C sort | head -n 1)"
}

DETECT_KERNEL_FORMAT() {
    local file="$1"

    if head -c2 "$file" | od -An -tx1 | grep -q "1f 8b"; then
        echo "gz"
        return
    fi

    if head -c4 "$file" | od -An -tx1 | grep -q "04 22 4d 18"; then
        echo "lz4"
        return
    fi

    echo "raw"
}

PATCH_KERNEL()
{
    DTBO_FILE="dtbo.img"

    KERNEL_IMG="$(find "$TMP_DIR/out/kernel_extracted" -type f \( -name "Image" -o -name "Image.gz" -o -name "Image.lz4" -o -name "zImage" \) | LC_ALL=C sort | head -n 1)"
    DTB_IMG="$TMP_DIR/out/kernel_extracted/dtb"
    DTBO_IMG="$TMP_DIR/out/kernel_extracted/dtbo.img"

    WORK_FMT=$(DETECT_KERNEL_FORMAT "$OUT_KERNEL")
    NEW_FMT=$(DETECT_KERNEL_FORMAT "$KERNEL_IMG")

    if [[ "$WORK_FMT" != "$NEW_FMT" ]]; then
        case "$WORK_FMT" in
            gz)
                if [[ "$NEW_FMT" == "raw" ]]; then
                    gzip -9 -c "$KERNEL_IMG" > "${KERNEL_IMG}.gz"
                    KERNEL_IMG="${KERNEL_IMG}.gz"
                elif [[ "$NEW_FMT" == "lz4" ]]; then
                    lz4 -d "$KERNEL_IMG" -c | gzip -9 > "${KERNEL_IMG}.gz"
                    KERNEL_IMG="${KERNEL_IMG}.gz"
                fi
            ;;

            lz4)
                if [[ "$NEW_FMT" == "raw" ]]; then
                    lz4 -9 "$KERNEL_IMG" "${KERNEL_IMG}.lz4"
                    KERNEL_IMG="${KERNEL_IMG}.lz4"
                elif [[ "$NEW_FMT" == "gz" ]]; then
                    gzip -d -c "$KERNEL_IMG" | lz4 -9 > "${KERNEL_IMG}.lz4"
                    KERNEL_IMG="${KERNEL_IMG}.lz4"
                fi
            ;;

            raw)
                if [[ "$NEW_FMT" == "gz" ]]; then
                    gzip -d -c "$KERNEL_IMG" > "${KERNEL_IMG%.gz}"
                    KERNEL_IMG="${KERNEL_IMG%.gz}"
                elif [[ "$NEW_FMT" == "lz4" ]]; then
                    lz4 -d "$KERNEL_IMG" -c > "${KERNEL_IMG%.lz4}"
                    KERNEL_IMG="${KERNEL_IMG%.lz4}"
                fi
            ;;
        esac
    fi

    EVAL "cp -af \"$KERNEL_IMG\" \"$OUT_KERNEL\""

    if [ -f "$DTB_IMG" ]; then
        OUT_DTB="$(find "$TMP_DIR/out" -maxdepth 1 -type f -name "dtb" | LC_ALL=C sort | head -n 1)"
        if [ -f "$OUT_DTB" ]; then
            EVAL "cp -af \"$DTB_IMG\" \"$OUT_DTB\""
        fi
    fi

    EVAL "mkbootimg $MKBOOT_FILEIMG_ARGS -o \"$TMP_DIR/new-$BOOT_FILE\""

    EVAL "mv -f \"$TMP_DIR/new-$BOOT_FILE\" \"$WORK_DIR/kernel/$BOOT_FILE\""
    
    if [ -f "$DTBO_IMG" ]; then
        EVAL "mv -f \"$DTBO_IMG\" \"$WORK_DIR/kernel/$DTBO_FILE\""
    fi

    EVAL "rm -rf \"$TMP_DIR\""
}

DOWNLOAD_KERNEL
EXTRACT_KERNEL
PATCH_KERNEL

unset -f DETECT_KERNEL_FORMAT DOWNLOAD_KERNEL EXTRACT_KERNEL PATCH_KERNEL
unset KERNEL_REPO KERNEL_URL KERNEL_ZIP BOOT_FILE KERNEL_IMG DTB_IMG OUT_KERNEL OUT_DTB MKBOOT_FILEIMG_ARGS
