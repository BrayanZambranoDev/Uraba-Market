import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/firestore_service.dart';

class PublicarProductoScreen extends StatefulWidget {
  const PublicarProductoScreen({super.key});

  @override
  State<PublicarProductoScreen> createState() => _PublicarProductoScreenState();
}

class _PublicarProductoScreenState extends State<PublicarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _firestoreService = FirestoreService();

  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF0DF220);

  String _categoria = 'Frutas';
  String _unidad = 'kg';
  bool _isLoading = false;

  final List<String> _categorias = [
    'Frutas',
    'Verduras',
    'Artesanías',
    'Gastronomía',
    'Otros'
  ];

  final List<String> _unidades = [
    'kg',
    'libra',
    'unidad',
    'docena',
    'bulto',
    'canasta',
    'litro'
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productoData = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'precio': double.tryParse(_precioController.text.trim()) ?? 0,
        'unidad': _unidad,
        'categoria': _categoria,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
      };

      await _firestoreService.publicarProducto(productoData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Éxito
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error al publicar. Intenta de nuevo.');
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF16A34A), size: 40),
          ),
          const SizedBox(height: 16),
          Text('¡Producto publicado!',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text('Tu producto ya está visible en el marketplace',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Ver en el marketplace',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Limpiar formulario para publicar otro
              _nombreController.clear();
              _descripcionController.clear();
              _precioController.clear();
              _stockController.clear();
              setState(() {
                _categoria = 'Frutas';
                _unidad = 'kg';
              });
            },
            child: Text('Publicar otro producto',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, color: _orange)),
          ),
        ]),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Nombre ──
                    _label('Nombre del producto *'),
                    const SizedBox(height: 6),
                    _field(
                      controller: _nombreController,
                      hint: 'Ej: Banano premium maduro',
                      icon: Icons.inventory_2_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El nombre es obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Categoría ──
                    _label('Categoría *'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _categoria,
                      items: _categorias,
                      icon: Icons.category_outlined,
                      onChanged: (v) => setState(() => _categoria = v!),
                    ),
                    const SizedBox(height: 16),

                    // ── Precio y unidad ──
                    _label('Precio y unidad *'),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        flex: 2,
                        child: _field(
                          controller: _precioController,
                          hint: 'Ej: 4500',
                          icon: Icons.attach_money_rounded,
                          type: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa el precio';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Precio inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          value: _unidad,
                          items: _unidades,
                          icon: Icons.straighten_rounded,
                          onChanged: (v) => setState(() => _unidad = v!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Stock ──
                    _label('Stock disponible *'),
                    const SizedBox(height: 6),
                    _field(
                      controller: _stockController,
                      hint: 'Ej: 100',
                      icon: Icons.layers_outlined,
                      type: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa el stock disponible'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Descripción ──
                    _label('Descripción (opcional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText:
                            'Describe tu producto: variedad, origen, características...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0), width: 1.5)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _green, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Botón publicar ──
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _publicar,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Icon(Icons.upload_rounded,
                                color: Colors.white, size: 20),
                        label: Text(
                          _isLoading ? 'Publicando...' : 'Publicar producto',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: _orange.withOpacity(0.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Publicar producto',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text('Llega a más compradores en Urabá',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.white70)),
        ]),
      ]),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151)));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: type,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 19),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
          errorStyle: GoogleFonts.plusJakartaSans(fontSize: 10),
        ),
      );

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500),
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13))))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ]),
      );
}
