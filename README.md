# NFCScreenOff
Thanks to [lapwat](https://github.com/lapwat) for creating the original!

* Read NFC tags when the screen is off.
* Disable NFC tagging/scanning sound.
* Be sure to wait 30 seconds after booting for the script to execute.

_Useful integrations: [NFC Card Emulator Pro](https://play.google.com/store/apps/details?id=com.yuanwofei.cardemulator.pro) - [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm) - []()_

XDA Forums thread: https://xdaforums.com/t/4667435/
# Installation
1. [Download](https://github.com/Jon8RFC/NfcScreenOff/releases/latest)
2. Install in Magisk
3. Wait for the upload, patch, and download
4. Reboot
5. Unlock phone
6. Wait ~30 seconds for the script to execute
7. Ready for use  

You may need to update or reinstall the module after an Android update, so check in the Magisk Modules list for info.  
If you have installed and setup Termux-Notification, you'll receive a notification upon reboot when NFC changes.  

---
# Help section
---
### HOW DOES IT WORK?

The NFC app is patched, during installation, into a modded version. This modded version is injected at boot time by [service.sh](service.sh) so that the app thinks the screen is always on and unlocked.

This patch only applies to the NFC Service, so it does not impact any other functionality of the phone that involves screen state detection.

The modded app is generated using [this server & method](https://github.com/Jon8RFC/nfcscreenoffpatcher).


### THE MODULE IS NOT WORKING SINCE LAST ANDROID UPDATE

As of v2.1.0, the module is auto-disabled when the NFC app is updated or moved.  
This prevents cyclical reboots as well as informs the user of a necessary update.  

Either a module update is necessary, or new support is needed for the new or moved NFC app.
1. Check for an update within Magisk's Module list
2. If no update is available, check the pinned [issues](https://github.com/Jon8RFC/NfcScreenOff/issues)
3. Reply to the appropriate pinned issue OR create new issue if your issue is different
4. Upload the zip file as instructed by the installer
5. Save the log in Magisk (the disk icon on the top-right) and upload the log

### cURL EXIT CODES
https://everything.curl.dev/cmdline/exitcode

### HTTP RESPONSE 545 or 555

Codes 545 and 555 are custom and exclusive to the server-side patcher.  
Only a server-side update can resolve these errors, if something is found to update.  
Please create an [issue](https://github.com/Jon8RFC/NfcScreenOff/issues) and upload the log & zip file(s).  

I'll create a server-side changelog and link here in the future.

---
### NFC IS NOT DETECTED ANYMORE

If you did not unlock your device since last boot, unlock it and wait ~30 seconds for the module to be loaded.

After that time, if NFCScreenOff or the NFC Service does not start automatically or manually, it means that the patch does not work for your device.  
Please uninstall the module and create an [issue](https://github.com/Jon8RFC/NfcScreenOff/issues).
