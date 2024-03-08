# Changelog

### v2.0.1 (jon8rfc) 2024-03-xx
#### CHANGE
* disabled repatching check
  * allows forced updating for server-side fixes
* sleep from 25 to 35, to better accommodate older devices & android versions
#### NOTES
* fixed server-side Android 14 patching compatibility with older Android versions

### v2.0.0 (jon8rfc) 2023-07-27
#### FIX
* odex and/or "classic" modding to only attempt if files exist, rather than long waiting & failing
* missing "Nfc_st" name from patched apks
  * *may* correct a small handful of successful patches which don't work
* build.prop missing fallbacks for device & rom, for troubleshooting
#### ADD
* Magisk module native update capability
* Fox/Androidacy [Magisk Module Manager](https://github.com/Androidacy/MagiskModuleManager) support
* backup of original, non-patched NFC apk on boot
  * allows for updating module and Android
* pre-patch verify:
  * if new NFC apk exists
  * if repatching/module update
  * server connectivity (no excess waiting if down)
  * successful zip
* server timeout of 5 seconds (reduce waiting by 2 minutes if down)
* [HTTP status response codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) support
  * custom display for some common codes
  * display of server-side textual responses
* custom HTTP status response codes support, if enabled server-side
  * distinction between potential patching failure/update-needed (545 & 555) and anything else
  * optional textual messages with abort or resume functionality within module
* saving of failed-to-patch zip file(s) for custom HTTP status codes (545 & 555, for now)
  * please create a [github issue](https://github.com/Jon8RFC/NfcScreenOff/issues) if code 545 or 555; maybe your device can be supported
* build.prop extra fallbacks for device & rom, for troubleshooting
* build.prop version/sdk & module version, for troubleshooting
#### CHANGE
* NFC apk replace method (permits repatching, module update, proper backup)
* various Magisk terminal outputs/layouts
* refactor & rearrange script
* save long client-side UNIX date as "DATE_ID" in .env, replacing server-side UNIX date instead of "timestamp"
  * assists troubleshooting when someone shares info with their DATE_ID
* server set to Jon8RFC's, for now
  * maintenance/cost is a factor and may not be sustainable
#### NOTES
* Possibly some minor forgotten things, as I didn't use a repo to track changes  
  
As of the June 2023 update, on my Pixel 7 Pro, the NFC service is being disabled/paused/suspended after some time when the screen is off.  
This may apply to more devices in the future, or may be a quirk with just my device.  A module-based remediation is unknown at this time.  
Currently, I'm using a [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm) profile to stop&start the service.  
[Jon8RFC NFC post 1](https://forum.xda-developers.com/t/module-nfc-screen-off.4034903/page-11#post-88691729)  
[Jon8RFC NFC post 2, with Tasker profile download](https://forum.xda-developers.com/t/module-nfc-screen-off.4034903/page-11#post-88720909)

---
### v0.3.3 (lapwat)  2022-03-30
