import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  String _userRole = 'Comprador';
  bool _isLoading = false;
  bool _isSaving = false;

  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    if (_user == null) return;
    setState(() => _isLoading = true);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['nombre'] ?? _user!.displayName ?? '';
      setState(() {
        _userRole = data['rol'] ?? 'Comprador';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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

    setState(() => _isSaving = true);

    try {
      if (_user != null) {
        await _user!.updateDisplayName(_nameController.text.trim());
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({
          'nombre': _nameController.text.trim(),
          'rol': _userRole,
        });
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Perfil actualizado ✓',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar. Intenta de nuevo.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.orange))
            : Column(
                children: [
                  // Header
                  Container(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                        gradient: AppTheme.orangeGradient),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: AppTheme.radiusS,
                            ),
                            child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Editar perfil',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Avatar
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: AppTheme.orangeGradient,
                                shape: BoxShape.circle,
                                boxShadow: [AppTheme.shadowOrange],
                              ),
                              child: Center(
                                child: Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0]
                                          .toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Nombre
                          Text('Nombre completo',
                              style: AppTheme.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            style: AppTheme.body,
                            onChanged: (_) => setState(() {}),
                            decoration: AppTheme.inputDecoration(
                              hint: 'Tu nombre completo',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Rol
                          Text('¿Cómo usas la app?',
                              style: AppTheme.label),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _roleCard(
                                  'Comprador',
                                  Icons.shopping_bag_outlined,
                                  'Compra productos'),
                              const SizedBox(width: 10),
                              _roleCard(
                                  'Comerciante',
                                  Icons.storefront_outlined,
                                  'Vende productos'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Email (no editable)
                          Text('Correo electrónico',
                              style: AppTheme.label),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0)
                                  .withOpacity(0.5),
                              borderRadius: AppTheme.radiusM,
                              border: Border.all(
                                  color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.mail_outline_rounded,
                                    color: AppTheme.textMuted,
                                    size: 19),
                                const SizedBox(width: 10),
                                Text(_user?.email ?? 'Sin correo',
                                    style: AppTheme.body.copyWith(
                                        color: AppTheme.textMuted)),
                                const Spacer(),
                                const Icon(Icons.lock_outline,
                                    color: AppTheme.textMuted,
                                    size: 14),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Guardar
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                disabledBackgroundColor:
                                    Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppTheme.radiusM),
                                elevation: 4,
                                shadowColor: AppTheme.orange
                                    .withOpacity(0.35),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5))
                                  : Text('Guardar cambios',
                                      style: AppTheme.buttonText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _roleCard(String role, IconData icon, String subtitle) {
    final selected = _userRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                selected ? AppTheme.orange.withOpacity(0.08) : AppTheme.bg,
            borderRadius: AppTheme.radiusM,
            border: Border.all(
              color: selected ? AppTheme.orange : AppTheme.border,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color:
                      selected ? AppTheme.orange : AppTheme.textMuted,
                  size: 28),
              const SizedBox(height: 6),
              Text(role,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.orange
                          : AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTheme.caption,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
