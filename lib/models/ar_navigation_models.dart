/// AR Tower Navigation Models
///
/// Models for augmented reality tower direction finding and navigation.
/// Provides device orientation tracking, tower direction calculation,
/// and real-time navigation feedback.
///
/// Author: Professional RF Analysis Suite
/// License: MIT

import 'dart:math' as math;

/// Device orientation and sensor data
class DeviceOrientation {
  /// Phone tilt from vertical (0 = perfectly vertical)
  final double tiltAngle;

  /// Compass bearing in degrees (0-360°)
  final double compassBearing;

  /// Gyroscope rotation rates
  final double rotationX;
  final double rotationY;
  final double rotationZ;

  /// Accelerometer data
  final double accelerometerX;
  final double accelerometerY;
  final double accelerometerZ;

  /// Is device held vertically? (within tolerance)
  final bool isVertical;

  /// Compass accuracy (0.0-1.0)
  final double compassAccuracy;

  /// Timestamp of measurement
  final DateTime timestamp;

  const DeviceOrientation({
    required this.tiltAngle,
    required this.compassBearing,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.isVertical,
    required this.compassAccuracy,
    required this.timestamp,
  });

  factory DeviceOrientation.fromSensorData({
    required List<double> accelerometer,
    required List<double> gyroscope,
    required double compass,
    required double compassAccuracy,
  }) {
    // Calculate tilt angle from accelerometer
    final double tiltAngle = _calculateTiltAngle(
        accelerometer[0], accelerometer[1], accelerometer[2]);

    // Check if device is vertical (within 15 degrees tolerance)
    final bool isVertical = tiltAngle < 15.0;

    return DeviceOrientation(
      tiltAngle: tiltAngle,
      compassBearing: compass,
      rotationX: gyroscope[0],
      rotationY: gyroscope[1],
      rotationZ: gyroscope[2],
      accelerometerX: accelerometer[0],
      accelerometerY: accelerometer[1],
      accelerometerZ: accelerometer[2],
      isVertical: isVertical,
      compassAccuracy: compassAccuracy,
      timestamp: DateTime.now(),
    );
  }

  static double _calculateTiltAngle(double x, double y, double z) {
    // Calculate angle from vertical using accelerometer
    final double magnitude = math.sqrt(x * x + y * y + z * z);
    final double normalizedZ = z / magnitude;
    return math.acos(normalizedZ.abs()) * 180.0 / math.pi;
  }

