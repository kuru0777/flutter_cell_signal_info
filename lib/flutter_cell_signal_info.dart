import 'dart:async';
import 'package:flutter/services.dart';
import 'models/rf_analysis_models.dart';

class CellularInfo {
  final int signalStrength;
  final String networkType;
  final String operatorName;
  final int cellId;
  final double latitude;
  final double longitude;
  // Advanced RF analysis fields
  final int? frequency;
  final int? bandClass;
  final String? technology;
  final int? pci; // Physical Cell Identity
  final int? tac; // Tracking Area Code
  final int? rsrp; // Reference Signal Received Power
  final int? rsrq; // Reference Signal Received Quality
  final int? sinr; // Signal to Interference plus Noise Ratio

  CellularInfo({
    required this.signalStrength,
    required this.networkType,
    required this.operatorName,
    required this.cellId,
    required this.latitude,
    required this.longitude,
    this.frequency,
    this.bandClass,
    this.technology,
    this.pci,
    this.tac,
    this.rsrp,
    this.rsrq,
    this.sinr,
  });

  factory CellularInfo.fromMap(Map<String, dynamic> map) {
    return CellularInfo(
      signalStrength: map['signalStrength'] ?? 0,
      networkType: map['networkType'] ?? 'unknown',
      operatorName: map['operatorName'] ?? 'unknown',
      cellId: map['cellId'] ?? 0,
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      frequency: map['frequency'],
      bandClass: map['bandClass'],
      technology: map['technology'],
      pci: map['pci'],
      tac: map['tac'],
      rsrp: map['rsrp'],
      rsrq: map['rsrq'],
      sinr: map['sinr'],
    );
  }

  /// Estimate distance to tower using signal strength
  double get estimatedDistance {
    if (frequency == null) return 0.0;
    return RFMath.estimateDistanceFromSignal(
        signalStrength, frequency!.toDouble());
  }

  /// Get signal quality assessment
  String get signalQuality {
    if (signalStrength >= -70) return 'Excellent';
    if (signalStrength >= -85) return 'Good';
    if (signalStrength >= -100) return 'Fair';
    return 'Poor';
  }
}

class WifiInfo {
  final String ssid;
  final int signalStrength;
  final String frequency;
  final String capabilities;
  // Advanced WiFi analysis fields
  final String? bssid;
  final int? channel;
  final int? bandwidth;
  final String? security;
  final int? linkSpeed;

  WifiInfo({
    required this.ssid,
    required this.signalStrength,
    required this.frequency,
    required this.capabilities,
    this.bssid,
    this.channel,
    this.bandwidth,
    this.security,
    this.linkSpeed,
  });

  factory WifiInfo.fromMap(Map<String, dynamic> map) {
    return WifiInfo(
      ssid: map['ssid'] ?? 'unknown',
      signalStrength: map['signalStrength'] ?? 0,
      frequency: map['frequency'] ?? 'unknown',
      capabilities: map['capabilities'] ?? 'unknown',
      bssid: map['bssid'],
      channel: map['channel'],
      bandwidth: map['bandwidth'],
      security: map['security'],
      linkSpeed: map['linkSpeed'],
    );
  }

  /// Get signal quality assessment
  String get signalQuality {
    if (signalStrength >= -30) return 'Excellent';
    if (signalStrength >= -50) return 'Good';
    if (signalStrength >= -70) return 'Fair';
    return 'Poor';
  }
}

class FlutterCellSignalInfo {
  static const MethodChannel _channel =
      MethodChannel('flutter_cell_signal_info');
  static const EventChannel _cellularEventChannel =
      EventChannel('flutter_cell_signal_info/cellular_stream');
  static const EventChannel _wifiEventChannel =
      EventChannel('flutter_cell_signal_info/wifi_stream');

  // === Basic API (existing) ===

  static Future<CellularInfo> getCellularInfo() async {
    try {
      final result = await _channel.invokeMethod('getCellularInfo');
      final Map<String, dynamic> data = Map<String, dynamic>.from(result);
      return CellularInfo.fromMap(data);
    } on PlatformException catch (e) {
      throw 'Failed to get cellular info: ${e.message}';
    }
  }

