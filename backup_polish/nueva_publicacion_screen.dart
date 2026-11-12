import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme/app_theme.dart';
import 'services/cloudinary_service.dart';
import 'package:iconsax/iconsax.dart';

// Gradientes de fondo (sincronizado con feed_screen.dart)
const List<List<Color>> kPostBgGradients = [
  [Color(0xFF1C3320), Color(0xFFEF4444)],
  [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
  [Color(0xFF10B981), Color(0xFF3B82F6)],
  [Color(0xFFF59E0B), Color(0xFF10B981)],
  [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  [Color(0xFF0F172A), Color(0xFF1E293B)],
];

enum _PostTipo { normal, oferta, pregunta, evento }

class NuevaPublicacionScreen extends StatefulWidget {
  const NuevaPublicacionScreen({super.key});

  @override
  State<NuevaPublicacionScreen> createState() =>
      _NuevaPublicacionScreenState();
}

class _NuevaPublicacionScreenState extends State<NuevaPublicacionScreen> {
  final _textoCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  List<XFile> _images = [];
  List<Uint8List> _imageBytes = [];
  bool _loading = false;
  bool _pickingImage = false;
  _PostTipo _tipo = _PostTipo.normal;
  int? _bgIndex; // null = sin fondo de color

  String? _userNombre;
  String? _userFoto;
  String? _userRol;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _textoCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (mounted) {
      setState(() {
        _userNombre = data?['nombre'] ?? data?['displayName'] ?? 'Usuario';
        _userFoto = data?['photoURL'] as String?;
        _userRol = data?['rol'] as String?;
      });
    }
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    _ubicacionCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_pickingImage || _images.length >= 4) return;
    _pickingImage = true;
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final picked = await picker.pickMultiImage(imageQuality: 80);
        if (picked.isNotEmpty) {
          final remaining = 4 - _images.length;
          final toAdd = picked.take(remaining).toList();
          final bytes =
              await Future.wait(toAdd.map((f) => f.readAsBytes()));
          setState(() {
            _images.addAll(toAdd);
            _imageBytes.addAll(bytes);
            _bgIndex = null;
          });
        }
      } else {
        final image =
            await picker.pickImage(source: source, imageQuality: 80);
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _images.add(image);
            _imageBytes.add(bytes);
            _bgIndex = null;
          });
        }
      }
    } finally {
      _pickingImage = false;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageBytes.removeAt(index);
    });
  }

  Future<void> _publish() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Escribe algo o agrega una foto',
            style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM),
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final List<String> imagenURLs = [];
      for (final bytes in _imageBytes) {
        final url = await CloudinaryService.uploadImage(
            bytes, folder: 'publicaciones');
        imagenURLs.add(url);
      }

      await FirebaseFirestore.instance.collection('publicaciones').add({
        'autorId': user.uid,
        'autorNombre': _userNombre ?? 'Usuario',
        'autorFoto': _userFoto,
        'autorRol': _userRol ?? '',
        'texto': texto,
        'ubicacion': _ubicacionCtrl.text.trim(),
        'imagenURL': imagenURLs.isNotEmpty ? imagenURLs.first : null,
        'imagenURLs': imagenURLs,
        'tipo': _tipo.name,
        'bgIndex': _bgIndex,
        'likes': [],
        'comentariosCount': 0,
        'vistas': 0,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Publicación creada!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error publicando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al publicar',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusM),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: AppTheme.radiusFull),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.1),
                    borderRadius: AppTheme.radiusM),
                child: const Icon(Iconsax.gallery,
                    color: AppTheme.orange),
              ),
              title: Text('Galería',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Selecciona hasta ${4 - _images.length} foto(s)',
                  style: AppTheme.caption),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.1),
                    borderRadius: AppTheme.radiusM),
                child: const Icon(Iconsax.camera,
                    color: AppTheme.green),
              ),
              title: Text('Cámara',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBg = _bgIndex != null && _images.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.close_circle,
              color: AppTheme.textPrimary.withValues(alpha: 0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nueva publicación',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppTheme.orange, strokeWidth: 2.5))
                : TextButton(
                    onPressed: _publish,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.radiusM),
                    ),
                    child: Text('Publicar',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.orangeGradient),
                    clipBehavior: Clip.antiAlias,
                    child: _userFoto != null
                        ? CachedNetworkImage(
                            imageUrl: _userFoto!, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                                _userNombre?.isNotEmpty == true
                                    ? _userNombre![0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontSize: 18)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userNombre ?? 'Usuario',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textPrimary)),
                      if (_userRol != null && _userRol!.isNotEmpty)
                        Text(_userRol!, style: AppTheme.caption),
                    ],
                  ),
                ],
              ),
            ),

            // ── Text area (con fondo opcional) ───────────────────
            GestureDetector(
              onTap: () => FocusScope.of(context).requestFocus(_textFocus),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                decoration: BoxDecoration(
                  gradient: hasBg
                      ? LinearGradient(
                          colors: kPostBgGradients[_bgIndex!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                      : null,
                  color: hasBg ? null : AppTheme.cardBg,
                  borderRadius: AppTheme.radiusL,
                  boxShadow: AppTheme.shadowSm,
                ),
                child: TextField(
                  controller: _textoCtrl,
                  focusNode: _textFocus,
                  maxLines: hasBg ? 6 : 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  textAlign: hasBg ? TextAlign.center : TextAlign.start,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: hasBg ? 20 : 15,
                    fontWeight:
                        hasBg ? FontWeight.w700 : FontWeight.w500,
                    color: hasBg ? Colors.white : AppTheme.textPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: hasBg
                        ? 'Escribe algo...'
                        : '¿Qué quieres compartir? Cuéntale a la gente dónde estás o qué tienes disponible hoy...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: hasBg ? 20 : 14,
                        color: hasBg
                            ? Colors.white60
                            : AppTheme.textMuted,
                        height: 1.5),
                    filled: !hasBg,
                    fillColor: AppTheme.cardBg,
                    border: OutlineInputBorder(
                        borderRadius: AppTheme.radiusL,
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: AppTheme.radiusL,
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: AppTheme.radiusL,
                        borderSide: hasBg
                            ? BorderSide.none
                            : const BorderSide(
                                color: AppTheme.orange, width: 2)),
                    contentPadding: EdgeInsets.all(hasBg ? 24 : 16),
                    counterStyle: AppTheme.caption.copyWith(
                        color:
                            hasBg ? Colors.white60 : null),
                  ),
                ),
              ),
            ),

            // ── Tipo de publicación ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tipoChip(_PostTipo.normal, Iconsax.notification, 'Normal'),
                    const SizedBox(width: 8),
                    _tipoChip(_PostTipo.oferta, Iconsax.discount_circle, 'Oferta'),
                    const SizedBox(width: 8),
                    _tipoChip(_PostTipo.pregunta, Iconsax.info_circle, 'Pregunta'),
                    const SizedBox(width: 8),
                    _tipoChip(_PostTipo.evento, Iconsax.location, 'Evento'),
                  ],
                ),
              ),
            ),

            // ── Fondos de color (solo sin imágenes) ──────────────
            if (_images.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Text('Fondo:', style: AppTheme.caption),
                    const SizedBox(width: 10),
                    // Opción: sin fondo
                    GestureDetector(
                      onTap: () => setState(() => _bgIndex = null),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _bgIndex == null
                                  ? AppTheme.orange
                                  : AppTheme.border,
                              width: _bgIndex == null ? 2.5 : 1),
                        ),
                        child: _bgIndex == null
                            ? const Icon(Iconsax.text,
                                size: 14, color: AppTheme.orange)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...List.generate(
                      kPostBgGradients.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _bgIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: _bgIndex == i ? 34 : 28,
                            height: _bgIndex == i ? 34 : 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: kPostBgGradients[i],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _bgIndex == i
                                      ? AppTheme.textPrimary
                                      : Colors.transparent,
                                  width: 2.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Fotos ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _images.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length +
                                (_images.length < 4 ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              if (i == _images.length) {
                                return _addTile();
                              }
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: AppTheme.radiusM,
                                    child: Image.memory(_imageBytes[i],
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(i),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle),
                                        child: const Icon(
                                            Iconsax.close_circle,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  if (i == 0)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              AppTheme.radiusFull,
                                        ),
                                        child: Text('Portada',
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color:
                                                        Colors.white)),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('Máx. 4 fotos • La primera es la portada',
                            style: AppTheme.caption),
                      ],
                    )
                  : _addButton(),
            ),

            const SizedBox(height: 16),

            // ── Ubicación ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: AppTheme.radiusL),
                child: TextField(
                  controller: _ubicacionCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTheme.body,
                  decoration: InputDecoration(
                    hintText: 'Añadir ubicación...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Iconsax.location,
                        color: Color(0xFF3B82F6), size: 20),
                    filled: true,
                    fillColor: AppTheme.cardBg,
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: AppTheme.radiusL,
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: AppTheme.radiusL,
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: AppTheme.radiusL,
                        borderSide: const BorderSide(
                            color: AppTheme.orange, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Publicar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusM),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _publish,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Iconsax.send_1, size: 18),
                  label: Text(
                    _loading ? 'Publicando...' : 'Publicar',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoChip(_PostTipo tipo, IconData icon, String label) {
    final selected = _tipo == tipo;
    return GestureDetector(
      onTap: () => setState(() => _tipo = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.orange : AppTheme.surfaceHigh,
          borderRadius: AppTheme.radiusFull,
          border: Border.all(
              color: selected ? AppTheme.orange : AppTheme.border),
          boxShadow: selected ? AppTheme.shadowOrangeList : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _addTile() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusM,
          border:
              Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.add,
                color: AppTheme.orange, size: 30),
            const SizedBox(height: 4),
            Text('Agregar', style: AppTheme.caption),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: AppTheme.radiusL,
          border: Border.all(
              color: AppTheme.border,
              style: BorderStyle.solid,
              width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color:
                      AppTheme.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(
                  Iconsax.gallery_add,
                  size: 26,
                  color: AppTheme.orange),
            ),
            const SizedBox(height: 10),
            Text('Agregar fotos',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 3),
            Text('Galería o cámara • hasta 4 fotos',
                style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}