  Map<String, dynamic> toMap() {
    return {
      'tiltAngle': tiltAngle,
      'compassBearing': compassBearing,
      'rotationX': rotationX,
      'rotationY': rotationY,
      'rotationZ': rotationZ,
      'accelerometerX': accelerometerX,
      'accelerometerY': accelerometerY,
      'accelerometerZ': accelerometerZ,
      'isVertical': isVertical,
      'compassAccuracy': compassAccuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Tower direction and navigation info
class TowerDirection {
  /// Target tower bearing in degrees (0-360°)
  final double targetBearing;

  /// Current device pointing direction
  final double currentBearing;

  /// Angular difference to target (-180 to +180)
  final double bearingDifference;

  /// Distance to tower in meters
  final double distance;

  /// Signal strength at tower location
  final int signalStrength;

  /// Tower ID/identifier
  final int towerId;

  /// Is user pointing at the tower? (within tolerance)
  final bool isOnTarget;

  /// Confidence level of direction (0.0-1.0)
  final double confidence;

  /// Navigation instruction for user
  final String instruction;

  const TowerDirection({
    required this.targetBearing,
    required this.currentBearing,
    required this.bearingDifference,
    required this.distance,
    required this.signalStrength,
    required this.towerId,
    required this.isOnTarget,
    required this.confidence,
    required this.instruction,
  });

  factory TowerDirection.calculate({
    required double targetBearing,
    required double currentBearing,
    required double distance,
    required int signalStrength,
    required int towerId,
    double tolerance = 10.0,
  }) {
    // Calculate bearing difference (-180 to +180)
    double difference = targetBearing - currentBearing;

    // Normalize to -180 to +180 range
    while (difference > 180) difference -= 360;
    while (difference < -180) difference += 360;

    // Check if on target
    final bool isOnTarget = difference.abs() <= tolerance;

    // Calculate confidence based on distance and signal
    final double confidence = _calculateConfidence(distance, signalStrength);

    // Generate instruction
    final String instruction = _generateInstruction(difference, isOnTarget);

    return TowerDirection(
      targetBearing: targetBearing,
      currentBearing: currentBearing,
      bearingDifference: difference,
      distance: distance,
      signalStrength: signalStrength,
      towerId: towerId,
      isOnTarget: isOnTarget,
      confidence: confidence,
      instruction: instruction,
    );
  }

  static double _calculateConfidence(double distance, int signalStrength) {
    // Closer distance = higher confidence
    final double distanceScore = math.max(0.0, 1.0 - (distance / 10000.0));

    // Stronger signal = higher confidence
    final double signalScore = math.max(0.0, (signalStrength + 120) / 50.0);

    return math.min(1.0, (distanceScore + signalScore) / 2.0);
  }

  static String _generateInstruction(double difference, bool isOnTarget) {
    if (isOnTarget) {
      return "🎯 HEDEF BULUNDU!";
    } else if (difference.abs() < 5) {
      return "🔥 Çok yakın! Biraz daha...";
    } else if (difference > 45) {
      return "↪️ Çok sağa dön: ${difference.toStringAsFixed(0)}°";
    } else if (difference > 15) {
      return "➡️ Sağa dön: ${difference.toStringAsFixed(0)}°";
    } else if (difference > 5) {
      return "↗️ Hafif sağa: ${difference.toStringAsFixed(0)}°";
    } else if (difference < -45) {
      return "↩️ Çok sola dön: ${(-difference).toStringAsFixed(0)}°";
    } else if (difference < -15) {
      return "⬅️ Sola dön: ${(-difference).toStringAsFixed(0)}°";
    } else if (difference < -5) {
      return "↖️ Hafif sola: ${(-difference).toStringAsFixed(0)}°";
    } else {
      return "🎯 Hedefte!";
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'targetBearing': targetBearing,
      'currentBearing': currentBearing,
      'bearingDifference': bearingDifference,
      'distance': distance,
      'signalStrength': signalStrength,
      'towerId': towerId,
      'isOnTarget': isOnTarget,
      'confidence': confidence,
      'instruction': instruction,
    };
  }
}

/// AR Navigation session state
class ARNavigationState {
  /// Is AR mode active?
  final bool isActive;

  /// Current device orientation
  final DeviceOrientation deviceOrientation;

  /// Current tower direction info
  final TowerDirection? towerDirection;

  /// Navigation session duration
  final Duration sessionDuration;

  /// Number of towers found in this session
  final int towersFound;

  /// Current navigation status
  final String status;

  /// Is calibration needed?
  final bool needsCalibration;

  const ARNavigationState({
    required this.isActive,
    required this.deviceOrientation,
    this.towerDirection,
    required this.sessionDuration,
    required this.towersFound,
    required this.status,
    required this.needsCalibration,
  });

  factory ARNavigationState.initial() {
    return ARNavigationState(
      isActive: false,
      deviceOrientation: DeviceOrientation(
        tiltAngle: 0.0,
        compassBearing: 0.0,
        rotationX: 0.0,
        rotationY: 0.0,
        rotationZ: 0.0,
        accelerometerX: 0.0,
        accelerometerY: 0.0,
        accelerometerZ: 9.8,
        isVertical: true,
        compassAccuracy: 0.0,
        timestamp: DateTime.now(),
      ),
      sessionDuration: Duration.zero,
      towersFound: 0,
      status: "AR Navigation Ready",
      needsCalibration: true,
    );
  }

  ARNavigationState copyWith({
    bool? isActive,
    DeviceOrientation? deviceOrientation,
    TowerDirection? towerDirection,
    Duration? sessionDuration,
    int? towersFound,
    String? status,
    bool? needsCalibration,
  }) {
    return ARNavigationState(
      isActive: isActive ?? this.isActive,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      towerDirection: towerDirection ?? this.towerDirection,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      towersFound: towersFound ?? this.towersFound,
      status: status ?? this.status,
      needsCalibration: needsCalibration ?? this.needsCalibration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'deviceOrientation': deviceOrientation.toMap(),
      'towerDirection': towerDirection?.toMap(),
      'sessionDuration': sessionDuration.inMilliseconds,
      'towersFound': towersFound,
      'status': status,
      'needsCalibration': needsCalibration,
    };
  }
}

/// AR calibration data
class ARCalibration {
  /// Compass offset correction in degrees
  final double compassOffset;

  /// GPS bearing vs compass bearing correlation
  final double bearingCorrelation;

  /// Number of calibration points used
  final int calibrationPoints;

  /// Calibration accuracy score (0.0-1.0)
  final double accuracy;

  /// When was calibration performed
  final DateTime calibrationTime;

  /// Is calibration valid?
  final bool isValid;

  const ARCalibration({
    required this.compassOffset,
    required this.bearingCorrelation,
    required this.calibrationPoints,
    required this.accuracy,
    required this.calibrationTime,
    required this.isValid,
  });

  factory ARCalibration.empty() {
    return ARCalibration(
      compassOffset: 0.0,
      bearingCorrelation: 0.0,
      calibrationPoints: 0,
      accuracy: 0.0,
      calibrationTime: DateTime.now(),
      isValid: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'compassOffset': compassOffset,
      'bearingCorrelation': bearingCorrelation,
      'calibrationPoints': calibrationPoints,
      'accuracy': accuracy,
      'calibrationTime': calibrationTime.millisecondsSinceEpoch,
      'isValid': isValid,
    };
  }
}
