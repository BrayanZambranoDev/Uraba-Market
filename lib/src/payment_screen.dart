import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/wompi_service.dart';
import 'wompi_checkout_screen.dart';
import 'package:iconsax/iconsax.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaymentScreen — Paso 2 del checkout
// Solo 2 métodos: Contra entrega (directo) y Pagar en línea (Wompi)
// ─────────────────────────────────────────────────────────────────────────────
class PaymentScreen extends StatefulWidget {
  final double total;
  final int itemCount;
  final Map<String, dynamic> direccionEntrega;
  final Future<void> Function(String metodoPago) onConfirm;

  const PaymentScreen({
    super.key,
    required this.total,
    required this.itemCount,
    required this.direccionEntrega,
    required this.onConfirm,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

// Opciones de pago simplificadas
enum _PayOption { contraEntrega, enLinea }

class _PaymentScreenState extends State<PaymentScreen> {
  _PayOption _selected = _PayOption.contraEntrega;
  bool _isProcessing = false;

  static String _fmtCOP(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    final len = s.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '\$${buf.toString()}';
  }

  Future<void> _confirm() async {
    if (_selected == _PayOption.contraEntrega) {
      // ── Efectivo: crea el pedido directamente ─────────────────────────────
      setState(() => _isProcessing = true);
      try {
        await widget.onConfirm('Contra entrega');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => _PaymentSuccessScreen(
              total: widget.total, metodoPago: 'Contra entrega'),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        final msg = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Error al crear el pedido';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
          margin: const EdgeInsets.all(12),
        ));
      }
    } else {
      // ── En línea: abre la pasarela de Wompi ──────────────────────────────
      final reference = WompiService.generateReference();
      final checkoutUrl = WompiService.buildCheckoutUrl(
        amountCOP: widget.total,
        reference: reference,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => WompiCheckoutScreen(
          checkoutUrl: checkoutUrl,
          reference: reference,
          total: widget.total,
          metodoPago: 'Pago en línea',
          onPaymentSuccess: () => widget.onConfirm('Pago en línea'),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16,
                MediaQuery.of(context).padding.bottom + 200),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Opción 1: Contra entrega ──────────────────────────────────
              _sectionTitle('Pago en efectivo'),
              const SizedBox(height: 10),
              _optionCard(
                option: _PayOption.contraEntrega,
                icon: Iconsax.truck,
                iconColor: const Color(0xFF34D399),
                iconBg: const Color(0xFF0D2E20),
                title: 'Contra entrega',
                subtitle: 'Paga en efectivo cuando recibes tu pedido',
                badge: null,
                detail: 'Sin costo adicional · Pago al momento de entrega',
              ),

              const SizedBox(height: 24),

              // ── Opción 2: Pago en línea ───────────────────────────────────
              _sectionTitle('Pago en línea'),
              const SizedBox(height: 10),
              _optionCard(
                option: _PayOption.enLinea,
                icon: Iconsax.card_tick,
                iconColor: const Color(0xFF818CF8),
                iconBg: const Color(0xFF1E1B4B),
                title: 'Pagar con Wompi',
                subtitle: 'Tarjeta, Nequi, PSE, Daviplata, Bancolombia y más',
                badge: 'SEGURO',
                detail: null,
                extra: _buildWompiLogos(),
              ),

              const SizedBox(height: 24),

              // ── Info de seguridad ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: AppTheme.radiusL,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  const Icon(Iconsax.shield_tick, size: 18, color: Color(0xFF34D399)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Todos los pagos son procesados de forma cifrada y segura. '
                    'Urabá Market nunca almacena datos de tu tarjeta.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textMuted, height: 1.5),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ]),
      bottomSheet: _buildConfirmBar(),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 0.8));
  }

  Widget _optionCard({
    required _PayOption option,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String? badge,
    required String? detail,
    Widget? extra,
  }) {
    final sel = _selected == option;
    return GestureDetector(
      onTap: () => setState(() => _selected = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? AppTheme.surfaceHigh : AppTheme.cardBg,
          borderRadius: AppTheme.radiusL,
          border: Border.all(
            color: sel ? AppTheme.primary : AppTheme.border,
            width: sel ? 2 : 1,
          ),
          boxShadow: sel
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ícono
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: iconBg, borderRadius: AppTheme.radiusM),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          // Contenido
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2E20),
                    borderRadius: AppTheme.radiusFull,
                    border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                  ),
                  child: Text(badge, style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF34D399))),
                ),
            ]),
            const SizedBox(height: 3),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppTheme.textSecondary)),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(detail, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textMuted)),
            ],
            if (extra != null) ...[
              const SizedBox(height: 10),
              extra,
            ],
          ])),
          const SizedBox(width: 12),
          // Radio
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sel ? AppTheme.primary : Colors.transparent,
              border: Border.all(
                color: sel ? AppTheme.primary : AppTheme.border,
                width: 2,
              ),
            ),
            child: sel
                ? const Icon(Iconsax.check, color: Colors.white, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _buildWompiLogos() {
    final methods = [
      _WompiMethod('Nequi',       const Color(0xFF6B21A8), Iconsax.wallet),
      _WompiMethod('PSE',         const Color(0xFF1D4ED8), Iconsax.buildings_2),
      _WompiMethod('Tarjeta',     const Color(0xFF374151), Iconsax.card_tick),
      _WompiMethod('Daviplata',   const Color(0xFFB91C1C), Icons.smartphone_rounded),
      _WompiMethod('Bancolombia', const Color(0xFF92400E), Iconsax.wallet),
      _WompiMethod('Efecty',      const Color(0xFFB45309), Iconsax.shop),
    ];
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: methods.map((m) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: m.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: m.color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(m.icon, size: 11, color: m.color.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(m.name, style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: m.color.withValues(alpha: 0.9))),
        ]),
      )).toList(),
    );
  }

  Widget _buildHeader() {
    final dir = widget.direccionEntrega;
    final municipio = dir['municipio'] as String? ?? '';
    final barrio    = dir['barrio']    as String? ?? '';
    final direccion = dir['direccion'] as String? ?? '';
    final telefono  = dir['telefono']  as String? ?? '';

    return Container(
      color: AppTheme.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back + título
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg, shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Método de pago', style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('Elige cómo pagar tu pedido', style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppTheme.textMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2E20),
                  borderRadius: AppTheme.radiusFull,
                  border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Iconsax.lock, size: 11, color: Color(0xFF34D399)),
                  const SizedBox(width: 4),
                  Text('Seguro', style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: const Color(0xFF34D399))),
                ]),
              ),
            ]),
            const SizedBox(height: 18),

            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 18),

            // Resumen del pedido
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: AppTheme.radiusL,
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.receipt_2, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.itemCount} producto${widget.itemCount != 1 ? 's' : ''} en tu pedido',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted)),
                  Text('Resumen del pedido', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textMuted)),
                  Text(_fmtCOP(widget.total), style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                ]),
              ]),
            ),
            const SizedBox(height: 8),

            // Dirección resumen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: AppTheme.radiusL,
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                const Icon(Iconsax.location, size: 16, color: Color(0xFF34D399)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$municipio${barrio.isNotEmpty ? ', $barrio' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (direccion.isNotEmpty)
                    Text(direccion, style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                if (telefono.isNotEmpty)
                  Text(telefono, style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppTheme.textMuted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(children: [
      _stepItem('1', 'Dirección', active: false, done: true),
      _stepLine(done: true),
      _stepItem('2', 'Pago', active: true, done: false),
      _stepLine(done: false),
      _stepItem('3', 'Listo', active: false, done: false),
    ]);
  }

  Widget _stepItem(String num, String label, {required bool active, required bool done}) {
    return Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : done ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppTheme.primary : done ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: done
              ? const Icon(Iconsax.check, size: 16, color: Colors.white)
              : Text(num, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppTheme.textMuted)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? AppTheme.primary : AppTheme.textMuted)),
    ]);
  }

  Widget _stepLine({required bool done}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
        decoration: BoxDecoration(
          color: done ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.surfaceHigh,
          borderRadius: AppTheme.radiusFull,
        ),
      ),
    );
  }

  Widget _buildConfirmBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Resumen del método seleccionado
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            _selected == _PayOption.contraEntrega ? Iconsax.truck : Iconsax.lock,
            size: 13,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            _selected == _PayOption.contraEntrega
                ? 'Contra entrega — pagas al recibir'
                : 'Pago seguro procesado por Wompi',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.surfaceHigh,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(
                      _selected == _PayOption.contraEntrega
                          ? Iconsax.tick_circle
                          : Iconsax.export_3,
                      color: Colors.white, size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selected == _PayOption.contraEntrega
                          ? 'Confirmar pedido'
                          : 'Ir a pagar con Wompi',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ]),
          ),
        ),
      ]),
    );
  }
}

