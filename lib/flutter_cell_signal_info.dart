import 'dart:async';
import 'package:flutter/services.dart';

class CellularInfo {
  final int signalStrength;
  final String networkType;
  final String operatorName;
  final int cellId;
  final double latitude;
  final double longitude;

  CellularInfo({
    required this.signalStrength,
    required this.networkType,
    required this.operatorName,
    required this.cellId,
    required this.latitude,
    required this.longitude,
  });

  factory CellularInfo.fromMap(Map<String, dynamic> map) {
    return CellularInfo(
      signalStrength: map['signalStrength'] ?? 0,
      networkType: map['networkType'] ?? 'unknown',
      operatorName: map['operatorName'] ?? 'unknown',
      cellId: map['cellId'] ?? 0,
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
    );
  }
}

class WifiInfo {
  final String ssid;
  final int signalStrength;
  final String frequency;
  final String capabilities;

  WifiInfo({
    required this.ssid,
    required this.signalStrength,
    required this.frequency,
    required this.capabilities,
  });

  factory WifiInfo.fromMap(Map<String, dynamic> map) {
    return WifiInfo(
      ssid: map['ssid'] ?? 'unknown',
      signalStrength: map['signalStrength'] ?? 0,
      frequency: map['frequency'] ?? 'unknown',
      capabilities: map['capabilities'] ?? 'unknown',
    );
  }
}

class FlutterCellSignalInfo {
  static const MethodChannel _channel =
      MethodChannel('flutter_cell_signal_info');
  static const EventChannel _cellularEventChannel =
      EventChannel('flutter_cell_signal_info/cellular_stream');
  static const EventChannel _wifiEventChannel =
      EventChannel('flutter_cell_signal_info/wifi_stream');

  static Future<CellularInfo> getCellularInfo() async {
    try {
      final Map<String, dynamic> result =
          await _channel.invokeMethod('getCellularInfo');
      return CellularInfo.fromMap(result);
    } on PlatformException catch (e) {
      throw 'Failed to get cellular info: ${e.message}';
    }
  }

  static Future<WifiInfo> getWifiInfo() async {
    try {
      final Map<String, dynamic> result =
          await _channel.invokeMethod('getWifiInfo');
      return WifiInfo.fromMap(result);
    } on PlatformException catch (e) {
      throw 'Failed to get WiFi info: ${e.message}';
    }
  }

  static Stream<CellularInfo> get cellularInfoStream {
    return _cellularEventChannel
        .receiveBroadcastStream()
        .map((event) => CellularInfo.fromMap(Map<String, dynamic>.from(event)));
  }

  static Stream<WifiInfo> get wifiInfoStream {
    return _wifiEventChannel
        .receiveBroadcastStream()
        .map((event) => WifiInfo.fromMap(Map<String, dynamic>.from(event)));
  }
}
