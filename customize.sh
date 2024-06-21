#!/system/bin/sh


# since update-binary changes modules to modules_update if $BOOTMODE=true
CURRENT_MODPATH="$NVBASE"/modules/"$MODID"

# source fallback binaries
chmod -R +x "$MODPATH/bin"
export PATH="$PATH:$MODPATH/bin"
chmod 0755 "$MODPATH/service.sh"

DO_PATCH=1
PATCH_URL="https://patcher.jon8rfc.com"
ISSUES_URL=https://github.com/Jon8RFC/NfcScreenOff/issues

check_http_response() {
	RESPONSE_CODE=$(echo "$RESPONSE" | tail -n1)
	RESPONSE_TEXT=$(echo "$RESPONSE" | sed '$d')
	# first, to show response code & text
	if [ "$RESPONSE_CODE" = "200" ]; then
		ui_print "   HTTP Response: $RESPONSE_CODE (SUCCESS)"; ui_print "";
	elif [ "$ZIP_ERROR" != "1" ]; then
		ui_print "   HTTP Response: $RESPONSE_CODE"; ui_print "$RESPONSE_TEXT" | fold -s; ui_print "";
	elif [ "$ZIP_ERROR" = "1" ]; then
		ui_print "!! CLIENT ZIP ERROR !!"; ui_print "";
	fi
	if [ "$curl_exit_status" != "0" ]; then ui_print "!! cURL failed with exit status $curl_exit_status."; fi
	if [ "$curl_exit_status" != "0" ] && [ "$RESPONSE_CODE" != "000" ]; then ui_print "   Check your connection."; ui_print "   If you have customized this or run a server,"; ui_print "   check the URL, server, firewall,"; ui_print "   and local network settings."; ui_print ""; DO_PATCH=0; fi
	if [ "$curl_exit_status" != "0" ] && [ "$SERVER_TEST" = "1" ]; then ui_print "!! Your device may not properly support cURL."; ui_print "https://everything.curl.dev/cmdline/exitcode"; ui_print ""; ui_print ""; DO_PATCH=0; fi
	if [ "$RESPONSE_CODE" = "000" ]; then ui_print "!! URL, DNS, timeout, or client network issue."; ui_print ""; ui_print "   Check your connection."; ui_print "   If you have customized this or run a server,"; ui_print "   check the URL, server, firewall,"; ui_print "   and local network settings."; DO_PATCH=0; fi
	if [ "$(echo "$RESPONSE_CODE" | grep -E '^3')" ]; then ui_print "!! Server-side network configuration issue, or maintenance."; ui_print "   Try again in a few hours."; DO_PATCH=0; fi
	if [ "$(echo "$RESPONSE_CODE" | grep -E '^4')" ]; then ui_print "!! URL, network/server issue, or maintenance."; ui_print "   Try again in a few hours."; ui_print ""; ui_print "Check here for updates/info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
	if [ "$(echo "$RESPONSE_CODE" | grep -E '^5')" ] && [ "$RESPONSE_CODE" != "545" ] && [ "$RESPONSE_CODE" != "555" ]; then ui_print "!! URL, network/server issue, or maintenance."; ui_print "Try again in a few hours."; ui_print ""; ui_print "   Check here for updates/info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
	if [ "$(echo "$RESPONSE_CODE" | grep -E '^7')" ]; then DO_PATCH=1; fi
	if [ "$(echo "$RESPONSE_CODE" | grep -E '^8')" ]; then DO_PATCH=0; fi
	if [ "$(echo "$RESPONSE_CODE" | grep -E '^9')" ] && [ "$RESPONSE_CODE" != "999" ]; then WAIT_HOURS="${RESPONSE_CODE:1}"; ui_print "!! Server maintenance."; ui_print "   Try again in $WAIT_HOURS hours"; ui_print ""; ui_print "   Check here for updates/info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
	if [ "$RESPONSE_CODE" = "999" ]; then ui_print "!! Server permanently/indefinitely shutdown."; ui_print ""; ui_print "Check here for info:"; ui_print "$ISSUES_URL"; DO_PATCH=0; fi
}

