import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'payment_screen.dart';
import 'package:iconsax/iconsax.dart';

class DeliveryAddressScreen extends StatefulWidget {
  final double total;
  final int itemCount;
  final Future<void> Function(String metodoPago, Map<String, dynamic> direccion) onConfirm;

  const DeliveryAddressScreen({
    super.key,
    required this.total,
    required this.itemCount,
    required this.onConfirm,
  });

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barrioCtrl     = TextEditingController();
  final _direccionCtrl  = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _telefonoCtrl   = TextEditingController();
  final _otroMunicipioCtrl = TextEditingController();

  String? _municipio;
  bool _showOtroField = false;
  bool _guardar = true;
  bool _isLoading = true;

  static const _municipios = [
    'Apartadó', 'Turbo', 'Carepa', 'Chigorodó', 'Necoclí',
    'Mutatá', 'Arboletes', 'San Pedro de Urabá', 'San Juan de Urabá',
    'Vigía del Fuerte', 'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrevious();
  }

  @override
  void dispose() {
    _barrioCtrl.dispose();
    _direccionCtrl.dispose();
    _referenciaCtrl.dispose();
    _telefonoCtrl.dispose();
    _otroMunicipioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrevious() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        final tel = data['telefono'] as String?;
        if (tel != null && tel.isNotEmpty) _telefonoCtrl.text = tel;
        final prev = data['ultimaDireccion'] as Map<String, dynamic>?;
        if (prev != null) {
          final muni = prev['municipio'] as String? ?? '';
          if (_municipios.contains(muni)) {
            _municipio = muni; _showOtroField = muni == 'Otro';
          } else if (muni.isNotEmpty) {
            _municipio = 'Otro'; _showOtroField = true;
            _otroMunicipioCtrl.text = muni;
          }
          _barrioCtrl.text    = prev['barrio']     as String? ?? '';
          _direccionCtrl.text = prev['direccion']  as String? ?? '';
          _referenciaCtrl.text = prev['referencia'] as String? ?? '';
          final prevTel = prev['telefono'] as String?;
          if (prevTel != null && prevTel.isNotEmpty) _telefonoCtrl.text = prevTel;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    if (_municipio == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Selecciona tu municipio',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }
    final municipioFinal = _showOtroField ? _otroMunicipioCtrl.text.trim() : _municipio!;
    final direccion = <String, dynamic>{
      'municipio': municipioFinal,
      'barrio': _barrioCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      if (_referenciaCtrl.text.trim().isNotEmpty) 'referencia': _referenciaCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
    };
    if (_guardar) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid)
            .update({'ultimaDireccion': direccion}).catchError((_) {});
      }
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentScreen(
        total: widget.total,
        itemCount: widget.itemCount,
        direccionEntrega: direccion,
        onConfirm: (metodoPago) => widget.onConfirm(metodoPago, direccion),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _buildForm(),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dirección de entrega',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('¿Dónde entregamos tu pedido?',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
              ])),
            ]),
            const SizedBox(height: 20),
            _buildStepIndicator(activeStep: 1),
          ]),
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required int activeStep}) {
    return Row(children: [
      _stepItem('1', 'Dirección', active: activeStep == 1, done: activeStep > 1),
      _stepLine(done: activeStep > 1),
      _stepItem('2', 'Pago', active: activeStep == 2, done: activeStep > 2),
      _stepLine(done: activeStep > 2),
      _stepItem('3', 'Listo', active: activeStep == 3, done: false),
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

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Municipio ──────────────────────────────────────────────────────
          _label(Iconsax.buildings_2, 'Municipio'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _municipios.map((m) => _municipioChip(m)).toList(),
          ),
          if (_showOtroField) ...[
            const SizedBox(height: 12),
            _field(ctrl: _otroMunicipioCtrl, hint: 'Nombre del municipio',
                icon: Iconsax.location,
                validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe el nombre' : null),
          ],
          const SizedBox(height: 24),

          // ── Barrio / Vereda ─────────────────────────────────────────────────
          _label(Iconsax.buildings_2, 'Barrio o Vereda'),
          const SizedBox(height: 10),
          _field(ctrl: _barrioCtrl, hint: 'Ej: Barrio Obrero, Vereda El Tres',
              icon: Iconsax.location,
              validator: (v) => (v == null || v.trim().length < 2) ? 'Campo requerido' : null),
          const SizedBox(height: 24),

          // ── Dirección exacta ────────────────────────────────────────────────
          _label(Iconsax.map, 'Dirección exacta'),
          const SizedBox(height: 10),
          _field(ctrl: _direccionCtrl, hint: 'Ej: Calle 12 #5-43, Casa 7',
              icon: Iconsax.map,
              validator: (v) => (v == null || v.trim().length < 5) ? 'Escribe la dirección completa' : null),
          const SizedBox(height: 24),

          // ── Referencia ──────────────────────────────────────────────────────
          _label(Iconsax.info_circle, 'Punto de referencia', optional: true),
          const SizedBox(height: 10),
          _field(ctrl: _referenciaCtrl, hint: 'Ej: Casa azul frente a la escuela',
              icon: Iconsax.location),
          const SizedBox(height: 24),

          // ── Teléfono ────────────────────────────────────────────────────────
          _label(Iconsax.call, 'Teléfono de contacto'),
          const SizedBox(height: 10),
          _field(
            ctrl: _telefonoCtrl, hint: 'Ej: 3001234567',
            icon: Icons.smartphone_rounded,
            inputType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu teléfono';
              final d = v.trim().replaceAll(RegExp(r'\D'), '');
              if (d.length != 10) return 'El número debe tener 10 dígitos';
              if (!RegExp(r'^3\d{9}$').hasMatch(d)) return 'Número colombiano inválido (debe empezar por 3)';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Toggle guardar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: AppTheme.radiusL,
              border: Border.all(color: _guardar ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.border),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.bookmark, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Guardar dirección',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Usarla como predeterminada la próxima vez',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted)),
              ])),
              Switch(
                value: _guardar,
                onChanged: (v) => setState(() => _guardar = v),
                activeColor: AppTheme.primary,
                activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.textMuted,
                inactiveTrackColor: AppTheme.surfaceHigh,
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Botón continuar ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _continuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
                elevation: 0,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Iconsax.arrow_right, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Continuar al pago',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _municipioChip(String nombre) {
    final isOtro = nombre == 'Otro';
    final selected = isOtro ? _showOtroField : _municipio == nombre && !_showOtroField;
    return GestureDetector(
      onTap: () => setState(() {
        _municipio = nombre;
        _showOtroField = isOtro;
        if (!isOtro) _otroMunicipioCtrl.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceHigh,
          borderRadius: AppTheme.radiusFull,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(nombre, style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _label(IconData icon, String text, {bool optional = false}) {
    return Row(children: [
      Icon(icon, size: 15, color: AppTheme.primary),
      const SizedBox(width: 6),
      Text(text, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      if (optional) ...[
        const SizedBox(width: 5),
        Text('(opcional)', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted)),
      ],
    ]);
  }

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? inputType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textDisabled),
        prefixIcon: Icon(icon, size: 19, color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.inputBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(borderRadius: AppTheme.radiusL,
            borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radiusL,
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: AppTheme.radiusL,
            borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: AppTheme.radiusL,
            borderSide: const BorderSide(color: AppTheme.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppTheme.radiusL,
            borderSide: const BorderSide(color: AppTheme.error, width: 2)),
      ),
    );
  }
}
