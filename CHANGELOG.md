## 0.1.0

* **Removed all four runtime dependencies.** `camera`, `sensors_plus`,
  `permission_handler` and `platform` were declared but imported nowhere in
  `lib/`; the Android side uses `SensorManager` directly. Depending on them
  forced every consumer to inherit the `camera` plugin (and its CAMERA
  permission), and the stale constraints - `sensors_plus ^4.0.2` against a
  current 7.x - made the package uninstallable alongside modern versions of
  those plugins. The package now depends only on the Flutter SDK.
* **`CellSignalException` replaces thrown strings.** All 17 throw sites raised
  raw `String`s, so `on Exception catch (e)` caught nothing. They now throw a
  type implementing `Exception`, carrying the platform error `code` where one
  is available.
* Telephony methods (`getNearbyTowers`, `getServingTower`,
  `analyzeRFEnvironment`, `startTowerHunting`, `measureSignalAtBearing`) now
  return `PERMISSION_DENIED` when permissions are missing, matching
  `getCellularInfo` and `getWifiInfo`.
* Moved the Android namespace off the `com.example` template placeholder to
  `com.kuru0777.flutter_cell_signal_info`.
* Removed a template unit test that asserted against `getPlatformVersion`, a
  method this plugin does not implement - it would have failed if ever run.
* Formatted all sources with `dart format` and upgraded to `flutter_lints` 6.
* Documented which parts of the API are measured and which are simulated.
  `bearing`, the RF environment metrics, `measureSignalAtBearing` and
  `calibrateARSensors` return modelled or placeholder values and are now marked
  experimental in both the dartdoc and the README.
* Rewrote the README around what the plugin actually reads from the Android
  platform APIs.
* Fixed a compile error in the example app (`CardTheme` -> `CardThemeData` for
  current Flutter SDKs) and cleared all 50 analyzer findings.
* Shortened the package description to fit pub.dev's 180 character guideline.

## 0.0.1

* Initial release of flutter_cell_signal_info
* Support for getting cellular signal information (signal strength, network type, operator name, cell ID)
* Support for getting WiFi information (SSID, signal strength, frequency)
* Real-time signal monitoring with streams
* Android platform support
* Example app demonstrating all features
* Comprehensive permission handling
