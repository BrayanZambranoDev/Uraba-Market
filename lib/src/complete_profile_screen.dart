import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_screen.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  String _userRole = 'Comprador';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor ingresa tu nombre',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(_nameController.text.trim());
      await _firestoreService.saveUser(user, additionalData: {
        'nombre': _nameController.text.trim(),
        'rol': _userRole,
        'perfilCompleto': true,
      });
    }

    if (!mounted) return;
    // No es necesario navegar aquí. El AuthWrapper se encargará de
    // redirigir a HomeScreen una vez que el perfil esté completo.
    // El estado de _isLoading se reseteará cuando el widget se reconstruya.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Ícono
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: AppTheme.orange, size: 36),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text('Un último paso',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Cuéntanos un poco sobre ti',
                  style: GoogleFonts.plusJakartaSans(
                      // Esto podría ser AppTheme.bodyMuted
                      fontSize: 14,
                      color: const Color(0xFF64748B)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 36),

              // Nombre
              Text('Nombre completo',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Tu nombre completo',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: AppTheme.textDisabled),
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: AppTheme.textDisabled, size: 19),
                  filled: true,
                  fillColor: AppTheme.background,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: OutlineInputBorder(
                      borderRadius: AppTheme.radiusM,
                      borderSide: const BorderSide(color: AppTheme.border)),
                  enabledBorder:
                      AppTheme.getTheme().inputDecorationTheme.enabledBorder,
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.green, width: 2)),
                ),
              ),
              const SizedBox(height: 20),

              // Rol
              Text('¿Cómo usarás la app?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 10),

              // Role selector cards
              Row(children: [
                _roleCard('Comprador', Icons.shopping_bag_outlined,
                    'Compra productos locales'),
                const SizedBox(width: 10),
                _roleCard('Comerciante', Icons.storefront_outlined,
                    'Vende tus productos'),
              ]),

              const Spacer(),

              // Botón
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: AppTheme.orange.withOpacity(0.35),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2.5))
                      : Text('Guardar y Continuar',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
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
            color: selected
                ? AppTheme.orange.withOpacity(0.08)
                : AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.orange : AppTheme.border,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? AppTheme.orange : AppTheme.textDisabled,
                size: 28),
            const SizedBox(height: 6),
            Text(role,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppTheme.orange : AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color:
                        selected ? AppTheme.textMuted : AppTheme.textDisabled),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
