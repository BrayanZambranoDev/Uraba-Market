import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Obtener stream de cambios de conectividad
  Stream<bool> get isConnected => _connectivity.onConnectivityChanged.map(
        (result) => result != ConnectivityResult.none,
      );

  // Verificar conectividad actual
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
