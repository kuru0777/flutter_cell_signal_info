import 'package:flutter/material.dart';
import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';
import 'package:flutter_cell_signal_info/models/rf_analysis_models.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professional RF Analysis Suite',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: const RFAnalysisHomePage(),
    );
  }
}

class RFAnalysisHomePage extends StatefulWidget {
  const RFAnalysisHomePage({super.key});

  @override
  State<RFAnalysisHomePage> createState() => _RFAnalysisHomePageState();
}

class _RFAnalysisHomePageState extends State<RFAnalysisHomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Basic info
  CellularInfo? _cellularInfo;
  WifiInfo? _wifiInfo;

  // Professional RF Analysis
  List<TowerBearing> _nearbyTowers = [];
  RFEnvironmentAnalysis? _rfAnalysis;
  NetworkOptimizationReport? _optimizationReport;

  // UI State
  bool _isAnalyzing = false;
  bool _isHunting = false;
  String _status = 'Ready for RF Analysis';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _startBasicInfoStream();
  }

  void _startBasicInfoStream() {
    // Start cellular info stream
    FlutterCellSignalInfo.cellularInfoStream.listen((info) {
      if (mounted) {
        setState(() {
          _cellularInfo = info;
        });
      }
    });

    // Start WiFi info stream
    FlutterCellSignalInfo.wifiInfoStream.listen((info) {
      if (mounted) {
        setState(() {
          _wifiInfo = info;
        });
      }
    });
  }

  Future<void> _performRFAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _status = 'Analyzing RF Environment...';
    });

    try {
      // Get nearby towers
      final towers = await FlutterCellSignalInfo.getNearbyTowers();

      // Perform full RF analysis
      final analysis = await FlutterCellSignalInfo.analyzeRFEnvironment();

      // Generate optimization report
      final report = await FlutterCellSignalInfo.getOptimizationReport();

      setState(() {
        _nearbyTowers = towers;
        _rfAnalysis = analysis;
        _optimizationReport = report;
        _status = 'RF Analysis Complete ✅';
      });
    } catch (e) {
      setState(() {
        _status = 'Analysis Error: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _toggleTowerHunting() async {
    try {
      if (_isHunting) {
        await FlutterCellSignalInfo.stopTowerHunting();
        setState(() {
          _isHunting = false;
          _status = 'Tower Hunting Stopped';
        });
      } else {
        await FlutterCellSignalInfo.startTowerHunting();
        setState(() {
          _isHunting = true;
          _status = 'Tower Hunting Active 🎯';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Hunting Error: $e';
      });
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await FlutterCellSignalInfo.exportAnalysisData();
      setState(() {
        _status = 'Data exported: ${data.keys.length} sections';
      });

      // In a real app, you would save this to file or share it
      debugPrint('📊 Exported RF Analysis Data: ${data.toString()}');
    } catch (e) {
      setState(() {
        _status = 'Export Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional RF Analysis Suite'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.signal_cellular_alt), text: 'Live Data'),
            Tab(icon: Icon(Icons.cell_tower), text: 'Towers'),
            Tab(icon: Icon(Icons.analytics), text: 'Analysis'),
            Tab(icon: Icon(Icons.tune), text: 'Optimize'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _isAnalyzing
                ? Colors.orange.shade100
                : _isHunting
                    ? Colors.green.shade100
                    : Colors.blue.shade50,
            child: Row(
              children: [
                if (_isAnalyzing || _isHunting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_isAnalyzing || _isHunting) const SizedBox(width: 8),
                Text(
                  _status,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveDataTab(),
                _buildTowersTab(),
                _buildAnalysisTab(),
                _buildOptimizationTab(),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "analysis",
            onPressed: _isAnalyzing ? null : _performRFAnalysis,
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.analytics, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "hunting",
            onPressed: _toggleTowerHunting,
            backgroundColor: _isHunting ? Colors.red : Colors.green,
            child: Icon(
              _isHunting ? Icons.stop : Icons.explore,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cellular Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.signal_cellular_alt, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('Cellular Network',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (_cellularInfo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _getSignalColor(_cellularInfo!.signalStrength),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _cellularInfo!.signalQuality,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_cellularInfo != null) ...[
                    _buildInfoRow('Signal Strength',
                        '${_cellularInfo!.signalStrength} dBm'),
                    _buildInfoRow('Network Type', _cellularInfo!.networkType),
                    _buildInfoRow('Operator', _cellularInfo!.operatorName),
                    _buildInfoRow('Cell ID', _cellularInfo!.cellId.toString()),
                    if (_cellularInfo!.frequency != null)
                      _buildInfoRow('Frequency',
                          '${(_cellularInfo!.frequency! / 1000000).toStringAsFixed(1)} MHz'),
                    if (_cellularInfo!.technology != null)
                      _buildInfoRow('Technology', _cellularInfo!.technology!),
                    if (_cellularInfo!.pci != null)
                      _buildInfoRow('PCI', _cellularInfo!.pci.toString()),
                    _buildInfoRow('Est. Distance',
                        '${_cellularInfo!.estimatedDistance.toStringAsFixed(0)} m'),
                  ] else
                    const Text('Waiting for cellular data...'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // WiFi Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('WiFi Network',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (_wifiInfo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSignalColor(_wifiInfo!.signalStrength),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _wifiInfo!.signalQuality,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_wifiInfo != null) ...[
                    _buildInfoRow('SSID', _wifiInfo!.ssid),
                    _buildInfoRow(
                        'Signal Strength', '${_wifiInfo!.signalStrength} dBm'),
                    _buildInfoRow('Frequency', _wifiInfo!.frequency),
                    if (_wifiInfo!.channel != null)
                      _buildInfoRow('Channel', _wifiInfo!.channel.toString()),
                    if (_wifiInfo!.linkSpeed != null)
                      _buildInfoRow(
                          'Link Speed', '${_wifiInfo!.linkSpeed} Mbps'),
                    if (_wifiInfo!.security != null)
                      _buildInfoRow('Security', _wifiInfo!.security!),
                  ] else
                    const Text('Waiting for WiFi data...'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Detected Towers: ${_nearbyTowers.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_nearbyTowers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No towers detected yet.\nTap the analysis button to scan for nearby towers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nearbyTowers.length,
              itemBuilder: (context, index) {
                final tower = _nearbyTowers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSignalColor(tower.signalStrength),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                        '${tower.bearing.toStringAsFixed(1)}° - ${tower.distance.toStringAsFixed(0)}m'),
                    subtitle: Text(
                      'Signal: ${tower.signalStrength} dBm\nConfidence: ${(tower.confidence * 100).toStringAsFixed(1)}%',
                    ),
                    trailing: Icon(
                      _getBearingIcon(tower.bearing),
                      size: 32,
                      color: Colors.grey.shade600,
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_rfAnalysis == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No RF analysis data yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the analysis button to start',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Environment Quality Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RF Environment Quality',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _rfAnalysis!.environmentQuality,
                    backgroundColor: Colors.grey.shade300,
                    color: _getQualityColor(_rfAnalysis!.environmentQuality),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '${(_rfAnalysis!.environmentQuality * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.explore, size: 32, color: Colors.blue),
                        const SizedBox(height: 8),
                        const Text('Optimal Bearing'),
                        Text(
                          '${_rfAnalysis!.optimalBearing.toStringAsFixed(1)}°',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.graphic_eq,
                            size: 32, color: Colors.green),
                        const SizedBox(height: 8),
                        const Text('SNR'),
                        Text(
                          _rfAnalysis!.signalToNoiseRatio.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Signal Pattern Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Signal Pattern Analysis',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Peak Bearing',
                      '${_rfAnalysis!.signalPattern.peakBearing.toStringAsFixed(1)}°'),
                  _buildInfoRow('Peak Strength',
                      '${_rfAnalysis!.signalPattern.peakStrength} dBm'),
                  _buildInfoRow('Directionality',
                      '${(_rfAnalysis!.signalPattern.directionalityIndex * 100).toStringAsFixed(1)}%'),
                  _buildInfoRow('Pattern Quality',
                      '${(_rfAnalysis!.signalPattern.quality * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    if (_optimizationReport == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No optimization report yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Run RF analysis to get recommendations',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Quality Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getQualityIcon(_optimizationReport!.currentQuality),
                        color: _getQualityColorByName(
                            _optimizationReport!.currentQuality),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Quality: ${_optimizationReport!.currentQuality}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_optimizationReport!.estimatedImprovement > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Potential improvement: +${_optimizationReport!.estimatedImprovement} dBm',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recommendations Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Optimization Recommendations',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_optimizationReport!.recommendations.isEmpty)
                    const Text(
                        'No specific recommendations needed - signal quality is excellent!')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _optimizationReport!.recommendations.length,
                      itemBuilder: (context, index) {
                        final recommendation =
                            _optimizationReport!.recommendations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(recommendation),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Export Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportData,
              icon: const Icon(Icons.download),
              label: const Text('Export Analysis Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getSignalColor(int signalStrength) {
    if (signalStrength >= -70) return Colors.green;
    if (signalStrength >= -85) return Colors.orange;
    if (signalStrength >= -100) return Colors.red;
    return Colors.grey;
  }

  Color _getQualityColor(double quality) {
    if (quality > 0.8) return Colors.green;
    if (quality > 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getQualityColorByName(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getQualityIcon(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Icons.signal_cellular_4_bar;
      case 'good':
        return Icons.signal_cellular_alt;
      case 'fair':
        return Icons.signal_cellular_alt;
      case 'poor':
        return Icons.signal_cellular_alt;
      default:
        return Icons.signal_cellular_off;
    }
  }

  IconData _getBearingIcon(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return Icons.north;
    if (bearing >= 22.5 && bearing < 67.5) return Icons.north_east;
    if (bearing >= 67.5 && bearing < 112.5) return Icons.east;
    if (bearing >= 112.5 && bearing < 157.5) return Icons.south_east;
    if (bearing >= 157.5 && bearing < 202.5) return Icons.south;
    if (bearing >= 202.5 && bearing < 247.5) return Icons.south_west;
    if (bearing >= 247.5 && bearing < 292.5) return Icons.west;
    return Icons.north_west;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
