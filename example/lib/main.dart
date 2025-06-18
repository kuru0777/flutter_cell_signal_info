import 'package:flutter/material.dart';
import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';
import 'package:flutter_cell_signal_info/models/rf_analysis_models.dart';
import 'package:flutter_cell_signal_info/models/ar_navigation_models.dart'
    as ar;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RF Signal Hunter Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  // Camera for AR Navigation
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // Basic info
  CellularInfo? _cellularInfo;
  WifiInfo? _wifiInfo;

  // Professional RF Analysis
  List<TowerBearing> _nearbyTowers = [];
  RFEnvironmentAnalysis? _rfAnalysis;
  NetworkOptimizationReport? _optimizationReport;

  // AR Navigation
  bool _isARActive = false;
  ar.DeviceOrientation? _deviceOrientation;
  ar.TowerDirection? _towerDirection;
  TowerBearing? _targetTower;

  // UI State
  bool _isAnalyzing = false;
  bool _isHunting = false;
  String _status = 'Ready for RF Analysis';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 tabs now
    _startBasicInfoStream();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
        );
      }
    } catch (e) {
      developer.log('Camera initialization failed: $e');
    }
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

  Future<void> _startARNavigation() async {
    try {
      // Check camera permission
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        setState(() {
          _status = 'Kamera izni gerekli';
        });
        return;
      }

      // Initialize camera if not already done
      if (_cameraController == null) {
        await _initializeCamera();
      }

      if (_cameraController != null) {
        await _cameraController!.initialize();
      }

      // Show dialog to choose tower type
      final bool useServingTower = await _showTowerSelectionDialog() ?? false;

      // Get tower based on selection
      final TowerBearing? targetTower;
      if (useServingTower) {
        targetTower = await FlutterCellSignalInfo.getServingTowerForAR();
        if (targetTower == null) {
          setState(() {
            _status = 'Aktif bağlı kule bulunamadı';
          });
          return;
        }
      } else {
        targetTower = await FlutterCellSignalInfo.getBestTowerForAR();
        if (targetTower == null) {
          setState(() {
            _status = 'Kule bulunamadı - önce analiz yapın';
          });
          return;
        }
      }

      // Start AR navigation
      await FlutterCellSignalInfo.startARNavigation();

      setState(() {
        _isARActive = true;
        _targetTower = targetTower;
        _status = useServingTower
            ? 'AR Navigation - Aktif Kule 📡'
            : 'AR Navigation - En İyi Kule 🎯';
      });

      // Start listening to sensor data
      FlutterCellSignalInfo.arSensorStream.listen((orientation) {
        if (mounted && _isARActive) {
          setState(() {
            _deviceOrientation = orientation;
          });

          // Calculate tower direction if we have a target
          if (_targetTower != null) {
            final direction = ar.TowerDirection.calculate(
              targetBearing: _targetTower!.bearing,
              currentBearing: orientation.compassBearing,
              distance: _targetTower!.distance,
              signalStrength: _targetTower!.signalStrength,
              towerId: _targetTower!.towerId,
            );

            setState(() {
              _towerDirection = direction;
              _status = direction.instruction;
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _status = 'AR Navigation Hatası: $e';
      });
    }
  }

  Future<bool?> _showTowerSelectionDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade50,
                  Colors.indigo.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.indigo],
                    ),
                  ),
                  child: const Icon(
                    Icons.cell_tower,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'AR Kule Navigasyonu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Hangi kuleye yönlendirilmek istiyorsunuz?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Option Cards
                Column(
                  children: [
                    // Serving Tower Option
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.radio_button_checked,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📡 Aktif Bağlı Kule',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Şu an kullandığınız kuleye yönlendirir',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.green,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Best Tower Option
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.purple.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🎯 En İyi Kule',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'En güçlü sinyal alan kuleye yönlendirir',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.purple,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _stopARNavigation() async {
    try {
      await FlutterCellSignalInfo.stopARNavigation();

      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      setState(() {
        _isARActive = false;
        _deviceOrientation = null;
        _towerDirection = null;
        _targetTower = null;
        _status = 'AR Navigation Durduruldu';
      });
    } catch (e) {
      setState(() {
        _status = 'AR Durdurma Hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade900,
              Colors.indigo.shade700,
              Colors.indigo.shade500,
              Colors.purple.shade400,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Custom AppBar with Gradient
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Column(
                children: [
                  // App Title with Icon
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.radar,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'RF Signal Hunter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Professional RF Analysis Suite',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Modern TabBar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                            icon: Icon(Icons.signal_cellular_alt, size: 16),
                            text: 'Canlı'),
                        Tab(
                            icon: Icon(Icons.cell_tower, size: 16),
                            text: 'Kuleler'),
                        Tab(
                            icon: Icon(Icons.analytics, size: 16),
                            text: 'Analiz'),
                        Tab(icon: Icon(Icons.tune, size: 16), text: 'Optimize'),
                        Tab(icon: Icon(Icons.camera_alt, size: 16), text: 'AR'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Status Bar
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isAnalyzing
                    ? Colors.orange.withOpacity(0.9)
                    : _isHunting
                        ? Colors.green.withOpacity(0.9)
                        : _isARActive
                            ? Colors.purple.withOpacity(0.9)
                            : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isAnalyzing || _isHunting || _isARActive)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isAnalyzing || _isHunting || _isARActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isAnalyzing
                            ? 'Analyzing'
                            : _isHunting
                                ? 'Hunting'
                                : 'AR Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Content with background
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLiveDataTab(),
                      _buildTowersTab(),
                      _buildAnalysisTab(),
                      _buildOptimizationTab(),
                      _buildARNavigationTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Modern Floating Action Buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isARActive) ...[
            _buildModernFAB(
              heroTag: "analysis",
              onPressed: _isAnalyzing ? null : _performRFAnalysis,
              icon: Icons.analytics,
              label: 'Analiz',
              color: Colors.indigo,
            ),
            const SizedBox(height: 8),
            _buildModernFAB(
              heroTag: "hunting",
              onPressed: _toggleTowerHunting,
              icon: _isHunting ? Icons.stop : Icons.explore,
              label: _isHunting ? 'Durdur' : 'Avla',
              color: _isHunting ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 8),
          ],
          _buildModernFAB(
            heroTag: "ar_nav",
            onPressed: _isARActive ? _stopARNavigation : _startARNavigation,
            icon: _isARActive ? Icons.stop : Icons.camera_alt,
            label: _isARActive ? 'Durdur' : 'AR',
            color: _isARActive ? Colors.red : Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB({
    required String heroTag,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLiveDataTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.signal_cellular_4_bar,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Canlı Sinyal Verileri',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gerçek zamanlı hücresel ve WiFi bilgileri',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Cellular Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.signal_cellular_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Hücresel Ağ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Mobil bağlantı bilgileri',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_cellularInfo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSignalColor(
                                  _cellularInfo!.signalStrength),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.signal_cellular_4_bar,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _cellularInfo!.signalQuality,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_cellularInfo != null) ...[
                      _buildModernInfoCard(
                        Icons.signal_cellular_4_bar,
                        'Sinyal Gücü',
                        '${_cellularInfo!.signalStrength} dBm',
                        _getSignalColor(_cellularInfo!.signalStrength),
                      ),
                      _buildModernInfoCard(
                        Icons.network_cell,
                        'Ağ Türü',
                        _cellularInfo!.networkType,
                        Colors.blue,
                      ),
                      _buildModernInfoCard(
                        Icons.business,
                        'Operatör',
                        _cellularInfo!.operatorName,
                        Colors.orange,
                      ),
                      _buildModernInfoCard(
                        Icons.perm_identity,
                        'Hücre ID',
                        _cellularInfo!.cellId.toString(),
                        Colors.purple,
                      ),
                      if (_cellularInfo!.frequency != null)
                        _buildModernInfoCard(
                          Icons.radio,
                          'Frekans',
                          '${(_cellularInfo!.frequency! / 1000000).toStringAsFixed(1)} MHz',
                          Colors.green,
                        ),
                      if (_cellularInfo!.technology != null)
                        _buildModernInfoCard(
                          Icons.router,
                          'Teknoloji',
                          _cellularInfo!.technology!,
                          Colors.teal,
                        ),
                      if (_cellularInfo!.pci != null)
                        _buildModernInfoCard(
                          Icons.tag,
                          'PCI',
                          _cellularInfo!.pci.toString(),
                          Colors.indigo,
                        ),
                      _buildModernInfoCard(
                        Icons.straighten,
                        'Tahmini Mesafe',
                        _cellularInfo!.formattedDistance,
                        Colors.brown,
                      ),
                    ] else
                      _buildLoadingCard('Hücresel veri bekleniyor...'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // WiFi Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.wifi,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'WiFi Ağı',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Kablosuz bağlantı bilgileri',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_wifiInfo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSignalColor(_wifiInfo!.signalStrength),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _wifiInfo!.signalQuality,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_wifiInfo != null) ...[
                      _buildModernInfoCard(
                        Icons.wifi,
                        'SSID',
                        _wifiInfo!.ssid,
                        Colors.blue,
                      ),
                      _buildModernInfoCard(
                        Icons.signal_wifi_4_bar,
                        'Sinyal Gücü',
                        '${_wifiInfo!.signalStrength} dBm',
                        _getSignalColor(_wifiInfo!.signalStrength),
                      ),
                      _buildModernInfoCard(
                        Icons.radio,
                        'Frekans',
                        _wifiInfo!.frequency,
                        Colors.purple,
                      ),
                      if (_wifiInfo!.channel != null)
                        _buildModernInfoCard(
                          Icons.tune,
                          'Kanal',
                          _wifiInfo!.channel.toString(),
                          Colors.orange,
                        ),
                      if (_wifiInfo!.linkSpeed != null)
                        _buildModernInfoCard(
                          Icons.speed,
                          'Bağlantı Hızı',
                          '${_wifiInfo!.linkSpeed} Mbps',
                          Colors.green,
                        ),
                      if (_wifiInfo!.security != null)
                        _buildModernInfoCard(
                          Icons.security,
                          'Güvenlik',
                          _wifiInfo!.security!,
                          Colors.red,
                        ),
                    ] else
                      _buildLoadingCard('WiFi verisi bekleniyor...'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowersTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cell_tower,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tespit Edilen Kuleler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_nearbyTowers.length} kule bulundu',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.radar,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_nearbyTowers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_nearbyTowers.isEmpty)
              _buildEmptyTowersCard()
            else
              Column(
                children: _nearbyTowers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tower = entry.value;
                  return _buildTowerCard(tower, index);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTowersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cell_tower,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz Kule Tespit Edilmedi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yakındaki kuleleri taramak için analiz butonuna tıklayın',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'RF Analiz butonu ile etraftaki baz istasyonlarını keşfedin',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowerCard(TowerBearing tower, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tower Header
            Row(
              children: [
                // Tower Number Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getSignalColor(tower.signalStrength),
                        _getSignalColor(tower.signalStrength).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getBearingIcon(tower.bearing),
                            size: 24,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tower.bearing.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tower.distance.toStringAsFixed(0)} metre uzaklıkta',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Signal Quality Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSignalColor(tower.signalStrength),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.signal_cellular_4_bar,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getSignalQuality(tower.signalStrength),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tower Details
            Row(
              children: [
                Expanded(
                  child: _buildTowerDetailItem(
                    Icons.signal_cellular_4_bar,
                    'Sinyal',
                    '${tower.signalStrength} dBm',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildTowerDetailItem(
                    Icons.precision_manufacturing,
                    'Güvenilirlik',
                    '${(tower.confidence * 100).toStringAsFixed(0)}%',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildTowerDetailItem(
                    Icons.access_time,
                    'Zaman',
                    _formatTimestamp(tower.timestamp),
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar for Signal Strength
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sinyal Gücü',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${tower.signalStrength} dBm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _normalizeSignalStrength(tower.signalStrength),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getSignalColor(tower.signalStrength),
                  ),
                  minHeight: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTowerDetailItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getSignalQuality(int signalStrength) {
    if (signalStrength >= -70) return 'Mükemmel';
    if (signalStrength >= -85) return 'İyi';
    if (signalStrength >= -100) return 'Orta';
    return 'Zayıf';
  }

  double _normalizeSignalStrength(int signalStrength) {
    // Normalize signal strength from -120 to -30 dBm to 0.0 to 1.0
    return ((signalStrength + 120) / 90).clamp(0.0, 1.0);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk';
    } else {
      return '${difference.inHours}sa';
    }
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
                  _buildModernInfoCard(
                    Icons.explore,
                    'Peak Bearing',
                    '${_rfAnalysis!.signalPattern.peakBearing.toStringAsFixed(1)}°',
                    Colors.blue,
                  ),
                  _buildModernInfoCard(
                    Icons.signal_cellular_4_bar,
                    'Peak Strength',
                    '${_rfAnalysis!.signalPattern.peakStrength} dBm',
                    Colors.green,
                  ),
                  _buildModernInfoCard(
                    Icons.trending_up,
                    'Directionality',
                    '${(_rfAnalysis!.signalPattern.directionalityIndex * 100).toStringAsFixed(1)}%',
                    Colors.orange,
                  ),
                  _buildModernInfoCard(
                    Icons.stars,
                    'Pattern Quality',
                    '${(_rfAnalysis!.signalPattern.quality * 100).toStringAsFixed(1)}%',
                    Colors.purple,
                  ),
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

  Widget _buildARNavigationTab() {
    if (!_isARActive) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Icon with Animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.indigo],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.shade200,
                        blurRadius: 12,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'AR Kule Navigasyonu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 24,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kameraya bakarak baz istasyonu kulesinin yönünü görün',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Features List
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Özellikler:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        Icons.gps_fixed,
                        'Gerçek zamanlı yön gösterimi',
                        Colors.green,
                      ),
                      _buildFeatureItem(
                        Icons.radio_button_checked,
                        'Aktif kule veya en iyi kule seçimi',
                        Colors.blue,
                      ),
                      _buildFeatureItem(
                        Icons.speed,
                        'Mesafe ve sinyal gücü bilgisi',
                        Colors.orange,
                      ),
                      _buildFeatureItem(
                        Icons.explore,
                        'Pusula tabanlı navigasyon',
                        Colors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Start Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.indigo],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.shade300,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _startARNavigation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'AR Navigation Başlat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Warning Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.amber.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Telefonu dik tutun ve çevrede dönerek kule yönünü bulun',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        if (_cameraController != null && _cameraController!.value.isInitialized)
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // AR Overlay UI
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _deviceOrientation?.isVertical == true
                    ? Colors.green
                    : Colors.red,
                width: 4,
              ),
            ),
            child: Stack(
              children: [
                // Device Orientation Indicator
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _deviceOrientation?.isVertical == true
                              ? '📱 Telefon Dik ✅'
                              : '📱 Telefonu Dik Tutun ❌',
                          style: TextStyle(
                            color: _deviceOrientation?.isVertical == true
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_deviceOrientation != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Eğim: ${_deviceOrientation!.tiltAngle.toStringAsFixed(1)}°',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Pusula: ${_deviceOrientation!.compassBearing.toStringAsFixed(1)}°',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Tower Direction Indicator
                if (_towerDirection != null)
                  Positioned(
                    bottom: 120,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _towerDirection!.isOnTarget
                            ? Colors.green.withOpacity(0.9)
                            : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _towerDirection!.instruction,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Mesafe: ${_towerDirection!.distance.toStringAsFixed(0)}m',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Sinyal: ${_towerDirection!.signalStrength}dBm',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Crosshair in center
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Stop button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _stopARNavigation,
                      icon: const Icon(Icons.stop),
                      label: const Text('Durdur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
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
    _cameraController?.dispose();
    super.dispose();
  }
}
