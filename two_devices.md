# Two-Device BLE SOS Test

This guide tests SafeMyanmar's optional Nearby SOS Bluetooth Low Energy (BLE)
sharing between two physical Android phones.

This is a local development test. Do not select real emergency contacts, send
real emergency SMS messages, or contact emergency services during the test.

## Requirements

- Two physical Android phones with BLE support.
- The same SafeMyanmar debug APK installed on both phones.
- Bluetooth enabled on both phones.
- Both phones unlocked and close to each other.
- SafeMyanmar open in the foreground on the receiving phone.

BLE testing does not require the backend, internet, Mapbox, or Gemma.

## Install The APK

From the repository root, build the debug APK if necessary:

```powershell
flutter build apk --debug
```

Find both device serial numbers:

```powershell
$adb = "C:\Users\USER\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

Install the same APK on both phones:

```powershell
& $adb -s PHONE_A_SERIAL install -r "mobile\build\app\outputs\flutter-apk\app-debug.apk"
& $adb -s PHONE_B_SERIAL install -r "mobile\build\app\outputs\flutter-apk\app-debug.apk"
```

Replace `PHONE_A_SERIAL` and `PHONE_B_SERIAL` with the values returned by
`adb devices`.

## Prepare Both Phones

1. Enable Bluetooth on both phones.
2. Open SafeMyanmar on both phones.
3. Grant Nearby Devices permission when requested.
4. Grant notification permission when requested.
5. Keep both phones unlocked and within normal Bluetooth range.

On some Android versions, Location Services must also be enabled for BLE
scanning even though SafeMyanmar does not request background location.

## Phone B: Receiver

1. Open the **SOS** screen.
2. Enable **Receive nearby SOS**.
3. Grant the requested Bluetooth permissions.
4. Optionally enable nearby SOS sound.
5. Leave SafeMyanmar visible on the screen.

The receiver is currently foreground-only, so backgrounding the app can stop
nearby event handling.

## Phone A: Sender

For a BLE-only test, do not select emergency contacts. This prevents a real
SMS attempt.

1. Create or select a local profile if required.
2. Do not select emergency contacts.
3. Enable **Share SOS data with nearby SafeMyanmar users**.
4. Hold the SOS confirmation control for three seconds.
5. Grant the requested Bluetooth permissions.

Expected sender status:

```text
Nearby SOS broadcasting
```

The sender status is shown only after Android confirms that BLE advertising
started. The broadcast uses a short discovery interval and higher transmit
power for the ten-minute emergency window. Press **Stop** on Phone A to end it
earlier.

## Expected Receiver Result

Phone B should display a nearby SOS alert. The event is peer-received and
unverified; it does not acknowledge, relay, or dispatch the alert.

The BLE payload contains only:

- temporary event ID;
- UTC creation timestamp;
- approximate one-kilometre location grid;
- current or last-known location status;
- battery percentage when available.

The payload does not contain names, phone numbers, message text, or exact
coordinates.

## Test Checklist

- Phone A receives Bluetooth permission successfully.
- Phone B receives Bluetooth and notification permissions successfully.
- Phone A shows the broadcasting state.
- Phone B shows one nearby SOS alert.
- Repeated advertisements do not create duplicate alert cards.
- Phone A's **Stop** control ends future broadcasts.
- No SMS is sent when no emergency contacts are selected.
- The receiver can dismiss the nearby alert.

## Troubleshooting

### No alert appears

- Confirm both phones support BLE.
- Confirm Bluetooth is enabled on both phones.
- Confirm Phone B has **Receive nearby SOS** enabled.
- Keep Phone B's SOS screen in the foreground.
- Recheck Nearby Devices permission in Android settings.
- Move the phones closer together and retry.
- Disable battery optimization for SafeMyanmar if the device aggressively
  stops foreground services.

### Sender says Bluetooth is unavailable

- Turn Bluetooth off and on again.
- Confirm the phone supports BLE advertising, not only BLE scanning.
- Reopen SafeMyanmar after granting permissions.
- Check that another application is not occupying the phone's BLE advertiser.

### Sender says broadcasting but Phone B receives nothing

- Install a fresh APK after any BLE code change; an old debug APK may still be
  running the previous advertiser implementation.
- Confirm Phone B has **Receive nearby SOS** enabled before starting Phone A.
- Keep Phone B's SOS screen open and keep both phones close together.
- Confirm both phones have Nearby Devices permission enabled.
- Check the sender log for the actual advertiser callback:

```powershell
$appPid = & $adb -s PHONE_A_SERIAL shell pidof org.safemyanmar.mobile
& $adb -s PHONE_A_SERIAL logcat --pid=$appPid -d |
  findstr /I "SosBleBroadcastService BLE SOS advertising"
```

The sender should contain:

```text
BLE SOS advertising started
```

The receiver should contain:

```text
BLE SOS scanning started
BLE SOS advertisement received
```

If the sender contains `BLE SOS advertising failed`, the error code is an
Android advertiser failure and the app should show a failed status instead of
claiming that the broadcast is active.

### Permission was permanently denied

Open Android app settings for SafeMyanmar and manually enable Nearby Devices
and Notifications permissions, then restart the test.

### Testing backend connectivity too

BLE does not need a backend. If backend behavior is also being tested, create
the USB tunnel for each phone independently:

```powershell
& $adb -s PHONE_A_SERIAL reverse tcp:8000 tcp:8000
& $adb -s PHONE_B_SERIAL reverse tcp:8000 tcp:8000
```

Use this mobile runtime setting for both phones:

```text
API_BASE_URL=http://127.0.0.1:8000
```
