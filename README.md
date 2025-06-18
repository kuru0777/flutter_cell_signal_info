# Flutter Cell Signal Info

A Flutter plugin that provides cellular and WiFi signal information for Android devices.

## Features

- 📱 Get cellular signal strength and network information
- 📶 Access WiFi connection details
- 🔄 Real-time signal monitoring with streams
- 🎯 Cell tower identification
- 📍 Network operator information

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_cell_signal_info: ^0.0.1
```

## Android Permissions

Add these permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Usage

### Import the package

```dart
import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';
```

### Get cellular information (one-time)

```dart
try {
  CellularInfo cellInfo = await FlutterCellSignalInfo.getCellularInfo();
  print('Signal Strength: ${cellInfo.signalStrength} dBm');
  print('Network Type: ${cellInfo.networkType}');
  print('Operator: ${cellInfo.operatorName}');
  print('Cell ID: ${cellInfo.cellId}');
} catch (e) {
  print('Error: $e');
}
```

### Get WiFi information (one-time)

```dart
try {
  WifiInfo wifiInfo = await FlutterCellSignalInfo.getWifiInfo();
  print('SSID: ${wifiInfo.ssid}');
  print('Signal Strength: ${wifiInfo.signalStrength} dBm');
  print('Frequency: ${wifiInfo.frequency} MHz');
} catch (e) {
  print('Error: $e');
}
```

### Monitor signal changes in real-time

```dart
// Cellular signal stream
StreamSubscription? cellularSubscription = FlutterCellSignalInfo.cellularInfoStream.listen(
  (CellularInfo info) {
    print('Updated signal: ${info.signalStrength} dBm');
  },
  onError: (error) {
    print('Stream error: $error');
  },
);

// WiFi signal stream
StreamSubscription? wifiSubscription = FlutterCellSignalInfo.wifiInfoStream.listen(
  (WifiInfo info) {
    print('WiFi signal: ${info.signalStrength} dBm');
  },
);

// Don't forget to cancel subscriptions
cellularSubscription?.cancel();
wifiSubscription?.cancel();
```

### Complete example with permission handling

```dart
import 'package:flutter/material.dart';
import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';
import 'package:permission_handler/permission_handler.dart';

class SignalMonitorPage extends StatefulWidget {
  @override
  _SignalMonitorPageState createState() => _SignalMonitorPageState();
}

class _SignalMonitorPageState extends State<SignalMonitorPage> {
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.request();
    final phoneStatus = await Permission.phone.request();

    setState(() {
      _hasPermissions = locationStatus.isGranted && phoneStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Permissions required'),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: Text('Request Permissions'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Signal Monitor')),
      body: Column(
        children: [
          StreamBuilder<CellularInfo>(
            stream: FlutterCellSignalInfo.cellularInfoStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              final info = snapshot.data!;
              return Card(
                child: ListTile(
                  title: Text('Cellular Signal'),
                  subtitle: Text('${info.signalStrength} dBm - ${info.networkType}'),
                ),
              );
            },
          ),
          StreamBuilder<WifiInfo>(
            stream: FlutterCellSignalInfo.wifiInfoStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              final info = snapshot.data!;
              return Card(
                child: ListTile(
                  title: Text('WiFi Signal'),
                  subtitle: Text('${info.signalStrength} dBm - ${info.ssid}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

## Data Models

### CellularInfo

| Property | Type | Description |
|----------|------|-------------|
| signalStrength | int | Signal strength in dBm |
| networkType | String | Network type (2G, 3G, 4G, 5G) |
| operatorName | String | Mobile network operator name |
| cellId | int | Cell tower identifier |
| latitude | double | Cell tower latitude (if available) |
| longitude | double | Cell tower longitude (if available) |

### WifiInfo

| Property | Type | Description |
|----------|------|-------------|
| ssid | String | WiFi network name |
| signalStrength | int | WiFi signal strength in dBm |
| frequency | String | WiFi frequency in MHz |
| capabilities | String | Security capabilities |

## Platform Support

- ✅ Android
- ❌ iOS (not yet implemented)

## Example App

Check out the example app in the `example/` directory for a complete implementation.

## Issues and Contributions

Please file feature requests and bugs at the [issue tracker](https://github.com/YOUR_GITHUB_USERNAME/flutter_cell_signal_info/issues).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

