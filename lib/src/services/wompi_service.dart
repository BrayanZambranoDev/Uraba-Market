import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class WompiService {
  // Llaves de Producción — dinero real
  static const String publicKey    = 'pub_prod_eLvtaRyyUPq4le4Kjp6E2F6t8Vv0VVXl';
  static const String _privateKey  = 'prv_prod_tqYPuBcULIELmkat0TCdw2hsFIFxUlu8';
  static const String _integrityKey = 'prod_integrity_4TtgMbxOe3MnmjGmpmzjhKG9IPNi2YvG';

  static const String _checkoutBase = 'https://checkout.wompi.co/p/';
  static const String _apiBase      = 'https://production.wompi.co/v1';

  // URL de retorno — el WebView intercepta esta URL antes de que se cargue
  static const String redirectBase = 'https://urabamarket.co/wompi-pago';

  /// Computa la firma de integridad SHA256 requerida por Wompi.
  static String _computeIntegrity(String reference, int amountCents) {
    final data = '$reference${amountCents}COP$_integrityKey';
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  /// Construye la URL del checkout de Wompi con firma de integridad.
  static String buildCheckoutUrl({
    required double amountCOP,
    required String reference,
  }) {
    final cents = amountCOP.toInt() * 100;
    final integrity = _computeIntegrity(reference, cents);
    final encodedRedirect = Uri.encodeComponent(redirectBase);
    return '$_checkoutBase'
        '?public-key=$publicKey'
        '&currency=COP'
        '&amount-in-cents=$cents'
        '&reference=$reference'
        '&signature:integrity=$integrity'
        '&redirect-url=$encodedRedirect';
  }

  /// Genera una referencia única para el pedido.
  static String generateReference() =>
      'UM-${DateTime.now().millisecondsSinceEpoch}';

  /// Consulta el estado de una transacción en la API de Wompi.
  static Future<Map<String, dynamic>?> getTransaction(String id) async {
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/transactions/$id'),
        headers: {'Authorization': 'Bearer $_privateKey'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  /// Retorna true si la transacción fue aprobada.
  static bool isApproved(Map<String, dynamic> txn) =>
      txn['status'] == 'APPROVED';

  /// Mensaje legible según el estado de la transacción.
  static String statusMessage(String status) {
    switch (status) {
      case 'DECLINED': return 'El banco rechazó el pago. Verifica tus datos.';
      case 'VOIDED':   return 'El pago fue anulado.';
      case 'ERROR':    return 'Error procesando el pago. Intenta de nuevo.';
      case 'PENDING':  return 'El pago está pendiente de confirmación.';
      default:         return 'El pago no fue aprobado ($status).';
    }
  }
}
