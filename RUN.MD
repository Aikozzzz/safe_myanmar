$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"                        
& $adb devices                                      
flutter devices

$deviceID = 

& $adb -s sseipbkjcudeijn7 reverse tcp:8000 tcp:8000

flutter run -d $deviceID `
    --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
    --dart-define=ENABLE_SIMULATION_DATA=true `
    --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=pk.eyJ1IjoiYWlrb21hcGJveCIsImEiOiJjbXNuZWVxN2kwaWxsMzJxd3h4anoxMG9iIn0.MQxZ27bJrgB_HV7TW2jcxA

& $adb -s sseipbkjcudeijn7 install -r "mobile\build\app\outputs\flutter-apk\app-debug.apk"                     


Wireless

$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
& $adb devices -l

  .\tools\run-android-usb-wireless.ps1 `
  -DeviceId sseipbkjcudeijn7 `
  -HostAddress 192.168.100.36 `
  -EnableSimulationData `
  -MapboxPublicAccessToken "pk.eyJ1IjoiYWlrb21hcGJveCIsImEiOiJjbXNuZWVxN2kwaWxsMzJxd3h4anoxMG9iIn0.MQxZ27bJrgB_HV7TW2jcxA"