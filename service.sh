#!/system/bin/sh
MODDIR=${0%/*}

# redefine to unify code between customize.sh and service.sh
CURRENT_MODPATH="$MODDIR"

umask 022

# For system apk copy
TMPDIR=/dev/tmp
rm -rf $TMPDIR 2>/dev/null
mkdir -p $TMPDIR

search_for_apk() {
	MODULE_PROP="$CURRENT_MODPATH/module.prop"
	APK_NAME=""
	APK_PATH=""
	FOUND_APKS=""
	NFC_APPS='NfcNci NQNfcNci NxpNfcNci Nfc_st' #Nfc NfcService NfcGoogle PixelNfc'
	NFC_DIRS='/system/app /system/system_ext/app /system_ext/app /system/priv-app /system/system_ext/priv-app /system_ext/priv-app /vendor/app /vendor/priv-app /product/app /product/priv-app /data/app'
	NFC_DIRS_FILTERED=""
	is_in_list() {
		local dir="$1"
		local list="$2"
		for item in $list; do
			if [ "$item" = "$dir" ]; then
				return 0
			fi
		done
		return 1
	}
	# resolve symlinks, remove duplicates & null
	for dir in $NFC_DIRS; do
		if [ -d "$dir" ]; then
			real_path=$(readlink -f "$dir")
			if ! is_in_list "$real_path" "$NFC_DIRS_FILTERED"; then
				NFC_DIRS_FILTERED="$NFC_DIRS_FILTERED $real_path"
				#
				#
			fi
		#
			#
		fi
	done
	#
	#
	#
	#
	ui_print "-- Searching for NFC apk..."
	for name in $NFC_APPS; do
		for dir in $NFC_DIRS_FILTERED; do
			if [ -d "$dir/$name" ]; then
				APK_PATH="$dir/$name/$name.apk"
				if [ -f "$APK_PATH" ]; then
					FOUND_APKS="$FOUND_APKS$APK_PATH "
				fi
			fi
		done
	done
	#
	#
	#
	if [ -n "$FOUND_APKS" ]; then
		FIRST_APK=$(echo $FOUND_APKS | awk '{print $1}')
		APK_PATH="$FIRST_APK"
		APK_NAME=$(basename $(dirname "$FIRST_APK"))
	fi
	if [ -z "$APK_NAME" ]; then
		#
		#
		#
		#
		#
		#
		#
		#
		ECHO_MOVED1='NFC apk has moved and needs to be located & repatched.'
		ECHO_MOVED2='Open Magisk, enable module, update; submit an issue on github, if not.'
		SED_VER="sed -i 's/^versionCode=.*/versionCode=0/' \"$MODULE_PROP\""
		SED_DESC="sed -i 's/^description=.*/description=UPDATE is NECESSARY.  $ECHO_MOVED1  $ECHO_MOVED2./' \"$MODULE_PROP\""
		DO_PATCH=0
	else
		#
		APK_BOOT="$CURRENT_MODPATH/${APK_NAME}_boot.apk"
		APK_BAK="$CURRENT_MODPATH/${APK_NAME}_bak.apk"
		APK_ALIGN="$CURRENT_MODPATH/${APK_NAME}_align.apk"
		APK_DIR="$(dirname $APK_PATH)"
		cp -f "$APK_PATH" "$TMPDIR/$APK_NAME.apk"
		cp -f "$TMPDIR/$APK_NAME.apk" "$MODDIR/${APK_NAME}_boot.apk"
		DO_PATCH=1
	fi
	#
}

repatch_check() {
	MD5_BOOT=$(md5sum "$APK_BOOT" | awk '{ print $1 }')
	MD5_BAK=$(md5sum "$APK_BAK" | awk '{ print $1 }')
	if [ "$MD5_BOOT" != "$MD5_BAK" ]; then
		#
		ECHO_REPATCH='NFC apk has updated and needs to be repatched.  Open Magisk, enable module, update.'
		SED_VER="sed -i 's/^versionCode=.*/versionCode=0/' \"$MODULE_PROP\""
		SED_DESC="sed -i 's/^description=.*/description=UPDATE is NECESSARY.  $ECHO_REPATCH/' \"$MODULE_PROP\""
		touch "$CURRENT_MODPATH/boot_repatch"
		chmod 0644 "$CURRENT_MODPATH/boot_repatch"
		DO_PATCH=0
		#
	fi
}

inject_apk() {
	mv "$APK_ALIGN" "$MODDIR/$APK_NAME.apk"
	killall com.android.nfc
	mount --bind "$MODDIR/$APK_NAME.apk" "$APK_DIR/$APK_NAME.apk"
	# whitelist to persist while screen off, below
	#dumpsys deviceidle whitelist +com.android.nfc #debug
	sleep 1
	killall com.android.nfc
	rm -rf $TMPDIR 2>/dev/null
}

is_screen_unlocked() {
	local unlocked=$(dumpsys window | grep -E 'mDreamingLockscreen=(false|true)|DreamingLockscreen=(false|true)' | grep 'false')
	if [ -n "$unlocked" ]; then
		true
	else
		false
	fi
}

# script execution
resetprop -w sys.boot_completed 0
sleep 35 # wait for nfc service; time for cyclical reboot abort
rm -f "$CURRENT_MODPATH/boot_repatch"
search_for_apk
if [ "$DO_PATCH" = "1" ]; then
	repatch_check
fi
if [ "$DO_PATCH" = "1" ]; then
	inject_apk
fi
if [ "$DO_PATCH" = "0" ]; then
	touch "$CURRENT_MODPATH/disable"
	chmod 0644 "$CURRENT_MODPATH/disable"
	eval $SED_VER
	eval $SED_DESC
	TERMUX='/data/data/com.termux/files/usr/bin/termux-notification'
	if [ -x "$TERMUX" ]; then
		while ! is_screen_unlocked; do
			sleep 5
		done
		sleep 3
		su -c "$TERMUX --priority 'max' --title 'NFCScreenOff' --content 'Disabled: $ECHO_REPATCH $ECHO_MOVED1 $ECHO_MOVED2' --button1 'Github Releases' --button1 'Github Issues/Status' --button1-action 'am start -a android.intent.action.VIEW -d https://github.com/Jon8RFC/NfcScreenOff/issues'"
	fi
fi
