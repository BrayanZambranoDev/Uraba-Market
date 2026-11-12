import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/cloudinary_service.dart';
import 'theme/app_theme.dart';
import 'constants/app_constants.dart';
import 'package:iconsax/iconsax.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  String _userRole = 'Comprador';
  String? _municipio;
  bool _isLoading = true;
  bool _isSaving = false;

  XFile? _imageFile;
  String? _photoUrl;
  final _picker = ImagePicker();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['nombre'] ?? _user!.displayName ?? '';
      _bioController.text = (data['bio'] as String?) ?? '';
      _phoneController.text = (data['telefono'] as String?) ?? '';
      setState(() {
        _userRole = data['rol'] ?? 'Comprador';
        _municipio = data['municipio'] as String?;
        _photoUrl = data['photoURL'] as String?;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600);
    if (picked != null && mounted) setState(() => _imageFile = picked);
  }

  Future<String?> _uploadPhoto() async {
    if (_imageFile == null) return null;
    final bytes = await _imageFile!.readAsBytes();
    return await CloudinaryService.uploadImage(bytes, folder: 'perfiles');
  }

  void _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Por favor ingresa tu nombre');
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (_imageFile != null) _photoUrl = await _uploadPhoto();
      await _user!.updateDisplayName(_nameController.text.trim());
      if (_photoUrl != null) await _user!.updatePhotoURL(_photoUrl);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'nombre': _nameController.text.trim(),
        'rol': _userRole,
        'bio': _bioController.text.trim(),
        'telefono': _phoneController.text.trim(),
        if (_municipio != null) 'municipio': _municipio,
        if (_photoUrl != null) 'photoURL': _photoUrl,
      });
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Perfil actualizado',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12)));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.plusJakartaSans(color: Colors.white)),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
      margin: const EdgeInsets.all(12)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                _buildHero(),
                Expanded(child: _buildForm()),
              ]));
  }

  // ── Hero oscuro con avatar grande ────────────────────────────────
  Widget _buildHero() {
    return Container(
      color: const Color(0xFF0A0F0A),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barra superior
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle),
                      child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20))),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Editar perfil', style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Actualiza tu información personal', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
                  ]),
                ])),

            const SizedBox(height: 24),

            // Avatar grande con botón de cámara
            GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF131C13),
                      border: Border.all(color: AppTheme.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 2),
                      ]),
                    clipBehavior: Clip.antiAlias,
                    child: _buildAvatar()),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0F0A), width: 2.5)),
                    child: const Icon(Iconsax.camera,
                        color: Colors.white, size: 16)),
                ])),

            const SizedBox(height: 10),
            Text('Toca para cambiar foto',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45))),
            const SizedBox(height: 24),
          ])));
  }

  Widget _buildAvatar() {
    if (_imageFile != null) {
      return Image.file(File(_imageFile!.path), fit: BoxFit.cover);
    }
    if (_photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: _photoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _avatarInitial(),
        errorWidget: (_, __, ___) => _avatarInitial());
    }
    return _avatarInitial();
  }

  Widget _avatarInitial() {
    final letter = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : 'U';
    return Center(
      child: Text(letter,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)));
  }

  // ── Formulario ────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nombre
          _sectionLabel('Nombre completo'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
            onChanged: (_) => setState(() {}),
            decoration: AppTheme.inputDecoration(
              hint: 'Tu nombre completo',
              icon: Iconsax.user)),
          const SizedBox(height: 16),

          // Bio / descripción
          _sectionLabel('Descripción (opcional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
            maxLines: 3,
            maxLength: 200,
            decoration: AppTheme.inputDecoration(
              hint: 'Cuéntale a los compradores quién eres...',
              icon: Iconsax.info_circle)),
          const SizedBox(height: 16),

          // Teléfono WhatsApp
          _sectionLabel('Teléfono WhatsApp (opcional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: AppTheme.inputDecoration(
              hint: 'Ej: 3001234567',
              icon: Iconsax.call).copyWith(
              counterText: '',
              helperText: 'Sin código de país. Los clientes te contactarán por WhatsApp.',
              helperStyle: AppTheme.caption)),
          const SizedBox(height: 16),

          // Municipio
          _sectionLabel('Municipio (opcional)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: AppTheme.radiusM,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  value: _municipio,
                  hint: Row(children: [
                    const Icon(Iconsax.location,
                        color: AppTheme.textDisabled, size: 19),
                    const SizedBox(width: 8),
                    Text('Selecciona tu municipio',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: AppTheme.textDisabled)),
                  ]),
                  isExpanded: true,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                  borderRadius: AppTheme.radiusM,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Ninguno',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, color: Colors.white.withValues(alpha: 0.45)))),
                    ...AppConstants.municipios.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m))),
                  ],
                  onChanged: (val) => setState(() => _municipio = val))))),
          const SizedBox(height: 16),

          // Rol
          _sectionLabel('¿Cómo usas la app?'),
          const SizedBox(height: 10),
          Row(
            children: [
              _roleCard('Comprador', Iconsax.bag, 'Explora y compra'),
              const SizedBox(width: 8),
              _roleCard('Comerciante', Iconsax.shop, 'Vende y revende'),
              const SizedBox(width: 8),
              _roleCard('Productor', Iconsax.sun_fog, 'Vendo lo que produzco'),
            ]),
          const SizedBox(height: 24),

          // Correo (no editable)
          _sectionLabel('Correo electrónico'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
              borderRadius: AppTheme.radiusM,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: Row(
              children: [
                Icon(Iconsax.sms,
                    color: Colors.white.withValues(alpha: 0.45), size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_user?.email ?? 'Sin correo',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))
                          .copyWith(color: Colors.white.withValues(alpha: 0.45)))),
                Icon(Iconsax.lock,
                    color: Colors.white.withValues(alpha: 0.45), size: 14),
              ])),
          const SizedBox(height: 36),

          // Botón guardar
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusFull),
                elevation: 0,
                shadowColor: Colors.transparent),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.check,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Guardar cambios', style: AppTheme.buttonText),
                      ]))),
        ]));
  }

  Widget _sectionLabel(String text) => Text(text, style: AppTheme.label);

  Future<void> _onRoleTap(String role) async {
    if (role == _userRole) return;
    // Advertencia al bajar de Comerciante/Productor a Comprador
    final esVendedor = _userRole == 'Comerciante' || _userRole == 'Productor';
    if (esVendedor && role == 'Comprador') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
          title: Text('¿Cambiar a Comprador?',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          content: Text(
            'Perderás acceso a la gestión de productos y publicaciones. Tus productos existentes permanecerán pero no podrás administrarlos.',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusFull),
                elevation: 0),
              child: Text('Sí, cambiar',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: Colors.white))),
          ]));
      if (confirmed != true) return;
    }
    setState(() => _userRole = role);
  }

  Widget _roleCard(String role, IconData icon, String subtitle) {
    final selected = _userRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleTap(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.12)
                : AppTheme.cardBg,
            borderRadius: AppTheme.radiusL,
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 2 : 1.5),
            boxShadow: selected ? AppTheme.shadowSm : []),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : AppTheme.bg,
                  shape: BoxShape.circle),
                child: Icon(icon,
                    color: selected ? AppTheme.primary : AppTheme.textMuted,
                    size: 22)),
              const SizedBox(height: 8),
              Text(role,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppTheme.primary : AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45)), textAlign: TextAlign.center),
            ]))));
  }
}
