import 'package:flutter/material.dart';
import 'package:flutter_cell_signal_info/flutter_cell_signal_info.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signal Hunter',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.request();
    final phoneStatus = await Permission.phone.request();

    setState(() {
      _hasPermissions = locationStatus.isGranted && phoneStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Uygulamanın çalışması için izinler gerekli'),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('İzinleri Kontrol Et'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Signal Hunter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCellularInfoCard(),
            const SizedBox(height: 16),
            _buildWifiInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCellularInfoCard() {
    return StreamBuilder<CellularInfo>(
      stream: FlutterCellSignalInfo.cellularInfoStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final info = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobil Veri Bilgileri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Sinyal Gücü', '${info.signalStrength} dBm'),
                _buildInfoRow('Ağ Tipi', info.networkType),
                _buildInfoRow('Operatör', info.operatorName),
                _buildInfoRow('Baz İstasyonu ID', info.cellId.toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWifiInfoCard() {
    return StreamBuilder<WifiInfo>(
      stream: FlutterCellSignalInfo.wifiInfoStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final info = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WiFi Bilgileri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('SSID', info.ssid),
                _buildInfoRow('Sinyal Gücü', '${info.signalStrength} dBm'),
                _buildInfoRow('Frekans', '${info.frequency} MHz'),
                _buildInfoRow('Güvenlik', info.capabilities),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
