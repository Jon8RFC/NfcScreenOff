# NFCScreenOff

Read NFC tags when screen is off. Disable NFC tagging sound.

_Useful integrations: [NFC Card Emulator Pro](https://play.google.com/store/apps/details?id=com.yuanwofei.cardemulator.pro) - [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm)_

# How does it work?

The NFC app is patched during installation into a `modded` version. This `modded` version is injected at boot time by [service.sh](service.sh) so that the phone thinks the screen is always on and unlocked. This patch only applies to NFC Service so it does not impact any other functionality of the phone that involves screen state detection.

The `modded` app was generated using [this method](https://github.com/lapwat/NfcScreenOffPie).

# Help section

### I AM STUCK IN A BOOTLOOP

Remove the module manually

1. Boot into TWRP
2. Advanced -> File Manager
3. Delete /adb/modules/NFCScreenOff
4. Reboot
#### OR
1. Boot into safe mode, which disables all magisk modules
    * Button combinations vary per device, so Google to find which works for yours
2. Mark it to be removed, then reboot normally
#### OR
1. Using [ADB](https://developer.android.com/tools/releases/platform-tools), run this command and reboot your phone while connected to your computer:
    * adb wait-for-device shell magisk --remove-modules
2. Let it do its thing and it may reboot a second time

---
### THE MODULE IS NOT WORKING SINCE LAST ANDROID UPDATE

Perform a clean reinstallation.

1. Uninstall the module
2. Reboot
3. Install the module
4. Reboot

### cURL EXIT CODES
https://everything.curl.dev/cmdline/exitcode

### HTTP RESPONSE 545 or 555

Codes 545 and 555 are custom and exclusive to the server-side patcher.  
Only a server-side update can resolve these errors, if something is found to update.  
Please create an [issue](https://github.com/Jon8RFC/NfcScreenOff/issues) and upload the log & zip file(s).  

I'll create a server-side changelog and link here in the future.

---
### MY NFC IS NOT DETECTED ANYMORE

If you did not unlock your device since last boot, unlock it and wait 30 seconds for the module to be loaded.

After that time, if NFC does not start automatically or manually, it means that the patch does not work for your device. You can uninstall the module and create an [issue](https://github.com/Jon8RFC/NfcScreenOff/issues).
