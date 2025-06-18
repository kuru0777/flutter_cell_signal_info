import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';

void main() {
  test('CellularInfo fromMap test', () {
    final map = {
      'signalStrength': -80,
      'networkType': '4G',
      'operatorName': 'Turkcell',
      'cellId': 12345,
      'latitude': 41.0082,
      'longitude': 28.9784,
    };

    final cellularInfo = CellularInfo.fromMap(map);

    expect(cellularInfo.signalStrength, -80);
    expect(cellularInfo.networkType, '4G');
    expect(cellularInfo.operatorName, 'Turkcell');
    expect(cellularInfo.cellId, 12345);
    expect(cellularInfo.latitude, 41.0082);
    expect(cellularInfo.longitude, 28.9784);
  });

  test('WifiInfo fromMap test', () {
    final map = {
      'ssid': 'TestWiFi',
      'signalStrength': -65,
      'frequency': '2400',
      'capabilities': 'WPA2',
    };

    final wifiInfo = WifiInfo.fromMap(map);

    expect(wifiInfo.ssid, 'TestWiFi');
    expect(wifiInfo.signalStrength, -65);
    expect(wifiInfo.frequency, '2400');
    expect(wifiInfo.capabilities, 'WPA2');
  });

  test('CellularInfo fromMap with missing values', () {
    final map = <String, dynamic>{};

    final cellularInfo = CellularInfo.fromMap(map);

    expect(cellularInfo.signalStrength, 0);
    expect(cellularInfo.networkType, 'unknown');
    expect(cellularInfo.operatorName, 'unknown');
    expect(cellularInfo.cellId, 0);
    expect(cellularInfo.latitude, 0.0);
    expect(cellularInfo.longitude, 0.0);
  });

  test('WifiInfo fromMap with missing values', () {
    final map = <String, dynamic>{};

    final wifiInfo = WifiInfo.fromMap(map);

    expect(wifiInfo.ssid, 'unknown');
    expect(wifiInfo.signalStrength, 0);
    expect(wifiInfo.frequency, 'unknown');
    expect(wifiInfo.capabilities, 'unknown');
  });
}
