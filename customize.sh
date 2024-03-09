#!/system/bin/sh

# since update-binary changes modules to modules_update if $BOOTMODE=true
CURRENT_MODPATH="$NVBASE"/modules/"$MODID"

# source fallback binaries
chmod -R +x "$MODPATH/bin"
export PATH="$PATH:$MODPATH/bin"

DO_PATCH=1
PATCH_URL="https://patcher.jon8rfc.com"
ISSUES_URL=https://github.com/Jon8RFC/NfcScreenOff/issues

my_grep_prop() {
	local REGEX="s/$1=//p"
	shift
	local FILES=$@
	[ -z "$FILES" ] && FILES='/system/build.prop /vendor/build.prop /product/build.prop'
	sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

create_backup() {
	local path="$1"
	local filename="${path##*/}"
	local extension="${filename##*.}"
	filename="${filename%.*}"
	ui_print "-- Searching for $filename.$extension backup..."
	if [ -f "$CURRENT_MODPATH/${filename}_bak.$extension" ]; then
			if [[ "$REPATCH" = 1 ]] && [ -f "$APK_BOOT" ]; then
				ui_print "   ${APK_NAME}_boot.apk found. Copying newer backup to the module update folder."
				cp "$APK_BOOT" "$MODPATH/${filename}_bak.$extension"
			else
				ui_print "   ${filename}_bak.$extension found. Copying backup to the module update folder."
				cp "$CURRENT_MODPATH/${filename}_bak.$extension" "$MODPATH/${filename}_bak.$extension"
			fi
	else
		ui_print "   ${filename}_bak.$extension not found. Creating backup of original $filename.$extension."
		cp "$path" "$MODPATH/${filename}_bak.$extension"
	fi
}

check_http_response() {
	RESPONSE_CODE=$(echo "$RESPONSE" | tail -n1)
	RESPONSE_TEXT=$(echo "$RESPONSE" | sed '$d')
	# first, to show response code & text
	if [[ "$RESPONSE_CODE" = 200 ]]; then
		ui_print "   HTTP Response: $RESPONSE_CODE (SUCCESS)"; ui_print "";
	elif [[ "$ZIP_ERROR" != 1 ]]; then
		ui_print "   HTTP Response: $RESPONSE_CODE"; ui_print "$RESPONSE_TEXT" | fold -s; ui_print "";
	elif [[ "$ZIP_ERROR" = 1 ]]; then
		ui_print "!! CLIENT ZIP ERROR !!"; ui_print "";
	fi
	if [[ "$curl_exit_status" -ne 0 ]]; then ui_print "!! cURL failed with exit status $curl_exit_status."; fi
	if [[ "$curl_exit_status" -ne 0 && "$RESPONSE_CODE" != 000 ]]; then ui_print "   Check your connection."; ui_print "   If you have customized this or run a server,"; ui_print "   check the URL, server, firewall,"; ui_print "   and local network settings."; ui_print ""; DO_PATCH=0; fi
	if [[ "$curl_exit_status" -ne 0 && "$SERVER_TEST" = 1 ]]; then ui_print "!! Your device may not properly support cURL."; ui_print ""; ui_print ""; DO_PATCH=0; fi
	if [[ "$RESPONSE_CODE" = 000 ]]; then ui_print "!! URL, DNS, timeout, or client network issue."; ui_print ""; ui_print "   Check your connection."; ui_print "   If you have customized this or run a server,"; ui_print "   check the URL, server, firewall,"; ui_print "   and local network settings."; DO_PATCH=0; fi
	if [[ "$RESPONSE_CODE" = 3?? ]]; then ui_print "!! Server-side network configuration issue, or maintenance."; ui_print "   Try again in a few hours."; DO_PATCH=0; fi
	if [[ "$RESPONSE_CODE" = 4?? ]]; then ui_print "!! URL, network/server issue, or maintenance."; ui_print "   Try again in a few hours."; ui_print ""; ui_print "Check here for updates/info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
	if [[ "$RESPONSE_CODE" = 5?? && "$RESPONSE_CODE" != 545 && "$RESPONSE_CODE" != 555 ]]; then ui_print "!! URL, network/server issue, or maintenance."; ui_print "Try again in a few hours."; ui_print ""; ui_print "   Check here for updates/info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
	if [[ "$RESPONSE_CODE" = 7?? ]]; then DO_PATCH=1; fi
	if [[ "$RESPONSE_CODE" = 8?? ]]; then DO_PATCH=0; fi
	if [[ "$RESPONSE_CODE" = 9?? && "$RESPONSE_CODE" != 999 ]]; then WAIT_HOURS="${RESPONSE_CODE:1}"; ui_print "!! Server maintenance."; ui_print "   Try again in $WAIT_HOURS hours"; ui_print ""; ui_print "   Check here for updates/info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
	if [[ "$RESPONSE_CODE" = 999 ]]; then ui_print "!! Server permanently/indefinitely shutdown."; ui_print ""; ui_print "Check here for info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
}

check_for_apk() {
ui_print "-- Searching for NFC app in /system/app/ and /system/system_ext/app/ folders..."
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
if [ -z "$APK_NAME" ]; then
	ui_print "!! Could not find any of ${APK_NAMES[*]} in /system/app/ or /system/system_ext/app/ Your phone may not be compatible with NFC technology."
	DO_PATCH=0
else
	ui_print "   $APK_NAME.apk found!"
	DO_PATCH=1
fi
mkdir "$MODPATH/$APK_NAME"
}

get_device_info() {
	DATE_ID="$(date +%s%N)_"
	MOD_VER="j$(grep_prop versionCode $MODPATH/module.prop)"
	MANUFACTURER="$(my_grep_prop 'ro.product.manufacturer')"
	[ -z "$MANUFACTURER" ] && MANUFACTURER="$(my_grep_prop 'ro.product.vendor.manufacturer')"
	[ -z "$MANUFACTURER" ] && MANUFACTURER="$(my_grep_prop 'ro.product.vendor.brand')"
	[ -z "$MANUFACTURER" ] && MANUFACTURER="$(my_grep_prop 'ro.product.system.manufacturer')"
	[ -z "$MANUFACTURER" ] && MANUFACTURER="$(my_grep_prop 'ro.product.system.brand')"
	MODEL="$(my_grep_prop 'ro.product.model')"
	[ -z "$MODEL" ] && MODEL="$(my_grep_prop 'ro.product.vendor.model')"
	[ -z "$MODEL" ] && MODEL="$(my_grep_prop 'ro.product.vendor.device')"
	[ -z "$MODEL" ] && MODEL="$(my_grep_prop 'ro.product.vendor.name')"
	[ -z "$MODEL" ] && MODEL="$(my_grep_prop 'ro.product.system.model')"
	[ -z "$MODEL" ] && MODEL="$(my_grep_prop 'ro.product.system.device')"
	[ -z "$MODEL" ] && MODEL="$(my_grep_prop 'ro.product.system.name')"
	DEVICE="$(my_grep_prop 'ro.product.device')"
	[ -z "$DEVICE" ] && DEVICE="$(my_grep_prop 'ro.product.vendor.device')"
	[ -z "$DEVICE" ] && DEVICE="$(my_grep_prop 'ro.product.vendor.name')"
	[ -z "$DEVICE" ] && DEVICE="$(my_grep_prop 'ro.product.system.device')"
	[ -z "$DEVICE" ] && DEVICE="$(my_grep_prop 'ro.product.system.name')"
	ROM="$(my_grep_prop 'build.version')"
	[ -z "$ROM" ] && ROM="$(my_grep_prop 'ro.vendor.build.id')"
	[ -z "$ROM" ] && ROM="$(my_grep_prop 'ro.build.id')"
	[ -z "$ROM" ] && ROM="$(my_grep_prop 'ro.system.build.id')"
	RELEASE="$(my_grep_prop 'ro.vendor.build.version.release')"
	[ -z "$RELEASE" ] && RELEASE="$(my_grep_prop 'ro.build.version.release')"
	[ -z "$RELEASE" ] && RELEASE="$(my_grep_prop 'ro.system.build.version.release')"
	SDK="$(my_grep_prop 'ro.vendor.build.version.sdk')"
	[ -z "$SDK" ] && SDK="$(my_grep_prop 'ro.build.version.sdk')"
	[ -z "$SDK" ] && SDK="$(my_grep_prop 'ro.system.build.version.sdk')"
	printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" "DATE_ID=$DATE_ID" "MOD_VER=$MOD_VER" "APK_NAME=$APK_NAME" "MANUFACTURER=$MANUFACTURER" "MODEL=$MODEL" "DEVICE=$DEVICE" "ROM=$ROM" "RELEASE=$RELEASE" "SDK=$SDK" > "$MODPATH/.env"
	# print device info
	ui_print "-- Device info --"
	ui_print "$(cat "$MODPATH/.env")"
	ui_print "-----------------"
}

# Check which version installed
if [ -f "$CURRENT_MODPATH/module.prop" ]; then
	if [[ ! "$(grep_prop author $CURRENT_MODPATH/module.prop)" =~ [Jj][Oo][Nn]8[Rr][Ff][Cc] ]]; then
		ui_print ""
		ui_print ""
		ui_print "Please uninstall/remove the installed"
		ui_print "NFCScreenOff module and reboot."
		ui_print ""
		exit 1
	fi
fi

# Re/patch check
check_for_apk

# backups & only attempt patching if files exist
if [[ "$DO_PATCH" = 1 ]]; then
	ODEX_EXIST=0
	CLASSIC_EXIST=0
	if [ -f "$APK_DIR/oat/arm64/$APK_NAME.odex" ]; then
		ODEX_EXIST=1
		create_backup "$APK_DIR/oat/arm64/$APK_NAME.odex"
		create_backup "$APK_DIR/oat/arm64/$APK_NAME.vdex"
	fi
	if [ -f "/system/framework/framework-res.apk" ]; then
		CLASSIC_EXIST=1
	fi
	if [[ "$CLASSIC_EXIST" = 0 && "$ODEX_EXIST" = 0 ]]; then
		ui_print "!! ERROR"
		ui_print "   $APK_PATH exists."
		ui_print "   Necessary support files do not exist:"
		ui_print "   /system/framework/framework-res.apk"
		ui_print "   $APK_DIR/oat/arm64/$APK_NAME.odex"
		ui_print "   $APK_DIR/oat/arm64/$APK_NAME.vdex"
		get_device_info
		DO_PATCH=0
	fi
create_backup "$APK_PATH"
fi

# local testing/checks/future-tests (prevent wasted time uploading)
if [[ "$DO_PATCH" = 1 ]]; then
	SERVER_TEST=1
	ui_print "-- Server test..."
	RESPONSE=$(curl -s -w "\n%{http_code}" --connect-timeout 5 "$PATCH_URL")
	curl_exit_status=$?
	check_http_response
	SERVER_TEST=0
fi

if [[ "$DO_PATCH" = 1 ]]; then
	UPLOAD_CLASSIC="NFCScreenOff_upload_this1.zip"
	UPLOAD_ODEX="NFCScreenOff_upload_this2.zip"
	FAIL_CLASSIC=0
	FAIL_ODEX=0
	get_device_info
	ln -s "$MODPATH/${APK_NAME}_bak.apk" "$TMPDIR/$APK_NAME.apk"
	ln -s "$MODPATH/${APK_NAME}_bak.odex" "$TMPDIR/$APK_NAME.odex"
	ln -s "$MODPATH/${APK_NAME}_bak.vdex" "$TMPDIR/$APK_NAME.vdex"
	ln -s /system/framework/arm64 "$TMPDIR/arm64"
	if [[ "$CLASSIC_EXIST" = 1 ]]; then
		ZIP_ERROR=0
		rm "$TMPDIR/$APK_NAME.zip"
		ui_print "-- Zipping $APK_NAME.apk and device's framework"
		ZIP_OUTPUT=$(zip -j "$TMPDIR/$APK_NAME" "$MODPATH/.env" "$TMPDIR/$APK_NAME.apk" /system/framework/framework-res.apk 2>&1)
		ui_print "$ZIP_OUTPUT"
		if [[ "$ZIP_OUTPUT" = *"warning"* ]]; then
			ZIP_ERROR=1
		else
			ui_print "-- Uploading apk for classic modding,"
			ui_print "   it may take a while ($(( $( stat -c '%s' $TMPDIR/$APK_NAME.zip) / 1024 / 1024))Mb)"
			ui_print "   Please wait..."
			ui_print ""
			RESPONSE=$(curl -w "\n%{http_code}" --connect-timeout 5 -X PUT --upload-file "$TMPDIR/$APK_NAME.zip" -o "$MODPATH/${APK_NAME}_align.apk" "$PATCH_URL")
			curl_exit_status=$?
		fi
		check_http_response
		if [[ "$RESPONSE_CODE" = 545 || "$RESPONSE_CODE" = 555 || "$ZIP_ERROR" = 1 ]]; then
			cp -f "$TMPDIR/$APK_NAME.zip" "$EXTERNAL_STORAGE/Download/$UPLOAD_CLASSIC" 2>/dev/null
			cp -f "$TMPDIR/$APK_NAME.zip" "$SECONDARY_STORAGE/Download/$UPLOAD_CLASSIC" 2>/dev/null
			cp -f "$TMPDIR/$APK_NAME.zip" "$EMULATED_STORAGE_TARGET/Download/$UPLOAD_CLASSIC" 2>/dev/null
			FAIL_CLASSIC=1
			ui_print ""; ui_print "!! MODDING FAILED (classic)"
		fi
	fi
	if [[ "$ODEX_EXIST" = 1 ]]; then
		ZIP_ERROR=0
		rm "$TMPDIR/$APK_NAME.zip"
		ui_print "";
		ui_print "-- Classic modding unavailable/failed, trying odex..."
		ui_print "   Adding framework folder, odex, vdex files to archive"
		printf "%s\n" "STRATEGY=odex" >> "$MODPATH/.env"
		ZIP_OUTPUT=$(zip -j "$TMPDIR/$APK_NAME" "$MODPATH/.env" "$TMPDIR/$APK_NAME.apk" "$TMPDIR/$APK_NAME.odex" "$TMPDIR/$APK_NAME.vdex" 2>&1)
		ui_print "$ZIP_OUTPUT"
		if [[ "$ZIP_OUTPUT" = *"warning"* ]]; then ZIP_ERROR=1; fi
		cd "$TMPDIR"; ZIP_OUTPUT=$(zip -r "$TMPDIR/$APK_NAME" arm64 2>&1); cd -
		ui_print "$ZIP_OUTPUT"
		if [[ "$ZIP_OUTPUT" = *"warning"* ]]; then
			ZIP_ERROR=1
		else
			ui_print "-- Uploading archive for odex modding,"
			ui_print "   it may take a while ($(( $( stat -c '%s' $TMPDIR/$APK_NAME.zip) / 1024 / 1024))Mb)"
			ui_print "   Please wait..."
			ui_print ""
			RESPONSE=$(curl -w "\n%{http_code}" --connect-timeout 5 -X PUT --upload-file "$TMPDIR/$APK_NAME.zip" -o "$MODPATH/${APK_NAME}_align.apk" "$PATCH_URL")
			curl_exit_status=$?
		fi
		check_http_response
		if [[ "$RESPONSE_CODE" = 545 || "$RESPONSE_CODE" = 555 || "$ZIP_ERROR" = 1 ]]; then
			cp -f "$TMPDIR/$APK_NAME.zip" "$EXTERNAL_STORAGE/Download/$UPLOAD_ODEX" 2>/dev/null
			cp -f "$TMPDIR/$APK_NAME.zip" "$SECONDARY_STORAGE/Download/$UPLOAD_ODEX" 2>/dev/null
			cp -f "$TMPDIR/$APK_NAME.zip" "$EMULATED_STORAGE_TARGET/Download/$UPLOAD_ODEX" 2>/dev/null
			FAIL_ODEX=1
		fi
	fi
	# abort/fail patching messages
	if [[ "$FAIL_ODEX" = 1 ]]; then ui_print ""; ui_print "!! MODDING FAILED (odex)"; fi
	if [[ "$FAIL_CLASSIC" = 1 && "$FAIL_ODEX" = 1 ]]; then ui_print ""; ui_print "!! MODDING FAILED (classic)"; fi
	if [[ "$RESPONSE_CODE" = 545 || "$RESPONSE_CODE" = 555 || "$ZIP_ERROR" = 1 ]]; then
		ui_print ""
		ui_print "-- Save this log (top-right 'disk' button)"
		ui_print "   Please upload log and the failed zip,"
		[ -f "$EXTERNAL_STORAGE/Download/$UPLOAD_CLASSIC" ] && ui_print "   /Download/$UPLOAD_CLASSIC"
		[ -f "$EXTERNAL_STORAGE/Download/$UPLOAD_ODEX" ] && ui_print "   /Download/$UPLOAD_ODEX"
		[ -f "$SECONDARY_STORAGE/Download/$UPLOAD_CLASSIC" ] && ui_print "   /Download/$UPLOAD_CLASSIC"
		[ -f "$SECONDARY_STORAGE/Download/$UPLOAD_ODEX" ] && ui_print "   /Download/$UPLOAD_ODEX"
		[ -f "$EMULATED_STORAGE_TARGET/Download/$UPLOAD_CLASSIC" ] && ui_print "   /Download/$UPLOAD_CLASSIC"
		[ -f "$EMULATED_STORAGE_TARGET/Download/$UPLOAD_ODEX" ] && ui_print "   /Download/$UPLOAD_ODEX"
		ui_print "TO:"
		ui_print "$ISSUES_URL"
		DO_PATCH=0
	fi
	if [[ "$DO_PATCH" = 1 && "$RESPONSE_CODE" = 200 ]]; then
		ui_print "-- Downloaded patched $APK_NAME.apk from Jon8RFC's server" | fold -s
	elif [[ "$DO_PATCH" = 1 && "$RESPONSE_CODE" != 200 ]]; then
		ui_print "-- Unknown/possible success." | fold -s
		ui_print "   Save and upload this log (top-right 'disk' button):"
		ui_print "$ISSUES_URL"
	fi
fi
ui_print ""
ui_print ""
ui_print "-- Wait 30 seconds after every boot for effect. --"
ui_print ""
ui_print ""
ui_print "   ALWAYS UNINSTALL the module BEFORE"
ui_print "   performing an Android/rom update."
ui_print ""
ui_print ""
if [[ "$DO_PATCH" != 1 ]]; then
	ui_print "   NO REBOOT NECESSARY."
	ui_print ""
	exit 1
fi
