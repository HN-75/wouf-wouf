import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service Bluetooth LE pour connecter un micro externe ou collier
class BluetoothService {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  
  final StreamController<BluetoothStatus> _statusController = 
      StreamController<BluetoothStatus>.broadcast();
  final StreamController<List<int>> _audioDataController = 
      StreamController<List<int>>.broadcast();

  Stream<BluetoothStatus> get statusStream => _statusController.stream;
  Stream<List<int>> get audioDataStream => _audioDataController.stream;
  
  bool get isConnected => _connectedDevice != null;
  String? get connectedDeviceName => _connectedDevice?.platformName;

  /// Vérifie si le Bluetooth est disponible et activé
  Future<bool> isAvailable() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return false;
      
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// Démarre le scan des appareils Bluetooth
  Future<Stream<List<ScanResult>>> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    // Arrêter tout scan en cours
    await FlutterBluePlus.stopScan();
    
    // Démarrer le scan
    await FlutterBluePlus.startScan(timeout: timeout);
    
    _statusController.add(BluetoothStatus.scanning);
    
    return FlutterBluePlus.scanResults;
  }

  /// Arrête le scan
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _statusController.add(BluetoothStatus.idle);
  }

  /// Se connecte à un appareil
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _statusController.add(BluetoothStatus.connecting);
      
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      
      // Écouter les changements de connexion
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });
      
      // Découvrir les services
      await _discoverServices(device);
      
      _statusController.add(BluetoothStatus.connected);
      return true;
    } catch (e) {
      _statusController.add(BluetoothStatus.error);
      return false;
    }
  }

  /// Découvre les services et caractéristiques de l'appareil
  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        // Chercher une caractéristique audio (notification)
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          _dataSubscription = characteristic.onValueReceived.listen((data) {
            _audioDataController.add(data);
          });
        }
      }
    }
  }

  /// Se déconnecte de l'appareil actuel
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _statusController.add(BluetoothStatus.disconnected);
  }

  /// Gère la déconnexion inattendue
  void _handleDisconnection() {
    _connectedDevice = null;
    _statusController.add(BluetoothStatus.disconnected);
  }

  /// Liste les appareils déjà appairés
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluePlus.bondedDevices;
  }

  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _statusController.close();
    _audioDataController.close();
  }
}

/// États du Bluetooth
enum BluetoothStatus {
  idle,
  scanning,
  connecting,
  connected,
  disconnected,
  error,
}

extension BluetoothStatusExtension on BluetoothStatus {
  String get label {
    switch (this) {
      case BluetoothStatus.idle:
        return 'En attente';
      case BluetoothStatus.scanning:
        return 'Recherche...';
      case BluetoothStatus.connecting:
        return 'Connexion...';
      case BluetoothStatus.connected:
        return 'Connecté';
      case BluetoothStatus.disconnected:
        return 'Déconnecté';
      case BluetoothStatus.error:
        return 'Erreur';
    }
  }
}
