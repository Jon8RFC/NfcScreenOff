#!/system/bin/sh
MODDIR=${0%/*}

umask 022

# For system apk copy
TMPDIR=/dev/tmp
rm -rf $TMPDIR 2>/dev/null
mkdir -p $TMPDIR

set 'NfcNci' 'NQNfcNci' 'NxpNfcNci' 'Nfc_st'
for name do
	if [ -d "/system/app/$name" ]; then
		APK_NAME="$name"
		APK_PATH="/system/app/$APK_NAME/$APK_NAME.apk"
	fi
	if [ -d "/system/system_ext/app/$name" ]; then
		APK_NAME="$name"
		APK_PATH="/system/system_ext/app/$APK_NAME/$APK_NAME.apk"
	fi
done

# APK_PATH="/system/app/$APK_NAME/$APK_NAME.apk"
APK_DIR="$(dirname $APK_PATH)"

# Copy system/boot apk before it's replaced
cp -f "$APK_PATH" "$TMPDIR/$APK_NAME.apk"
cp -f "$TMPDIR/$APK_NAME.apk" "$MODDIR/${APK_NAME}_boot.apk"

# wait for nfc service to start
sleep 35

# inject modded apk
mkdir "$MODDIR/$APK_NAME"
cp "$MODDIR/${APK_NAME}_align.apk" "$MODDIR/$APK_NAME/$APK_NAME.apk"
killall com.android.nfc
mount --bind "$MODDIR/$APK_NAME" "$APK_DIR"

# whitelist to persist while screen off
#dumpsys deviceidle whitelist +com.android.nfc #debug

# restart nfc service
sleep 1
killall com.android.nfc
rm -rf $TMPDIR 2>/dev/null
