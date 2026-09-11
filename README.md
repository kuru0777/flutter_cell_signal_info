# flutter_cell_signal_info

Read live cellular and WiFi radio data on Android from Flutter — signal strength,
network type, operator, serving cell identity and LTE metrics — plus a path-loss
distance estimate and raw orientation sensor data.

[![pub package](https://img.shields.io/pub/v/flutter_cell_signal_info.svg)](https://pub.dev/packages/flutter_cell_signal_info)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84)

> **Android only.** iOS does not expose cellular radio details to third-party apps,
> so there is no iOS implementation and there is unlikely to ever be one.

---

## What this package actually measures

Everything in this section is read from the Android platform APIs.

| Data | Source |
|---|---|
| Signal strength (dBm) | `CellSignalStrength.dbm` |
| Network type, operator name | `TelephonyManager` |
| Serving cell identity, cell ID | `CellInfo.isRegistered` over `allCellInfo` |
| LTE metrics — RSRP, RSRQ, SINR, PCI, TAC | `CellSignalStrengthLte`, `CellIdentityLte` |
| Frequency / band class | `CellIdentity` EARFCN, mapped to band |
| Nearby cells and their signal strength | `TelephonyManager.allCellInfo` |
| Distance estimate to a cell | Log-distance path-loss model over the measured dBm |
| WiFi SSID, signal, frequency, capabilities | `WifiManager` |
| Compass heading, accelerometer, gyroscope | `SensorManager` |

## What is simulated, and why

Some of the API surface returns modelled values rather than measurements. These
methods are marked in their dartdoc and listed here so nobody builds on them by
mistake.

| Value | Status |
|---|---|
| `TowerBearing.bearing` | **Simulated.** Android does not expose tower azimuth to apps. Bearing is currently derived from the cell's index in the scan result. Do not use it to aim an antenna. |
| `RFEnvironmentAnalysis.signalToNoiseRatio` | **Simulated.** The noise floor is a generated value, not a measurement. |
| `RFEnvironmentAnalysis.interferenceLevel` | **Simulated.** Estimated from the number of visible WiFi networks. |
| Directional signal pattern | **Simulated.** Per-bearing strengths are modelled from the current signal. |
| `measureSignalAtBearing()` | **Simulated.** There is no per-bearing signal API on Android. |
| `calibrateARSensors()` | **Not implemented.** Returns placeholder constants. |

Real bearing requires resolving cell identity against a tower database such as
OpenCelliD, or triangulating across multiple positions. That is planned; see
[Roadmap](#roadmap).

---

## Install

```yaml
dependencies:
  flutter_cell_signal_info: ^0.1.0
```

Requires `minSdkVersion 21`. The package itself pulls in no third-party
dependencies - only the Flutter SDK - so it will not conflict with the
versions of `sensors_plus`, `permission_handler` or `camera` your app uses.

## Permissions

The plugin manifest declares these; they are merged into your app:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

`ACCESS_FINE_LOCATION` and `READ_PHONE_STATE` are runtime permissions — request them
before calling any method, for example with `permission_handler`. Without location
permission Android returns empty or redacted cell information.

## Usage

```dart
import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';

// Cellular
final cell = await FlutterCellSignalInfo.getCellularInfo();
print('${cell.operatorName} ${cell.networkType} ${cell.signalStrength} dBm');
print('RSRP ${cell.rsrp}  RSRQ ${cell.rsrq}  PCI ${cell.pci}');

// WiFi
final wifi = await FlutterCellSignalInfo.getWifiInfo();
print('${wifi.ssid} ${wifi.signalStrength} dBm @ ${wifi.frequency} MHz');

// Nearby cells — signal and distance are real, bearing is not (see above)
for (final tower in await FlutterCellSignalInfo.getNearbyTowers()) {
  print('${tower.signalStrength} dBm, ~${tower.distance.toInt()} m');
}

// Orientation sensors
if (await FlutterCellSignalInfo.isARNavigationSupported()) {
  await FlutterCellSignalInfo.startARNavigation();
  final o = await FlutterCellSignalInfo.getDeviceOrientation();
  print('compass ${o.compassBearing}°');
  await FlutterCellSignalInfo.stopARNavigation();
}
```

A full example app is in [`example/`](example) — it exercises every method and renders
the sensor and signal data live.

## Error handling

Every method throws [`CellSignalException`] on failure, which implements
`Exception`, so the idiomatic pattern works:

```dart
try {
  final cell = await FlutterCellSignalInfo.getCellularInfo();
} on CellSignalException catch (e) {
  if (e.code == 'PERMISSION_DENIED') {
    // ACCESS_FINE_LOCATION or READ_PHONE_STATE is missing
  }
  print(e.message);
}
```

Methods that read telephony data return `PERMISSION_DENIED` when location or
phone-state permission has not been granted, rather than failing with an opaque
error. Sensor-only methods (`getDeviceOrientation`, `startARNavigation`,
`isARNavigationSupported`) need no permission.

## API

| Method | Returns |
|---|---|
| `getCellularInfo()` | `CellularInfo` — strength, type, operator, cell id, LTE metrics |
| `getWifiInfo()` | `WifiInfo` — SSID, strength, frequency, capabilities |
| `getNearbyTowers()` | `List<TowerBearing>` — one entry per visible cell |
| `getServingTowerForAR()` | `TowerBearing?` for the registered cell |
| `analyzeRFEnvironment()` | `RFEnvironmentAnalysis` — see simulation notes |
| `getOptimizationReport()` | `NetworkOptimizationReport` — see simulation notes |
| `isARNavigationSupported()` | `bool` — accelerometer, gyroscope and magnetometer all present |
| `startARNavigation()` / `stopARNavigation()` | Registers / unregisters sensor listeners |
| `getDeviceOrientation()` | Compass heading, accelerometer and gyroscope values |
| `startTowerHunting()` / `stopTowerHunting()` | See simulation notes |
| `measureSignalAtBearing()` | See simulation notes |
| `calibrateARSensors()` | Placeholder, not implemented |

## Roadmap

- Real bearing via OpenCelliD lookup on `cellId` + `tac` + `mcc`/`mnc`
- Real bearing via triangulation across recorded positions
- Replace the simulated RF environment metrics with measured values, or remove them
- Migrate to current `sensors_plus`, `permission_handler` and `camera` majors

Contributions and bug reports welcome:
[issues](https://github.com/kuru0777/flutter_cell_signal_info/issues)

## License

Apache-2.0 — see [LICENSE](LICENSE).