check_other_patcher() {
	if [ -f "$CURRENT_MODPATH/module.prop" ]; then
		if [ -z "$(grep_prop author $CURRENT_MODPATH/module.prop | grep -E '[Jj][Oo][Nn]8[Rr][Ff][Cc]')" ]; then
			ui_print ""
			ui_print "!!"
			ui_print "   Please first uninstall/remove the current"
			ui_print "   NFCScreenOff module, then reboot."
			ui_print "!!"
			ui_print ""
			exit 1
		fi
	fi
}

search_for_apk() {
	#ui_print "-- Filtering directories..." #debug
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
	#		else #debug
	#			ui_print "   $dir SYMLINKS $real_path --duplicate; removing." #debug
			fi
	#	else #debug
	#		ui_print "   $dir does not exist. Removing." #debug
		fi
	done
	#ui_print "-- Filtered directories:" #debug
	#for dir in $NFC_DIRS_FILTERED; do #debug
	#	ui_print "   $dir" #debug
	#done #debug
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
	#for apk in $FOUND_APKS; do #debug
	#	ui_print "   $apk" #debug
	#done #debug
	if [ -n "$FOUND_APKS" ]; then
		FIRST_APK=$(echo $FOUND_APKS | awk '{print $1}')
		APK_PATH="$FIRST_APK"
		APK_NAME=$(basename $(dirname "$FIRST_APK"))
	fi
	if [ -z "$APK_NAME" ]; then
		ui_print "!! Could not find any NFC apk"
	#	for name in $NFC_APPS; do #debug
	#		ui_print "   $name" #debug
	#	done #debug
	#	ui_print "  in:" #debug
	#	for dir in $NFC_DIRS_FILTERED; do #debug
	#		ui_print "   $dir" #debug
	#	done #debug
		ui_print ""
		#
		#
		#
		DO_PATCH=0
	else
		ui_print "   $APK_NAME.apk set!"
		APK_BOOT="$CURRENT_MODPATH/${APK_NAME}_boot.apk"
		APK_BAK="$CURRENT_MODPATH/${APK_NAME}_bak.apk"
		APK_ALIGN="$CURRENT_MODPATH/${APK_NAME}_align.apk"
		APK_DIR="$(dirname $APK_PATH)"
		#
		#
		DO_PATCH=1
	fi
	#exit 1 #debug
}

create_backup() {
	local path="$1"
	local filename="${path##*/}"
	local extension="${filename##*.}"
	filename="${filename%.*}"
	ui_print "-- Searching for $filename.$extension backup..."
	if [ -f "$CURRENT_MODPATH/${filename}_bak.$extension" ]; then
		if [ -f "$APK_BOOT" ]; then
			ui_print "   Copying _boot backup to the module update folder."
			cp "$APK_BOOT" "$MODPATH/${filename}_bak.$extension"
		else
			ui_print "   Copying _bak backup to the module update folder."
			cp "$CURRENT_MODPATH/${filename}_bak.$extension" "$MODPATH/${filename}_bak.$extension"
		fi
	else
		ui_print "   ${filename}_bak.$extension not found. Creating backup of original $filename.$extension."
		cp "$path" "$MODPATH/${filename}_bak.$extension"
	fi
}

# backup & only attempt patching if files exist
search_for_framework_and_backup() {
	if [ "$DO_PATCH" = "1" ]; then
		ODEX_EXIST=0
		CLASSIC_EXIST=0
		if [ -f "$APK_DIR/oat/arm64/$APK_NAME.odex" ]; then
			ODEX_EXIST=1
			create_backup "$APK_DIR/oat/arm64/$APK_NAME.odex"
			create_backup "$APK_DIR/oat/arm64/$APK_NAME.vdex"
		fi
		FRAMEWORK_DIRS='/system/framework /system_ext/framework /system/system_ext/framework /vendor/framework /product/framework'
		FRAMEWORK_RES_PATH=""
		# resolve symlinks, remove duplicates & null
		for dir in $FRAMEWORK_DIRS; do
			if [ -d "$dir" ]; then
				real_path=$(readlink -f "$dir")
				if ! is_in_list "$real_path" "$FRAMEWORK_DIRS_FILTERED"; then
					FRAMEWORK_DIRS_FILTERED="$FRAMEWORK_DIRS_FILTERED $real_path"
					#
					#
				fi
			#
				#
			fi
		done
		for dir in $FRAMEWORK_DIRS_FILTERED; do
			if [ -f "$dir/framework-res.apk" ]; then
				FRAMEWORK_RES_PATH="$dir/framework-res.apk"
				CLASSIC_EXIST=1
				break
			fi
		done
		if [ "$CLASSIC_EXIST" = "0" ] && [ "$ODEX_EXIST" = "0" ]; then
			ui_print "!! ERROR"
			ui_print "   $APK_PATH exists."
			ui_print "   Necessary support files do not exist:"
			ui_print "   framework-res.apk"
			ui_print "   $APK_DIR/oat/arm64/$APK_NAME.odex"
			ui_print "   $APK_DIR/oat/arm64/$APK_NAME.vdex"
			DO_PATCH=0
		fi
		create_backup "$APK_PATH"
	fi
}

