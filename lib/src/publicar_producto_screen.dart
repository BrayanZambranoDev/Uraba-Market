import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'services/cloudinary_service.dart';
import 'theme/app_theme.dart';
import 'constants/app_constants.dart';
import 'utils/validators.dart';
import 'package:iconsax/iconsax.dart';

class PublicarProductoScreen extends StatefulWidget {
  /// Si se pasan [productoId] y [productoData], la pantalla entra en modo edición.
  final String? productoId;
  final Map<String, dynamic>? productoData;

  const PublicarProductoScreen({
    super.key,
    this.productoId,
    this.productoData,
  });

  @override
  State<PublicarProductoScreen> createState() => _PublicarProductoScreenState();
}

class _PublicarProductoScreenState extends State<PublicarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _precioOriginalController = TextEditingController();
  final _stockController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _picker = ImagePicker();

  static const Color _orange = AppTheme.primary;
  static const Color _green = AppTheme.green;

  String _categoria = AppConstants.categorias.first;
  String _unidad = AppConstants.unidades.first;
  String _municipio = AppConstants.municipios.first;
  bool _isLoading = false;
  bool _tieneOferta = false;
  String? _userRol; // null = cargando

  static const int _maxImages = 4;
  final List<XFile> _newImageFiles = [];   // Nuevas imágenes locales a subir
  List<String> _existingImageUrls = [];    // URLs ya guardadas en Firestore

  bool get _isEditing => widget.productoId != null;

  Future<void> _loadUserRol() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    setState(() => _userRol = (doc.data()?['rol'] as String?) ?? 'Comprador');
  }

  @override
  void initState() {
    super.initState();
    _loadUserRol();
    // Pre-llenar campos si es modo edición
    final d = widget.productoData;
    if (d != null) {
      _nombreController.text = d['nombre'] ?? '';
      _descripcionController.text = d['descripcion'] ?? '';
      _precioController.text = (d['precio'] ?? '').toString();
      _stockController.text = (d['stock'] ?? '').toString();
      _categoria = AppConstants.categorias.contains(d['categoria'])
          ? d['categoria']
          : AppConstants.categorias.first;
      _unidad = AppConstants.unidades.contains(d['unidad'])
          ? d['unidad']
          : AppConstants.unidades.first;
      _municipio = AppConstants.municipios.contains(d['municipio'])
          ? d['municipio']
          : AppConstants.municipios.first;
      // Oferta / precio original
      final precioOrig = d['precioOriginal'];
      if (precioOrig != null) {
        _tieneOferta = true;
        _precioOriginalController.text = precioOrig.toString();
      }
      // Cargar URLs existentes: nuevo campo imagenUrls o fallback a imagenUrl
      final urls = d['imagenUrls'];
      if (urls is List && urls.isNotEmpty) {
        _existingImageUrls = List<String>.from(urls.whereType<String>());
      } else if (d['imagenUrl'] is String) {
        _existingImageUrls = [d['imagenUrl'] as String];
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _precioOriginalController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // ─── Selección de imagen ───────────────────────────────────────────────────

  int get _totalImages => _existingImageUrls.length + _newImageFiles.length;
  bool get _canAddMore => _totalImages < _maxImages;

  Future<void> _pickImage(ImageSource source) async {
    if (!_canAddMore) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200);
      if (picked != null) {
        setState(() => _newImageFiles.add(picked));
      }
    } catch (e) {
      if (!mounted) return;
      _showError('No se pudo acceder a la ${source == ImageSource.camera ? 'cámara' : 'galería'}.');
    }
  }

  void _showAddImageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Agregar foto ($_totalImages/$_maxImages)',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 16),
              _sheetOption(
                icon: Iconsax.camera,
                label: 'Tomar foto',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                }),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Iconsax.gallery,
                label: 'Elegir de la galería',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                }),
              const SizedBox(height: 8),
            ]))));
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.radiusM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: AppTheme.radiusM,
          border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ])));
  }

  // ─── Subida a Cloudinary ──────────────────────────────────────────────────

  Future<List<String>> _uploadNewImages() async {
    final uploaded = <String>[];
    for (final file in _newImageFiles) {
      final bytes = await file.readAsBytes();
      final url = await CloudinaryService.uploadImage(bytes, folder: 'productos');
      uploaded.add(url);
    }
    return uploaded;
  }

  // ─── Guardar (crear o editar) ──────────────────────────────────────────────

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Subir imágenes nuevas y combinar con las existentes
      final newUrls = await _uploadNewImages();
      final allUrls = [..._existingImageUrls, ...newUrls];

      final productoData = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'precio': double.tryParse(_precioController.text.trim()) ?? 0,
        'unidad': _unidad,
        'categoria': _categoria,
        'municipio': _municipio,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        // imagenUrl = primera imagen (backwards compat con cards existentes)
        'imagenUrl': allUrls.isNotEmpty ? allUrls.first : null,
        'imagenUrls': allUrls,
        'precioOriginal': _tieneOferta
            ? (double.tryParse(_precioOriginalController.text.trim()))
            : null,
      };

      if (_isEditing) {
        await _firestoreService.updateProduct(widget.productoId!, productoData);
      } else {
        await _firestoreService.publicarProducto(productoData);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle),
            child: const Icon(Iconsax.check,
                color: AppTheme.success, size: 40)),
          const SizedBox(height: 16),
          Text(
            _isEditing ? '¡Cambios guardados!' : '¡Producto publicado!',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            _isEditing
                ? 'Tu producto ha sido actualizado correctamente'
                : 'Tu producto ya está visible en el marketplace',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
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
                    borderRadius: AppTheme.radiusFull),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(
                _isEditing ? 'Volver a mis productos' : 'Ver en el marketplace',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: const Color(0xFF131C13))))),
          if (!_isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _nombreController.clear();
                _descripcionController.clear();
                _precioController.clear();
                _stockController.clear();
                setState(() {
                  _categoria = AppConstants.categorias.first;
                  _unidad = AppConstants.unidades.first;
                  _municipio = AppConstants.municipios.first;
                  _newImageFiles.clear();
                  _existingImageUrls.clear();
                });
              },
              child: Text('Publicar otro producto',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, color: _orange))),
          ],
        ])));
  }


  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF131C13))),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
      margin: const EdgeInsets.all(12)));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Mientras carga el rol
    if (_userRol == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }

    // Bloqueado: solo Comerciante y Productor pueden publicar
    if (_userRol == 'Comprador') {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F0A),
        body: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                      child: const Icon(Iconsax.shop,
                          color: AppTheme.primary, size: 40)),
                    const SizedBox(height: 20),
                    Text('Solo vendedores pueden publicar',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Colors.white),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text('Cambia tu rol a Comerciante o Productor en tu perfil para publicar productos.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)), textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.radiusFull),
                          elevation: 0),
                        child: Text('Volver', style: AppTheme.buttonText))),
                  ])))),
          ])));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Imagen ──
                    _buildImagePicker(),
                    const SizedBox(height: 20),

                    // ── Nombre ──
                    _label('Nombre del producto *'),
                    const SizedBox(height: 6),
                    _field(
                      controller: _nombreController,
                      hint: 'Ej: Banano premium maduro',
                      icon: Iconsax.box,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'El nombre')),
                    const SizedBox(height: 16),

                    // ── Categoría ──
                    _label('Categoría *'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _categoria,
                      items: AppConstants.categorias,
                      icon: Iconsax.category,
                      onChanged: (v) => setState(() => _categoria = v!)),
                    const SizedBox(height: 16),

                    // ── Municipio ──
                    _label('Municipio'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _municipio,
                      items: AppConstants.municipios,
                      icon: Iconsax.location,
                      onChanged: (v) => setState(() => _municipio = v!)),
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
                          icon: Iconsax.dollar_circle,
                          type: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: Validators.precio)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          value: _unidad,
                          items: AppConstants.unidades,
                          icon: Iconsax.ruler,
                          onChanged: (v) => setState(() => _unidad = v!))),
                    ]),
                    const SizedBox(height: 16),

                    // ── Stock ──
                    _label('Stock disponible *'),
                    const SizedBox(height: 6),
                    _field(
                      controller: _stockController,
                      hint: 'Ej: 100',
                      icon: Iconsax.element_3,
                      type: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: Validators.stock),
                    const SizedBox(height: 16),

                    // ── Oferta / precio rebajado ──
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _tieneOferta
                            ? _orange.withValues(alpha: 0.05)
                            : const Color(0xFF0A0F0A),
                        borderRadius: AppTheme.radiusM,
                        border: Border.all(
                          color: _tieneOferta
                              ? _orange.withValues(alpha: 0.35)
                              : AppTheme.border)),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _tieneOferta
                                ? _orange.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: AppTheme.radiusS),
                          child: Icon(Iconsax.discount_circle,
                              size: 18,
                              color: _tieneOferta ? _orange : AppTheme.textMuted)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Precio con descuento',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text('Muestra el precio original tachado',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
                              ])),
                        Switch.adaptive(
                          value: _tieneOferta,
                          onChanged: (v) => setState(() => _tieneOferta = v),
                          activeThumbColor: Colors.white,
                          activeTrackColor: _orange),
                      ])),
                    if (_tieneOferta) ...[
                      const SizedBox(height: 12),
                      _label('Precio original (antes del descuento) *'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _precioOriginalController,
                        hint: 'Ej: 6000',
                        icon: Iconsax.discount_circle,
                        type: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          final orig = double.tryParse(v ?? '');
                          final actual = double.tryParse(
                              _precioController.text.trim());
                          if (orig == null || orig <= 0) {
                            return 'Ingresa el precio original';
                          }
                          if (actual != null && orig <= actual) {
                            return 'Debe ser mayor al precio actual';
                          }
                          return null;
                        }),
                    ],
                    const SizedBox(height: 16),

                    // ── Descripción ──
                    _label('Descripción (opcional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Describe tu producto: variedad, origen, características...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: AppTheme.textDisabled),
                        filled: true,
                        fillColor: const Color(0xFF0A0F0A),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                            borderRadius: AppTheme.radiusM,
                            borderSide:
                                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: AppTheme.radiusM,
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08), width: 1.5)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: AppTheme.radiusM,
                            borderSide:
                                const BorderSide(color: _green, width: 2)))),
                    const SizedBox(height: 28),

                    // ── Botón guardar / publicar ──
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
                            : Icon(
                                _isEditing
                                    ? Iconsax.tick_circle
                                    : Iconsax.export_3,
                                color: Colors.white,
                                size: 20),
                        label: Text(
                          _isLoading
                              ? (_isEditing ? 'Guardando...' : 'Publicando...')
                              : (_isEditing
                                  ? 'Guardar cambios'
                                  : 'Publicar producto'),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.radiusFull),
                          elevation: 0))),
                    const SizedBox(height: 16),
                  ])))),
        ])));
  }

  Widget _buildImagePicker() {
    // Construir la lista de todos los thumbnails (existentes + nuevos) + botón "+"
    final allThumbs = <Widget>[];

    // URLs existentes (modo edición)
    for (int i = 0; i < _existingImageUrls.length; i++) {
      allThumbs.add(_imageTile(
        child: CachedNetworkImage(
          imageUrl: _existingImageUrls[i],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
          errorWidget: (_, __, ___) =>
              Icon(Icons.broken_image_outlined, color: Colors.white.withValues(alpha: 0.45))),
        onRemove: () => setState(() => _existingImageUrls.removeAt(i))));
    }

    // Nuevas imágenes locales
    for (int i = 0; i < _newImageFiles.length; i++) {
      allThumbs.add(_imageTile(
        child: Image.file(File(_newImageFiles[i].path),
            fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        onRemove: () => setState(() => _newImageFiles.removeAt(i))));
    }

    // Botón agregar (si hay espacio)
    if (_canAddMore) {
      allThumbs.add(GestureDetector(
        onTap: _showAddImageSheet,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F0A),
            borderRadius: AppTheme.radiusM,
            border: Border.all(
                color: _orange.withValues(alpha: 0.4),
                width: 1.5,
                style: BorderStyle.solid)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.camera, color: _orange, size: 24),
              const SizedBox(height: 4),
              Text('Foto', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45)).copyWith(color: _orange, fontSize: 10)),
            ]))));
    }

    if (allThumbs.isEmpty) {
      // Sin imágenes aún — placeholder grande
      return GestureDetector(
        onTap: _showAddImageSheet,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F0A),
            borderRadius: AppTheme.radiusL,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Iconsax.camera, color: _orange, size: 24)),
              const SizedBox(height: 8),
              Text('Agregar hasta $_maxImages fotos',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 2),
              Text('Opcional · Cámara o galería', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
            ])));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allThumbs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => allThumbs[i])),
        const SizedBox(height: 6),
        Text('$_totalImages/$_maxImages fotos · Toca la X para eliminar',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
      ]);
  }

  Widget _imageTile({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: AppTheme.radiusM,
          child: SizedBox(width: 90, height: 90, child: child)),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A0F0A), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: const Icon(Iconsax.close_circle, color: Colors.white, size: 14)))),
      ]);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFF0A0F0A),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle),
            child: Icon(Iconsax.arrow_left,
                color: AppTheme.primary, size: 20))),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _isEditing ? 'Editar producto' : 'Publicar producto',
            style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppTheme.primary)),
          Text(
            _isEditing
                ? 'Actualiza la información de tu producto'
                : 'Llega a más compradores en Urabá',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ]),
      ]));
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.6)));

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
            color: Colors.white,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppTheme.textDisabled),
          prefixIcon: Icon(icon, color: AppTheme.textDisabled, size: 19),
          filled: true,
          fillColor: const Color(0xFF0A0F0A),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: _green, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide:
                  const BorderSide(color: AppTheme.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: AppTheme.error, width: 2)),
          errorStyle: GoogleFonts.plusJakartaSans(fontSize: 10)));

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F0A),
          borderRadius: AppTheme.radiusM,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5)),
        child: Row(children: [
          Icon(icon, color: AppTheme.textDisabled, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13))))
                    .toList(),
                onChanged: onChanged))),
        ]));
}
