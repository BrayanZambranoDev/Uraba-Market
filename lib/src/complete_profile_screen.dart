import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'services/firestore_service.dart';
import 'services/cloudinary_service.dart';
import 'theme/app_theme.dart';
import '../home_screen.dart';
import 'login_screen.dart';
import 'package:iconsax/iconsax.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  String _userRole = 'Comprador';
  bool _isLoading = false;
  XFile? _photoFile;
  String? _photoUrl;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) setState(() => _photoFile = picked);
  }

  void _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor ingresa tu nombre',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_photoFile != null) {
          final bytes = await _photoFile!.readAsBytes();
          _photoUrl =
              await CloudinaryService.uploadImage(bytes, folder: 'perfiles');
        }
        await user.updateDisplayName(_nameController.text.trim());
        await _firestoreService.saveUser(user, additionalData: {
          'nombre': _nameController.text.trim(),
          'rol': _userRole,
          'perfilCompleto': true,
          if (_photoUrl != null) 'photoURL': _photoUrl,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar el perfil. Intenta de nuevo.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  static const _bg = Color(0xFF060C07);
  static const _card = Color(0xFF0F1A10);
  static const _green = AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botón atrás
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.arrow_left,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAvatarSection(),
                const SizedBox(height: 28),
                _buildNameField(),
                const SizedBox(height: 24),
                _buildRoleSection(),
                const SizedBox(height: 20),
                _buildFeatureBadges(),
                const SizedBox(height: 24),
                _buildCTAButton(),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Iconsax.shield_tick,
                      size: 13, color: Colors.white.withValues(alpha: 0.35)),
                  const SizedBox(width: 5),
                  Text('Es rápido, fácil y seguro',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35))),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(children: [
      // Avatar con glow y hojas decorativas
      SizedBox(
        height: 160,
        child: Stack(alignment: Alignment.center, children: [
          // Glow de fondo
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _green.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          // Hojas decorativas
          Positioned(
            left: 20, top: 30,
            child: Transform.rotate(
              angle: -0.4,
              child: Icon(Iconsax.tree,
                  size: 32, color: _green.withValues(alpha: 0.5)),
            ),
          ),
          Positioned(
            right: 20, top: 30,
            child: Transform.rotate(
              angle: 0.4,
              child: Icon(Iconsax.tree,
                  size: 32, color: _green.withValues(alpha: 0.5)),
            ),
          ),
          // Círculo exterior con borde verde
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F1F10),
                  border: Border.all(color: _green, width: 2.5),
                ),
                child: ClipOval(
                  child: _photoFile != null
                      ? Image.file(File(_photoFile!.path), fit: BoxFit.cover)
                      : Icon(Iconsax.user,
                          color: _green.withValues(alpha: 0.7), size: 54),
                ),
              ),
              // Badge cámara
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 2.5),
                  ),
                  child: const Icon(Iconsax.camera,
                      color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      // Título
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          TextSpan(text: 'Completa tu ',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          TextSpan(text: 'perfil',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 26, fontWeight: FontWeight.w800, color: _green)),
        ]),
      ),
      const SizedBox(height: 6),
      Text('Un último paso para comenzar',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _buildNameField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Iconsax.user, size: 16, color: _green),
        const SizedBox(width: 6),
        Text('Nombre completo',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: _nameController,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: '¿Cómo te llamas?',
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(Iconsax.user,
              color: Colors.white.withValues(alpha: 0.35), size: 20),
          filled: true,
          fillColor: _card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.radiusM,
              borderSide: const BorderSide(color: _green, width: 1.8)),
        ),
      ),
    ]);
  }

  Widget _buildRoleSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Iconsax.tree, size: 16, color: _green),
        const SizedBox(width: 6),
        Text('¿Cómo usarás Urabá Market?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
      const SizedBox(height: 12),
      _roleCard('Comprador', Iconsax.bag,
          'Encuentra productos frescos\nde la región'),
      const SizedBox(height: 10),
      _roleCard('Comerciante', Iconsax.shop,
          'Vende y distribuye\nproductos locales'),
      const SizedBox(height: 10),
      _roleCard('Productor', Iconsax.sun_fog,
          'Vende directamente\nlo que cultivas'),
    ]);
  }

  Widget _roleCard(String role, IconData icon, String subtitle) {
    final selected = _userRole == role;
    return GestureDetector(
      onTap: () => setState(() => _userRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _green : _card,
          borderRadius: AppTheme.radiusM,
          border: Border.all(
            color: selected ? _green : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _green.withValues(alpha: 0.25),
                  blurRadius: 14, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.45),
                size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.45),
                      height: 1.4)),
            ]),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selected
                ? Container(
                    key: const ValueKey('check'),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.check,
                        color: Colors.white, size: 16),
                  )
                : Icon(Iconsax.arrow_right,
                    key: const ValueKey('arrow'),
                    color: Colors.white.withValues(alpha: 0.3), size: 22),
          ),
        ]),
      ),
    );
  }

  Widget _buildFeatureBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: AppTheme.radiusM,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        _featureBadge(Iconsax.tree, 'Productos\nfrescos', 'de la región'),
        _divider(),
        _featureBadge(Iconsax.shield_tick, 'Transacciones\nseguras', 'y confiables'),
        _divider(),
        _featureBadge(Iconsax.people, 'Apoya nuestra\ncomunidad', 'y productores'),
      ]),
    );
  }

  Widget _featureBadge(IconData icon, String title, String sub) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_green, _green.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                height: 1.3),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(sub,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.45)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 50,
      color: Colors.white.withValues(alpha: 0.08));

  Widget _buildCTAButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.send_1,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Comenzar ahora',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                const SizedBox(width: 12),
                const Icon(Iconsax.arrow_right,
                    color: Colors.black87, size: 20),
              ]),
      ),
    );
  }
}
