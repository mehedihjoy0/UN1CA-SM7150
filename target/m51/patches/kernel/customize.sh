LOG_STEP_IN "- Replacing the default kernel with LostPrime-Kernel"

# ----------------------------------------------------------------------------
# Function: DETECT_KERNEL_FORMAT
# Description: Detects the compression format of a kernel image by checking
#              magic bytes at the beginning of the file
# Parameters:
#   $1 - Path to the kernel image file
# Returns:
#   Prints format type: "gz", "lz4", or "raw" (uncompressed)
# ----------------------------------------------------------------------------
DETECT_KERNEL_FORMAT() {
    local file="$1"

    # Check for gzip magic bytes: 1F 8B
    if head -c2 "$file" | od -An -tx1 | grep -q "1f 8b"; then
        echo "gz"
        return
    fi

    # Check for lz4 magic bytes: 04 22 4D 18
    if head -c4 "$file" | od -An -tx1 | grep -q "04 22 4d 18"; then
        echo "lz4"
        return
    fi

    # If no compression magic bytes found, assume raw/uncompressed kernel
    echo "raw"
}

# ----------------------------------------------------------------------------
# Function: DOWNLOAD_KERNEL
# Description: Downloads the latest LostPrime-Kernel zip from GitHub releases
#              and prepares the temporary extraction directory
# ----------------------------------------------------------------------------
DOWNLOAD_KERNEL()
{
    # Clean up any existing temporary directory and create fresh extraction structure
    EVAL "rm -rf \"$TMP_DIR\""
    EVAL "mkdir -p \"$TMP_DIR/out/kernel_extracted\""

    # Fetch the latest release download URL from GitHub API
    KERNEL_REPO="https://api.github.com/repos/mehedihjoy0/android_kernel_samsung_sm7150/releases/latest"
    KERNEL_URL=$(curl -s ${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"} \
        "$KERNEL_REPO" | grep -o 'https://[^"]*m51-ksu[^"]*\.zip' | head -n1)
    
    # Set the local path for the downloaded kernel zip
    KERNEL_ZIP="$TMP_DIR/LostPrime-Kernel-m51.zip"
    
    # Download the kernel zip file
    LOG "- Downloading LostPrime-Kernel"
    DOWNLOAD_FILE "$KERNEL_URL" "$KERNEL_ZIP" || {
        ABORT "Failed to download LostPrime-Kernel zip"
        return 1
    }
}

# ----------------------------------------------------------------------------
# Function: EXTRACT_KERNEL
# Description: Extracts the downloaded kernel zip and unpacks the boot image
#              for patching
# ----------------------------------------------------------------------------
EXTRACT_KERNEL()
{
    # Extract the kernel zip to the temporary working directory
    LOG "- Extracting LostPrime-Kernel zip"
    EVAL "unzip -oq \"$KERNEL_ZIP\" -d \"$TMP_DIR/out/kernel_extracted\"" || {
        ABORT "Failed to extract LostPrime-Kernel zip"
        return 1
    }
    
    # Verify that the source boot image exists
    BOOT_FILE="boot.img"
    if [ ! -f "$WORK_DIR/kernel/$BOOT_FILE" ]; then
        ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/kernel/$BOOT_FILE"
        return 1
    fi
    
    # Copy the boot image to temporary directory and unpack it
    LOG "- Unpacking $BOOT_FILE"
    EVAL "cp -a \"$WORK_DIR/kernel/$BOOT_FILE\" \"$TMP_DIR/$BOOT_FILE\""
    
    # Temporarily disable exit-on-error to capture mkbootimg output
    set +e
    MKBOOT_FILEIMG_ARGS="$(unpack_bootimg --boot_img "$TMP_DIR/$BOOT_FILE" --out "$TMP_DIR/out" --format mkbootimg 2>&1)"
    RC=$?
    set -e
    
    # Check if unpack_bootimg succeeded
    if [ $RC != 0 ]; then
        LOGE "$MKBOOT_FILEIMG_ARGS"
        ABORT "unpack_bootimg failed for $BOOT_FILE"
        return 1
    fi

    # Find the unpacked kernel image (could be named kernel, Image, or zImage)
    OUT_KERNEL="$(find "$TMP_DIR/out" -maxdepth 1 -type f \( -name "kernel" -o -name "Image" -o -name "zImage" \) | LC_ALL=C sort | head -n 1)"
    if [ ! -f "$OUT_KERNEL" ]; then
        ABORT "Unpacked kernel slot not found"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Function: PATCH_KERNEL
# Description: Replaces the kernel in the boot image with the new custom kernel,
#              converting compression formats if necessary, and repacks
# ----------------------------------------------------------------------------
PATCH_KERNEL()
{
    # Verify that the dtbo image exists (device tree blob overlay)
    DTBO_FILE="dtbo.img"
    if [ ! -f "$WORK_DIR/kernel/$DTBO_FILE" ]; then
        ABORT "File not found: ${WORK_DIR//$SRC_DIR\//}/kernel/$DTBO_FILE"
        return 1
    fi

    # Locate kernel image and dtb files within the extracted zip
    KERNEL_IMG="$(find "$TMP_DIR/out/kernel_extracted" -type f \( -name "Image" -o -name "Image.gz" -o -name "Image.lz4" -o -name "zImage" \) | LC_ALL=C sort | head -n 1)"
    DTB_IMG="$TMP_DIR/out/kernel_extracted/dtb"
    DTBO_IMG="$TMP_DIR/out/kernel_extracted/dtbo.img"

    if [ ! -f "$KERNEL_IMG" ]; then
        ABORT "Kernel Image not found inside LostPrime-Kernel zip"
        return 1
    fi

    # Detect compression formats of both the existing and new kernel
    WORK_FMT=$(DETECT_KERNEL_FORMAT "$OUT_KERNEL")
    NEW_FMT=$(DETECT_KERNEL_FORMAT "$KERNEL_IMG")
    LOG "- Work kernel format: $WORK_FMT"
    LOG "- New kernel format: $NEW_FMT"

    # Convert kernel format if necessary to match the original boot image format
    if [[ "$WORK_FMT" != "$NEW_FMT" ]]; then
        LOG "- Converting kernel format ($NEW_FMT → $WORK_FMT)"

        case "$WORK_FMT" in
            # Convert to gzip format
            gz)
                if [[ "$NEW_FMT" == "raw" ]]; then
                    gzip -9 -c "$KERNEL_IMG" > "${KERNEL_IMG}.gz" || ABORT "gzip failed"
                    KERNEL_IMG="${KERNEL_IMG}.gz"
                elif [[ "$NEW_FMT" == "lz4" ]]; then
                    lz4 -d "$KERNEL_IMG" -c | gzip -9 > "${KERNEL_IMG}.gz" || ABORT "lz4→gz failed"
                    KERNEL_IMG="${KERNEL_IMG}.gz"
                fi
            ;;

            # Convert to lz4 format
            lz4)
                if [[ "$NEW_FMT" == "raw" ]]; then
                    lz4 -9 "$KERNEL_IMG" "${KERNEL_IMG}.lz4" || ABORT "lz4 failed"
                    KERNEL_IMG="${KERNEL_IMG}.lz4"
                elif [[ "$NEW_FMT" == "gz" ]]; then
                    gzip -d -c "$KERNEL_IMG" | lz4 -9 > "${KERNEL_IMG}.lz4" || ABORT "gz→lz4 failed"
                    KERNEL_IMG="${KERNEL_IMG}.lz4"
                fi
            ;;

            # Convert to raw/uncompressed format
            raw)
                if [[ "$NEW_FMT" == "gz" ]]; then
                    gzip -d -c "$KERNEL_IMG" > "${KERNEL_IMG%.gz}" || ABORT "gunzip failed"
                    KERNEL_IMG="${KERNEL_IMG%.gz}"
                elif [[ "$NEW_FMT" == "lz4" ]]; then
                    lz4 -d "$KERNEL_IMG" -c > "${KERNEL_IMG%.lz4}" || ABORT "lz4 decompress failed"
                    KERNEL_IMG="${KERNEL_IMG%.lz4}"
                fi
            ;;
        esac
    else
        LOG "- Kernel format already matches"
    fi

    # Replace the original kernel image with the new one
    LOG "- Replacing kernel Image"
    EVAL "cp -af \"$KERNEL_IMG\" \"$OUT_KERNEL\""

    # Handle device tree blob (dtb) if present in the zip
    if [ -f "$DTB_IMG" ]; then
        OUT_DTB="$(find "$TMP_DIR/out" -maxdepth 1 -type f -name "dtb" | LC_ALL=C sort | head -n 1)"
        if [ -f "$OUT_DTB" ]; then
            LOG "- Replacing dtb"
            EVAL "cp -af \"$DTB_IMG\" \"$OUT_DTB\""
        else
            LOGW "No separate dtb slot found"
        fi
    else
        LOGW "No dtb file found in zip"
    fi

    # Repack the boot image with the new kernel and dtb
    LOG "- Repacking $BOOT_FILE"
    EVAL "mkbootimg $MKBOOT_FILEIMG_ARGS -o \"$TMP_DIR/new-$BOOT_FILE\"" || {
        ABORT "mkbootimg failed"
        return 1
    }

    # Verify the repacked boot image isn't empty and replace the original
    if [ ! -s "$TMP_DIR/new-$BOOT_FILE" ]; then
        ABORT "Repacked boot image is empty"
        return 1
    else
        LOG "- Replacing $BOOT_FILE"
        EVAL "mv -f \"$TMP_DIR/new-$BOOT_FILE\" \"$WORK_DIR/kernel/$BOOT_FILE\""
    fi
    
    # Replace dtbo image if available
    if [ -f "$DTBO_IMG" ]; then
        LOG "- Replacing $DTBO_FILE"
        EVAL "mv -f \"$DTBO_IMG\" \"$WORK_DIR/kernel/$DTBO_FILE\""
    else
        LOGW "No dtbo.img found in zip"
    fi

    # Clean up temporary files
    EVAL "rm -rf \"$TMP_DIR\""
}

# ============================================================================
# Main execution flow
# ============================================================================

DOWNLOAD_KERNEL
EXTRACT_KERNEL
PATCH_KERNEL

LOG_STEP_OUT

unset -f DETECT_KERNEL_FORMAT DOWNLOAD_KERNEL EXTRACT_KERNEL PATCH_KERNEL
unset KERNEL_REPO KERNEL_URL KERNEL_ZIP BOOT_FILE KERNEL_IMG DTB_IMG OUT_KERNEL OUT_DTB MKBOOT_FILEIMG_ARGS RC