  static Future<WifiInfo> getWifiInfo() async {
    try {
      final result = await _channel.invokeMethod('getWifiInfo');
      final Map<String, dynamic> data = Map<String, dynamic>.from(result);
      return WifiInfo.fromMap(data);
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

  // === Professional RF Analysis API ===

  /// Get detailed tower bearing information
  static Future<List<TowerBearing>> getNearbyTowers() async {
    try {
      final result = await _channel.invokeMethod('getNearbyTowers');
      final List<dynamic> towersList = result as List<dynamic>;
      return towersList
          .map(
              (tower) => TowerBearing.fromMap(Map<String, dynamic>.from(tower)))
          .toList();
    } on PlatformException catch (e) {
      throw 'Failed to get nearby towers: ${e.message}';
    }
  }

  /// Perform comprehensive RF environment analysis
  static Future<RFEnvironmentAnalysis> analyzeRFEnvironment() async {
    try {
      final result = await _channel.invokeMethod('analyzeRFEnvironment');
      final Map<String, dynamic> data = Map<String, dynamic>.from(result);

      // Parse nearby towers
      final List<dynamic> towersData = data['nearbyTowers'] ?? [];
      final List<TowerBearing> towers = towersData
          .map(
              (tower) => TowerBearing.fromMap(Map<String, dynamic>.from(tower)))
          .toList();

      // Parse signal pattern
      final Map<String, dynamic> patternData = data['signalPattern'] ?? {};
      final List<int> strengths =
          (patternData['signalStrengths'] as List?)?.cast<int>() ?? [];
      final List<double> bearings = (patternData['bearings'] as List?)
              ?.cast<num>()
              .map((e) => e.toDouble())
              .toList() ??
          [];

      SignalPattern pattern;
      if (strengths.isNotEmpty && bearings.isNotEmpty) {
        pattern = SignalPattern.fromMeasurements(strengths, bearings);
      } else {
        // Create default pattern if no data
        pattern = SignalPattern.fromMeasurements([0], [0.0]);
      }

      return RFEnvironmentAnalysis(
        nearbyTowers: towers,
        signalPattern: pattern,
        optimalBearing: (data['optimalBearing'] ?? 0.0).toDouble(),
        signalToNoiseRatio: (data['signalToNoiseRatio'] ?? 0.0).toDouble(),
        interferenceLevel: (data['interferenceLevel'] ?? 0.0).toDouble(),
        environmentQuality: (data['environmentQuality'] ?? 0.5).toDouble(),
        timestamp: DateTime.now(),
      );
    } on PlatformException catch (e) {
      throw 'Failed to analyze RF environment: ${e.message}';
    }
  }

  /// Generate network optimization recommendations
  static Future<NetworkOptimizationReport> getOptimizationReport() async {
    try {
      final analysis = await analyzeRFEnvironment();
      return NetworkOptimizationReport.fromAnalysis(analysis);
    } catch (e) {
      throw 'Failed to generate optimization report: $e';
    }
  }

  /// Start tower direction hunting mode (continuous bearing analysis)
  static Future<void> startTowerHunting() async {
    try {
      await _channel.invokeMethod('startTowerHunting');
    } on PlatformException catch (e) {
      throw 'Failed to start tower hunting: ${e.message}';
    }
  }

  /// Stop tower direction hunting mode
  static Future<void> stopTowerHunting() async {
    try {
      await _channel.invokeMethod('stopTowerHunting');
    } on PlatformException catch (e) {
      throw 'Failed to stop tower hunting: ${e.message}';
    }
  }

  /// Calculate bearing to strongest tower from current location
  static Future<double?> getStrongestTowerBearing() async {
    try {
      final towers = await getNearbyTowers();
      if (towers.isEmpty) return null;

      // Find strongest tower
      final strongestTower = towers.reduce((current, next) =>
          current.signalStrength > next.signalStrength ? current : next);

      return strongestTower.bearing;
    } catch (e) {
      return null;
    }
  }

  /// Measure signal in specific direction (requires device rotation)
  static Future<int> measureSignalAtBearing(double bearing) async {
    try {
      final result = await _channel.invokeMethod('measureSignalAtBearing', {
        'bearing': bearing,
      });
      return result as int;
    } on PlatformException catch (e) {
      throw 'Failed to measure signal at bearing: ${e.message}';
    }
  }

  /// Export RF analysis data to JSON for professional tools
  static Future<Map<String, dynamic>> exportAnalysisData() async {
    try {
      final analysis = await analyzeRFEnvironment();
      final cellular = await getCellularInfo();
      final wifi = await getWifiInfo();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': {
          'platform': 'android', // TODO: detect platform
        },
        'cellular': {
          'signal_strength': cellular.signalStrength,
          'network_type': cellular.networkType,
          'operator': cellular.operatorName,
          'cell_id': cellular.cellId,
          'location': {
            'latitude': cellular.latitude,
            'longitude': cellular.longitude,
          },
          'frequency': cellular.frequency,
          'technology': cellular.technology,
          'rsrp': cellular.rsrp,
          'rsrq': cellular.rsrq,
          'sinr': cellular.sinr,
        },
        'wifi': {
          'ssid': wifi.ssid,
          'signal_strength': wifi.signalStrength,
          'frequency': wifi.frequency,
          'bssid': wifi.bssid,
          'channel': wifi.channel,
          'security': wifi.security,
        },
        'rf_analysis': {
          'nearby_towers': analysis.nearbyTowers.map((t) => t.toMap()).toList(),
          'optimal_bearing': analysis.optimalBearing,
          'signal_to_noise_ratio': analysis.signalToNoiseRatio,
          'interference_level': analysis.interferenceLevel,
          'environment_quality': analysis.environmentQuality,
          'signal_pattern': {
            'peak_bearing': analysis.signalPattern.peakBearing,
            'peak_strength': analysis.signalPattern.peakStrength,
            'directionality_index': analysis.signalPattern.directionalityIndex,
            'quality': analysis.signalPattern.quality,
          },
        },
      };
    } catch (e) {
      throw 'Failed to export analysis data: $e';
    }
  }
}
