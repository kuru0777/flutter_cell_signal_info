/// Professional RF Analysis Models
///
/// Advanced data structures for professional cellular signal analysis,
/// tower direction finding, and network optimization.
///
/// Author: Professional RF Analysis Suite
/// License: MIT

import 'dart:math' as math;

class TowerBearing {
  /// Bearing angle in degrees (0-360°) from North
  final double bearing;

  /// Distance to tower in meters
  final double distance;

  /// Confidence level (0.0-1.0) of the bearing calculation
  final double confidence;

  /// Signal strength at this bearing (dBm)
  final int signalStrength;

  /// Tower/Cell ID
  final int towerId;

  /// Timestamp of measurement
  final DateTime timestamp;

  const TowerBearing({
    required this.bearing,
    required this.distance,
    required this.confidence,
    required this.signalStrength,
    required this.towerId,
    required this.timestamp,
  });

  factory TowerBearing.fromMap(Map<String, dynamic> map) {
    return TowerBearing(
      bearing: (map['bearing'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      signalStrength: map['signalStrength'] ?? 0,
      towerId: map['towerId'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bearing': bearing,
      'distance': distance,
      'confidence': confidence,
      'signalStrength': signalStrength,
      'towerId': towerId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'TowerBearing(${bearing.toStringAsFixed(1)}°, ${distance.toStringAsFixed(0)}m, ${signalStrength}dBm)';
  }
}

class SignalPattern {
  /// Array of signal strengths in different directions (0-360°)
  final List<int> signalStrengths;

  /// Array of corresponding bearing angles
  final List<double> bearings;

  /// Peak signal strength direction
  final double peakBearing;

  /// Peak signal strength value
  final int peakStrength;

  /// Signal variation coefficient (higher = more directional)
  final double directionalityIndex;

  /// Measurement quality score (0.0-1.0)
  final double quality;

  const SignalPattern({
    required this.signalStrengths,
    required this.bearings,
    required this.peakBearing,
    required this.peakStrength,
    required this.directionalityIndex,
    required this.quality,
  });

  factory SignalPattern.fromMeasurements(
    List<int> strengths,
    List<double> bearings,
  ) {
    if (strengths.isEmpty ||
        bearings.isEmpty ||
        strengths.length != bearings.length) {
      throw ArgumentError('Invalid signal pattern data');
    }

    // Find peak
    int maxIndex = 0;
    for (int i = 1; i < strengths.length; i++) {
      if (strengths[i] > strengths[maxIndex]) {
        maxIndex = i;
      }
    }

    // Calculate directionality index (signal variation)
    final double mean =
        strengths.fold(0, (sum, val) => sum + val) / strengths.length;
    final double variance =
        strengths.fold(0.0, (sum, val) => sum + (val - mean) * (val - mean)) /
            strengths.length;
    final double stdDev = math.sqrt(variance);
    final double directionalityIndex = stdDev / mean;

    // Calculate quality based on measurement consistency
    final double quality =
        math.max(0.0, math.min(1.0, 1.0 - (directionalityIndex / 2.0)));

    return SignalPattern(
      signalStrengths: List.unmodifiable(strengths),
      bearings: List.unmodifiable(bearings),
      peakBearing: bearings[maxIndex],
      peakStrength: strengths[maxIndex],
      directionalityIndex: directionalityIndex,
      quality: quality,
    );
  }
}

class RFEnvironmentAnalysis {
  /// List of detected towers/cells
  final List<TowerBearing> nearbyTowers;

  /// Signal pattern analysis for current location
  final SignalPattern signalPattern;

  /// Recommended optimal bearing for best signal
  final double optimalBearing;

  /// Signal to noise ratio
  final double signalToNoiseRatio;

  /// Interference level (0.0-1.0, higher = more interference)
  final double interferenceLevel;

  /// Overall RF environment quality score (0.0-1.0)
  final double environmentQuality;

  /// Analysis timestamp
  final DateTime timestamp;

  const RFEnvironmentAnalysis({
    required this.nearbyTowers,
    required this.signalPattern,
    required this.optimalBearing,
    required this.signalToNoiseRatio,
    required this.interferenceLevel,
    required this.environmentQuality,
    required this.timestamp,
  });

  /// Get the strongest tower
  TowerBearing? get strongestTower {
    if (nearbyTowers.isEmpty) return null;

    return nearbyTowers.reduce((current, next) =>
        current.signalStrength > next.signalStrength ? current : next);
  }

  /// Get towers sorted by signal strength (strongest first)
  List<TowerBearing> get towersByStrength {
    final List<TowerBearing> sorted = List.from(nearbyTowers);
    sorted.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
    return sorted;
  }
}

class NetworkOptimizationReport {
  /// Current signal quality assessment
  final String currentQuality;

  /// Recommended actions for signal improvement
  final List<String> recommendations;

  /// Optimal device orientation (degrees from North)
  final double? optimalOrientation;

  /// Estimated signal improvement if recommendations followed
  final int estimatedImprovement;

  /// Technical details for advanced users
  final Map<String, dynamic> technicalDetails;

  /// Report generation timestamp
  final DateTime timestamp;

  const NetworkOptimizationReport({
    required this.currentQuality,
    required this.recommendations,
    this.optimalOrientation,
    required this.estimatedImprovement,
    required this.technicalDetails,
    required this.timestamp,
  });

  factory NetworkOptimizationReport.fromAnalysis(
      RFEnvironmentAnalysis analysis) {
    String quality;
    List<String> recommendations = [];
    int estimatedImprovement = 0;

    // Assess current quality
    if (analysis.environmentQuality > 0.8) {
      quality = 'Excellent';
    } else if (analysis.environmentQuality > 0.6) {
      quality = 'Good';
      recommendations.add(
          'Consider moving to optimal bearing: ${analysis.optimalBearing.toStringAsFixed(1)}°');
      estimatedImprovement = 5;
    } else if (analysis.environmentQuality > 0.4) {
      quality = 'Fair';
      recommendations.addAll([
        'Move to optimal bearing: ${analysis.optimalBearing.toStringAsFixed(1)}°',
        'Check for nearby obstacles blocking signal',
      ]);
      estimatedImprovement = 10;
    } else {
      quality = 'Poor';
      recommendations.addAll([
        'Move to optimal bearing: ${analysis.optimalBearing.toStringAsFixed(1)}°',
        'Consider changing location to reduce interference',
        'Check if device supports higher frequency bands',
      ]);
      estimatedImprovement = 15;
    }

    // Add interference-specific recommendations
    if (analysis.interferenceLevel > 0.6) {
      recommendations.add(
          'High interference detected - move away from electronic devices');
      estimatedImprovement += 5;
    }

    return NetworkOptimizationReport(
      currentQuality: quality,
      recommendations: recommendations,
      optimalOrientation: analysis.optimalBearing,
      estimatedImprovement: estimatedImprovement,
      technicalDetails: {
        'signalToNoiseRatio': analysis.signalToNoiseRatio,
        'interferenceLevel': analysis.interferenceLevel,
        'environmentQuality': analysis.environmentQuality,
        'towersDetected': analysis.nearbyTowers.length,
        'strongestTowerBearing': analysis.strongestTower?.bearing,
        'directionalityIndex': analysis.signalPattern.directionalityIndex,
      },
      timestamp: DateTime.now(),
    );
  }
}

// Helper class for mathematical calculations
class RFMath {
  /// Calculate bearing between two points (Haversine formula)
  static double calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    final double dLon = _toRadians(lon2 - lon1);
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);

    final double x = math.sin(dLon) * math.cos(lat2Rad);
    final double y = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final double bearing = math.atan2(x, y);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Estimate distance from signal strength (simplified path loss model)
  static double estimateDistanceFromSignal(
      int signalStrength, double frequency) {
    // Simplified free space path loss model
    // FSPL(dB) = 20*log10(d) + 20*log10(f) + 32.45
    // Where d is distance in km, f is frequency in MHz

    final double pathLoss =
        signalStrength.abs().toDouble(); // Assuming signal strength is in dBm
    final double frequencyMHz = frequency / 1000000; // Convert Hz to MHz

    // Solve for distance: d = 10^((FSPL - 20*log10(f) - 32.45) / 20)
    final double logDistance =
        (pathLoss - 20 * math.log(frequencyMHz) / math.ln10 - 32.45) / 20;
    final double distanceKm = math.pow(10, logDistance).toDouble();

    return distanceKm * 1000; // Convert to meters
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;
}
