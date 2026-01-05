import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/bluetooth_service.dart';

/// Écran de connexion Bluetooth
class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
  }

  Future<void> _checkBluetooth() async {
    final provider = context.read<AppProvider>();
    final isAvailable = await provider.bluetooth.isAvailable();
    
    if (!isAvailable && mounted) {
      setState(() {
        _error = 'Bluetooth non disponible ou désactivé';
      });
    }
  }

  Future<void> _startScan() async {
    final provider = context.read<AppProvider>();
    
    setState(() {
      _isScanning = true;
      _scanResults = [];
      _error = null;
    });

    try {
      final stream = await provider.bluetooth.startScan();
      
      stream.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results
                .where((r) => r.device.platformName.isNotEmpty)
                .toList();
          });
        }
      });

      // Arrêter après 10 secondes
      await Future.delayed(const Duration(seconds: 10));
      await _stopScan();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de scan: $e';
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _stopScan() async {
    final provider = context.read<AppProvider>();
    await provider.bluetooth.stopScan();
    
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final provider = context.read<AppProvider>();
    
    setState(() => _error = null);

    final success = await provider.bluetooth.connect(device);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecté à ${device.platformName}'),
            backgroundColor: const Color(0xFF81B29A),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error = 'Impossible de se connecter à ${device.platformName}';
        });
      }
    }
  }

  Future<void> _disconnect() async {
    final provider = context.read<AppProvider>();
    await provider.bluetooth.disconnect();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D405B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Micro Bluetooth',
          style: TextStyle(
            color: Color(0xFF3D405B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF81B29A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF81B29A).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF81B29A),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Connecte un micro Bluetooth ou un collier compatible pour une meilleure détection.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Appareil connecté
              if (provider.isBluetoothConnected) ...[
                _buildConnectedDevice(provider),
                const SizedBox(height: 24),
              ],

              // Erreur
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bouton de scan
              if (!provider.isBluetoothConnected)
                ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScan : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(_isScanning
                      ? 'Recherche en cours...'
                      : 'Rechercher des appareils'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE07A5F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              const SizedBox(height: 24),

              // Liste des appareils trouvés
              if (_scanResults.isNotEmpty) ...[
                const Text(
                  'Appareils trouvés',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D405B),
                  ),
                ),
                const SizedBox(height: 12),
                ..._scanResults.map((result) => _buildDeviceCard(result)),
              ],

              // Message si aucun appareil
              if (!_isScanning && _scanResults.isEmpty && !provider.isBluetoothConnected)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun appareil trouvé',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assure-toi que ton appareil est allumé et en mode appairage',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectedDevice(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF81B29A),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF81B29A).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF81B29A).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bluetooth_connected,
              color: Color(0xFF81B29A),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.bluetoothDeviceName ?? 'Appareil connecté',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D405B),
                  ),
                ),
                const Text(
                  'Connecté',
                  style: TextStyle(
                    color: Color(0xFF81B29A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _disconnect,
            child: const Text(
              'Déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final rssi = result.rssi;
    
    // Indicateur de force du signal
    IconData signalIcon;
    if (rssi > -60) {
      signalIcon = Icons.signal_cellular_4_bar;
    } else if (rssi > -70) {
      signalIcon = Icons.signal_cellular_alt;
    } else {
      signalIcon = Icons.signal_cellular_alt_1_bar;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFE07A5F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.bluetooth,
            color: Color(0xFFE07A5F),
          ),
        ),
        title: Text(
          device.platformName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D405B),
          ),
        ),
        subtitle: Row(
          children: [
            Icon(signalIcon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              '$rssi dBm',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(device),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE07A5F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Text('Connecter'),
        ),
      ),
    );
  }
}