// Modelo para los logos de Wompi
class _WompiMethod {
  final String name;
  final Color color;
  final IconData icon;
  const _WompiMethod(this.name, this.color, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla de éxito — Contra entrega
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentSuccessScreen extends StatefulWidget {
  final double total;
  final String metodoPago;
  const _PaymentSuccessScreen({required this.total, required this.metodoPago});

  @override
  State<_PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<_PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  static String _fmtCOP(double v) {
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
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(children: [
              const Spacer(flex: 2),

              // Ícono animado
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Iconsax.tick_circle, color: AppTheme.primary, size: 64),
                ),
              ),
              const SizedBox(height: 28),

              Text('¡Pedido confirmado!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('El vendedor fue notificado y pronto\ntendrás tu pedido en casa.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: AppTheme.textMuted, height: 1.6)),
              const SizedBox(height: 32),

              // Resumen
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: AppTheme.radiusXL,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(children: [
                  _row(Iconsax.truck, const Color(0xFF34D399),
                      'Método', widget.metodoPago),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 12),
                  _row(Iconsax.receipt_2, AppTheme.primary, 'Total',
                      _fmtCOP(widget.total), highlight: true),
                ]),
              ),

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
                    elevation: 0,
                  ),
                  child: Text('Ver mis pedidos', style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text('Seguir comprando', style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String label, String value, {bool highlight = false}) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, color: AppTheme.textMuted))),
      Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: highlight ? 18 : 13,
          fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
          color: highlight ? AppTheme.primary : Colors.white)),
    ]);
  }
}
