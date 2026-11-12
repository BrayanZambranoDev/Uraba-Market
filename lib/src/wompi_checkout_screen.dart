import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme/app_theme.dart';
import 'services/wompi_service.dart';
import 'package:iconsax/iconsax.dart';

class WompiCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  final String reference;
  final double total;
  final String metodoPago;
  final Future<void> Function() onPaymentSuccess;

  const WompiCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.reference,
    required this.total,
    required this.metodoPago,
    required this.onPaymentSuccess,
  });

  @override
  State<WompiCheckoutScreen> createState() => _WompiCheckoutScreenState();
}

class _WompiCheckoutScreenState extends State<WompiCheckoutScreen> {
  late final WebViewController _wvc;
  bool _pageLoading = true;
  bool _verifying  = false;

  @override
  void initState() {
    super.initState();
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF011713))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _pageLoading = true),
        onPageFinished: (_) => setState(() => _pageLoading = false),
        onNavigationRequest: (req) {
          // Interceptar la URL de retorno de Wompi
          if (req.url.startsWith(WompiService.redirectBase)) {
            _handleRedirect(req.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _handleRedirect(String url) async {
    setState(() => _verifying = true);
    try {
      final uri = Uri.parse(url);
      final txnId = uri.queryParameters['id'];

      if (txnId == null) {
        _goToResult(false, 'No se recibió confirmación del pago.');
        return;
      }

      // Pequeña espera para que Wompi registre el resultado
      await Future.delayed(const Duration(seconds: 2));

      final txn = await WompiService.getTransaction(txnId);

      if (txn != null && WompiService.isApproved(txn)) {
        await widget.onPaymentSuccess();
        if (!mounted) return;
        _goToResult(true, null);
      } else {
        final st = txn?['status'] as String? ?? 'UNKNOWN';
        _goToResult(false, WompiService.statusMessage(st));
      }
    } catch (_) {
      _goToResult(false, 'Error verificando el pago. Contacta al soporte.');
    }
  }

  void _goToResult(bool success, String? errorMsg) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => _WompiResultScreen(
        success: success,
        errorMsg: errorMsg,
        total: widget.total,
        metodoPago: widget.metodoPago,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.close_circle, color: AppTheme.textPrimary.withValues(alpha: 0.8)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Cancelar pago',
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B4A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Iconsax.lock, size: 11, color: Colors.white),
              const SizedBox(width: 4),
              Text('Pago seguro',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 10),
          Text('Wompi',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _wvc),

        // Loader inicial mientras carga el checkout
        if (_pageLoading)
          Container(
            color: AppTheme.bg,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                const SizedBox(height: 18),
                Text('Cargando pasarela de pago...',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted, fontSize: 14)),
              ]),
            ),
          ),

        // Overlay de verificación después de pagar
        if (_verifying)
          Container(
            color: Colors.black.withValues(alpha: 0.78),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                const SizedBox(height: 20),
                Text('Verificando tu pago...',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 8),
                Text('Por favor espera un momento',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted, fontSize: 13)),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla de resultado del pago
// ─────────────────────────────────────────────────────────────────────────────
class _WompiResultScreen extends StatelessWidget {
  final bool success;
  final String? errorMsg;
  final double total;
  final String metodoPago;

  const _WompiResultScreen({
    required this.success,
    required this.total,
    required this.metodoPago,
    this.errorMsg,
  });

  String _fmtCOP(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    final len = s.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '\$${buf.toString()} COP';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: (success ? AppTheme.primary : AppTheme.error)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Iconsax.tick_circle : Iconsax.close_circle,
                  size: 56,
                  color: success ? AppTheme.primary : AppTheme.error,
                ),
              ),
              const SizedBox(height: 28),

              // Título
              Text(
                success ? '¡Pago exitoso!' : 'Pago no completado',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                success
                    ? 'Tu pedido fue confirmado y el vendedor\nfue notificado.'
                    : (errorMsg ?? 'El pago no pudo ser procesado.\nIntenta con otro método.'),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: AppTheme.textMuted, height: 1.6),
                textAlign: TextAlign.center,
              ),

              if (success) ...[
                const SizedBox(height: 28),
                // Resumen del pago
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(children: [
                    _row('Método', metodoPago),
                    const SizedBox(height: 10),
                    _row('Total pagado', _fmtCOP(total), highlight: true),
                  ]),
                ),
              ],

              const SizedBox(height: 40),

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success ? AppTheme.primary : AppTheme.cardBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    success ? 'Ver mis pedidos' : 'Volver',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppTheme.textMuted)),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? AppTheme.primary : AppTheme.textPrimary)),
      ],
    );
  }
}
