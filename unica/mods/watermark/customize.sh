LOG_STEP_IN "- Removing \"AI-generated content\" watermark from all desired apps"

DESIRED_APPS="
system/app/SketchBook/SketchBook.apk
system/priv-app/DressRoom/DressRoom.apk
system/priv-app/PhotoEditor_AIFull/PhotoEditor_AIFull.apk
system/priv-app/SpriteWallpaper/SpriteWallpaper.apk
"

for APP in $DESIRED_APPS
do
    # Decode apks
    DECODE_APK "system" "$APP"
    
    LOG "- Removing watermark from $APP"
    
    # Replace AI-generated strings with a non-breaking space (U+00A0)
    find "$APKTOOL_DIR/$APP" -name "strings.xml" \
        -exec sed -i $'s/>AI-generated content</>\u00A0</g; s/>AI-generated</>\u00A0</g' {} +
    
    # Replace watermark drawables with transparent vectors
    find "$APKTOOL_DIR/$APP" -name "*watermark*.xml" \
        -exec sh -c 'cat > "$1" << "EOF"
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:height="3.0dp"
    android:width="3.0dp"
    android:viewportWidth="3.0"
    android:viewportHeight="3.0">
    <path
        android:fillColor="#00000000"
        android:pathData="M0,0h3v3h-3z" />
</vector>
EOF' _ {} \;
done

LOG_STEP_OUT

unset DESIRED_APPS