# local testing/checks/future-tests (prevent wasted time uploading)
do_server_precheck() {
	if [ "$DO_PATCH" = "1" ]; then
		SERVER_TEST=1
		ui_print "-- Server test..."
		RESPONSE=$(curl -s -w "\n%{http_code}" --connect-timeout 5 "$PATCH_URL")
		curl_exit_status=$?
		check_http_response
		SERVER_TEST=0
	fi
}

my_grep_prop() {
	local REGEX="s/$1=//p"
	shift
	local FILES=$@
	[ -z "$FILES" ] && FILES='/system/build.prop /vendor/build.prop /product/build.prop'
	sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

get_device_info() {
	REPATCH=""
	REPATCH_DATE_ID=""
	if [ -f "$CURRENT_MODPATH/.env" ]; then
		REPATCH="y"
		REPATCH_DATE_ID="$(grep_prop DATE_ID $CURRENT_MODPATH/.env)"
		if [ -f "$CURRENT_MODPATH/boot_repatch" ]; then
			REPATCH="boot"
		fi
	fi
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
	printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" "DATE_ID=$DATE_ID" "REPATCH=$REPATCH" "REPATCH_DATE_ID=$REPATCH_DATE_ID" "MOD_VER=$MOD_VER" "APK_NAME=$APK_NAME" "APK_DIR=$APK_DIR" "MANUFACTURER=$MANUFACTURER" "MODEL=$MODEL" "DEVICE=$DEVICE" "ROM=$ROM" "RELEASE=$RELEASE" "SDK=$SDK" > "$MODPATH/.env"
	# print device info
	ui_print "-- Device info --"
	ui_print "$(cat "$MODPATH/.env")"
	ui_print "-----------------"
}

do_patching() {
	if [ "$DO_PATCH" = "1" ]; then
		UPLOAD_CLASSIC="NFCScreenOff_upload_this1.zip"
		UPLOAD_ODEX="NFCScreenOff_upload_this2.zip"
		FAIL_CLASSIC=0
		FAIL_ODEX=0
		ln -s "$MODPATH/${APK_NAME}_bak.apk" "$TMPDIR/$APK_NAME.apk"
		ln -s "$MODPATH/${APK_NAME}_bak.odex" "$TMPDIR/$APK_NAME.odex"
		ln -s "$MODPATH/${APK_NAME}_bak.vdex" "$TMPDIR/$APK_NAME.vdex"
		ln -s /system/framework/arm64 "$TMPDIR/arm64"
		if [ "$CLASSIC_EXIST" = "1" ]; then
			ZIP_ERROR=0
			rm "$TMPDIR/$APK_NAME.zip"
			ui_print "-- Zipping $APK_NAME.apk and device's framework"
			ZIP_OUTPUT=$(zip -j "$TMPDIR/$APK_NAME" "$MODPATH/.env" "$TMPDIR/$APK_NAME.apk" "$FRAMEWORK_RES_PATH" 2>&1)
			ui_print "$ZIP_OUTPUT"
			if [ "$(echo "$ZIP_OUTPUT" | grep "warning")" ]; then
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
			if [ "$RESPONSE_CODE" = "545" ] || [ "$RESPONSE_CODE" = "555" ] || [ "$ZIP_ERROR" = "1" ]; then
				cp -f "$TMPDIR/$APK_NAME.zip" "$EXTERNAL_STORAGE/Download/$UPLOAD_CLASSIC" 2>/dev/null
				cp -f "$TMPDIR/$APK_NAME.zip" "$SECONDARY_STORAGE/Download/$UPLOAD_CLASSIC" 2>/dev/null
				cp -f "$TMPDIR/$APK_NAME.zip" "$EMULATED_STORAGE_TARGET/Download/$UPLOAD_CLASSIC" 2>/dev/null
				FAIL_CLASSIC=1
				ui_print ""; ui_print "!! MODDING FAILED (classic)"
			fi
		fi
		if [ "$ODEX_EXIST" = "1" ]; then
			ZIP_ERROR=0
			rm "$TMPDIR/$APK_NAME.zip"
			ui_print "";
			ui_print "-- Classic modding unavailable/failed, trying odex..."
			ui_print "   Adding framework folder, odex, vdex files to archive"
			printf "%s\n" "STRATEGY=odex" >> "$MODPATH/.env"
			ZIP_OUTPUT=$(zip -j "$TMPDIR/$APK_NAME" "$MODPATH/.env" "$TMPDIR/$APK_NAME.apk" "$TMPDIR/$APK_NAME.odex" "$TMPDIR/$APK_NAME.vdex" 2>&1)
			ui_print "$ZIP_OUTPUT"
			if [ "$(echo "$ZIP_OUTPUT" | grep "warning")" ]; then ZIP_ERROR=1; fi
			cd "$TMPDIR"; ZIP_OUTPUT=$(zip -r "$TMPDIR/$APK_NAME" arm64 2>&1); cd -
			ui_print "$ZIP_OUTPUT"
			if [ "$(echo "$ZIP_OUTPUT" | grep "warning")" ]; then
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
			if [ "$RESPONSE_CODE" = "545" ] || [ "$RESPONSE_CODE" = "555" ] || [ "$ZIP_ERROR" = "1" ]; then
				cp -f "$TMPDIR/$APK_NAME.zip" "$EXTERNAL_STORAGE/Download/$UPLOAD_ODEX" 2>/dev/null
				cp -f "$TMPDIR/$APK_NAME.zip" "$SECONDARY_STORAGE/Download/$UPLOAD_ODEX" 2>/dev/null
				cp -f "$TMPDIR/$APK_NAME.zip" "$EMULATED_STORAGE_TARGET/Download/$UPLOAD_ODEX" 2>/dev/null
				FAIL_ODEX=1
			fi
		fi
		# abort/fail patching messages
		if [ "$FAIL_ODEX" = "1" ]; then ui_print ""; ui_print "!! MODDING FAILED (odex)"; fi
		if [ "$FAIL_CLASSIC" = "1" ] && [ "$FAIL_ODEX" = "1" ]; then ui_print ""; ui_print "!! MODDING FAILED (classic)"; fi
		if [ "$RESPONSE_CODE" = "545" ] || [ "$RESPONSE_CODE" = "555" ] || [ "$ZIP_ERROR" = "1" ]; then
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
		if [ "$DO_PATCH" = "1" ] && [ "$RESPONSE_CODE" = "200" ]; then
			ui_print "-- Downloaded patched $APK_NAME.apk from Jon8RFC's server" | fold -s
		elif [ "$DO_PATCH" = "1" ] && [ "$RESPONSE_CODE" != "200" ]; then
			ui_print "-- Unknown/possible success." | fold -s
			ui_print "   Save and upload this log (top-right 'disk' button):"
			ui_print "$ISSUES_URL"
		fi
	fi
}
#
check_other_patcher
search_for_apk
search_for_framework_and_backup
do_server_precheck
get_device_info
do_patching
if [ "$DO_PATCH" = "1" ]; then
	su -c "svc nfc enable"
fi
#
ui_print ""
ui_print ""
ui_print "-- Wait 30 seconds after boot for effect. --"
ui_print ""
ui_print ""
ui_print "   ALWAYS UNINSTALL the module BEFORE"
ui_print "   performing an Android/rom/firmware update."
ui_print ""
ui_print ""
if [ "$DO_PATCH" != "1" ]; then
	ui_print "   NO REBOOT NECESSARY."
	ui_print ""
	exit 1
fi
