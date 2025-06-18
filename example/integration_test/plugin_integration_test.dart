// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getCellularInfo test', (WidgetTester tester) async {
    try {
      final CellularInfo cellInfo =
          await FlutterCellSignalInfo.getCellularInfo();
      // Check that we got some data back
      expect(cellInfo.signalStrength, isA<int>());
      expect(cellInfo.networkType, isA<String>());
      expect(cellInfo.operatorName, isA<String>());
    } catch (e) {
      // Test might fail if permissions are not granted
      expect(e.toString(), contains('PERMISSION_DENIED'));
    }
  });

  testWidgets('getWifiInfo test', (WidgetTester tester) async {
    try {
      final WifiInfo wifiInfo = await FlutterCellSignalInfo.getWifiInfo();
      // Check that we got some data back
      expect(wifiInfo.ssid, isA<String>());
      expect(wifiInfo.signalStrength, isA<int>());
      expect(wifiInfo.frequency, isA<String>());
    } catch (e) {
      // Test might fail if permissions are not granted
      expect(e.toString(), contains('PERMISSION_DENIED'));
    }
  });
}
