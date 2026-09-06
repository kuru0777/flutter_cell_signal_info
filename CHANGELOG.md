## 0.1.0

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
